package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"oa-satzsystem/internal/build"
)

func TestVersion(t *testing.T) {
	var stdout, stderr bytes.Buffer

	exitCode := run([]string{"version"}, &stdout, &stderr)

	if exitCode != 0 {
		t.Fatalf("run(version) exit code = %d, want 0; stderr: %s", exitCode, stderr.String())
	}
	if got, want := stdout.String(), "oa "+version+"\n"; got != want {
		t.Fatalf("run(version) output = %q, want %q", got, want)
	}
}

func TestParseBuildArgsAllFormatsAndOutput(t *testing.T) {
	projectPath, formats, output, err := parseBuildArgs([]string{
		"--format", "print-pdf",
		"Projekte/Musterbuch",
		"--format=web-pdf",
		"--format", "epub",
		"--output", "dist",
	})
	if err != nil {
		t.Fatal(err)
	}
	if projectPath != "Projekte/Musterbuch" || output != "dist" {
		t.Fatalf("parseBuildArgs() project=%q output=%q", projectPath, output)
	}
	want := []build.Format{build.PrintPDF, build.WebPDF, build.EPUB}
	if len(formats) != len(want) {
		t.Fatalf("formats = %v, want %v", formats, want)
	}
	for i := range want {
		if formats[i] != want[i] {
			t.Fatalf("formats = %v, want %v", formats, want)
		}
	}
}

func TestValidateExitCodes(t *testing.T) {
	projectDir := filepath.Join(t.TempDir(), "Buch")
	if err := os.MkdirAll(filepath.Join(projectDir, "Strukturierte_Daten"), 0o755); err != nil {
		t.Fatal(err)
	}
	var stdout, stderr bytes.Buffer
	if got := run([]string{"validate", projectDir}, &stdout, &stderr); got != exitValidation {
		t.Fatalf("validate invalid project exit code = %d, want %d", got, exitValidation)
	}
	if err := os.WriteFile(filepath.Join(projectDir, "Strukturierte_Daten", "Buch.xml"), []byte("<book/>"), 0o644); err != nil {
		t.Fatal(err)
	}
	stdout.Reset()
	stderr.Reset()
	if got := run([]string{"validate", projectDir}, &stdout, &stderr); got != exitOK {
		t.Fatalf("validate valid project exit code = %d, want %d; stderr: %s", got, exitOK, stderr.String())
	}
}

func TestDoctor(t *testing.T) {
	var stdout, stderr bytes.Buffer

	exitCode := run([]string{"doctor"}, &stdout, &stderr)

	if exitCode != 0 {
		t.Fatalf("run(doctor) exit code = %d, want 0; stderr: %s", exitCode, stderr.String())
	}
	for _, expected := range []string{"Betriebssystem:", "Architektur:", "Version:", "Ressourcen:"} {
		if !strings.Contains(stdout.String(), expected) {
			t.Errorf("run(doctor) output does not contain %q:\n%s", expected, stdout.String())
		}
	}
}

func TestUnknownCommand(t *testing.T) {
	var stdout, stderr bytes.Buffer

	exitCode := run([]string{"unbekannt"}, &stdout, &stderr)

	if exitCode != 2 {
		t.Fatalf("run(unknown) exit code = %d, want 2", exitCode)
	}
	if !strings.Contains(stderr.String(), "Unbekannter Befehl") {
		t.Fatalf("run(unknown) stderr = %q", stderr.String())
	}
}

func TestGUIRejectsArguments(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if got := run([]string{"gui", "--port", "8000"}, &stdout, &stderr); got != exitUsage {
		t.Fatalf("gui with arguments exit code = %d, want %d", got, exitUsage)
	}
	if !strings.Contains(stderr.String(), "Verwendung: oa gui") {
		t.Fatalf("unexpected stderr: %s", stderr.String())
	}
}

func TestParseGUIArgs(t *testing.T) {
	workspace, persistent, err := parseGUIArgs(nil)
	if err != nil || workspace != "" || persistent {
		t.Fatalf("parseGUIArgs(nil) = %q, %v, %v", workspace, persistent, err)
	}
	workspace, persistent, err = parseGUIArgs([]string{"--workspace", "gui-data"})
	if err != nil {
		t.Fatal(err)
	}
	if !persistent || !filepath.IsAbs(workspace) || filepath.Base(workspace) != "gui-data" {
		t.Fatalf("persistent workspace = %q, %v", workspace, persistent)
	}
}
