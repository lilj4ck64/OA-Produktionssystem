package build

import (
	"bytes"
	"fmt"
	"os"
)

// prepareXML creates an offline-safe build copy. External DTD declarations
// are not needed by the XSLT pipeline and would otherwise make builds depend
// on an HTTP server. Replacing them with whitespace preserves line numbers in
// later diagnostics and leaves the user's source untouched.
func prepareXML(source, destination string) error {
	content, err := os.ReadFile(source)
	if err != nil {
		return fmt.Errorf("XML für Build lesen: %w", err)
	}
	content, err = neutralizeDOCTYPE(content)
	if err != nil {
		return fmt.Errorf("XML-DOCTYPE verarbeiten: %w", err)
	}
	if err := os.WriteFile(destination, content, 0o644); err != nil {
		return fmt.Errorf("temporäre XML-Datei schreiben: %w", err)
	}
	return nil
}

func neutralizeDOCTYPE(content []byte) ([]byte, error) {
	token := []byte("<!DOCTYPE")
	searchFrom := 0
	start := -1
	for {
		relative := bytes.Index(content[searchFrom:], token)
		if relative < 0 {
			return content, nil
		}
		candidate := searchFrom + relative
		before := content[:candidate]
		commentStart := bytes.LastIndex(before, []byte("<!--"))
		commentEnd := bytes.LastIndex(before, []byte("-->"))
		if commentStart <= commentEnd {
			start = candidate
			break
		}
		searchFrom = candidate + len(token)
	}

	quote := byte(0)
	subsetDepth := 0
	end := -1
	for index := start + len(token); index < len(content); index++ {
		current := content[index]
		if quote != 0 {
			if current == quote {
				quote = 0
			}
			continue
		}
		switch current {
		case '\'', '"':
			quote = current
		case '[':
			subsetDepth++
		case ']':
			if subsetDepth > 0 {
				subsetDepth--
			}
		case '>':
			if subsetDepth == 0 {
				end = index + 1
			}
		}
		if end >= 0 {
			break
		}
	}
	if end < 0 {
		return nil, fmt.Errorf("nicht abgeschlossene DOCTYPE-Deklaration")
	}

	result := bytes.Clone(content)
	for index := start; index < end; index++ {
		if result[index] != '\r' && result[index] != '\n' {
			result[index] = ' '
		}
	}
	return result, nil
}
