// Package build contains the shared publication build pipeline.
package build

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	"oa-satzsystem/internal/java"
	"oa-satzsystem/internal/project"
)

// Format identifies one supported PDF output.
type Format string

const (
	PrintPDF Format = "print-pdf"
	WebPDF   Format = "web-pdf"
	EPUB     Format = "epub"
)

// Artifact describes a successfully published build result.
type Artifact struct {
	Format Format
	Path   string
	Size   int64
}

// Engine runs PDF builds using the staged FOP libraries.
type Engine struct {
	Root       string
	Java       java.Runner
	TempParent string
	OutputDir  string
}

type pendingArtifact struct {
	format Format
	temp   string
	target string
	size   int64
}

// BuildPDFs builds and validates every requested format before publishing any.
func (e Engine) BuildPDFs(ctx context.Context, projectPath string, formats []Format) ([]Artifact, error) {
	pub, err := project.Open(projectPath)
	if err != nil {
		return nil, err
	}
	root, err := filepath.Abs(e.Root)
	if err != nil {
		return nil, fmt.Errorf("Anwendungswurzel auflösen: %w", err)
	}
	if len(formats) == 0 {
		return nil, fmt.Errorf("mindestens ein PDF-Format ist erforderlich")
	}
	if err := validateFormats(formats); err != nil {
		return nil, err
	}

	jobDir, err := os.MkdirTemp(e.TempParent, "oa-pdf-*")
	if err != nil {
		return nil, fmt.Errorf("Arbeitsverzeichnis anlegen: %w", err)
	}
	defer os.RemoveAll(jobDir)
	buildXML := filepath.Join(jobDir, pub.Name+".xml")
	if err := prepareXML(pub.XML, buildXML); err != nil {
		return nil, err
	}

	layout := resolveLayout(root)
	classpath := filepath.Join(layout.lib, "*")
	stylesheet := filepath.Join(layout.resources, "Stylesheets", "XMLtoPDF_FOP.xsl")
	if err := requireFile(stylesheet); err != nil {
		return nil, err
	}
	outputDir, err := e.outputDir(pub)
	if err != nil {
		return nil, err
	}
	projectURI := fileURI(pub.Dir)
	sharedImagesDir := filepath.Join(layout.resources, "Shared", "Images")
	sharedImagesURI := fileURI(sharedImagesDir)

	pending := make([]pendingArtifact, 0, len(formats))
	seen := make(map[Format]bool)
	for _, format := range formats {
		if seen[format] {
			continue
		}
		seen[format] = true
		suffix, configName := formatSettings(format)
		config := filepath.Join(layout.resources, "Stylesheets", configName)
		if err := requireFile(config); err != nil {
			return nil, err
		}
		tempPDF := filepath.Join(jobDir, pub.Name+"-"+suffix+".pdf")
		args := []string{
			"-cp", classpath,
			"org.apache.fop.cli.Main",
			"-d",
			"-c", config,
			"-xml", buildXML,
			"-xsl", stylesheet,
			"-pdf", tempPDF,
			"-param", "Projektname", pub.Name,
			"-param", "Projektpfad", projectURI,
			"-param", "SharedImagesPfad", sharedImagesURI,
		}
		logToolStart(ctx, "FOP", fmt.Sprintf("%s wird erzeugt.", format))
		result, runErr := e.javaRunner(root).RunWithOutput(ctx, root, logToolOutput(ctx, "FOP"), args...)
		logToolResult(ctx, "FOP", result, runErr)
		if runErr != nil {
			diagnostics := strings.TrimSpace(result.Stdout + "\n" + result.Stderr)
			return nil, fmt.Errorf("FOP für %s fehlgeschlagen (Exitcode %d, Dauer %s): %w\n%s",
				format, result.ExitCode, result.Duration.Round(1e6), runErr, diagnostics)
		}
		size, err := validatePDF(tempPDF)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", format, err)
		}
		target := filepath.Join(outputDir, pub.Name+"-"+suffix+".pdf")
		pending = append(pending, pendingArtifact{format: format, temp: tempPDF, target: target, size: size})
	}

	if err := os.MkdirAll(outputDir, 0o755); err != nil {
		return nil, fmt.Errorf("Zielordner anlegen: %w", err)
	}
	if err := publishAll(pending); err != nil {
		return nil, err
	}
	artifacts := make([]Artifact, len(pending))
	for i, item := range pending {
		artifacts[i] = Artifact{Format: item.format, Path: item.target, Size: item.size}
	}
	return artifacts, nil
}

