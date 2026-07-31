// Command oa is the command-line entry point for the OA publishing system.
package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"syscall"
	"time"

	"oa-satzsystem/internal/build"
	"oa-satzsystem/internal/gui"
	"oa-satzsystem/internal/project"
)

// version is intentionally a variable so release builds can override it with
// -ldflags "-X main.version=v0.1.0".
var version = "0.1.0-dev"

const (
	exitOK         = 0
	exitFailure    = 1
	exitUsage      = 2
	exitValidation = 3
)

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		printUsage(stderr)
		return exitUsage
	}

	switch args[0] {
	case "version":
		if len(args) != 1 {
			printUsage(stderr)
			return exitUsage
		}
		fmt.Fprintf(stdout, "oa %s\n", version)
		return exitOK
	case "doctor":
		if len(args) != 1 {
			printUsage(stderr)
			return exitUsage
		}
		return runDoctor(stdout, stderr)
	case "build":
		return runBuild(args[1:], stdout, stderr)
	case "validate":
		return runValidate(args[1:], stdout, stderr)
	case "gui":
		return runGUI(args[1:], stdout, stderr)
	case "-h", "--help", "help":
		printUsage(stdout)
		return exitOK
	default:
		fmt.Fprintf(stderr, "Unbekannter Befehl: %s\n\n", args[0])
		printUsage(stderr)
		return exitUsage
	}
}

func printUsage(w io.Writer) {
	fmt.Fprintln(w, "Verwendung: oa <Befehl> [Optionen]")
	fmt.Fprintln(w)
	fmt.Fprintln(w, "Befehle:")
	fmt.Fprintln(w, "  version  Anwendungsversion anzeigen")
	fmt.Fprintln(w, "  doctor   System und gefundene Ressourcen anzeigen")
	fmt.Fprintln(w, "  validate <Projekt>")
	fmt.Fprintln(w, "  build <Projekt> --format FORMAT [--format FORMAT ...] [--output ORDNER]")
	fmt.Fprintln(w, "  gui [--workspace ORDNER]  Lokale Browser-GUI starten")
	fmt.Fprintln(w)
	fmt.Fprintln(w, "Formate: print-pdf, web-pdf, epub")
}

func runGUI(args []string, stdout, stderr io.Writer) int {
	workspace, persistent, err := parseGUIArgs(args)
	if err != nil {
		fmt.Fprintf(stderr, "Ungültiger Aufruf: %v\n", err)
		fmt.Fprintln(stderr, "Verwendung: oa gui [--workspace ORDNER]")
		return exitUsage
	}
	root, err := findApplicationRoot()
	if err != nil {
		fmt.Fprintf(stderr, "Anwendungsressourcen nicht gefunden: %v\n", err)
		return exitFailure
	}
	if !persistent {
		workspace, err = os.MkdirTemp("", "oa-gui-workspace-*")
		if err != nil {
			fmt.Fprintf(stderr, "Temporären GUI-Workspace anlegen: %v\n", err)
			return exitFailure
		}
		defer os.RemoveAll(workspace)
	}
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	if err := gui.Run(ctx, root, workspace, stdout); err != nil {
		fmt.Fprintf(stderr, "GUI fehlgeschlagen: %v\n", err)
		return exitFailure
	}
	return exitOK
}

func parseGUIArgs(args []string) (workspace string, persistent bool, err error) {
	if len(args) == 0 {
		return "", false, nil
	}
	if len(args) == 2 && args[0] == "--workspace" && strings.TrimSpace(args[1]) != "" {
		absolute, err := filepath.Abs(args[1])
		if err != nil {
			return "", false, fmt.Errorf("Workspace-Pfad auflösen: %w", err)
		}
		return filepath.Clean(absolute), true, nil
	}
	if len(args) == 1 && strings.HasPrefix(args[0], "--workspace=") {
		value := strings.TrimSpace(strings.TrimPrefix(args[0], "--workspace="))
		if value == "" {
			return "", false, fmt.Errorf("Workspace-Pfad fehlt")
		}
		absolute, err := filepath.Abs(value)
		if err != nil {
			return "", false, fmt.Errorf("Workspace-Pfad auflösen: %w", err)
		}
		return filepath.Clean(absolute), true, nil
	}
	return "", false, fmt.Errorf("unbekannte Optionen")
}

