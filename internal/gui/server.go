// Package gui implements the local, browser-based user interface.
package gui

import (
	"archive/zip"
	"context"
	"crypto/rand"
	"embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"io/fs"
	"log"
	"mime/multipart"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"

	"oa-satzsystem/internal/build"
	"oa-satzsystem/internal/project"
)

//go:embed assets/*
var assets embed.FS

type buildFunc func(context.Context, string, []build.Format, string) ([]build.Artifact, error)

// Server owns the small in-memory state shared by HTTP requests.
type Server struct {
	root         string
	projectsDir  string
	templates    *template.Template
	build        buildFunc
	mux          *http.ServeMux
	projectMu    sync.Mutex
	mu           sync.RWMutex
	jobs         map[string]*Job
	queue        []queuedBuild
	queueWake    chan struct{}
	workerWG     sync.WaitGroup
	requestMu    sync.Mutex
	requestWG    sync.WaitGroup
	shuttingDown bool
	// outputRoot is set only in the desktop GUI. All finished local builds are
	// published into the single Outputs directory beside the application.
	outputRoot string
	// artifactRoot is set only in server mode. Server builds publish into this
	// process-owned temporary directory instead of a project's Outputs folder.
	artifactRoot string
	// temporaryProjects is enabled only by oa serve. Imported sources are then
	// removed as soon as their queued build has finished or been cancelled.
	temporaryProjects bool
	jobRetention      time.Duration
	downloadGrace     time.Duration
	projectRetention  time.Duration
	// localHost is set only by oa gui. Requiring this exact loopback host blocks
	// other websites from reaching the unauthenticated local API via DNS rebinding.
	localHost string
	lifecycle *localLifecycle
}

type localLifecycle struct {
	mu               sync.Mutex
	clients          map[string]localClient
	seenClient       bool
	heartbeatTimeout time.Duration
	closeGrace       time.Duration
	done             chan struct{}
	once             sync.Once
}

type localClient struct {
	deadline time.Time
	closing  bool
}

func newLocalLifecycle(heartbeatTimeout, closeGrace time.Duration) *localLifecycle {
	return &localLifecycle{
		clients: make(map[string]localClient), heartbeatTimeout: heartbeatTimeout,
		closeGrace: closeGrace, done: make(chan struct{}),
	}
}

func (l *localLifecycle) heartbeat(id string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.seenClient = true
	if client, exists := l.clients[id]; exists && client.closing {
		return
	}
	l.clients[id] = localClient{deadline: time.Now().Add(l.heartbeatTimeout)}
}

func (l *localLifecycle) closing(id string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.seenClient = true
	l.clients[id] = localClient{deadline: time.Now().Add(l.closeGrace), closing: true}
}

func (l *localLifecycle) watch(ctx context.Context) {
	interval := l.closeGrace / 4
	if interval <= 0 || interval > time.Second {
		interval = time.Second
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case now := <-ticker.C:
			l.mu.Lock()
			for id, client := range l.clients {
				if !now.Before(client.deadline) {
					delete(l.clients, id)
				}
			}
			finished := l.seenClient && len(l.clients) == 0
			l.mu.Unlock()
			if finished {
				l.once.Do(func() { close(l.done) })
				return
			}
		}
	}
}

// Job is the browser-visible state of one asynchronous build.
type Job struct {
	ID              string         `json:"id"`
	Project         string         `json:"project"`
	Status          string         `json:"status"`
	Progress        int            `json:"progress"`
	Logs            []string       `json:"logs"`
	Artifacts       []artifactLink `json:"artifacts"`
	Created         time.Time      `json:"-"`
	QueuePosition   int            `json:"queuePosition,omitempty"`
	downloads       map[string]downloadArtifact
	projectDir      string
	expiresAt       time.Time
	activeDownloads int
	cleaning        bool
}

type downloadArtifact struct {
	name string
	path string
}

type queuedBuild struct {
	jobID      string
	projectDir string
	formats    []build.Format
}

const (
	serverAreaPrefix        = ".oa-server-"
	serverAreaMarker        = ".oa-server-owned"
	serverAreaMarkerValue   = "oa-satzsystem temporary server area\n"
	serverAreaStaleAfter    = 24 * time.Hour
	defaultJobRetention     = time.Hour
	defaultDownloadGrace    = 10 * time.Minute
	defaultProjectRetention = time.Hour
	defaultCleanupInterval  = time.Minute
)

type artifactLink struct {
	Format build.Format `json:"format"`
	Size   int64        `json:"size"`
	URL    string       `json:"url"`
}

type projectView struct {
	Name, Path string
}

