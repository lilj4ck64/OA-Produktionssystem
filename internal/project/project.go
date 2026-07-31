// Package project discovers and validates OA publication projects.
package project

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Project contains the canonical paths needed by a build.
type Project struct {
	Dir  string
	Name string
	XML  string
}

// Open validates a project directory and its expected XML source.
func Open(path string) (Project, error) {
	if strings.TrimSpace(path) == "" {
		return Project{}, fmt.Errorf("Projektpfad fehlt")
	}
	absolute, err := filepath.Abs(path)
	if err != nil {
		return Project{}, fmt.Errorf("Projektpfad auflösen: %w", err)
	}
	absolute = filepath.Clean(absolute)
	linkInfo, err := os.Lstat(absolute)
	if err != nil {
		return Project{}, fmt.Errorf("Projekt prüfen: %w", err)
	}
	if linkInfo.Mode()&os.ModeSymlink != 0 {
		return Project{}, fmt.Errorf("Projektpfad darf kein symbolischer Link sein: %s", absolute)
	}
	info, err := os.Stat(absolute)
	if err != nil {
		return Project{}, fmt.Errorf("Projekt prüfen: %w", err)
	}
	if !info.IsDir() {
		return Project{}, fmt.Errorf("Projektpfad ist kein Verzeichnis: %s", absolute)
	}

	name := filepath.Base(absolute)
	xmlPath, err := Within(absolute, "Strukturierte_Daten", name+".xml")
	if err != nil {
		return Project{}, err
	}
	xmlInfo, err := os.Stat(xmlPath)
	if err != nil {
		if os.IsNotExist(err) {
			return Project{}, fmt.Errorf("erwartete XML-Datei fehlt: %s", xmlPath)
		}
		return Project{}, fmt.Errorf("XML-Datei prüfen: %w", err)
	}
	if !xmlInfo.Mode().IsRegular() {
		return Project{}, fmt.Errorf("XML-Pfad ist keine reguläre Datei: %s", xmlPath)
	}
	xmlLinkInfo, err := os.Lstat(xmlPath)
	if err != nil {
		return Project{}, fmt.Errorf("XML-Datei prüfen: %w", err)
	}
	if xmlLinkInfo.Mode()&os.ModeSymlink != 0 {
		return Project{}, fmt.Errorf("XML-Datei darf kein symbolischer Link sein: %s", xmlPath)
	}
	return Project{Dir: absolute, Name: name, XML: xmlPath}, nil
}

// Within resolves path elements and rejects paths outside base.
func Within(base string, elements ...string) (string, error) {
	baseAbs, err := filepath.Abs(base)
	if err != nil {
		return "", fmt.Errorf("Basisverzeichnis auflösen: %w", err)
	}
	for _, element := range elements {
		if filepath.IsAbs(element) || filepath.VolumeName(element) != "" {
			return "", fmt.Errorf("absoluter Pfad ist innerhalb des Projektverzeichnisses nicht erlaubt: %s", element)
		}
	}
	candidate := filepath.Join(append([]string{baseAbs}, elements...)...)
	candidate, err = filepath.Abs(candidate)
	if err != nil {
		return "", fmt.Errorf("Pfad auflösen: %w", err)
	}
	relative, err := filepath.Rel(baseAbs, candidate)
	if err != nil {
		return "", fmt.Errorf("Pfad begrenzen: %w", err)
	}
	if relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) || filepath.IsAbs(relative) {
		return "", fmt.Errorf("Pfad liegt außerhalb des Projektverzeichnisses: %s", candidate)
	}
	return candidate, nil
}