func fileURI(path string) string {
	uriPath := filepath.ToSlash(path)
	if filepath.VolumeName(path) != "" {
		uriPath = "/" + uriPath
	}
	return (&url.URL{Scheme: "file", Path: uriPath}).String()
}

func (e Engine) outputDir(pub project.Project) (string, error) {
	if strings.TrimSpace(e.OutputDir) == "" {
		return project.Within(pub.Dir, "Outputs")
	}
	outputDir, err := filepath.Abs(e.OutputDir)
	if err != nil {
		return "", fmt.Errorf("Ausgabeverzeichnis auflösen: %w", err)
	}
	return filepath.Clean(outputDir), nil
}

// Build creates all selected output formats as one transaction. The individual
// builders first write into a private staging directory. Only after every
// requested file has passed its checks are all results copied to Outputs. This
// matters to users because a failed EPUB build must not leave newly replaced
// PDFs behind and make a partly updated publication look successful.
func (e Engine) Build(ctx context.Context, projectPath string, formats []Format) ([]Artifact, error) {
	if len(formats) == 0 {
		return nil, fmt.Errorf("mindestens ein Format ist erforderlich")
	}
	seen := make(map[Format]bool)
	pdfFormats := make([]Format, 0, 2)
	wantEPUB := false
	for _, format := range formats {
		if seen[format] {
			continue
		}
		seen[format] = true
		switch format {
		case PrintPDF, WebPDF:
			pdfFormats = append(pdfFormats, format)
		case EPUB:
			wantEPUB = true
		default:
			return nil, fmt.Errorf("nicht unterstütztes Format: %s", format)
		}
	}
	pub, err := project.Open(projectPath)
	if err != nil {
		return nil, err
	}
	finalOutputDir, err := e.outputDir(pub)
	if err != nil {
		return nil, err
	}

	// BuildPDFs and BuildEPUB can also be called on their own, so each of them
	// publishes its result. Pointing a copy of the engine at this temporary
	// directory turns those publications into harmless staging operations.
	stagingDir, err := os.MkdirTemp(e.TempParent, "oa-publication-*")
	if err != nil {
		return nil, fmt.Errorf("Arbeitsverzeichnis für Gesamtausgabe anlegen: %w", err)
	}
	defer os.RemoveAll(stagingDir)
	stagedEngine := e
	stagedEngine.OutputDir = stagingDir

	byFormat := make(map[Format]Artifact, len(seen))
	if len(pdfFormats) > 0 {
		artifacts, err := stagedEngine.BuildPDFs(ctx, projectPath, pdfFormats)
		if err != nil {
			return nil, err
		}
		for _, artifact := range artifacts {
			byFormat[artifact.Format] = artifact
		}
	}
	if wantEPUB {
		artifacts, err := stagedEngine.BuildEPUB(ctx, projectPath)
		if err != nil {
			return nil, err
		}
		for _, artifact := range artifacts {
			byFormat[artifact.Format] = artifact
		}
	}
	pending := make([]pendingArtifact, 0, len(byFormat))
	result := make([]Artifact, 0, len(byFormat))
	for _, format := range formats {
		if artifact, ok := byFormat[format]; ok {
			target := filepath.Join(finalOutputDir, filepath.Base(artifact.Path))
			pending = append(pending, pendingArtifact{format: format, temp: artifact.Path, target: target, size: artifact.Size})
			result = append(result, Artifact{Format: format, Path: target, Size: artifact.Size})
			delete(byFormat, format)
		}
	}
	if err := os.MkdirAll(finalOutputDir, 0o755); err != nil {
		return nil, fmt.Errorf("Zielordner anlegen: %w", err)
	}
	if err := publishAll(pending); err != nil {
		return nil, err
	}
	return result, nil
}

func validateFormats(formats []Format) error {
	for _, format := range formats {
		if format != PrintPDF && format != WebPDF {
			return fmt.Errorf("nicht unterstütztes Format: %s", format)
		}
	}
	return nil
}

func formatSettings(format Format) (suffix, config string) {
	if format == PrintPDF {
		return "print", "fop-print.xconf"
	}
	return "web", "fop-web.xconf"
}