func newServer(root, projectsDir string) (*Server, error) {
	root, err := filepath.Abs(root)
	if err != nil {
		return nil, err
	}
	projectsDir, err = filepath.Abs(projectsDir)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(projectsDir, 0o755); err != nil {
		return nil, fmt.Errorf("GUI-Workspace anlegen: %w", err)
	}
	tmpl, err := template.ParseFS(assets, "assets/*.html")
	if err != nil {
		return nil, err
	}
	engine := build.Engine{Root: root}
	server := &Server{
		root: root, projectsDir: projectsDir, templates: tmpl,
		build: func(ctx context.Context, projectPath string, formats []build.Format, outputDir string) ([]build.Artifact, error) {
			configured := engine
			configured.OutputDir = outputDir
			return configured.Build(ctx, projectPath, formats)
		},
		jobs: make(map[string]*Job), mux: http.NewServeMux(), queueWake: make(chan struct{}, 1),
		jobRetention: defaultJobRetention, downloadGrace: defaultDownloadGrace,
		projectRetention: defaultProjectRetention,
	}
	server.routes()
	return server, nil
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !s.beginRequest() {
		http.Error(w, "Server wird beendet.", http.StatusServiceUnavailable)
		return
	}
	defer s.requestWG.Done()
	// These headers tell browsers not to guess file types, embed the UI in other
	// sites, or load scripts from unexpected locations.
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("Referrer-Policy", "same-origin")
	w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'")
	if s.localHost != "" {
		if r.Host != s.localHost || strings.EqualFold(r.Header.Get("Sec-Fetch-Site"), "cross-site") {
			http.Error(w, "Lokaler Zugriff abgelehnt.", http.StatusForbidden)
			return
		}
		if origin := r.Header.Get("Origin"); origin != "" {
			parsed, err := url.Parse(origin)
			if err != nil || parsed.Scheme != "http" || parsed.Host != s.localHost {
				http.Error(w, "Lokaler Zugriff abgelehnt.", http.StatusForbidden)
				return
			}
		}
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead && r.Method != http.MethodOptions {
		if strings.EqualFold(r.Header.Get("Sec-Fetch-Site"), "cross-site") {
			http.Error(w, "Browserübergreifender Zugriff abgelehnt.", http.StatusForbidden)
			return
		}
		if origin := r.Header.Get("Origin"); origin != "" {
			parsed, err := url.Parse(origin)
			if err != nil || parsed.Host != r.Host || (parsed.Scheme != "http" && parsed.Scheme != "https") {
				http.Error(w, "Fremder Ursprung abgelehnt.", http.StatusForbidden)
				return
			}
		}
	}
	s.mux.ServeHTTP(w, r)
}

func (s *Server) beginRequest() bool {
	s.requestMu.Lock()
	defer s.requestMu.Unlock()
	if s.shuttingDown {
		return false
	}
	s.requestWG.Add(1)
	return true
}

func (s *Server) stopRequests() {
	s.requestMu.Lock()
	s.shuttingDown = true
	s.requestMu.Unlock()
}

func (s *Server) routes() {
	staticFS, err := fs.Sub(assets, "assets")
	if err != nil {
		panic(err)
	}
	static := http.FileServer(http.FS(staticFS))
	s.mux.Handle("/static/", http.StripPrefix("/static/", static))
	s.mux.HandleFunc("/", s.home)
	s.mux.HandleFunc("/import", s.importProject)
	s.mux.HandleFunc("/import-folder", s.importFolder)
	s.mux.HandleFunc("/build", s.startBuild)
	s.mux.HandleFunc("/jobs/", s.jobPage)
	s.mux.HandleFunc("/api/jobs/", s.jobJSON)
	s.mux.HandleFunc("/api/local-session/heartbeat", s.localSessionHeartbeat)
	s.mux.HandleFunc("/api/local-session/close", s.localSessionClose)
	s.mux.HandleFunc("/artifacts/", s.artifact)
}

func (s *Server) localSessionHeartbeat(w http.ResponseWriter, r *http.Request) {
	s.localSession(w, r, false)
}

func (s *Server) localSessionClose(w http.ResponseWriter, r *http.Request) {
	s.localSession(w, r, true)
}

func (s *Server) localSession(w http.ResponseWriter, r *http.Request, closing bool) {
	if s.lifecycle == nil {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 256))
	id := strings.TrimSpace(string(body))
	if err != nil || id == "" || len(id) > 128 {
		http.Error(w, "Ungültige lokale Sitzung.", http.StatusBadRequest)
		return
	}
	if closing {
		s.lifecycle.closing(id)
	} else {
		s.lifecycle.heartbeat(id)
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *Server) home(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	projects, err := s.projects()
	data := struct {
		Projects []projectView
		Jobs     []jobView
		Message  string
		Error    string
		Local    bool
	}{Projects: projects, Jobs: s.recentJobs(), Message: r.URL.Query().Get("message"), Local: s.localHost != ""}
	if err != nil {
		data.Error = err.Error()
	}
	s.render(w, "index", data)
}

func (s *Server) projects() ([]projectView, error) {
	projectsDir := s.projectsDir
	entries, err := os.ReadDir(projectsDir)
	if err != nil {
		return nil, err
	}
	result := make([]projectView, 0, len(entries))
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		path := filepath.Join(projectsDir, entry.Name())
		if _, err := project.Open(path); err == nil {
			result = append(result, projectView{Name: entry.Name(), Path: path})
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Name < result[j].Name })
	return result, nil
}

