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

type buildFunc func(context.Context, string, []build.Format) ([]build.Artifact, error)

// Server owns the small in-memory state shared by HTTP requests.
type Server struct {
	root         string
	workspace    string
	templates    *template.Template
	build        buildFunc
	mux          *http.ServeMux
	mu           sync.RWMutex
	jobs         map[string]*Job
	buildRunning bool
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
	ID        string         `json:"id"`
	Project   string         `json:"project"`
	Status    string         `json:"status"`
	Progress  int            `json:"progress"`
	Logs      []string       `json:"logs"`
	Artifacts []artifactLink `json:"artifacts"`
	Created   time.Time      `json:"-"`
}

type artifactLink struct {
	Format build.Format `json:"format"`
	Size   int64        `json:"size"`
	URL    string       `json:"url"`
}

type projectView struct {
	Name, Path, URLName string
}

// New creates the shared handler used by the local GUI and small server.
func New(root, workspace string) (*Server, error) {
	root, err := filepath.Abs(root)
	if err != nil {
		return nil, err
	}
	workspace, err = filepath.Abs(workspace)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Join(workspace, "projects"), 0o755); err != nil {
		return nil, fmt.Errorf("GUI-Workspace anlegen: %w", err)
	}
	tmpl, err := template.ParseFS(assets, "assets/*.html")
	if err != nil {
		return nil, err
	}
	engine := build.Engine{Root: root}
	server := &Server{
		root: root, workspace: workspace, templates: tmpl,
		build: engine.Build, jobs: make(map[string]*Job), mux: http.NewServeMux(),
	}
	server.routes()
	return server, nil
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
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
	s.mux.HandleFunc("/validate", s.validateProject)
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
	projectsDir := filepath.Join(s.workspace, "projects")
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
			result = append(result, projectView{Name: entry.Name(), Path: path, URLName: url.QueryEscape(entry.Name())})
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
	projectsDir := filepath.Join(s.workspace, "projects")
	name, err := importZIP(file, header, projectsDir)
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
	projectsDir := filepath.Join(s.workspace, "projects")
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

func (s *Server) validateProject(w http.ResponseWriter, r *http.Request) {
	pub, err := s.openWorkspaceProject(r.URL.Query().Get("project"))
	if err != nil {
		s.redirectMessage(w, r, "Prüfung fehlgeschlagen: "+err.Error())
		return
	}
	s.redirectMessage(w, r, "Projekt "+pub.Name+" ist gültig.")
}

func (s *Server) startBuild(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
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
	job := &Job{ID: id, Project: pub.Name, Status: "läuft", Progress: 10, Logs: []string{"Build wurde gestartet."}, Created: time.Now()}
	s.mu.Lock()
	if s.buildRunning {
		s.mu.Unlock()
		s.redirectMessage(w, r, "Es läuft bereits ein Build. Bitte nach dessen Abschluss erneut versuchen.")
		return
	}
	s.buildRunning = true
	s.jobs[id] = job
	s.mu.Unlock()
	go s.runBuild(job, pub.Dir, formats)
	http.Redirect(w, r, "/jobs/"+id, http.StatusSeeOther)
}

