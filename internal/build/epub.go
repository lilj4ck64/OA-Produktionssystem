package build

import (
	"archive/zip"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"oa-satzsystem/internal/project"
)

const epubMimetype = "application/epub+zip"
const epubCSSFilename = "HTWK-OAVerlag.css"

var zipTimestamp = time.Date(1980, 1, 1, 0, 0, 0, 0, time.UTC)

// BuildEPUB transforms, packages, validates, and only then publishes an EPUB.
func (e Engine) BuildEPUB(ctx context.Context, projectPath string) ([]Artifact, error) {
	pub, err := project.Open(projectPath)
	if err != nil {
		return nil, err
	}
	root, err := filepath.Abs(e.Root)
	if err != nil {
		return nil, fmt.Errorf("Anwendungswurzel auflösen: %w", err)
	}
	layout := resolveLayout(root)
	stylesheet := filepath.Join(layout.resources, "Stylesheets", "XMLtoEPUB.xsl")
	if err := requireFile(stylesheet); err != nil {
		return nil, err
	}

	jobDir, err := os.MkdirTemp(e.TempParent, "oa-epub-*")
	if err != nil {
		return nil, fmt.Errorf("Arbeitsverzeichnis anlegen: %w", err)
	}
	defer os.RemoveAll(jobDir)
	buildXML := filepath.Join(jobDir, pub.Name+".xml")
	if err := prepareXML(pub.XML, buildXML); err != nil {
		return nil, err
	}

	epubRoot := filepath.Join(jobDir, "epub")
	for _, dir := range []string{"META-INF", "OEBPS", "OEBPS/Content", "OEBPS/Images", "OEBPS/Styles", "OEBPS/Fonts"} {
		if err := os.MkdirAll(filepath.Join(epubRoot, filepath.FromSlash(dir)), 0o755); err != nil {
			return nil, fmt.Errorf("EPUB-Verzeichnis anlegen: %w", err)
		}
	}

	outputURI := fileURI(epubRoot)
	classpath := filepath.Join(layout.lib, "*")
	principalOutput := filepath.Join(jobDir, "saxon-result.xml")
	saxonArgs := []string{
		"-cp", classpath,
		"net.sf.saxon.Transform",
		"-s:" + buildXML,
		"-xsl:" + stylesheet,
		"-o:" + principalOutput,
		"Projekt=" + pub.Name,
		"OutputRoot=" + outputURI,
		"CSSStylesheet=" + epubCSSFilename,
	}
	logToolStart(ctx, "Saxon", "EPUB-Inhalte werden transformiert.")
	result, runErr := e.javaRunner(root).Run(ctx, root, saxonArgs...)
	logToolResult(ctx, "Saxon", result, runErr)
	if runErr != nil {
		return nil, fmt.Errorf("Saxon-Transformation fehlgeschlagen (Exitcode %d, Dauer %s): %w\n%s",
			result.ExitCode, result.Duration.Round(time.Millisecond), runErr, strings.TrimSpace(result.Stderr))
	}

	imagesTarget := filepath.Join(epubRoot, "OEBPS", "Images")
	if err := copyTree(filepath.Join(layout.resources, "Shared", "Images"), imagesTarget); err != nil {
		return nil, fmt.Errorf("gemeinsame Bilder kopieren: %w", err)
	}
	if err := copyTree(filepath.Join(pub.Dir, "Media", "Images"), imagesTarget); err != nil {
		return nil, fmt.Errorf("Bilder kopieren: %w", err)
	}
	// Fonts are shared application resources, just like the EPUB stylesheet.
	// Keeping a single source prevents project copies from drifting away from
	// the font files referenced by the central CSS and OPF manifest.
	if err := copyTree(filepath.Join(layout.resources, "Shared", "Fonts"), filepath.Join(epubRoot, "OEBPS", "Fonts")); err != nil {
		return nil, fmt.Errorf("zentrale Fonts kopieren: %w", err)
	}
	// The EPUB stylesheet is an application resource. The legacy pipeline also
	// copied this central stylesheet; a similarly named project stylesheet is
	// intended for other output variants and lacks EPUB image/font rules.
	cssSource := filepath.Join(layout.resources, "Stylesheets", epubCSSFilename)
	if err := requireFile(cssSource); err != nil {
		return nil, err
	}
	if err := copyFile(cssSource, filepath.Join(epubRoot, "OEBPS", "Styles", epubCSSFilename)); err != nil {
		return nil, fmt.Errorf("CSS kopieren: %w", err)
	}

	tempEPUB := filepath.Join(jobDir, pub.Name+".epub")
	if err := createEPUB(epubRoot, tempEPUB); err != nil {
		return nil, err
	}

	logToolStart(ctx, "EPUBCheck", "Das gepackte EPUB wird validiert.")
	checkResult, checkErr := e.javaRunner(root).Run(ctx, root,
		"-cp", classpath,
		"com.adobe.epubcheck.tool.Checker",
		tempEPUB,
	)
	logToolResult(ctx, "EPUBCheck", checkResult, checkErr)
	if checkErr != nil {
		diagnostics := strings.TrimSpace(checkResult.Stdout + "\n" + checkResult.Stderr)
		return nil, fmt.Errorf("EPUBCheck fehlgeschlagen (Exitcode %d, Dauer %s): %w\n%s",
			checkResult.ExitCode, checkResult.Duration.Round(time.Millisecond), checkErr, diagnostics)
	}

	info, err := os.Stat(tempEPUB)
	if err != nil {
		return nil, fmt.Errorf("EPUB prüfen: %w", err)
	}
	if info.Size() < 1024 {
		return nil, fmt.Errorf("EPUB ist mit %d Bytes unplausibel klein", info.Size())
	}
	targetDir, err := e.outputDir(pub)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return nil, fmt.Errorf("Zielordner anlegen: %w", err)
	}
	target := filepath.Join(targetDir, pub.Name+".epub")
	pending := []pendingArtifact{{format: EPUB, temp: tempEPUB, target: target, size: info.Size()}}
	if err := publishAll(pending); err != nil {
		return nil, err
	}
	return []Artifact{{Format: EPUB, Path: target, Size: info.Size()}}, nil
}