func (s *Server) importProject(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	file, header, err := r.FormFile("project")
	if err != nil {
		s.redirectMessage(w, r, "ZIP-Datei fehlt oder ist ungültig.")
		return
	}
	defer file.Close()
	projectsDir := s.projectsDir
	s.projectMu.Lock()
	name, err := importZIP(file, header, projectsDir)
	s.projectMu.Unlock()
	if err != nil {
		s.redirectMessage(w, r, "Import fehlgeschlagen: "+err.Error())
		return
	}
	s.redirectMessage(w, r, "Projekt "+name+" wurde importiert.")
}

// importFolder accepts the files selected through the browser's directory
// picker. It exists only in the loopback GUI; the networked server deliberately
// keeps the simpler ZIP-only import.
func (s *Server) importFolder(w http.ResponseWriter, r *http.Request) {
	if s.localHost == "" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		s.folderImportResponse(w, r, "", fmt.Errorf("Ordnerdaten fehlen oder sind ungültig"))
		return
	}
	defer r.MultipartForm.RemoveAll()
	files := r.MultipartForm.File["files"]
	paths := r.MultipartForm.Value["paths"]
	if len(files) == 0 || len(files) != len(paths) {
		s.folderImportResponse(w, r, "", fmt.Errorf("Ordnerauswahl ist unvollständig"))
		return
	}
	projectsDir := s.projectsDir
	stage, err := os.MkdirTemp(projectsDir, ".folder-import-*")
	if err != nil {
		s.folderImportResponse(w, r, "", err)
		return
	}
	defer os.RemoveAll(stage)
	for index, header := range files {
		relative, pathErr := safeImportPath(paths[index])
		if pathErr != nil {
			s.folderImportResponse(w, r, "", pathErr)
			return
		}
		if containsOutputsDirectory(relative) {
			continue
		}
		input, openErr := header.Open()
		if openErr != nil {
			s.folderImportResponse(w, r, "", openErr)
			return
		}
		target := filepath.Join(stage, relative)
		if mkdirErr := os.MkdirAll(filepath.Dir(target), 0o755); mkdirErr != nil {
			input.Close()
			s.folderImportResponse(w, r, "", mkdirErr)
			return
		}
		output, createErr := os.OpenFile(target, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o644)
		if createErr != nil {
			input.Close()
			s.folderImportResponse(w, r, "", createErr)
			return
		}
		_, copyErr := io.Copy(output, input)
		closeOutputErr, closeInputErr := output.Close(), input.Close()
		if copyErr != nil || closeOutputErr != nil || closeInputErr != nil {
			if copyErr == nil {
				copyErr = closeOutputErr
			}
			if copyErr == nil {
				copyErr = closeInputErr
			}
			s.folderImportResponse(w, r, "", copyErr)
			return
		}
	}
	name, err := publishImportedStage(stage, projectsDir)
	if err != nil {
		if name != "" {
			_ = os.RemoveAll(filepath.Join(projectsDir, name))
		}
		s.folderImportResponse(w, r, "", err)
		return
	}
	s.folderImportResponse(w, r, name, nil)
}

func safeImportPath(value string) (string, error) {
	clean := filepath.Clean(filepath.FromSlash(value))
	if clean == "." || filepath.IsAbs(clean) || filepath.VolumeName(clean) != "" || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("unsicherer Ordnerpfad %q", value)
	}
	return clean, nil
}

func (s *Server) folderImportResponse(w http.ResponseWriter, r *http.Request, name string, err error) {
	if strings.Contains(r.Header.Get("Accept"), "application/json") {
		w.Header().Set("Content-Type", "application/json")
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]string{"project": name})
		return
	}
	if err != nil {
		s.redirectMessage(w, r, "Ordnerimport fehlgeschlagen: "+err.Error())
		return
	}
	s.redirectMessage(w, r, "Projekt "+name+" wurde importiert.")
}

