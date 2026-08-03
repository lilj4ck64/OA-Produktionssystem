package gui

import (
	"archive/zip"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"oa-satzsystem/internal/project"
)

type projectView struct {
	Name, Path string
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
