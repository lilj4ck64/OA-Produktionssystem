package gui

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"oa-satzsystem/internal/build"

	_ "modernc.org/sqlite"
)

const (
	serverQueueSize  = 16
	serverWorkers    = 2
	serverJobTimeout = 10 * time.Minute
)

type persistentState struct {
	// queue has a fixed capacity so a burst of requests cannot create an
	// unlimited number of memory-hungry builds.
	db      *sql.DB
	dataDir string
	queue   chan queuedJob
	ctx     context.Context
	cancel  context.CancelFunc
	wg      sync.WaitGroup
}

type queuedJob struct {
	id, projectDir string
	formats        []build.Format
}

type jobView struct {
	ID, Project, Status string
}

// NewPersistent creates the shared web UI backed by SQLite and a bounded
// in-process worker queue. The caller must close the server.
func NewPersistent(root, dataDir string) (*Server, error) {
	absolute, err := filepath.Abs(dataDir)
	if err != nil {
		return nil, fmt.Errorf("Datenverzeichnis auflösen: %w", err)
	}
	if err := os.MkdirAll(filepath.Join(absolute, "jobs"), 0o755); err != nil {
		return nil, fmt.Errorf("Datenverzeichnis anlegen: %w", err)
	}
	s, err := New(root, absolute)
	if err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", filepath.Join(absolute, "server.db"))
	if err != nil {
		return nil, fmt.Errorf("SQLite öffnen: %w", err)
	}
	db.SetMaxOpenConns(1)
	state := &persistentState{db: db, dataDir: absolute, queue: make(chan queuedJob, serverQueueSize)}
	state.ctx, state.cancel = context.WithCancel(context.Background())
	s.persistent = state
	if err := s.initializeDatabase(); err != nil {
		db.Close()
		return nil, err
	}
	if err := s.loadPersistentJobs(); err != nil {
		db.Close()
		return nil, err
	}
	for range serverWorkers {
		state.wg.Add(1)
		go s.worker()
	}
	return s, nil
}

func (s *Server) initializeDatabase() error {
	// CREATE IF NOT EXISTS and the small migrations make startup safe for both a
	// new data directory and databases written by earlier MVP stages.
	statements := []string{
		`PRAGMA journal_mode=WAL`,
		`PRAGMA foreign_keys=ON`,
		`CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY, username TEXT NOT NULL UNIQUE,
			password_hash TEXT NOT NULL DEFAULT '', role TEXT NOT NULL DEFAULT 'user',
			active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL,
			CHECK(role IN ('admin','user'))
		)`,
		`CREATE TABLE IF NOT EXISTS projects (
			id INTEGER PRIMARY KEY, name TEXT NOT NULL,
			path TEXT NOT NULL, owner_id INTEGER REFERENCES users(id), created_at TEXT NOT NULL,
			UNIQUE(owner_id,name)
		)`,
		`CREATE TABLE IF NOT EXISTS jobs (
			id TEXT PRIMARY KEY, project TEXT NOT NULL, status TEXT NOT NULL,
			progress INTEGER NOT NULL, logs_json TEXT NOT NULL,
			formats_json TEXT NOT NULL, owner_id INTEGER REFERENCES users(id),
			created_at TEXT NOT NULL, updated_at TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS artifacts (
			id INTEGER PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
			format TEXT NOT NULL, filename TEXT NOT NULL, size INTEGER NOT NULL,
			UNIQUE(job_id, filename)
		)`,
		`CREATE TABLE IF NOT EXISTS sessions (
			token_hash TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			csrf_token TEXT NOT NULL, expires_at TEXT NOT NULL, created_at TEXT NOT NULL
		)`,
	}
	for _, statement := range statements {
		if _, err := s.persistent.db.Exec(statement); err != nil {
			return fmt.Errorf("SQLite-Schema anlegen: %w", err)
		}
	}
	for _, column := range []struct{ table, name, definition string }{
		{"users", "password_hash", `TEXT NOT NULL DEFAULT ''`},
		{"users", "role", `TEXT NOT NULL DEFAULT 'user'`},
		{"projects", "owner_id", `INTEGER REFERENCES users(id)`},
		{"jobs", "owner_id", `INTEGER REFERENCES users(id)`},
	} {
		if err := ensureColumn(s.persistent.db, column.table, column.name, column.definition); err != nil {
			return err
		}
	}
	if err := migrateProjectUniqueness(s.persistent.db); err != nil {
		return err
	}
	_, err := s.persistent.db.Exec(
		`UPDATE jobs SET status = 'abgebrochen', progress = 100,
		 logs_json = json_insert(logs_json, '$[#]', 'Server wurde während des Auftrags beendet.'),
		 updated_at = ? WHERE status IN ('wartet', 'läuft')`, time.Now().UTC().Format(time.RFC3339Nano))
	if err != nil {
		return fmt.Errorf("unterbrochene Jobs markieren: %w", err)
	}
	return nil
}