func importZIP(file multipart.File, header *multipart.FileHeader, projectsDir string) (string, error) {
	if !strings.EqualFold(filepath.Ext(header.Filename), ".zip") {
		return "", fmt.Errorf("nur ZIP-Dateien werden unterstützt")
	}
	temp, err := os.CreateTemp("", "oa-import-*.zip")
	if err != nil {
		return "", err
	}
	tempPath := temp.Name()
	defer os.Remove(tempPath)
	if _, err := io.Copy(temp, file); err != nil {
		temp.Close()
		return "", err
	}
	if err := temp.Close(); err != nil {
		return "", err
	}
	reader, err := zip.OpenReader(tempPath)
	if err != nil {
		return "", fmt.Errorf("ZIP öffnen: %w", err)
	}
	defer reader.Close()
	stage, err := os.MkdirTemp(projectsDir, ".import-*")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(stage)
	for _, entry := range reader.File {
		clean := filepath.Clean(filepath.FromSlash(entry.Name))
		if clean == "." || filepath.IsAbs(clean) || filepath.VolumeName(clean) != "" || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
			return "", fmt.Errorf("unsicherer ZIP-Pfad %q", entry.Name)
		}
		if entry.Mode()&os.ModeSymlink != 0 {
			return "", fmt.Errorf("symbolische Links sind nicht erlaubt")
		}
		if containsOutputsDirectory(clean) {
			continue
		}
		target := filepath.Join(stage, clean)
		relative, err := filepath.Rel(stage, target)
		if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
			return "", fmt.Errorf("ZIP-Eintrag verlässt den Importordner")
		}
		if entry.FileInfo().IsDir() {
			if err := os.MkdirAll(target, 0o755); err != nil {
				return "", err
			}
			continue
		}
		if !entry.Mode().IsRegular() {
			return "", fmt.Errorf("Sonderdateien sind nicht erlaubt")
		}
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return "", err
		}
		input, err := entry.Open()
		if err != nil {
			return "", err
		}
		output, err := os.OpenFile(target, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o644)
		if err == nil {
			_, err = io.Copy(output, input)
			if closeErr := output.Close(); err == nil {
				err = closeErr
			}
		}
		input.Close()
		if err != nil {
			return "", err
		}
	}
	return publishImportedStage(stage, projectsDir)
}

func containsOutputsDirectory(path string) bool {
	for _, part := range strings.Split(filepath.Clean(path), string(filepath.Separator)) {
		if strings.EqualFold(part, "Outputs") {
			return true
		}
	}
	return false
}

// publishImportedStage validates the staged directory and moves the one
// discovered project into the visible workspace only after validation.
func publishImportedStage(stage, projectsDir string) (string, error) {
	projectDir, projectName, err := locateImportedProject(stage)
	if err != nil {
		return "", err
	}
	target := filepath.Join(projectsDir, projectName)
	if _, err := os.Stat(target); err == nil {
		return "", fmt.Errorf("Projekt %q ist bereits importiert", projectName)
	} else if !os.IsNotExist(err) {
		return "", err
	}
	if err := os.Rename(projectDir, target); err != nil {
		return "", fmt.Errorf("Projekt veröffentlichen: %w", err)
	}
	if _, err := project.Open(target); err != nil {
		_ = os.RemoveAll(target)
		return "", fmt.Errorf("importiertes Projekt prüfen: %w", err)
	}
	return projectName, nil
}

func locateImportedProject(stage string) (string, string, error) {
	// A ZIP may contain the project contents directly. The staging directory
	// has a random name, so project.Open cannot validate it until it has been
	// renamed to the name derived from the XML file.
	xmlDir := filepath.Join(stage, "Strukturierte_Daten")
	if entries, err := os.ReadDir(xmlDir); err == nil {
		var names []string
		for _, entry := range entries {
			if entry.Type().IsRegular() && strings.EqualFold(filepath.Ext(entry.Name()), ".xml") {
				names = append(names, strings.TrimSuffix(entry.Name(), filepath.Ext(entry.Name())))
			}
		}
		if len(names) == 1 && names[0] != "" && filepath.Base(names[0]) == names[0] {
			return stage, names[0], nil
		}
	}
	entries, err := os.ReadDir(stage)
	if err != nil {
		return "", "", err
	}
	type candidate struct {
		path string
		name string
	}
	var candidates []candidate
	for _, entry := range entries {
		if entry.IsDir() {
			path := filepath.Join(stage, entry.Name())
			if pub, err := project.Open(path); err == nil {
				candidates = append(candidates, candidate{path: path, name: pub.Name})
			}
		}
	}
	if len(candidates) != 1 {
		return "", "", fmt.Errorf(
			"ZIP muss genau ein OA-Projekt enthalten; erwartet wird Strukturierte_Daten/<Projektname>.xml, entweder direkt im ZIP oder in einem gleichnamigen Projektordner",
		)
	}
	return candidates[0].path, candidates[0].name, nil
}

