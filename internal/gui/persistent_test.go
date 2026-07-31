package gui

import (
	"context"
	"database/sql"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"oa-satzsystem/internal/build"
)

func TestPersistentJobSurvivesRestart(t *testing.T) {
	dataDir := t.TempDir()
	projectDir := filepath.Join(dataDir, "projects", "Buch")
	if err := os.MkdirAll(filepath.Join(projectDir, "Strukturierte_Daten"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(projectDir, "Strukturierte_Daten", "Buch.xml"), []byte("<book/>"), 0o644); err != nil {
		t.Fatal(err)
	}
	server, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	user := addTestUser(t, server, "alice", "alice-password-123")
	if err := server.recordProject(user, "Buch", projectDir); err != nil {
		t.Fatal(err)
	}
	server.build = func(_ context.Context, path string, formats []build.Format) ([]build.Artifact, error) {
		output := filepath.Join(path, "Outputs", "Buch-print.pdf")
		if err := os.MkdirAll(filepath.Dir(output), 0o755); err != nil {
			return nil, err
		}
		if err := os.WriteFile(output, []byte("%PDF-persistent"), 0o644); err != nil {
			return nil, err
		}
		return []build.Artifact{{Format: formats[0], Path: output, Size: 15}}, nil
	}
	job := &Job{ID: "persistent-job", Project: "Buch", Status: "wartet", Progress: 5, Logs: []string{"Build wurde eingeplant."}, OwnerID: user.ID}
	if err := server.enqueuePersistent(job, projectDir, []build.Format{build.PrintPDF}); err != nil {
		t.Fatal(err)
	}
	waitForJobStatus(t, server, job.ID, "fertig")
	if err := server.Close(); err != nil {
		t.Fatal(err)
	}

	restarted, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	defer restarted.Close()
	user = &User{ID: user.ID, Username: user.Username, Role: user.Role}
	restarted.mu.RLock()
	loaded := restarted.jobs[job.ID]
	restarted.mu.RUnlock()
	if loaded == nil || loaded.Status != "fertig" || len(loaded.Artifacts) != 1 {
		t.Fatalf("loaded job = %#v", loaded)
	}
	cookie := testSessionCookie(t, restarted, user.ID)
	home := httptest.NewRecorder()
	homeRequest := httptest.NewRequest(http.MethodGet, "/", nil)
	homeRequest.AddCookie(cookie)
	restarted.ServeHTTP(home, homeRequest)
	if !strings.Contains(home.Body.String(), job.ID) {
		t.Fatalf("home does not list persistent job: %s", home.Body.String())
	}
	artifact := httptest.NewRecorder()
	artifactRequest := httptest.NewRequest(http.MethodGet, loaded.Artifacts[0].URL, nil)
	artifactRequest.AddCookie(cookie)
	restarted.ServeHTTP(artifact, artifactRequest)
	if artifact.Code != http.StatusOK || artifact.Body.String() != "%PDF-persistent" {
		t.Fatalf("artifact response = %d, %q", artifact.Code, artifact.Body.String())
	}
}

func addTestUser(t *testing.T, server *Server, username, password string) *User {
	t.Helper()
	if err := server.createUser(username, password, roleUser); err != nil {
		t.Fatal(err)
	}
	user := &User{Username: username, Role: roleUser}
	if err := server.persistent.db.QueryRow(`SELECT id FROM users WHERE username=?`, username).Scan(&user.ID); err != nil {
		t.Fatal(err)
	}
	return user
}

func testSessionCookie(t *testing.T, server *Server, userID int64) *http.Cookie {
	t.Helper()
	response := httptest.NewRecorder()
	if err := server.startSession(response, httptest.NewRequest(http.MethodGet, "/", nil), userID); err != nil {
		t.Fatal(err)
	}
	for _, cookie := range response.Result().Cookies() {
		if cookie.Name == sessionCookie {
			return cookie
		}
	}
	t.Fatal("session cookie missing")
	return nil
}

func TestRestartMarksRunningJobsAborted(t *testing.T) {
	dataDir := t.TempDir()
	server, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC().Format(time.RFC3339Nano)
	_, err = server.persistent.db.Exec(`INSERT INTO jobs(id, project, status, progress, logs_json, formats_json, created_at, updated_at)
		VALUES('interrupted', 'Buch', 'läuft', 20, '["gestartet"]', '["print-pdf"]', ?, ?)`, now, now)
	if err != nil {
		t.Fatal(err)
	}
	if err := server.Close(); err != nil {
		t.Fatal(err)
	}
	// Simulate an unclean stop after the close hook by restoring the running
	// state directly in SQLite. Startup must repair it independently.
	db, err := sql.Open("sqlite", filepath.Join(dataDir, "server.db"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`UPDATE jobs SET status='läuft', progress=20 WHERE id='interrupted'`); err != nil {
		db.Close()
		t.Fatal(err)
	}
	if err := db.Close(); err != nil {
		t.Fatal(err)
	}
	restarted, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	defer restarted.Close()
	if got := restarted.jobs["interrupted"].Status; got != "abgebrochen" {
		t.Fatalf("status after restart = %q", got)
	}
}

func waitForJobStatus(t *testing.T, server *Server, id, want string) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		server.mu.RLock()
		job := server.jobs[id]
		status := ""
		if job != nil {
			status = job.Status
		}
		server.mu.RUnlock()
		if status == want {
			return
		}
		if status == "fehlgeschlagen" {
			t.Fatalf("job failed: %#v", job)
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("job %s did not reach %q", id, want)
}
