//go:build integration

package tests

import (
	"archive/zip"
	"bytes"
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	buildpkg "oa-satzsystem/internal/build"
	javapkg "oa-satzsystem/internal/java"
)

const minimumArtifactSize = 1024

func TestMusterbuchFullBuild(t *testing.T) {
	root, err := filepath.Abs("..")
	if err != nil {
		t.Fatal(err)
	}
	projectDir := filepath.Join(root, "Projekte", "Musterbuch")
	outputDir := t.TempDir()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	var toolLogs []string
	ctx = buildpkg.WithLogger(ctx, func(message string) {
		toolLogs = append(toolLogs, message)
	})
	engine := buildpkg.Engine{Root: root, OutputDir: outputDir}
	if executable := os.Getenv("OA_JAVA"); executable != "" {
		engine.Java = javapkg.Runner{Executable: executable}
	}
	artifacts, err := engine.Build(ctx, projectDir, []buildpkg.Format{
		buildpkg.PrintPDF,
		buildpkg.WebPDF,
		buildpkg.EPUB,
	})
	if err != nil {
		t.Fatalf("vollständiger Musterbuch-Build: %v", err)
	}
	joinedLogs := strings.Join(toolLogs, "\n")
	for _, expected := range []string{"Saxon: erfolgreich", "FOP: erfolgreich", "EPUBCheck: erfolgreich"} {
		if !strings.Contains(joinedLogs, expected) {
			t.Errorf("Werkzeugmeldung %q fehlt in:\n%s", expected, joinedLogs)
		}
	}

	byFormat := make(map[buildpkg.Format]buildpkg.Artifact, len(artifacts))
	for _, artifact := range artifacts {
		byFormat[artifact.Format] = artifact
	}
	for _, format := range []buildpkg.Format{buildpkg.PrintPDF, buildpkg.WebPDF, buildpkg.EPUB} {
		artifact, ok := byFormat[format]
		if !ok {
			t.Errorf("Artefakt %s fehlt", format)
			continue
		}
		if artifact.Size < minimumArtifactSize {
			t.Errorf("%s ist mit %d Bytes zu klein", format, artifact.Size)
		}
		if info, statErr := os.Stat(artifact.Path); statErr != nil {
			t.Errorf("%s existiert nicht: %v", format, statErr)
		} else if info.Size() != artifact.Size {
			t.Errorf("%s: gemeldete Größe %d, Dateigröße %d", format, artifact.Size, info.Size())
		}
	}

	for _, format := range []buildpkg.Format{buildpkg.PrintPDF, buildpkg.WebPDF} {
		if artifact, ok := byFormat[format]; ok {
			assertReadablePDF(t, artifact.Path)
		}
	}
	if artifact, ok := byFormat[buildpkg.EPUB]; ok {
		assertEPUBContainer(t, artifact.Path)
	}
}

func assertReadablePDF(t *testing.T, path string) {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(content) < minimumArtifactSize {
		t.Fatalf("%s ist mit %d Bytes zu klein", path, len(content))
	}
	if !bytes.HasPrefix(content, []byte("%PDF-")) {
		t.Errorf("%s hat keinen PDF-Header", path)
	}
	if !bytes.Contains(content, []byte("/Type /Page")) {
		t.Errorf("%s enthält keine lesbare Seitenstruktur", path)
	}
	if !bytes.Contains(content, []byte("%%EOF")) {
		t.Errorf("%s enthält keinen PDF-Endmarker", path)
	}
}

func assertEPUBContainer(t *testing.T, path string) {
	t.Helper()
	reader, err := zip.OpenReader(path)
	if err != nil {
		t.Fatal(err)
	}
	defer reader.Close()
	if len(reader.File) == 0 {
		t.Fatal("EPUB-ZIP ist leer")
	}
	first := reader.File[0]
	if first.Name != "mimetype" || first.Method != zip.Store {
		t.Fatalf("erster EPUB-Eintrag = %s (Methode %d), erwartet unkomprimiertes mimetype",
			first.Name, first.Method)
	}
	entry, err := first.Open()
	if err != nil {
		t.Fatal(err)
	}
	mimetype, readErr := io.ReadAll(entry)
	closeErr := entry.Close()
	if readErr != nil {
		t.Fatal(readErr)
	}
	if closeErr != nil {
		t.Fatal(closeErr)
	}
	if string(mimetype) != "application/epub+zip" {
		t.Fatalf("EPUB-mimetype = %q", mimetype)
	}
}