func (s *Server) startBuild(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	s.projectMu.Lock()
	defer s.projectMu.Unlock()
	pub, err := s.openWorkspaceProject(r.FormValue("project"))
	if err != nil {
		s.redirectMessage(w, r, "Build abgelehnt: "+err.Error())
		return
	}
	formats := make([]build.Format, 0, 3)
	for _, value := range r.Form["format"] {
		format := build.Format(value)
		if format != build.PrintPDF && format != build.WebPDF && format != build.EPUB {
			s.redirectMessage(w, r, "Unbekanntes Format: "+value)
			return
		}
		formats = append(formats, format)
	}
	if len(formats) == 0 {
		s.redirectMessage(w, r, "Mindestens ein Ausgabeformat auswählen.")
		return
	}
	id := randomID()
	job := &Job{
		ID: id, Project: pub.Name, Status: "wartet", Progress: 0,
		Logs: []string{"Build wurde in die Warteschlange aufgenommen."}, Created: time.Now(),
		downloads: make(map[string]downloadArtifact), projectDir: pub.Dir,
	}
	s.mu.Lock()
	for _, existing := range s.jobs {
		if filepath.Clean(existing.projectDir) == filepath.Clean(pub.Dir) && (existing.Status == "wartet" || existing.Status == "läuft") {
			s.mu.Unlock()
			s.redirectMessage(w, r, "Für dieses Projekt ist bereits ein Build eingeplant.")
			return
		}
	}
	s.queue = append(s.queue, queuedBuild{jobID: id, projectDir: pub.Dir, formats: append([]build.Format(nil), formats...)})
	job.QueuePosition = len(s.queue)
	s.jobs[id] = job
	s.mu.Unlock()
	s.wakeWorker()
	http.Redirect(w, r, "/jobs/"+id, http.StatusSeeOther)
}

func (s *Server) wakeWorker() {
	select {
	case s.queueWake <- struct{}{}:
	default:
	}
}

func (s *Server) startWorker(ctx context.Context) {
	s.workerWG.Add(1)
	go func() {
		defer s.workerWG.Done()
		for {
			request, ok := s.nextBuild(ctx)
			if !ok {
				s.cancelQueuedBuilds()
				return
			}
			s.runBuild(ctx, request)
		}
	}()
}

func (s *Server) nextBuild(ctx context.Context) (queuedBuild, bool) {
	for {
		select {
		case <-ctx.Done():
			return queuedBuild{}, false
		default:
		}
		s.mu.Lock()
		if len(s.queue) > 0 {
			request := s.queue[0]
			s.queue = s.queue[1:]
			for index, queued := range s.queue {
				if job := s.jobs[queued.jobID]; job != nil {
					job.QueuePosition = index + 1
				}
			}
			if job := s.jobs[request.jobID]; job != nil {
				job.QueuePosition = 0
				job.Status, job.Progress = "läuft", 10
				job.Logs = append(job.Logs, "Build wurde gestartet.")
			}
			s.mu.Unlock()
			return request, true
		}
		s.mu.Unlock()
		select {
		case <-ctx.Done():
			return queuedBuild{}, false
		case <-s.queueWake:
		}
	}
}

func (s *Server) cancelQueuedBuilds() {
	s.mu.Lock()
	queued := append([]queuedBuild(nil), s.queue...)
	s.queue = nil
	for _, request := range queued {
		if job := s.jobs[request.jobID]; job != nil {
			job.Status, job.Progress, job.QueuePosition = "abgebrochen", 100, 0
			job.Logs = append(job.Logs, "Server wird beendet; wartender Build wurde abgebrochen.")
		}
	}
	s.mu.Unlock()
	if s.temporaryProjects {
		s.projectMu.Lock()
		defer s.projectMu.Unlock()
		for _, request := range queued {
			_ = os.RemoveAll(request.projectDir)
		}
	}
}

func (s *Server) runBuild(parent context.Context, request queuedBuild) {
	// Browser requests return immediately; the expensive Java work continues in
	// the background while the job page polls the small JSON status endpoint.
	if s.temporaryProjects {
		defer func() {
			s.projectMu.Lock()
			defer s.projectMu.Unlock()
			_ = os.RemoveAll(request.projectDir)
		}()
	}
	s.updateJob(request.jobID, func(item *Job) {
		item.Status, item.Progress = "läuft", 20
		item.Logs = append(item.Logs, "Projekt wurde geprüft.", "Buildkern wird gestartet.")
	})
	ctx, cancel := context.WithTimeout(parent, 10*time.Minute)
	defer cancel()
	ctx = build.WithLogger(ctx, func(message string) {
		s.updateJob(request.jobID, func(item *Job) {
			item.Logs = append(item.Logs, message)
		})
	})
	outputDir := ""
	if s.artifactRoot != "" {
		outputDir = filepath.Join(s.artifactRoot, request.jobID)
	} else if s.outputRoot != "" {
		outputDir = s.outputRoot
	}
	artifacts, err := s.build(ctx, request.projectDir, request.formats, outputDir)
	downloads := make(map[string]downloadArtifact, len(artifacts))
	if err == nil {
		for _, artifact := range artifacts {
			base := filepath.Base(artifact.Path)
			downloads[base] = downloadArtifact{name: base, path: artifact.Path}
		}
	}
	if err != nil && s.artifactRoot != "" {
		_ = os.RemoveAll(outputDir)
	}
	s.updateJob(request.jobID, func(item *Job) {
		item.expiresAt = time.Now().Add(s.retention())
		if err != nil {
			if parent.Err() != nil {
				item.Status = "abgebrochen"
			} else {
				item.Status = "fehlgeschlagen"
			}
			item.Progress = 100
			item.Logs = append(item.Logs, "Fehler: "+err.Error())
			return
		}
		item.Status, item.Progress = "fertig", 100
		for _, artifact := range artifacts {
			base := filepath.Base(artifact.Path)
			item.downloads[base] = downloads[base]
			item.Artifacts = append(item.Artifacts, artifactLink{
				Format: artifact.Format, Size: artifact.Size,
				URL: "/artifacts/" + url.PathEscape(item.ID) + "/" + url.PathEscape(base),
			})
			item.Logs = append(item.Logs, fmt.Sprintf("%s erzeugt: %s", artifact.Format, base))
		}
	})
}