func (s *Server) loadPersistentJobs() error {
	rows, err := s.persistent.db.Query(`SELECT id, project, status, progress, logs_json, COALESCE(owner_id,0) FROM jobs ORDER BY created_at`)
	if err != nil {
		return err
	}
	defer rows.Close()
	var loaded []*Job
	for rows.Next() {
		job := &Job{}
		var logs string
		if err := rows.Scan(&job.ID, &job.Project, &job.Status, &job.Progress, &logs, &job.OwnerID); err != nil {
			return err
		}
		if err := json.Unmarshal([]byte(logs), &job.Logs); err != nil {
			return fmt.Errorf("Joblogs lesen: %w", err)
		}
		loaded = append(loaded, job)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return err
	}
	if err := rows.Close(); err != nil {
		return err
	}
	for _, job := range loaded {
		artifactRows, err := s.persistent.db.Query(`SELECT format, filename, size FROM artifacts WHERE job_id = ? ORDER BY id`, job.ID)
		if err != nil {
			return err
		}
		for artifactRows.Next() {
			var format, filename string
			var size int64
			if err := artifactRows.Scan(&format, &filename, &size); err != nil {
				artifactRows.Close()
				return err
			}
			job.Artifacts = append(job.Artifacts, artifactLink{Format: build.Format(format), Size: size, URL: "/artifacts/jobs/" + job.ID + "/" + filename})
		}
		artifactRows.Close()
		s.jobs[job.ID] = job
	}
	return nil
}

func (s *Server) recordProject(user *User, name, path string) error {
	if s.persistent == nil {
		return nil
	}
	if user == nil {
		return fmt.Errorf("Anmeldung erforderlich")
	}
	_, err := s.persistent.db.Exec(`INSERT INTO projects(name, path, owner_id, created_at) VALUES(?, ?, ?, ?)`,
		name, path, user.ID, time.Now().UTC().Format(time.RFC3339Nano))
	if err != nil {
		return fmt.Errorf("Projekt speichern: %w", err)
	}
	return nil
}

func (s *Server) enqueuePersistent(job *Job, projectDir string, formats []build.Format) error {
	// Store the job before queueing it so it remains visible after a restart.
	// If the bounded queue is full, undo that database entry immediately.
	formatJSON, _ := json.Marshal(formats)
	logsJSON, _ := json.Marshal(job.Logs)
	now := time.Now().UTC().Format(time.RFC3339Nano)
	_, err := s.persistent.db.Exec(`INSERT INTO jobs(id, project, status, progress, logs_json, formats_json, owner_id, created_at, updated_at)
		VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)`, job.ID, job.Project, job.Status, job.Progress, logsJSON, formatJSON, job.OwnerID, now, now)
	if err != nil {
		return fmt.Errorf("Job speichern: %w", err)
	}
	s.mu.Lock()
	s.jobs[job.ID] = job
	s.mu.Unlock()
	queued := queuedJob{id: job.ID, projectDir: projectDir, formats: append([]build.Format(nil), formats...)}
	select {
	case s.persistent.queue <- queued:
		return nil
	default:
		s.mu.Lock()
		delete(s.jobs, job.ID)
		s.mu.Unlock()
		_, _ = s.persistent.db.Exec(`DELETE FROM jobs WHERE id = ?`, job.ID)
		return fmt.Errorf("Jobqueue ist voll; bitte später erneut versuchen")
	}
}

func (s *Server) worker() {
	defer s.persistent.wg.Done()
	for {
		select {
		case <-s.persistent.ctx.Done():
			return
		case queued := <-s.persistent.queue:
			s.runPersistentBuild(queued)
		}
	}
}

