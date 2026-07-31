package build

import (
	"archive/zip"
	"os"
	"path/filepath"
	"testing"
)

func TestCreateEPUBWritesMimetypeFirstAndUncompressed(t *testing.T) {
	root := t.TempDir()
	for path, content := range map[string]string{
		"mimetype":                    epubMimetype,
		"META-INF/container.xml":      "<container/>",
		"OEBPS/content.opf":           "<package/>",
		"OEBPS/Content/chapter.xhtml": "<html/>",
	} {
		fullPath := filepath.Join(root, filepath.FromSlash(path))
		if err := os.MkdirAll(filepath.Dir(fullPath), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(fullPath, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	destination := filepath.Join(t.TempDir(), "book.epub")
	if err := createEPUB(root, destination); err != nil {
		t.Fatal(err)
	}
	reader, err := zip.OpenReader(destination)
	if err != nil {
		t.Fatal(err)
	}
	defer reader.Close()
	if len(reader.File) == 0 || reader.File[0].Name != "mimetype" {
		t.Fatalf("first ZIP entry = %q, want mimetype", reader.File[0].Name)
	}
	if reader.File[0].Method != zip.Store {
		t.Fatalf("mimetype method = %d, want Store", reader.File[0].Method)
	}
	for i := 2; i < len(reader.File); i++ {
		if reader.File[i-1].Name > reader.File[i].Name {
			t.Fatalf("entries are not sorted: %q before %q", reader.File[i-1].Name, reader.File[i].Name)
		}
	}
}