func (s *Server) retention() time.Duration {
	if s.jobRetention > 0 {
		return s.jobRetention
	}
	return defaultJobRetention
}

func (s *Server) updateJob(id string, change func(*Job)) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if job := s.jobs[id]; job != nil {
		change(job)
	}
}

func (s *Server) jobPage(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/jobs/")
	s.mu.RLock()
	job := s.jobs[id]
	if job != nil {
		copy := *job
		copy.Logs = append([]string(nil), job.Logs...)
		job = &copy
	}
	s.mu.RUnlock()
	if job == nil {
		http.NotFound(w, r)
		return
	}
	data := struct {
		ID, Project, Status, Logs string
		Progress, QueuePosition   int
		Local                     bool
	}{ID: job.ID, Project: job.Project, Status: job.Status, Logs: strings.Join(job.Logs, "\n"), Progress: job.Progress, QueuePosition: job.QueuePosition, Local: s.localHost != ""}
	s.render(w, "job", data)
}

func (s *Server) jobJSON(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/api/jobs/")
	s.mu.RLock()
	job := s.jobs[id]
	if job != nil {
		copy := *job
		copy.Logs = append([]string(nil), job.Logs...)
		copy.Artifacts = append([]artifactLink(nil), job.Artifacts...)
		job = &copy
	}
	s.mu.RUnlock()
	if job == nil {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(job)
}

func (s *Server) artifact(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/artifacts/"), "/")
	if len(parts) != 2 {
		http.NotFound(w, r)
		return
	}
	if filepath.Base(parts[1]) != parts[1] {
		http.NotFound(w, r)
		return
	}
	s.mu.Lock()
	job := s.jobs[parts[0]]
	download := downloadArtifact{}
	if job != nil && !job.cleaning {
		download = job.downloads[parts[1]]
		if download.name != "" {
			job.activeDownloads++
		}
	}
	s.mu.Unlock()
	if download.name == "" {
		http.NotFound(w, r)
		return
	}
	defer func() {
		s.mu.Lock()
		if current := s.jobs[parts[0]]; current != nil {
			current.activeDownloads--
			grace := s.downloadGrace
			if grace <= 0 {
				grace = defaultDownloadGrace
			}
			current.expiresAt = time.Now().Add(grace)
		}
		s.mu.Unlock()
	}()
	w.Header().Set("Content-Disposition", fmt.Sprintf("inline; filename=%q", download.name))
	if download.path == "" {
		http.NotFound(w, r)
		return
	}
	http.ServeFile(w, r, download.path)
}

func (s *Server) openWorkspaceProject(name string) (project.Project, error) {
	// Never trust a project name received from a URL or form.
	if name == "" || filepath.Base(name) != name || name == "." || name == ".." {
		return project.Project{}, fmt.Errorf("ungültiger Projektname")
	}
	path := filepath.Join(s.projectsDir, name)
	return project.Open(path)
}

func (s *Server) recentJobs() []jobView {
	s.mu.RLock()
	type recentJob struct {
		view    jobView
		created time.Time
	}
	jobs := make([]recentJob, 0, len(s.jobs))
	for _, job := range s.jobs {
		jobs = append(jobs, recentJob{view: jobView{ID: job.ID, Project: job.Project, Status: job.Status}, created: job.Created})
	}
	s.mu.RUnlock()
	sort.Slice(jobs, func(i, j int) bool { return jobs[i].created.After(jobs[j].created) })
	if len(jobs) > 20 {
		jobs = jobs[:20]
	}
	result := make([]jobView, 0, len(jobs))
	for _, job := range jobs {
		result = append(result, job.view)
	}
	return result
}

type jobView struct {
	ID, Project, Status string
}

func (s *Server) render(w http.ResponseWriter, name string, data any) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := s.templates.ExecuteTemplate(w, name, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func (s *Server) redirectMessage(w http.ResponseWriter, r *http.Request, message string) {
	http.Redirect(w, r, "/?message="+url.QueryEscape(message), http.StatusSeeOther)
}

func randomID() string {
	var bytes [12]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return hex.EncodeToString(bytes[:])
}

func createServerArea(parent string) (string, string, error) {
	parent, err := filepath.Abs(parent)
	if err != nil {
		return "", "", fmt.Errorf("temporären Serverbereich auflösen: %w", err)
	}
	parent = filepath.Clean(parent)
	if err := os.MkdirAll(parent, 0o755); err != nil {
		return "", "", fmt.Errorf("Elternverzeichnis für Serverbereich anlegen: %w", err)
	}
	if err := cleanupOrphanedServerAreas(parent, time.Now()); err != nil {
		return "", "", err
	}
	area, err := os.MkdirTemp(parent, serverAreaPrefix+"*")
	if err != nil {
		return "", "", fmt.Errorf("temporären Serverbereich anlegen: %w", err)
	}
	marker := filepath.Join(area, serverAreaMarker)
	if err := os.WriteFile(marker, []byte(serverAreaMarkerValue), 0o600); err != nil {
		_ = os.RemoveAll(area)
		return "", "", fmt.Errorf("Serverbereich markieren: %w", err)
	}
	return area, marker, nil
}

func cleanupOrphanedServerAreas(parent string, now time.Time) error {
	entries, err := os.ReadDir(parent)
	if err != nil {
		return fmt.Errorf("alte Serverbereiche auflisten: %w", err)
	}
	for _, entry := range entries {
		if !strings.HasPrefix(entry.Name(), serverAreaPrefix) || entry.Type()&os.ModeSymlink != 0 || !entry.IsDir() {
			continue
		}
		area := filepath.Join(parent, entry.Name())
		marker := filepath.Join(area, serverAreaMarker)
		info, err := os.Lstat(marker)
		if err != nil || !info.Mode().IsRegular() || now.Sub(info.ModTime()) < serverAreaStaleAfter {
			continue
		}
		content, err := os.ReadFile(marker)
		if err != nil || string(content) != serverAreaMarkerValue {
			continue
		}
		relative, err := filepath.Rel(parent, area)
		if err != nil || relative == "." || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
			return fmt.Errorf("unsicherer verwaister Serverbereich: %s", area)
		}
		if err := os.RemoveAll(area); err != nil {
			return fmt.Errorf("verwaisten Serverbereich löschen: %w", err)
		}
	}
	return nil
}

func (s *Server) maintainTemporaryData(ctx context.Context, marker string) {
	ticker := time.NewTicker(defaultCleanupInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case now := <-ticker.C:
			_ = os.Chtimes(marker, now, now)
			s.cleanupExpiredJobs(now)
			s.cleanupStaleProjects(now)
		}
	}
}