func (s *Server) runPersistentBuild(queued queuedJob) {
	// Each server job builds a private copy. One user can therefore never change
	// another user's imported source while a build is running.
	jobRoot := filepath.Join(s.persistent.dataDir, "jobs", queued.id)
	workProject := filepath.Join(jobRoot, "work", filepath.Base(queued.projectDir))
	artifactDir := filepath.Join(jobRoot, "artifacts")
	s.updateJob(queued.id, func(job *Job) {
		job.Status, job.Progress = "läuft", 15
		job.Logs = append(job.Logs, "Isoliertes Arbeitsverzeichnis wird vorbereitet.")
	})
	if err := copyProject(queued.projectDir, workProject); err != nil {
		s.finishPersistentError(queued.id, err)
		return
	}
	ctx, cancel := context.WithTimeout(s.persistent.ctx, serverJobTimeout)
	defer cancel()
	ctx = build.WithLogger(ctx, func(message string) {
		s.updateJob(queued.id, func(job *Job) {
			job.Logs = append(job.Logs, message)
		})
	})
	artifacts, err := s.build(ctx, workProject, queued.formats)
	if err != nil {
		s.finishPersistentError(queued.id, err)
		return
	}
	if err := os.MkdirAll(artifactDir, 0o755); err != nil {
		s.finishPersistentError(queued.id, err)
		return
	}
	links := make([]artifactLink, 0, len(artifacts))
	for _, artifact := range artifacts {
		filename := filepath.Base(artifact.Path)
		target := filepath.Join(artifactDir, filename)
		if err := copyRegularFile(artifact.Path, target); err != nil {
			s.finishPersistentError(queued.id, err)
			return
		}
		info, err := os.Stat(target)
		if err != nil {
			s.finishPersistentError(queued.id, err)
			return
		}
		links = append(links, artifactLink{Format: artifact.Format, Size: info.Size(), URL: "/artifacts/jobs/" + queued.id + "/" + filename})
	}
	s.updateJob(queued.id, func(job *Job) {
		job.Status, job.Progress, job.Artifacts = "fertig", 100, links
		job.Logs = append(job.Logs, fmt.Sprintf("Build abgeschlossen: %d Artefakt(e).", len(links)))
	})
}

func (s *Server) finishPersistentError(id string, err error) {
	status := "fehlgeschlagen"
	if errors.Is(err, context.Canceled) {
		status = "abgebrochen"
	}
	s.updateJob(id, func(job *Job) {
		job.Status, job.Progress = status, 100
		job.Logs = append(job.Logs, "Fehler: "+err.Error())
	})
}

