// Package gui implements the local, browser-based user interface.
package gui

import (
	"context"
	"embed"
	"fmt"
	"html/template"
	"io/fs"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"oa-satzsystem/internal/build"
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