func requireFile(path string) error {
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("benötigte Ressource fehlt (%s): %w", path, err)
	}
	if !info.Mode().IsRegular() {
		return fmt.Errorf("benötigte Ressource ist keine Datei: %s", path)
	}
	return nil
}

func validatePDF(path string) (int64, error) {
	file, err := os.Open(path)
	if err != nil {
		return 0, fmt.Errorf("PDF wurde nicht erzeugt: %w", err)
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return 0, fmt.Errorf("PDF prüfen: %w", err)
	}
	if info.Size() < 1024 {
		return 0, fmt.Errorf("PDF ist mit %d Bytes unplausibel klein", info.Size())
	}
	header := make([]byte, 5)
	if _, err := io.ReadFull(bufio.NewReader(file), header); err != nil || string(header) != "%PDF-" {
		return 0, fmt.Errorf("Ausgabe besitzt keinen gültigen PDF-Header")
	}
	return info.Size(), nil
}

// publishAll preserves existing outputs if any publication operation fails.
func publishAll(items []pendingArtifact) error {
	// Stage validated files beside their final targets first. This also makes
	// publication work when the job directory is on another filesystem.
	staged := make([]string, len(items))
	for i, item := range items {
		var err error
		staged[i], err = stageFile(item.temp, item.target)
		if err != nil {
			for _, path := range staged {
				if path != "" {
					_ = os.Remove(path)
				}
			}
			return fmt.Errorf("geprüfte Ausgabe bereitstellen: %w", err)
		}
	}
	defer func() {
		for _, path := range staged {
			_ = os.Remove(path)
		}
	}()

	type move struct{ target, backup string }
	moves := make([]move, 0, len(items))
	rollback := func() {
		for i := len(moves) - 1; i >= 0; i-- {
			_ = os.Remove(moves[i].target)
			if moves[i].backup != "" {
				_ = os.Rename(moves[i].backup, moves[i].target)
			}
		}
	}
	for i, item := range items {
		backup := ""
		// An output name may only replace a normal file. Refusing directories,
		// links and special files prevents an unexpected filesystem object from
		// being moved aside or followed during publication.
		targetInfo, err := os.Lstat(item.target)
		if err == nil {
			if !targetInfo.Mode().IsRegular() {
				rollback()
				return fmt.Errorf("Ausgabeziel ist keine reguläre Datei: %s", item.target)
			}
			reservation, reserveErr := os.CreateTemp(filepath.Dir(item.target), "."+filepath.Base(item.target)+".oa-backup-*")
			if reserveErr != nil {
				rollback()
				return fmt.Errorf("Sicherungspfad anlegen: %w", reserveErr)
			}
			backup = reservation.Name()
			if closeErr := reservation.Close(); closeErr != nil {
				_ = os.Remove(backup)
				rollback()
				return fmt.Errorf("Sicherungspfad schließen: %w", closeErr)
			}
			if removeErr := os.Remove(backup); removeErr != nil {
				rollback()
				return fmt.Errorf("Sicherungspfad vorbereiten: %w", removeErr)
			}
			if err := os.Rename(item.target, backup); err != nil {
				rollback()
				return fmt.Errorf("vorhandene Ausgabe sichern: %w", err)
			}
		} else if !os.IsNotExist(err) {
			rollback()
			return fmt.Errorf("Ausgabe prüfen: %w", err)
		}
		moves = append(moves, move{target: item.target, backup: backup})
		if err := os.Rename(staged[i], item.target); err != nil {
			rollback()
			return fmt.Errorf("geprüfte Ausgabe veröffentlichen: %w", err)
		}
	}
	for _, moved := range moves {
		if moved.backup != "" {
			_ = os.Remove(moved.backup)
		}
	}
	return nil
}

func stageFile(source, target string) (path string, returnErr error) {
	input, err := os.Open(source)
	if err != nil {
		return "", err
	}
	defer input.Close()
	output, err := os.CreateTemp(filepath.Dir(target), "."+filepath.Base(target)+".oa-new-*")
	if err != nil {
		return "", err
	}
	path = output.Name()
	defer func() {
		if err := output.Close(); returnErr == nil {
			returnErr = err
		}
		if returnErr != nil {
			_ = os.Remove(path)
		}
	}()
	if _, err := io.Copy(output, input); err != nil {
		return path, err
	}
	if err := output.Sync(); err != nil {
		return path, err
	}
	return path, nil
}
