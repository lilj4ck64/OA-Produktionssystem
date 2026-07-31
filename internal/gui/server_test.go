package gui

import (
	"archive/zip"
	"bytes"
	"context"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"oa-satzsystem/internal/build"
)

func TestHomeAndEmbeddedAssets(t *testing.T) {
	server, err := New(t.TempDir(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range []struct {
		path, contains string
	}{
		{"/", "Projekt importieren"},
		{"/static/style.css", ".dropzone"},
		{"/static/app.js", "dragenter"},
	} {
		request := httptest.NewRequest(http.MethodGet, test.path, nil)
		response := httptest.NewRecorder()
		server.ServeHTTP(response, request)
		if response.Code != http.StatusOK {
			t.Fatalf("GET %s returned %d", test.path, response.Code)
		}
		if !strings.Contains(response.Body.String(), test.contains) {
			t.Fatalf("GET %s did not contain %q", test.path, test.contains)
		}
	}
}

func TestImportZIPAndRejectTraversal(t *testing.T) {
	projectsDir := t.TempDir()
	valid := makeZIP(t, map[string]string{
		"Buch/Strukturierte_Daten/Buch.xml": "<book/>",
		"Buch/Media/Images/cover.jpg":       "image",
	})
	file, err := os.Open(valid)
	if err != nil {
		t.Fatal(err)
	}
	name, err := importZIP(file, &multipart.FileHeader{Filename: "buch.zip"}, projectsDir)
	file.Close()
	if err != nil {
		t.Fatal(err)
	}
	if name != "Buch" {
		t.Fatalf("imported project = %q, want Buch", name)
	}
	if _, err := os.Stat(filepath.Join(projectsDir, "Buch", "Strukturierte_Daten", "Buch.xml")); err != nil {
		t.Fatal(err)
	}

	malicious := makeZIP(t, map[string]string{"../escape.txt": "no"})
	file, err = os.Open(malicious)
	if err != nil {
		t.Fatal(err)
	}
	_, err = importZIP(file, &multipart.FileHeader{Filename: "bad.zip"}, projectsDir)
	file.Close()
	if err == nil || !strings.Contains(err.Error(), "unsicherer ZIP-Pfad") {
		t.Fatalf("traversal import error = %v", err)
	}
}

func TestImportZIPWithProjectContentsAtArchiveRoot(t *testing.T) {
	projectsDir := t.TempDir()
	archivePath := makeZIP(t, map[string]string{
		"Strukturierte_Daten/TTT.xml": "<book/>",
		"Media/Images/cover.jpg":      "image",
	})
	file, err := os.Open(archivePath)
	if err != nil {
		t.Fatal(err)
	}
	name, err := importZIP(file, &multipart.FileHeader{Filename: "TTT.zip"}, projectsDir)
	file.Close()
	if err != nil {
		t.Fatal(err)
	}
	if name != "TTT" {
		t.Fatalf("imported project = %q, want TTT", name)
	}
	if _, err := os.Stat(filepath.Join(projectsDir, "TTT", "Strukturierte_Daten", "TTT.xml")); err != nil {
		t.Fatal(err)
	}
}

func TestBuildJobUsesSharedBuildFunction(t *testing.T) {
	workspace := t.TempDir()
	projectDir := filepath.Join(workspace, "projects", "Buch")
	if err := os.MkdirAll(filepath.Join(projectDir, "Strukturierte_Daten"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(projectDir, "Strukturierte_Daten", "Buch.xml"), []byte("<book/>"), 0o644); err != nil {
		t.Fatal(err)
	}
	server, err := New(t.TempDir(), workspace)
	if err != nil {
		t.Fatal(err)
	}
	called := make(chan []build.Format, 1)
	server.build = func(_ context.Context, path string, formats []build.Format) ([]build.Artifact, error) {
		called <- formats
		output := filepath.Join(path, "Outputs", "Buch-print.pdf")
		if err := os.MkdirAll(filepath.Dir(output), 0o755); err != nil {
			return nil, err
		}
		if err := os.WriteFile(output, []byte("%PDF-test"), 0o644); err != nil {
			return nil, err
		}
		return []build.Artifact{{Format: build.PrintPDF, Path: output, Size: 9}}, nil
	}
	form := url.Values{"project": {"Buch"}, "format": {"print-pdf"}}
	request := httptest.NewRequest(http.MethodPost, "/build", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response := httptest.NewRecorder()
	server.ServeHTTP(response, request)
	if response.Code != http.StatusSeeOther {
		t.Fatalf("POST /build returned %d: %s", response.Code, response.Body.String())
	}
	location := response.Header().Get("Location")
	id := strings.TrimPrefix(location, "/jobs/")
	jobPage := httptest.NewRecorder()
	server.ServeHTTP(jobPage, httptest.NewRequest(http.MethodGet, location, nil))
	expectedScript := `window.OA_JOB_ID = "` + id + `";`
	if !strings.Contains(jobPage.Body.String(), expectedScript) {
		t.Fatalf("job page does not contain %q: %s", expectedScript, jobPage.Body.String())
	}
	select {
	case formats := <-called:
		if len(formats) != 1 || formats[0] != build.PrintPDF {
			t.Fatalf("build formats = %v", formats)
		}
	case <-time.After(time.Second):
		t.Fatal("shared build function was not called")
	}
	deadline := time.Now().Add(time.Second)
	for {
		server.mu.RLock()
		status := server.jobs[id].Status
		server.mu.RUnlock()
		if status == "fertig" {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("job status = %q, want fertig", status)
		}
		time.Sleep(time.Millisecond)
	}
	apiResponse := httptest.NewRecorder()
	server.ServeHTTP(apiResponse, httptest.NewRequest(http.MethodGet, "/api/jobs/"+id, nil))
	if !strings.Contains(apiResponse.Body.String(), `"status":"fertig"`) ||
		!strings.Contains(apiResponse.Body.String(), "/artifacts/Buch/Buch-print.pdf") {
		t.Fatalf("unexpected job JSON: %s", apiResponse.Body.String())
	}
}

func TestImportHandlerAcceptsMultipartZIP(t *testing.T) {
	server, err := New(t.TempDir(), t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	archivePath := makeZIP(t, map[string]string{"Buch/Strukturierte_Daten/Buch.xml": "<book/>"})
	archive, err := os.Open(archivePath)
	if err != nil {
		t.Fatal(err)
	}
	defer archive.Close()
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	part, err := writer.CreateFormFile("project", "Buch.zip")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := io.Copy(part, archive); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/import", &body)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()
	server.ServeHTTP(response, request)
	if response.Code != http.StatusSeeOther {
		t.Fatalf("POST /import returned %d: %s", response.Code, response.Body.String())
	}
	if !strings.Contains(response.Header().Get("Location"), "wurde+importiert") {
		t.Fatalf("redirect = %q", response.Header().Get("Location"))
	}
}

func makeZIP(t *testing.T, files map[string]string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "project.zip")
	output, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	archive := zip.NewWriter(output)
	for name, content := range files {
		entry, err := archive.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := io.WriteString(entry, content); err != nil {
			t.Fatal(err)
		}
	}
	if err := archive.Close(); err != nil {
		t.Fatal(err)
	}
	if err := output.Close(); err != nil {
		t.Fatal(err)
	}
	return path
}
