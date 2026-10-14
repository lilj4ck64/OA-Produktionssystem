package build

import (
	"bytes"
	"context"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"oa-satzsystem/internal/project"
)

const (
	bitsDTDRelativePath    = "Schema/BITS-2-2-DTD/BITS-book2-2.dtd"
	schematronRelativePath = "Schema/schematron.sch"
	schXsltMainClass       = "name.dmaus.schxslt.cli.Application"
)

// ValidateProject performs the validation shared by the CLI and the GUI
// import: first the expected project layout, then the XML against each
// validation schema that is available in the application installation.
func (e Engine) ValidateProject(ctx context.Context, path string) (project.Project, error) {
	pub, err := project.Open(path)
	if err != nil {
		return project.Project{}, fmt.Errorf("Projektstruktur ungültig: %w", err)
	}
	if err := e.ValidateXML(ctx, pub.XML); err != nil {
		return project.Project{}, err
	}
	return pub, nil
}

// ValidateXML validates one XML document against the application's fixed BITS
// DTD and Schematron schema when they are installed. Missing schemas are
// optional: the corresponding check is logged and skipped. A DOCTYPE from the
// input is removed from a temporary copy so it cannot select or load a
// different grammar.
func (e Engine) ValidateXML(ctx context.Context, source string) error {
	root, err := filepath.Abs(e.Root)
	if err != nil {
		return fmt.Errorf("Anwendungswurzel auflösen: %w", err)
	}
	layout := resolveLayout(root)
	dtd := filepath.Join(layout.resources, filepath.FromSlash(bitsDTDRelativePath))
	dtdAvailable, err := validationSchemaAvailable(dtd, "DTD")
	if err != nil {
		return err
	}
	schematron := filepath.Join(layout.resources, filepath.FromSlash(schematronRelativePath))
	schematronAvailable, err := validationSchemaAvailable(schematron, "Schematron-Schema")
	if err != nil {
		return err
	}
	if !dtdAvailable {
		Log(ctx, "DTD-Validierung: übersprungen, da die BITS-2.2-DTD nicht installiert ist.")
	}
	if !schematronAvailable {
		Log(ctx, "Schematron-Validierung: übersprungen, da das Schematron-Schema nicht installiert ist.")
	}
	if !dtdAvailable && !schematronAvailable {
		return nil
	}
	jobDir, err := os.MkdirTemp(e.TempParent, "oa-validate-*")
	if err != nil {
		return fmt.Errorf("Arbeitsverzeichnis für XML-Validierung anlegen: %w", err)
	}
	defer os.RemoveAll(jobDir)

	validationXML := filepath.Join(jobDir, filepath.Base(source))
	if dtdAvailable {
		if err := writeXMLWithFixedDTD(source, validationXML, fileURI(dtd)); err != nil {
			return fmt.Errorf("XML für DTD-Validierung vorbereiten: %w", err)
		}
	} else if err := writeXMLWithoutDOCTYPE(source, validationXML); err != nil {
		return fmt.Errorf("XML für Schematron-Validierung vorbereiten: %w", err)
	}

	if dtdAvailable {
		logToolStart(ctx, "DTD-Validierung", "XML wird gegen die feste BITS-2.2-DTD geprüft.")
		classpath, err := sharedJavaClasspath(layout.lib)
		if err != nil {
			return fmt.Errorf("DTD-Validierung konnte nicht vorbereitet werden: Java-Bibliotheken fehlen oder sind nicht lesbar")
		}
		result, runErr := e.javaRunner(root).RunWithOutput(ctx, root, nil,
			"-cp", classpath,
			toolAdapterMainClass,
			"dtd", dtd, validationXML,
		)
		logToolResult(ctx, "DTD-Validierung", result, runErr)
		if runErr != nil {
			return apiToolFailure("DTD", result, runErr,
				apiPathRedaction{path: validationXML, replacement: filepath.Base(source)},
				apiPathRedaction{path: jobDir, replacement: "<temporär>"},
				apiPathRedaction{path: dtd, replacement: filepath.Base(dtd)},
				apiPathRedaction{path: layout.resources, replacement: "<Anwendung>"},
			)
		}
	}

	if !schematronAvailable {
		return nil
	}
	cli, err := findSchXsltCLI(layout.lib)
	if err != nil {
		return fmt.Errorf("Schematron-Validierung konnte nicht vorbereitet werden: SchXslt-Bibliothek fehlt oder ist nicht lesbar")
	}

	logToolStart(ctx, "Schematron-Validierung", "XML wird gegen Schema/schematron.sch geprüft.")
	toolOutput := logToolOutput(ctx, "Schematron-Validierung")
	safeToolOutput := func(line string) {
		if safeLine := sanitizeValidationOutput(line, validationXML, source); safeLine != "" {
			toolOutput(safeLine)
		}
	}
	result, runErr := e.javaRunner(root).RunWithOutput(ctx, root, safeToolOutput,
		"-Djdk.xml.totalEntitySizeLimit=10000000",
		"-Djdk.xml.entityExpansionLimit=100000",
		"-cp", cli,
		schXsltMainClass,
		"-s", schematron,
		"-d", validationXML,
		"-v",
		"-e", "3",
	)
	logToolResult(ctx, "Schematron-Validierung", result, runErr)
	diagnostics := sanitizeValidationOutput(
		strings.TrimSpace(result.Stdout+"\n"+result.Stderr),
		validationXML,
		source,
	)
	if runErr != nil {
		if diagnostics == "" {
			return fmt.Errorf("XML ist nicht Schematron-valide: Schematron-Validierung konnte nicht ausgeführt werden: %w", runErr)
		}
		return fmt.Errorf("XML ist nicht Schematron-valide: %w\n%s", runErr, diagnostics)
	}
	return nil
}

