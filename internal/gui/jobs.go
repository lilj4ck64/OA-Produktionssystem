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

type artifactLink struct {
	Format build.Format `json:"format"`
	Size   int64        `json:"size"`
	URL    string       `json:"url"`
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
