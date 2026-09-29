package build

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"oa-satzsystem/internal/project"
)

const (
	bitsDTDRelativePath    = "Schema/BITS-2-2-DTD/BITS-book2-2.dtd"
	schematronRelativePath = "Schema/schematron.sch"
	schXsltMainClass       = "name.dmaus.schxslt.cli.Application"
)

// ValidateProject performs the complete validation shared by the CLI and the
// GUI import: first the expected project layout, then the XML against the
// application's fixed BITS DTD and finally against its Schematron rules.
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

// ValidateXML validates one XML document first against the application's fixed
// BITS DTD and, only if that succeeds, against its fixed Schematron schema. A
// DOCTYPE from the input is removed from a temporary copy so it cannot select
// or load a different grammar.
func (e Engine) ValidateXML(ctx context.Context, source string) error {
	root, err := filepath.Abs(e.Root)
	if err != nil {
		return fmt.Errorf("Anwendungswurzel auflösen: %w", err)
	}
	layout := resolveLayout(root)
	dtd := filepath.Join(layout.resources, filepath.FromSlash(bitsDTDRelativePath))
	if err := requireFile(dtd); err != nil {
		return err
	}
	jobDir, err := os.MkdirTemp(e.TempParent, "oa-validate-*")
	if err != nil {
		return fmt.Errorf("Arbeitsverzeichnis für XML-Validierung anlegen: %w", err)
	}
	defer os.RemoveAll(jobDir)

	validationXML := filepath.Join(jobDir, filepath.Base(source))
	if err := writeXMLWithFixedDTD(source, validationXML, fileURI(dtd)); err != nil {
		return fmt.Errorf("XML für DTD-Validierung vorbereiten: %w", err)
	}

	logToolStart(ctx, "DTD-Validierung", "XML wird gegen die feste BITS-2.2-DTD geprüft.")
	result, runErr := e.javaRunner(root).RunWithOutput(ctx, root, logToolOutput(ctx, "DTD-Validierung"),
		"-cp", filepath.Join(layout.lib, "*"),
		"com.sun.msv.driver.textui.Driver",
		"-dtd", fileURI(dtd),
		fileURI(validationXML),
	)
	logToolResult(ctx, "DTD-Validierung", result, runErr)
	diagnostics := strings.TrimSpace(result.Stdout + "\n" + result.Stderr)
	if runErr != nil {
		if diagnostics == "" {
			return fmt.Errorf("XML ist nicht DTD-valide: DTD-Validierung konnte nicht ausgeführt werden: %w", runErr)
		}
		return fmt.Errorf("XML ist nicht DTD-valide: XML entspricht nicht der festen BITS-2.2-DTD: %w\n%s", runErr, diagnostics)
	}

	schematron := filepath.Join(layout.resources, filepath.FromSlash(schematronRelativePath))
	if err := requireFile(schematron); err != nil {
		return fmt.Errorf("Schematron-Validierung konnte nicht vorbereitet werden: %w", err)
	}
	cli, err := findSchXsltCLI(layout.lib)
	if err != nil {
		return fmt.Errorf("Schematron-Validierung konnte nicht vorbereitet werden: %w", err)
	}

	logToolStart(ctx, "Schematron-Validierung", "XML wird gegen Schema/schematron.sch geprüft.")
	result, runErr = e.javaRunner(root).RunWithOutput(ctx, root, logToolOutput(ctx, "Schematron-Validierung"),
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
	diagnostics = strings.TrimSpace(result.Stdout + "\n" + result.Stderr)
	if runErr != nil {
		if diagnostics == "" {
			return fmt.Errorf("XML ist nicht Schematron-valide: Schematron-Validierung konnte nicht ausgeführt werden: %w", runErr)
		}
		return fmt.Errorf("XML ist nicht Schematron-valide: %w\n%s", runErr, diagnostics)
	}
	return nil
}

func findSchXsltCLI(libDir string) (string, error) {
	entries, err := os.ReadDir(libDir)
	if err != nil {
		return "", fmt.Errorf("SchXslt-Bibliotheksverzeichnis lesen: %w", err)
	}
	var matches []string
	for _, entry := range entries {
		if entry.Type().IsRegular() && strings.HasPrefix(entry.Name(), "cli-") && strings.HasSuffix(entry.Name(), ".jar") {
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