func (s *Server) cleanupExpiredJobs(now time.Time) {
	type candidate struct {
		id   string
		path string
	}
	s.mu.Lock()
	var candidates []candidate
	for id, job := range s.jobs {
		if !job.cleaning && !job.expiresAt.IsZero() && !now.Before(job.expiresAt) && job.activeDownloads == 0 {
			job.cleaning = true
			candidates = append(candidates, candidate{id: id, path: filepath.Join(s.artifactRoot, id)})
		}
	}
	s.mu.Unlock()
	for _, item := range candidates {
		if err := os.RemoveAll(item.path); err != nil {
			s.mu.Lock()
			if job := s.jobs[item.id]; job != nil {
				job.cleaning = false
			}
			s.mu.Unlock()
			continue
		}
		s.mu.Lock()
		if job := s.jobs[item.id]; job != nil && job.cleaning {
			delete(s.jobs, item.id)
		}
		s.mu.Unlock()
	}
}

func (s *Server) cleanupStaleProjects(now time.Time) {
	retention := s.projectRetention
	if retention <= 0 {
		retention = defaultProjectRetention
	}
	s.projectMu.Lock()
	defer s.projectMu.Unlock()
	active := make(map[string]bool)
	s.mu.RLock()
	for _, job := range s.jobs {
		if job.Status == "wartet" || job.Status == "läuft" {
			active[filepath.Clean(job.projectDir)] = true
		}
	}
	s.mu.RUnlock()
	entries, err := os.ReadDir(s.projectsDir)
	if err != nil {
		return
	}
	for _, entry := range entries {
		if !entry.IsDir() || entry.Type()&os.ModeSymlink != 0 || strings.HasPrefix(entry.Name(), ".") {
			continue
		}
		path := filepath.Join(s.projectsDir, entry.Name())
		info, err := entry.Info()
		if err == nil && !active[filepath.Clean(path)] && now.Sub(info.ModTime()) >= retention {
			_ = os.RemoveAll(path)
		}
	}
}

