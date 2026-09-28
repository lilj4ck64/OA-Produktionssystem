package gui

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"oa-satzsystem/internal/build"
	"oa-satzsystem/internal/project"
)

// Job is the browser-visible state of one asynchronous build.
type Job struct {
	ID              string         `json:"id"`
	Project         string         `json:"project"`
	Status          string         `json:"status"`
	Progress        int            `json:"progress"`
	ProgressMessage string         `json:"progressMessage"`
	Logs            []string       `json:"logs"`
	Artifacts       []artifactLink `json:"artifacts"`
	LogFileName     string         `json:"logFileName,omitempty"`
	LogDownloadURL  string         `json:"logDownloadUrl,omitempty"`
	LogSize         int64          `json:"logSize,omitempty"`
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

type artifactLink struct {
	Format      build.Format `json:"format"`
	Size        int64        `json:"size"`
	URL         string       `json:"url"`
	DownloadURL string       `json:"downloadUrl"`
	PreviewURL  string       `json:"previewUrl"`
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
		ProgressMessage: "Build wurde in die Warteschlange aufgenommen.", Created: time.Now(),
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
				job.ProgressMessage = "Build wurde gestartet."
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
			job.ProgressMessage = "Server wird beendet; wartender Build wurde abgebrochen."
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
		item.ProgressMessage = "Projekt wurde geprüft. Buildkern wird gestartet."
	})
	ctx, cancel := context.WithTimeout(parent, 10*time.Minute)
	defer cancel()
	var completeLog []string
	ctx = build.WithLogger(ctx, func(event build.LogEvent) {
		completeLog = append(completeLog, event.String())
		s.updateJob(request.jobID, func(item *Job) {
			if event.Kind == build.LogProgress {
				item.ProgressMessage = event.Message
				return
			}
			if showInGUILog(event) {
				item.Logs = append(item.Logs, event.String())
			}
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
	if err != nil {
		completeLog = append(completeLog, "Fehler: "+err.Error())
	}
	logName, logPath, logSize, logErr := s.writeBuildLog(request.jobID, completeLog)
	s.updateJob(request.jobID, func(item *Job) {
		item.expiresAt = time.Now().Add(s.retention())
		if logErr != nil {
			item.Logs = append(item.Logs, "Logdatei konnte nicht gespeichert werden: "+firstLine(logErr.Error()))
		} else {
			item.LogFileName = logName
			item.LogSize = logSize
			if s.artifactRoot != "" {
				item.downloads[logName] = downloadArtifact{name: logName, path: logPath}
				item.LogDownloadURL = "/artifacts/" + url.PathEscape(item.ID) + "/" + url.PathEscape(logName) + "?download=1"
			}
		}
		if err != nil {
			if parent.Err() != nil {
				item.Status = "abgebrochen"
			} else {
				item.Status = "fehlgeschlagen"
			}
			item.Progress = 100
			item.ProgressMessage = "Build fehlgeschlagen."
			item.Logs = append(item.Logs, "Fehler: "+firstLine(err.Error()))
			return
		}
		item.Status, item.Progress = "fertig", 100
		item.ProgressMessage = "Alle Ausgaben wurden erfolgreich erzeugt."
		for _, artifact := range artifacts {
			base := filepath.Base(artifact.Path)
			item.downloads[base] = downloads[base]
			artifactURL := "/artifacts/" + url.PathEscape(item.ID) + "/" + url.PathEscape(base)
			previewURL := artifactURL
			if artifact.Format == build.EPUB {
				previewURL = "/epub-preview/" + url.PathEscape(item.ID) + "/manifest"
			}
			item.Artifacts = append(item.Artifacts, artifactLink{
				Format: artifact.Format, Size: artifact.Size, URL: artifactURL,
				DownloadURL: artifactURL + "?download=1", PreviewURL: previewURL,
			})
		}
	})
}

func (s *Server) writeBuildLog(jobID string, lines []string) (string, string, int64, error) {
	s.mu.RLock()
	job := s.jobs[jobID]
	if job == nil {
		s.mu.RUnlock()
		return "", "", 0, fmt.Errorf("Buildauftrag nicht gefunden")
	}
	name := logFileName(job.Project, job.Created)
	s.mu.RUnlock()

	directory := s.logRoot
	if directory == "" && s.artifactRoot != "" {
		directory = filepath.Join(s.artifactRoot, jobID)
	}
	if directory == "" {
		return "", "", 0, fmt.Errorf("kein Speicherort für Logdateien konfiguriert")
	}
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return "", "", 0, fmt.Errorf("Log-Ordner anlegen: %w", err)
	}
	path := filepath.Join(directory, name)
	content := strings.Join(lines, "\n")
	if content != "" {
		content += "\n"
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		return "", "", 0, fmt.Errorf("Logdatei schreiben: %w", err)
	}
	return name, path, int64(len([]byte(content))), nil
}

func logFileName(projectName string, created time.Time) string {
	return safeFileComponent(projectName) + "_" + created.Format("2006-01-02_15-04-05") + ".log"
}

func safeFileComponent(value string) string {
	value = strings.TrimSpace(value)
	value = strings.Map(func(character rune) rune {
		if character < 32 || strings.ContainsRune(`<>:"/\\|?*`, character) {
			return '_'
		}
		return character
	}, value)
	value = strings.Trim(value, ". ")
	if value == "" {
		return "Projekt"
	}
	return value
}

func showInGUILog(event build.LogEvent) bool {
	return event.Kind == build.LogToolOutput
}

func firstLine(message string) string {
	if index := strings.IndexByte(message, '\n'); index >= 0 {
		return strings.TrimSpace(message[:index])
	}
	return strings.TrimSpace(message)
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
		ID, Project, Status, ProgressMessage, Logs string
		Progress, QueuePosition                    int
		Local                                      bool
	}{ID: job.ID, Project: job.Project, Status: job.Status, ProgressMessage: job.ProgressMessage, Logs: strings.Join(job.Logs, "\n"), Progress: job.Progress, QueuePosition: job.QueuePosition, Local: s.localHost != ""}
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
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "Nur GET und HEAD sind erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/artifacts/"), "/")
	if len(parts) != 2 {
		http.NotFound(w, r)
		return
	}
	if filepath.Base(parts[1]) != parts[1] {
		http.NotFound(w, r)
		return
	}
	download, ok := s.acquireArtifact(parts[0], parts[1])
	if !ok {
		http.NotFound(w, r)
		return
	}
	defer s.releaseArtifact(parts[0])
	disposition := "inline"
	if r.URL.Query().Has("download") {
		disposition = "attachment"
	} else {
		// Build results may be embedded only by this GUI. The default response
		// headers intentionally deny framing everywhere else.
		w.Header().Set("X-Frame-Options", "SAMEORIGIN")
		w.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'self'")
	}
	w.Header().Set("Content-Disposition", fmt.Sprintf("%s; filename=%q", disposition, download.name))
	if download.path == "" {
		http.NotFound(w, r)
		return
	}
	http.ServeFile(w, r, download.path)
}

func (s *Server) acquireArtifact(jobID, name string) (downloadArtifact, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	job := s.jobs[jobID]
	if job == nil || job.cleaning {
		return downloadArtifact{}, false
	}
	artifact := job.downloads[name]
	if artifact.name == "" {
		return downloadArtifact{}, false
	}
	job.activeDownloads++
	return artifact, true
}

func (s *Server) acquireEPUBArtifact(jobID string) (downloadArtifact, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	job := s.jobs[jobID]
	if job == nil || job.cleaning {
		return downloadArtifact{}, false
	}
	for _, artifact := range job.downloads {
		if strings.EqualFold(filepath.Ext(artifact.name), ".epub") {
			job.activeDownloads++
			return artifact, true
		}
	}
	return downloadArtifact{}, false
}

func (s *Server) releaseArtifact(jobID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if job := s.jobs[jobID]; job != nil {
		if job.activeDownloads > 0 {
			job.activeDownloads--
		}
		grace := s.downloadGrace
		if grace <= 0 {
			grace = defaultDownloadGrace
		}
		job.expiresAt = time.Now().Add(grace)
	}
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
