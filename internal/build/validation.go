package build

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const bitsDTDRelativePath = "Schema/BITS-2-2-DTD/BITS-book2-2.dtd"

// ValidateXML validates one XML document against the application's fixed BITS
// DTD. A DOCTYPE from the input is removed from a temporary copy so it cannot
// select or load a different grammar.
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

	result, runErr := e.javaRunner(root).RunWithOutput(ctx, root, nil,
		"-cp", filepath.Join(layout.lib, "*"),
		"com.sun.msv.driver.textui.Driver",
		"-dtd", fileURI(dtd),
		fileURI(validationXML),
	)
	diagnostics := strings.TrimSpace(result.Stdout + "\n" + result.Stderr)
	if runErr != nil {
		if diagnostics == "" {
			return fmt.Errorf("DTD-Validierung konnte nicht ausgeführt werden: %w", runErr)
		}
		return fmt.Errorf("XML entspricht nicht der festen BITS-2.2-DTD: %w\n%s", runErr, diagnostics)
	}
	return nil
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