// Run starts the GUI with a process-owned temporary project area on loopback
// and opens it in the default browser.
func Run(ctx context.Context, root string, stdout io.Writer) (returnErr error) {
	workspace, err := os.MkdirTemp("", "oa-gui-workspace-*")
	if err != nil {
		return fmt.Errorf("temporären GUI-Arbeitsbereich anlegen: %w", err)
	}
	defer func() {
		if err := os.RemoveAll(workspace); err != nil && returnErr == nil {
			returnErr = fmt.Errorf("temporären GUI-Arbeitsbereich löschen: %w", err)
		}
	}()
	server, err := newServer(root, filepath.Join(workspace, "projects"))
	if err != nil {
		return err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return fmt.Errorf("lokalen GUI-Port öffnen: %w", err)
	}
	httpServer := &http.Server{Handler: server, ReadHeaderTimeout: 5 * time.Second}
	address := "http://" + listener.Addr().String()
	server.localHost = listener.Addr().String()
	server.outputRoot = filepath.Join(root, "Outputs")
	server.temporaryProjects = true
	server.lifecycle = newLocalLifecycle(2*time.Minute, 4*time.Second)
	workerCtx, stopWorker := context.WithCancel(ctx)
	server.startWorker(workerCtx)
	defer func() {
		stopWorker()
		server.workerWG.Wait()
	}()
	defer func() {
		server.stopRequests()
		_ = httpServer.Close()
		server.requestWG.Wait()
	}()
	fmt.Fprintf(stdout, "OA-GUI läuft unter %s\nTemporärer Projektbereich: %s\nZum Beenden Browser-Tab schließen oder Strg+C drücken.\n", address, workspace)
	go server.lifecycle.watch(ctx)
	go func() {
		select {
		case <-ctx.Done():
		case <-server.lifecycle.done:
		}
		server.stopRequests()
		shutdown, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_ = httpServer.Shutdown(shutdown)
	}()
	go func() {
		if err := openBrowser(address); err != nil {
			log.Printf("Browser konnte nicht automatisch geöffnet werden: %v", err)
		}
	}()
	err = httpServer.Serve(listener)
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}

// RunServer starts the shared UI in a process-owned temporary area without
// opening a browser. Access control belongs to the private network, VPN or an
// authenticating service in front of this deliberately small server.
func RunServer(ctx context.Context, root, address string, stdout io.Writer) error {
	return runServerIn(ctx, root, os.TempDir(), address, stdout)
}

func runServerIn(ctx context.Context, root, tempParent, address string, stdout io.Writer) (returnErr error) {
	serverArea, marker, err := createServerArea(tempParent)
	if err != nil {
		return err
	}
	defer func() {
		if err := os.RemoveAll(serverArea); err != nil && returnErr == nil {
			returnErr = fmt.Errorf("temporären Serverbereich löschen: %w", err)
		}
	}()
	server, err := newServer(root, filepath.Join(serverArea, "projects"))
	if err != nil {
		return err
	}
	server.artifactRoot = filepath.Join(serverArea, "artifacts")
	server.temporaryProjects = true
	if err := os.MkdirAll(server.artifactRoot, 0o755); err != nil {
		return fmt.Errorf("temporären Downloadbereich anlegen: %w", err)
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("Serveradresse öffnen: %w", err)
	}
	httpServer := &http.Server{
		Handler: server, ReadHeaderTimeout: 5 * time.Second,
		WriteTimeout: 15 * time.Minute, IdleTimeout: 60 * time.Second,
	}
	workerCtx, stopWorker := context.WithCancel(ctx)
	server.startWorker(workerCtx)
	go server.maintainTemporaryData(workerCtx, marker)
	defer func() {
		stopWorker()
		server.workerWG.Wait()
	}()
	defer func() {
		server.stopRequests()
		_ = httpServer.Close()
		server.requestWG.Wait()
	}()
	fmt.Fprintf(stdout, "OA-Server läuft unter http://%s\nTemporärer Serverbereich: %s\nBeenden mit Strg+C.\n", listener.Addr(), serverArea)
	go func() {
		<-ctx.Done()
		server.stopRequests()
		shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = httpServer.Shutdown(shutdown)
	}()
	err = httpServer.Serve(listener)
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}

func openBrowser(address string) error {
	var command string
	var args []string
	switch runtime.GOOS {
	case "windows":
		command, args = "rundll32", []string{"url.dll,FileProtocolHandler", address}
	case "darwin":
		command, args = "open", []string{address}
	default:
		command, args = "xdg-open", []string{address}
	}
	return exec.Command(command, args...).Start()
}