func copyTree(source, target string) error {
	// Links are rejected instead of followed. That guarantees an EPUB can only
	// contain the ordinary files visibly stored below the selected source tree.
	info, err := os.Lstat(source)
	if err != nil {
		return err
	}
	if !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("Quelle ist kein reguläres Verzeichnis: %s", source)
	}
	return filepath.WalkDir(source, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if path == source {
			return nil
		}
		relative, err := filepath.Rel(source, path)
		if err != nil {
			return err
		}
		destination := filepath.Join(target, relative)
		entryInfo, err := entry.Info()
		if err != nil {
			return err
		}
		if entryInfo.Mode()&os.ModeSymlink != 0 {
			return fmt.Errorf("symbolischer Link ist als EPUB-Quelle nicht erlaubt: %s", path)
		}
		if entry.IsDir() {
			return os.MkdirAll(destination, 0o755)
		}
		if !entryInfo.Mode().IsRegular() {
			return fmt.Errorf("Sonderdatei ist als EPUB-Quelle nicht erlaubt: %s", path)
		}
		return copyFile(path, destination)
	})
}

func copyFile(source, target string) (returnErr error) {
	input, err := os.Open(source)
	if err != nil {
		return err
	}
	defer input.Close()
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		return err
	}
	output, err := os.OpenFile(target, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer func() {
		if err := output.Close(); returnErr == nil {
			returnErr = err
		}
	}()
	_, err = io.Copy(output, input)
	return err
}

func createEPUB(root, destination string) (returnErr error) {
	// EPUB is a ZIP file with extra rules: "mimetype" must be first and stored
	// without compression, while all remaining entries are sorted so repeated
	// builds are reproducible.
	mimetypePath := filepath.Join(root, "mimetype")
	content, err := os.ReadFile(mimetypePath)
	if err != nil {
		return fmt.Errorf("EPUB-mimetype fehlt: %w", err)
	}
	if string(content) != epubMimetype {
		return fmt.Errorf("EPUB-mimetype ist ungültig: %q", string(content))
	}

	files := make([]string, 0)
	for _, top := range []string{"META-INF", "OEBPS"} {
		err := filepath.WalkDir(filepath.Join(root, top), func(path string, entry os.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}
			if entry.IsDir() {
				return nil
			}
			info, err := entry.Info()
			if err != nil {
				return err
			}
			if !info.Mode().IsRegular() {
				return fmt.Errorf("ungültiger EPUB-Eintrag: %s", path)
			}
			files = append(files, path)
			return nil
		})
		if err != nil {
			return err
		}
	}
	sort.Slice(files, func(i, j int) bool {
		left, _ := filepath.Rel(root, files[i])
		right, _ := filepath.Rel(root, files[j])
		return filepath.ToSlash(left) < filepath.ToSlash(right)
	})

	output, err := os.Create(destination)
	if err != nil {
		return fmt.Errorf("EPUB-Datei anlegen: %w", err)
	}
	defer func() {
		if err := output.Close(); returnErr == nil {
			returnErr = err
		}
		if returnErr != nil {
			_ = os.Remove(destination)
		}
	}()
	archive := zip.NewWriter(output)
	defer func() {
		if err := archive.Close(); returnErr == nil {
			returnErr = err
		}
	}()

	// EPUB forbids every ZIP extra field on this entry. In particular,
	// SetModTime would add an extended timestamp extra field.
	mimetypeHeader := &zip.FileHeader{Name: "mimetype", Method: zip.Store}
	mimetypeHeader.SetMode(0o644)
	writer, err := archive.CreateHeader(mimetypeHeader)
	if err != nil {
		return err
	}
	if _, err := io.WriteString(writer, epubMimetype); err != nil {
		return err
	}
	for _, path := range files {
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		header := &zip.FileHeader{Name: filepath.ToSlash(relative), Method: zip.Deflate}
		header.SetModTime(zipTimestamp)
		header.SetMode(0o644)
		entryWriter, err := archive.CreateHeader(header)
		if err != nil {
			return err
		}
		input, err := os.Open(path)
		if err != nil {
			return err
		}
		_, copyErr := io.Copy(entryWriter, input)
		closeErr := input.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
	}
	return nil
}