func (s *Server) persistJob(job *Job) error {
	logs, _ := json.Marshal(job.Logs)
	tx, err := s.persistent.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`UPDATE jobs SET status=?, progress=?, logs_json=?, updated_at=? WHERE id=?`,
		job.Status, job.Progress, logs, time.Now().UTC().Format(time.RFC3339Nano), job.ID); err != nil {
		return err
	}
	if _, err := tx.Exec(`DELETE FROM artifacts WHERE job_id=?`, job.ID); err != nil {
		return err
	}
	for _, artifact := range job.Artifacts {
		filename := filepath.Base(artifact.URL)
		if _, err := tx.Exec(`INSERT INTO artifacts(job_id, format, filename, size) VALUES(?, ?, ?, ?)`,
			job.ID, string(artifact.Format), filename, artifact.Size); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (s *Server) recentJobs(user *User) []jobView {
	if s.persistent == nil {
		return nil
	}
	s.mu.RLock()
	result := make([]jobView, 0, len(s.jobs))
	for _, job := range s.jobs {
		if user == nil || job.OwnerID != user.ID {
			continue
		}
		result = append(result, jobView{ID: job.ID, Project: job.Project, Status: job.Status})
	}
	s.mu.RUnlock()
	sort.Slice(result, func(i, j int) bool { return result[i].ID > result[j].ID })
	if len(result) > 20 {
		result = result[:20]
	}
	return result
}

func (s *Server) persistentArtifact(user *User, jobID, filename string) (string, error) {
	// The joined query is the ownership check: knowing another job's random ID
	// and filename is not enough to download its result.
	if filepath.Base(jobID) != jobID || filepath.Base(filename) != filename || strings.ContainsAny(jobID+filename, `/\\`) {
		return "", fmt.Errorf("ungültiger Artefaktpfad")
	}
	if user == nil {
		return "", fmt.Errorf("Anmeldung erforderlich")
	}
	var count int
	if err := s.persistent.db.QueryRow(`SELECT count(*) FROM artifacts a JOIN jobs j ON j.id=a.job_id WHERE a.job_id=? AND a.filename=? AND j.owner_id=?`, jobID, filename, user.ID).Scan(&count); err != nil || count != 1 {
		return "", fmt.Errorf("Artefakt nicht gefunden")
	}
	return filepath.Join(s.persistent.dataDir, "jobs", jobID, "artifacts", filename), nil
}

func ensureColumn(db *sql.DB, table, name, definition string) error {
	rows, err := db.Query(`PRAGMA table_info(` + table + `)`)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var cid int
		var column, typ string
		var notNull, pk int
		var defaultValue any
		if err := rows.Scan(&cid, &column, &typ, &notNull, &defaultValue, &pk); err != nil {
			return err
		}
		if column == name {
			return nil
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if _, err := db.Exec(`ALTER TABLE ` + table + ` ADD COLUMN ` + name + ` ` + definition); err != nil {
		return fmt.Errorf("SQLite-Spalte %s.%s ergänzen: %w", table, name, err)
	}
	return nil
}

func migrateProjectUniqueness(db *sql.DB) error {
	var schema string
	if err := db.QueryRow(`SELECT sql FROM sqlite_master WHERE type='table' AND name='projects'`).Scan(&schema); err != nil {
		return err
	}
	if !strings.Contains(strings.ToUpper(schema), "NAME TEXT NOT NULL UNIQUE") {
		return nil
	}
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	statements := []string{
		`ALTER TABLE projects RENAME TO projects_legacy`,
		`CREATE TABLE projects (id INTEGER PRIMARY KEY, name TEXT NOT NULL, path TEXT NOT NULL, owner_id INTEGER REFERENCES users(id), created_at TEXT NOT NULL, UNIQUE(owner_id,name))`,
		`INSERT INTO projects(id,name,path,owner_id,created_at) SELECT id,name,path,owner_id,created_at FROM projects_legacy`,
		`DROP TABLE projects_legacy`,
	}
	for _, statement := range statements {
		if _, err := tx.Exec(statement); err != nil {
			return fmt.Errorf("Projektschema migrieren: %w", err)
		}
	}
	return tx.Commit()
}

func copyProject(source, target string) error {
	return filepath.WalkDir(source, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		relative, err := filepath.Rel(source, path)
		if err != nil {
			return err
		}
		if relative == "Outputs" && entry.IsDir() {
			return filepath.SkipDir
		}
		destination := filepath.Join(target, relative)
		info, err := entry.Info()
		if err != nil {
			return err
		}
		if info.Mode()&os.ModeSymlink != 0 || (!info.IsDir() && !info.Mode().IsRegular()) {
			return fmt.Errorf("Projekt enthält Link oder Sonderdatei: %s", relative)
		}
		if info.IsDir() {
			return os.MkdirAll(destination, 0o755)
		}
		return copyRegularFile(path, destination)
	})
}

func copyRegularFile(source, target string) error {
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return err
	}
	input, err := os.Open(source)
	if err != nil {
		return err
	}
	defer input.Close()
	output, err := os.OpenFile(target, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	_, copyErr := io.Copy(output, input)
	closeErr := output.Close()
	if copyErr != nil {
		return copyErr
	}
	return closeErr
}

// Close stops workers and closes SQLite.
func (s *Server) Close() error {
	if s.persistent == nil {
		return nil
	}
	s.persistent.cancel()
	s.persistent.wg.Wait()
	_, _ = s.persistent.db.Exec(`UPDATE jobs SET status='abgebrochen', progress=100 WHERE status IN ('wartet','läuft')`)
	return s.persistent.db.Close()
}

// RunServer starts the persistent server without opening a browser.
func RunServer(ctx context.Context, root, dataDir, address string, stdout io.Writer) error {
	server, err := NewPersistent(root, dataDir)
	if err != nil {
		return err
	}
	defer server.Close()
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("Serveradresse öffnen: %w", err)
	}
	httpServer := &http.Server{
		Handler: server, ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout: 30 * time.Second, WriteTimeout: 15 * time.Minute, IdleTimeout: 60 * time.Second,
	}
	fmt.Fprintf(stdout, "OA-Server läuft unter http://%s\nDaten: %s\nBeenden mit Strg+C.\n", listener.Addr(), dataDir)
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