// sanitizeValidationOutput replaces every spelling SchXslt/Saxon may use for
// the temporary validation document. This happens before live output reaches
// the logger and again before diagnostics are returned to callers, so neither
// the GUI nor persisted logs disclose the server's temporary directory.
func sanitizeValidationOutput(output, validationXML, source string) string {
	publicName := portableBase(source)
	output = replacePrivatePath(output, validationXML, publicName)
	// Also redact a diagnostic that mentions only the working directory rather
	// than the complete document path.
	output = replacePrivatePath(output, portableDir(validationXML), "<temporär>")

	// SchXslt emits a document-only header before the actual failed assertions.
	// Once the private path has been removed this line carries no information,
	// so omit it while retaining every concrete rule violation below it.
	lines := strings.Split(output, "\n")
	filtered := lines[:0]
	for _, line := range lines {
		if strings.TrimSpace(line) == "[invalid] "+publicName {
			continue
		}
		filtered = append(filtered, line)
	}
	return strings.Join(filtered, "\n")
}

func replacePrivatePath(output, path, replacement string) string {
	for _, variant := range privatePathVariants(path) {
		pattern := regexp.MustCompile("(?i)" + regexp.QuoteMeta(variant))
		output = pattern.ReplaceAllStringFunc(output, func(string) string { return replacement })
	}
	return output
}

func privatePathVariants(path string) []string {
	slashPath := strings.ReplaceAll(path, `\`, "/")
	backslashPath := strings.ReplaceAll(path, "/", `\`)
	escapedPath := (&url.URL{Path: slashPath}).EscapedPath()

	variants := map[string]struct{}{}
	add := func(value string) {
		if value != "" {
			variants[value] = struct{}{}
		}
	}
	add(path)
	add(slashPath)
	add(backslashPath)
	add(fileURI(path))
	for _, uriPath := range []string{slashPath, escapedPath} {
		trimmedPath := strings.TrimLeft(uriPath, "/")
		add("file:" + uriPath)
		add("file:/" + trimmedPath)
		add("file:///" + trimmedPath)
		add("file://localhost/" + trimmedPath)
	}

	result := make([]string, 0, len(variants))
	for variant := range variants {
		result = append(result, variant)
	}
	// Replace URI forms before their raw path suffixes, otherwise a leading
	// "file:" could remain visible in the diagnostic.
	sort.Slice(result, func(i, j int) bool { return len(result[i]) > len(result[j]) })
	return result
}

func portableBase(path string) string {
	path = strings.TrimRight(path, `/\`)
	if separator := strings.LastIndexAny(path, `/\`); separator >= 0 {
		return path[separator+1:]
	}
	return path
}

func portableDir(path string) string {
	path = strings.TrimRight(path, `/\`)
	separator := strings.LastIndexAny(path, `/\`)
	if separator < 0 {
		return ""
	}
	if separator == 0 {
		return path[:1]
	}
	return path[:separator]
}

// validationSchemaAvailable deliberately reports schemas by their public
// purpose rather than by their absolute installation path. The latter is an
// implementation detail and must not leak into CLI or server-side import logs.
func validationSchemaAvailable(path, name string) (bool, error) {
	info, err := os.Stat(path)
	if err == nil {
		return info.Mode().IsRegular(), nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, fmt.Errorf("%s kann nicht geprüft werden", name)
}

func findSchXsltCLI(libDir string) (string, error) {
	entries, err := os.ReadDir(libDir)
	if err != nil {
		return "", fmt.Errorf("SchXslt-Bibliotheksverzeichnis lesen: %w", err)
	}
	var matches []string
	for _, entry := range entries {
		if entry.Type().IsRegular() && strings.HasPrefix(entry.Name(), schXsltCLIJARPrefix) && strings.HasSuffix(entry.Name(), ".jar") {
			matches = append(matches, filepath.Join(libDir, entry.Name()))
		}
	}
	if len(matches) == 0 {
		return "", fmt.Errorf("SchXslt-CLI fehlt in %s", libDir)
	}
	if len(matches) > 1 {
		return "", fmt.Errorf("mehrere SchXslt-CLI-Versionen in %s gefunden", libDir)
	}
	return matches[0], nil
}

func writeXMLWithFixedDTD(source, destination, dtdURI string) error {
	content, err := os.ReadFile(source)
	if err != nil {
		return fmt.Errorf("XML lesen: %w", err)
	}
	content, err = neutralizeDOCTYPE(content)
	if err != nil {
		return fmt.Errorf("XML-DOCTYPE verarbeiten: %w", err)
	}

	insertAt := 0
	const utf8BOMLength = 3
	if bytes.HasPrefix(content, []byte{0xef, 0xbb, 0xbf}) {
		insertAt = utf8BOMLength
	}
	if bytes.HasPrefix(content[insertAt:], []byte("<?xml")) {
		declarationEnd := bytes.Index(content[insertAt:], []byte("?>"))
		if declarationEnd < 0 {
			return fmt.Errorf("nicht abgeschlossene XML-Deklaration")
		}
		insertAt += declarationEnd + len("?>")
	}

	// Do not add line breaks: diagnostics must keep the source line numbers.
	doctype := []byte(fmt.Sprintf("<!DOCTYPE book SYSTEM %q>", dtdURI))
	result := make([]byte, 0, len(content)+len(doctype))
	result = append(result, content[:insertAt]...)
	result = append(result, doctype...)
	result = append(result, content[insertAt:]...)
	if err := os.WriteFile(destination, result, 0o644); err != nil {
		return fmt.Errorf("temporäre XML-Datei schreiben: %w", err)
	}
	return nil
}