func (s *Server) runBuild(job *Job, projectDir string, formats []build.Format) {
	// Browser requests return immediately; the expensive Java work continues in
	// the background while the job page polls the small JSON status endpoint.
	defer func() {
		s.mu.Lock()
		s.buildRunning = false
		s.mu.Unlock()
	}()
	s.updateJob(job.ID, func(item *Job) {
		item.Status, item.Progress = "läuft", 20
		item.Logs = append(item.Logs, "Projekt wurde geprüft.", "Buildkern wird gestartet.")
	})
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	ctx = build.WithLogger(ctx, func(message string) {
		s.updateJob(job.ID, func(item *Job) {
			item.Logs = append(item.Logs, message)
		})
	})
	artifacts, err := s.build(ctx, projectDir, formats)
	s.updateJob(job.ID, func(item *Job) {
		if err != nil {
			item.Status, item.Progress = "fehlgeschlagen", 100
			item.Logs = append(item.Logs, "Fehler: "+err.Error())
			return
		}
		item.Status, item.Progress = "fertig", 100
		for _, artifact := range artifacts {
			base := filepath.Base(artifact.Path)
			item.Artifacts = append(item.Artifacts, artifactLink{
				Format: artifact.Format, Size: artifact.Size,
				URL: "/artifacts/" + url.PathEscape(item.Project) + "/" + url.PathEscape(base),
			})
			item.Logs = append(item.Logs, fmt.Sprintf("%s erzeugt: %s", artifact.Format, base))
		}
	})
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
		job = &copy
	}
	s.mu.RUnlock()
	if job == nil {
		http.NotFound(w, r)
		return
	}
	data := struct {
		ID, Project, Status, Logs string
		Progress                  int
		Local                     bool
	}{ID: job.ID, Project: job.Project, Status: job.Status, Logs: strings.Join(job.Logs, "\n"), Progress: job.Progress, Local: s.localHost != ""}
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
	pub, err := s.openWorkspaceProject(parts[0])
	if err != nil {
		http.NotFound(w, r)
		return
	}
	path, err := project.Within(pub.Dir, "Outputs", filepath.Base(parts[1]))
	if err != nil {
		http.NotFound(w, r)
		return
	}
	http.ServeFile(w, r, path)
}

func (s *Server) openWorkspaceProject(name string) (project.Project, error) {
	// Never trust a project name received from a URL or form.
	if name == "" || filepath.Base(name) != name || name == "." || name == ".." {
		return project.Project{}, fmt.Errorf("ungültiger Projektname")
	}
	projectsDir := filepath.Join(s.workspace, "projects")
	path := filepath.Join(projectsDir, name)
	return project.Open(path)
}

func (s *Server) recentJobs() []jobView {
	s.mu.RLock()
	jobs := make([]*Job, 0, len(s.jobs))
	for _, job := range s.jobs {
		jobs = append(jobs, job)
	}
	s.mu.RUnlock()
	sort.Slice(jobs, func(i, j int) bool { return jobs[i].Created.After(jobs[j].Created) })
	if len(jobs) > 20 {
		jobs = jobs[:20]
	}
	result := make([]jobView, 0, len(jobs))
	for _, job := range jobs {
		result = append(result, jobView{ID: job.ID, Project: job.Project, Status: job.Status})
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

// Run starts the GUI on loopback and opens it in the default browser.
func Run(ctx context.Context, root, workspace string, stdout io.Writer) error {
	server, err := New(root, workspace)
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
	server.lifecycle = newLocalLifecycle(2*time.Minute, 4*time.Second)
	fmt.Fprintf(stdout, "OA-GUI läuft unter %s\nWorkspace: %s\nZum Beenden Browser-Tab schließen oder Strg+C drücken.\n", address, workspace)
	go server.lifecycle.watch(ctx)
	go func() {
		select {
		case <-ctx.Done():
		case <-server.lifecycle.done:
		}
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

// RunServer starts the shared-workspace UI without opening a browser. Access
// control belongs to the private network, VPN or authenticating reverse proxy
// in front of this deliberately small server.
func RunServer(ctx context.Context, root, workspace, address string, stdout io.Writer) error {
	server, err := New(root, workspace)
	if err != nil {
		return err
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("Serveradresse öffnen: %w", err)
	}
	httpServer := &http.Server{
		Handler: server, ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout: 30 * time.Second, WriteTimeout: 15 * time.Minute, IdleTimeout: 60 * time.Second,
	}
	fmt.Fprintf(stdout, "OA-Server läuft unter http://%s\nGemeinsamer Workspace: %s\nBeenden mit Strg+C.\n", listener.Addr(), workspace)
	go func() {
		<-ctx.Done()
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
