// Command oa is the command-line entry point for the OA publishing system.
package main

import (
	"bufio"
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

	"golang.org/x/term"

	"oa-satzsystem/internal/build"
	"oa-satzsystem/internal/gui"
	"oa-satzsystem/internal/project"
)

// version is intentionally a variable so release builds can override it with
// -ldflags "-X main.version=v0.1.0".
var version = "0.1.0-dev"

// defaultCommand is set only for the separately packaged GUI launcher. The
// regular oa binary keeps its command-line behavior, while the launcher can
// start the same application code without requiring users to type `oa gui`.
var defaultCommand string

const (
	exitOK         = 0
	exitFailure    = 1
	exitUsage      = 2
	exitValidation = 3
)

func main() {
	os.Exit(run(startupArgs(os.Args[1:]), os.Stdout, os.Stderr))
}

func startupArgs(args []string) []string {
	if defaultCommand == "" {
		return args
	}
	return append([]string{defaultCommand}, args...)
}

// run is the application's traffic controller. It reads the first word after
// "oa", sends the remaining words to the matching command, and returns a
// stable exit code that scripts can understand.
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
	case "serve":
		return runServe(args[1:], stdout, stderr)
	case "admin":
		return runAdmin(args[1:], stdout, stderr)
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
	fmt.Fprintln(w, "  serve --data-dir ORDNER [--listen ADRESSE]  Persistenten Server starten")
	fmt.Fprintln(w, "  admin init --data-dir ORDNER --username NAME  Initialen Administrator anlegen")
	fmt.Fprintln(w)
	fmt.Fprintln(w, "Formate: print-pdf, web-pdf, epub")
}

func runAdmin(args []string, stdout, stderr io.Writer) int {
	dataDir, username, err := parseAdminInitArgs(args)
	if err != nil {
		fmt.Fprintf(stderr, "Ungültiger Aufruf: %v\n", err)
		fmt.Fprintln(stderr, "Verwendung: oa admin init --data-dir ORDNER --username NAME")
		return exitUsage
	}
	password, err := promptNewPassword(stderr)
	if err != nil {
		fmt.Fprintf(stderr, "Passwort konnte nicht gelesen werden: %v\n", err)
		return exitFailure
	}
	if err := gui.CreateInitialAdmin(dataDir, username, password); err != nil {
		fmt.Fprintf(stderr, "Administrator konnte nicht angelegt werden: %v\n", err)
		return exitFailure
	}
	fmt.Fprintf(stdout, "Initialer Administrator %q wurde angelegt.\n", username)
	return exitOK
}

// parseAdminInitArgs separates command-line options from their values without
// starting the server or changing any data. Keeping parsing separate makes bad
// invocations easy to test safely.
func parseAdminInitArgs(args []string) (dataDir, username string, err error) {
	if len(args) == 0 || args[0] != "init" {
		return "", "", fmt.Errorf("Unterbefehl init fehlt")
	}
	for i := 1; i < len(args); i++ {
		key, value := args[i], ""
		if strings.Contains(key, "=") {
			parts := strings.SplitN(key, "=", 2)
			key, value = parts[0], parts[1]
		} else if key == "--data-dir" || key == "--username" {
			if i+1 >= len(args) {
				return "", "", fmt.Errorf("Wert nach %s fehlt", key)
			}
			i++
			value = args[i]
		}
		switch key {
		case "--data-dir":
			absolute, pathErr := filepath.Abs(value)
			if pathErr != nil {
				return "", "", pathErr
			}
			dataDir = filepath.Clean(absolute)
		case "--username":
			username = strings.TrimSpace(value)
		default:
			return "", "", fmt.Errorf("unbekannte Option %q", key)
		}
	}
	if dataDir == "" || username == "" {
		return "", "", fmt.Errorf("--data-dir und --username sind erforderlich")
	}
	return dataDir, username, nil
}

func promptNewPassword(stderr io.Writer) (string, error) {
	fmt.Fprint(stderr, "Passwort (mindestens 12 Zeichen): ")
	if term.IsTerminal(int(os.Stdin.Fd())) {
		first, err := term.ReadPassword(int(os.Stdin.Fd()))
		fmt.Fprintln(stderr)
		if err != nil {
			return "", err
		}
		fmt.Fprint(stderr, "Passwort wiederholen: ")
		second, err := term.ReadPassword(int(os.Stdin.Fd()))
		fmt.Fprintln(stderr)
		if err != nil {
			return "", err
		}
		if string(first) != string(second) {
			return "", fmt.Errorf("Passwörter stimmen nicht überein")
		}
		return string(first), nil
	}
	scanner := bufio.NewScanner(os.Stdin)
	if !scanner.Scan() {
		return "", fmt.Errorf("Passwort fehlt")
	}
	return scanner.Text(), scanner.Err()
}

// runServe starts the persistent, login-protected multi-user mode and keeps it
// alive until the operating system asks the program to stop.
func runServe(args []string, stdout, stderr io.Writer) int {
	dataDir, address, err := parseServeArgs(args)
	if err != nil {
		fmt.Fprintf(stderr, "Ungültiger Aufruf: %v\n", err)
		fmt.Fprintln(stderr, "Verwendung: oa serve --data-dir ORDNER [--listen 127.0.0.1:8080]")
		return exitUsage
	}
	root, err := findApplicationRoot()
	if err != nil {
		fmt.Fprintf(stderr, "Anwendungsressourcen nicht gefunden: %v\n", err)
		return exitFailure
	}
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	if err := gui.RunServer(ctx, root, dataDir, address, stdout); err != nil {
		fmt.Fprintf(stderr, "Server fehlgeschlagen: %v\n", err)
		return exitFailure
	}
	return exitOK
}

func parseServeArgs(args []string) (dataDir, address string, err error) {
	address = "127.0.0.1:8080"
	for i := 0; i < len(args); i++ {
		key, value := args[i], ""
		if strings.Contains(key, "=") {
			parts := strings.SplitN(key, "=", 2)
			key, value = parts[0], parts[1]
		} else if key == "--data-dir" || key == "--listen" {
			if i+1 >= len(args) {
				return "", "", fmt.Errorf("Wert nach %s fehlt", key)
			}
			i++
			value = args[i]
		}
		switch key {
		case "--data-dir":
			if dataDir != "" {
				return "", "", fmt.Errorf("--data-dir darf nur einmal angegeben werden")
			}
			if strings.TrimSpace(value) == "" {
				return "", "", fmt.Errorf("Datenverzeichnis fehlt")
			}
			absolute, pathErr := filepath.Abs(value)
			if pathErr != nil {
				return "", "", fmt.Errorf("Datenverzeichnis auflösen: %w", pathErr)
			}
			dataDir = filepath.Clean(absolute)
		case "--listen":
			if strings.TrimSpace(value) == "" {
				return "", "", fmt.Errorf("Serveradresse fehlt")
			}
			address = value
		default:
			return "", "", fmt.Errorf("unbekannte Option %q", key)
		}
	}
	if dataDir == "" {
		return "", "", fmt.Errorf("--data-dir ist erforderlich")
	}
	return dataDir, address, nil
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

// parseBuildArgs accepts options before or after the project path and rejects
// ambiguous input before an expensive Java build can begin.
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
	// Development files live in the repository; release files live next to the
	// executable. Walking upward supports starting oa from a subdirectory too.
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
