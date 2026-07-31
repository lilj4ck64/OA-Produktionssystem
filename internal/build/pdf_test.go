package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPublishAllLeavesExistingOutputsUntouchedWhenStagingFails(t *testing.T) {
	outputDir := t.TempDir()
	oldTarget := filepath.Join(outputDir, "book-print.pdf")
	if err := os.WriteFile(oldTarget, []byte("old-valid-pdf"), 0o644); err != nil {
		t.Fatal(err)
	}
	newSource := filepath.Join(t.TempDir(), "new.pdf")
	if err := os.WriteFile(newSource, []byte("new-pdf"), 0o644); err != nil {
		t.Fatal(err)
	}

	err := publishAll([]pendingArtifact{
		{temp: newSource, target: oldTarget},
		{temp: filepath.Join(t.TempDir(), "missing.epub"), target: filepath.Join(outputDir, "book.epub")},
	})
	if err == nil {
		t.Fatal("publishAll succeeded despite a missing staged artifact")
	}
	content, readErr := os.ReadFile(oldTarget)
	if readErr != nil {
		t.Fatal(readErr)
	}
	if string(content) != "old-valid-pdf" {
		t.Fatalf("existing output changed to %q", content)
	}
}

func TestPublishAllRefusesToReplaceDirectory(t *testing.T) {
	outputDir := t.TempDir()
	target := filepath.Join(outputDir, "book.pdf")
	if err := os.Mkdir(target, 0o755); err != nil {
		t.Fatal(err)
	}
	source := filepath.Join(t.TempDir(), "book.pdf")
	if err := os.WriteFile(source, []byte("new-pdf"), 0o644); err != nil {
		t.Fatal(err)
	}

	err := publishAll([]pendingArtifact{{temp: source, target: target}})
	if err == nil || !strings.Contains(err.Error(), "keine reguläre Datei") {
		t.Fatalf("publishAll error = %v", err)
	}
	if info, statErr := os.Stat(target); statErr != nil || !info.IsDir() {
		t.Fatalf("target directory was changed: info=%v err=%v", info, statErr)
	}
}
