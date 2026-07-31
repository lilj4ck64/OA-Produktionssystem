package project

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestOpenExpectedXML(t *testing.T) {
	parent := t.TempDir()
	dir := filepath.Join(parent, "Buch")
	if err := os.MkdirAll(filepath.Join(dir, "Strukturierte_Daten"), 0o755); err != nil {
		t.Fatal(err)
	}
	xml := filepath.Join(dir, "Strukturierte_Daten", "Buch.xml")
	if err := os.WriteFile(xml, []byte("<book/>"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := Open(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got.Dir != dir || got.Name != "Buch" || got.XML != xml {
		t.Fatalf("Open() = %#v", got)
	}
}

func TestOpenRejectsMissingXML(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "Buch")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	_, err := Open(dir)
	if err == nil || !strings.Contains(err.Error(), "XML-Datei fehlt") {
		t.Fatalf("Open() error = %v", err)
	}
}

func TestWithinRejectsEscape(t *testing.T) {
	_, err := Within(t.TempDir(), "..", "außerhalb")
	if err == nil {
		t.Fatal("Within() accepted path escape")
	}
}

func TestWithinRejectsAbsolutePath(t *testing.T) {
	absolute := filepath.Join(t.TempDir(), "outside")
	_, err := Within(t.TempDir(), absolute)
	if err == nil || !strings.Contains(err.Error(), "absoluter Pfad") {
		t.Fatalf("Within() error = %v, want absolute-path error", err)
	}
}
