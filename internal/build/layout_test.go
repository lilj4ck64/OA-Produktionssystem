package build

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveLayoutPrefersPackagedDistribution(t *testing.T) {
	root := t.TempDir()
	for _, dir := range []string{
		filepath.Join(root, "resources", "Stylesheets"),
		filepath.Join(root, "lib"),
		filepath.Join(root, "runtime", "bin"),
	} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	javaName := "java"
	if filepath.Separator == '\\' {
		javaName = "java.exe"
	}
	javaPath := filepath.Join(root, "runtime", "bin", javaName)
	if err := os.WriteFile(javaPath, []byte("test"), 0o755); err != nil {
		t.Fatal(err)
	}

	layout := resolveLayout(root)
	if layout.resources != filepath.Join(root, "resources") {
		t.Fatalf("resources = %q", layout.resources)
	}
	if layout.lib != filepath.Join(root, "lib") {
		t.Fatalf("lib = %q", layout.lib)
	}
	if got := (Engine{}).javaRunner(root).Executable; got != javaPath {
		t.Fatalf("Java executable = %q, want %q", got, javaPath)
	}
}

func TestResolveLayoutSupportsRepository(t *testing.T) {
	root := t.TempDir()
	layout := resolveLayout(root)
	if layout.resources != root {
		t.Fatalf("resources = %q, want %q", layout.resources, root)
	}
	wantLib := filepath.Join(root, "java-toolchain", "build", "stage", "lib")
	if layout.lib != wantLib {
		t.Fatalf("lib = %q, want %q", layout.lib, wantLib)
	}
}
