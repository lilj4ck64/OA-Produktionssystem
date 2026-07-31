package gui

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestInitialAdminLoginAndCSRF(t *testing.T) {
	dataDir := t.TempDir()
	if err := CreateInitialAdmin(dataDir, "admin", "very-secure-password"); err != nil {
		t.Fatal(err)
	}
	if err := CreateInitialAdmin(dataDir, "other-admin", "very-secure-password"); err == nil || !strings.Contains(err.Error(), "bereits") {
		t.Fatalf("second bootstrap error = %v", err)
	}
	server, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()

	unauthorized := httptest.NewRecorder()
	server.ServeHTTP(unauthorized, httptest.NewRequest(http.MethodGet, "/", nil))
	if unauthorized.Code != http.StatusSeeOther || unauthorized.Header().Get("Location") != "/login" {
		t.Fatalf("unauthorized home = %d, %q", unauthorized.Code, unauthorized.Header().Get("Location"))
	}
	cookie := loginTestUser(t, server, "admin", "very-secure-password")
	home := httptest.NewRecorder()
	homeRequest := httptest.NewRequest(http.MethodGet, "/", nil)
	homeRequest.AddCookie(cookie)
	server.ServeHTTP(home, homeRequest)
	if home.Code != http.StatusOK || !strings.Contains(home.Body.String(), "Benutzer verwalten") {
		t.Fatalf("admin home = %d: %s", home.Code, home.Body.String())
	}
	missingCSRF := httptest.NewRecorder()
	post := httptest.NewRequest(http.MethodPost, "/logout", nil)
	post.AddCookie(cookie)
	server.ServeHTTP(missingCSRF, post)
	if missingCSRF.Code != http.StatusForbidden {
		t.Fatalf("POST without CSRF = %d, want 403", missingCSRF.Code)
	}
}

func TestUsersCanOnlyAccessTheirOwnJobsAndArtifacts(t *testing.T) {
	server, err := NewPersistent(t.TempDir(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	alice := addTestUser(t, server, "alice", "alice-password-123")
	bob := addTestUser(t, server, "bobby", "bobby-password-123")
	job := &Job{ID: "alice-job", Project: "AliceBook", Status: "fertig", Progress: 100, OwnerID: alice.ID}
	server.jobs[job.ID] = job
	now := time.Now().UTC().Format(time.RFC3339Nano)
	if _, err := server.persistent.db.Exec(`INSERT INTO jobs(id,project,status,progress,logs_json,formats_json,owner_id,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,?)`, job.ID, job.Project, job.Status, job.Progress, `[]`, `[]`, alice.ID, now, now); err != nil {
		t.Fatal(err)
	}
	if _, err := server.persistent.db.Exec(`INSERT INTO artifacts(job_id,format,filename,size) VALUES(?,?,?,?)`, job.ID, "print-pdf", "book.pdf", 4); err != nil {
		t.Fatal(err)
	}
	artifactPath := filepath.Join(server.persistent.dataDir, "jobs", job.ID, "artifacts", "book.pdf")
	if err := os.MkdirAll(filepath.Dir(artifactPath), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(artifactPath, []byte("test"), 0o644); err != nil {
		t.Fatal(err)
	}

	aliceCookie := testSessionCookie(t, server, alice.ID)
	bobCookie := testSessionCookie(t, server, bob.ID)
	for _, test := range []struct {
		name, path string
		cookie     *http.Cookie
		want       int
	}{
		{"owner job", "/jobs/alice-job", aliceCookie, http.StatusOK},
		{"foreign job", "/jobs/alice-job", bobCookie, http.StatusNotFound},
		{"owner artifact", "/artifacts/jobs/alice-job/book.pdf", aliceCookie, http.StatusOK},
		{"foreign artifact", "/artifacts/jobs/alice-job/book.pdf", bobCookie, http.StatusNotFound},
	} {
		t.Run(test.name, func(t *testing.T) {
			response := httptest.NewRecorder()
			request := httptest.NewRequest(http.MethodGet, test.path, nil)
			request.AddCookie(test.cookie)
			server.ServeHTTP(response, request)
			if response.Code != test.want {
				t.Fatalf("status = %d, want %d", response.Code, test.want)
			}
		})
	}
}

func TestUsersCanUseSameProjectNameWithoutCrossAccess(t *testing.T) {
	dataDir := t.TempDir()
	server, err := NewPersistent(t.TempDir(), dataDir)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	alice := addTestUser(t, server, "alice2", "alice-password-123")
	bob := addTestUser(t, server, "bobby2", "bobby-password-123")
	for _, user := range []*User{alice, bob} {
		path := filepath.Join(dataDir, "projects", fmt.Sprint(user.ID), "Buch")
		if err := os.MkdirAll(filepath.Join(path, "Strukturierte_Daten"), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(path, "Strukturierte_Daten", "Buch.xml"), []byte("<book/>"), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := server.recordProject(user, "Buch", path); err != nil {
			t.Fatal(err)
		}
	}
	aliceProject, err := server.openWorkspaceProject(alice, "Buch")
	if err != nil {
		t.Fatal(err)
	}
	bobProject, err := server.openWorkspaceProject(bob, "Buch")
	if err != nil {
		t.Fatal(err)
	}
	if aliceProject.Dir == bobProject.Dir || !strings.Contains(aliceProject.Dir, fmt.Sprint(alice.ID)) || !strings.Contains(bobProject.Dir, fmt.Sprint(bob.ID)) {
		t.Fatalf("projects crossed owners: alice=%q bob=%q", aliceProject.Dir, bobProject.Dir)
	}
}

func TestDisabledUserCannotLogin(t *testing.T) {
	server, err := NewPersistent(t.TempDir(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	user := addTestUser(t, server, "carol", "carol-password-123")
	if _, err := server.persistent.db.Exec(`UPDATE users SET active=0 WHERE id=?`, user.ID); err != nil {
		t.Fatal(err)
	}
	response := performLogin(t, server, "carol", "carol-password-123")
	if response.Code != http.StatusSeeOther || !strings.HasPrefix(response.Header().Get("Location"), "/login?error=") {
		t.Fatalf("disabled login = %d, %q", response.Code, response.Header().Get("Location"))
	}
}

func loginTestUser(t *testing.T, server *Server, username, password string) *http.Cookie {
	t.Helper()
	response := performLogin(t, server, username, password)
	if response.Code != http.StatusSeeOther || response.Header().Get("Location") != "/" {
		t.Fatalf("login = %d, %q: %s", response.Code, response.Header().Get("Location"), response.Body.String())
	}
	for _, cookie := range response.Result().Cookies() {
		if cookie.Name == sessionCookie {
			return cookie
		}
	}
	t.Fatal("login did not return a session cookie")
	return nil
}

func performLogin(t *testing.T, server *Server, username, password string) *httptest.ResponseRecorder {
	t.Helper()
	get := httptest.NewRecorder()
	server.ServeHTTP(get, httptest.NewRequest(http.MethodGet, "/login", nil))
	var csrfCookie *http.Cookie
	for _, cookie := range get.Result().Cookies() {
		if cookie.Name == loginCSRFCookie {
			csrfCookie = cookie
		}
	}
	if csrfCookie == nil {
		t.Fatal("login CSRF cookie missing")
	}
	form := url.Values{"csrf_token": {csrfCookie.Value}, "username": {username}, "password": {password}}
	request := httptest.NewRequest(http.MethodPost, "/login", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request.AddCookie(csrfCookie)
	response := httptest.NewRecorder()
	server.ServeHTTP(response, request)
	return response
}