func runBuild(args []string, stdout, stderr io.Writer) int {
	projectPath, formats, outputDir, err := parseBuildArgs(args)
	if err != nil {
		fmt.Fprintf(stderr, "Ungültiger Aufruf: %v\n", err)
		fmt.Fprintln(stderr, "Hilfe: oa build <Projekt> --format print-pdf --format web-pdf --format epub [--output ORDNER]")
		return exitUsage
	}
	if _, err := project.Open(projectPath); err != nil {
		fmt.Fprintf(stderr, "Projekt ungültig: %v\n", err)
		return exitValidation
	}
	root, err := findApplicationRoot()
	if err != nil {
		fmt.Fprintf(stderr, "Anwendungsressourcen nicht gefunden: %v\n", err)
		return exitFailure
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	engine := build.Engine{Root: root, OutputDir: outputDir}
	artifacts, err := engine.Build(ctx, projectPath, formats)
	if err != nil {
		fmt.Fprintf(stderr, "Build fehlgeschlagen: %v\n", err)
		return exitFailure
	}
	for _, artifact := range artifacts {
		fmt.Fprintf(stdout, "%s: %s (%d Bytes)\n", artifact.Format, artifact.Path, artifact.Size)
	}
	return exitOK
}

func parseBuildArgs(args []string) (string, []build.Format, string, error) {
	var projectPath, outputDir string
	outputSet := false
	formats := make([]build.Format, 0, 3)
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "--format":
			if i+1 >= len(args) {
				return "", nil, "", fmt.Errorf("Wert nach --format fehlt")
			}
			i++
			formats = append(formats, build.Format(args[i]))
		case strings.HasPrefix(arg, "--format="):
			formats = append(formats, build.Format(strings.TrimPrefix(arg, "--format=")))
		case arg == "--output":
			if i+1 >= len(args) {
				return "", nil, "", fmt.Errorf("Wert nach --output fehlt")
			}
			if outputSet {
				return "", nil, "", fmt.Errorf("--output darf nur einmal angegeben werden")
			}
			i++
			outputDir = args[i]
			outputSet = true
		case strings.HasPrefix(arg, "--output="):
			if outputSet {
				return "", nil, "", fmt.Errorf("--output darf nur einmal angegeben werden")
			}
			outputDir = strings.TrimPrefix(arg, "--output=")
			outputSet = true
		case strings.HasPrefix(arg, "-"):
			return "", nil, "", fmt.Errorf("unbekannte Option %q", arg)
		default:
			if projectPath != "" {
				return "", nil, "", fmt.Errorf("mehr als ein Projektpfad angegeben")
			}
			projectPath = arg
		}
	}
	if strings.TrimSpace(projectPath) == "" {
		return "", nil, "", fmt.Errorf("Projektpfad fehlt")
	}
	if len(formats) == 0 {
		return "", nil, "", fmt.Errorf("mindestens ein --format ist erforderlich")
	}
	for _, format := range formats {
		if format != build.PrintPDF && format != build.WebPDF && format != build.EPUB {
			return "", nil, "", fmt.Errorf("unbekanntes Format %q", format)
		}
	}
	if outputSet && strings.TrimSpace(outputDir) == "" {
		return "", nil, "", fmt.Errorf("Ausgabeverzeichnis fehlt")
	}
	return projectPath, formats, outputDir, nil
}

func runValidate(args []string, stdout, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "Verwendung: oa validate <Projekt>")
		return exitUsage
	}
	pub, err := project.Open(args[0])
	if err != nil {
		fmt.Fprintf(stderr, "Projekt ungültig: %v\n", err)
		return exitValidation
	}
	fmt.Fprintf(stdout, "Projekt gültig: %s\nXML: %s\n", pub.Dir, pub.XML)
	return exitOK
}

func findApplicationRoot() (string, error) {
	var candidates []string
	if executable, err := os.Executable(); err == nil {
		candidates = append(candidates, filepath.Dir(executable))
	}
	if cwd, err := os.Getwd(); err == nil {
		candidates = append(candidates, cwd)
	}
	for _, candidate := range candidates {
		absolute, err := filepath.Abs(candidate)
		if err != nil {
			continue
		}
		for {
			developmentStylesheet := filepath.Join(absolute, "Stylesheets", "XMLtoPDF_FOP.xsl")
			developmentLibraries := filepath.Join(absolute, "java-toolchain", "build", "stage", "lib")
			packagedStylesheet := filepath.Join(absolute, "resources", "Stylesheets", "XMLtoPDF_FOP.xsl")
			packagedLibraries := filepath.Join(absolute, "lib")
			if (regularFile(developmentStylesheet) && directory(developmentLibraries)) ||
				(regularFile(packagedStylesheet) && directory(packagedLibraries)) {
				return absolute, nil
			}
			parent := filepath.Dir(absolute)
			if parent == absolute {
				break
			}
			absolute = parent
		}
	}
	return "", fmt.Errorf("Stylesheets und Java-Bibliotheken fehlen")
}

func regularFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}

func directory(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func runDoctor(stdout, stderr io.Writer) int {
	resourceDir, resources, err := findResources()
	if err != nil {
		fmt.Fprintf(stderr, "Ressourcen konnten nicht untersucht werden: %v\n", err)
		return 1
	}

	fmt.Fprintln(stdout, "OA-Systemdiagnose")
	fmt.Fprintf(stdout, "Betriebssystem: %s\n", runtime.GOOS)
	fmt.Fprintf(stdout, "Architektur:    %s\n", runtime.GOARCH)
	fmt.Fprintf(stdout, "Version:        %s\n", version)
	fmt.Fprintf(stdout, "Ressourcen:     %s\n", resourceDir)
	if len(resources) == 0 {
		fmt.Fprintln(stdout, "  (keine Ressourcen gefunden)")
		return 0
	}
	for _, resource := range resources {
		fmt.Fprintf(stdout, "  - %s\n", filepath.ToSlash(resource))
	}
	return 0
}

func findResources() (string, []string, error) {
	candidates := make([]string, 0, 2)
	if executable, err := os.Executable(); err == nil {
		candidates = append(candidates, filepath.Join(filepath.Dir(executable), "resources"))
	}
	if cwd, err := os.Getwd(); err == nil {
		candidates = append(candidates, filepath.Join(cwd, "resources"))
	}

	for _, candidate := range candidates {
		info, err := os.Stat(candidate)
		if err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return "", nil, err
		}
		if !info.IsDir() {
			continue
		}

		entries, err := os.ReadDir(candidate)
		if err != nil {
			return "", nil, err
		}
		names := make([]string, 0, len(entries))
		for _, entry := range entries {
			if entry.Name() == ".gitkeep" {
				continue
			}
			names = append(names, entry.Name())
		}
		sort.Strings(names)

		absolute, err := filepath.Abs(candidate)
		if err != nil {
			return "", nil, err
		}
		return absolute, names, nil
	}

	return "nicht gefunden", nil, nil
}
