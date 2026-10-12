package build

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"oa-satzsystem/internal/java"
)

const toolAdapterMainClass = "oa.tools.ToolAdapter"

type apiDiagnostic struct {
	Code    string `json:"code"`
	File    string `json:"file"`
	Line    int    `json:"line"`
	Column  int    `json:"column"`
	Message string `json:"message"`
}

func apiToolFailure(tool string, result java.Result, runErr error) error {
	var diagnostic apiDiagnostic
	if err := json.Unmarshal([]byte(strings.TrimSpace(result.Stdout)), &diagnostic); err == nil && strings.TrimSpace(diagnostic.Message) != "" {
		return fmt.Errorf("%s: %s", tool, formatAPIDiagnostic(diagnostic))
	}

	var exitErr *exec.ExitError
	if runErr != nil && !errors.As(runErr, &exitErr) {
		return fmt.Errorf("%s konnte nicht ausgeführt werden: %w", tool, runErr)
	}
	return fmt.Errorf("%s: Verarbeitung fehlgeschlagen", tool)
}

func formatAPIDiagnostic(diagnostic apiDiagnostic) string {
	file := compactDiagnosticPath(diagnostic.File)
	location := file
	if diagnostic.Line > 0 {
		location += ":" + strconv.Itoa(diagnostic.Line)
		if diagnostic.Column > 0 {
			location += ":" + strconv.Itoa(diagnostic.Column)
		}
	}
	message := strings.Join(strings.Fields(diagnostic.Message), " ")
	if diagnostic.Code != "" && !strings.Contains(message, diagnostic.Code) {
		message = "[" + diagnostic.Code + "] " + message
	}
	if location == "" {
		return message
	}
	return location + " – " + message
}

func compactDiagnosticPath(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}
	if parsed, err := url.Parse(value); err == nil && parsed.Scheme == "file" {
		if parsed.Path != "" {
			value = parsed.Path
		} else {
			value = parsed.Opaque
		}
	}
	value = strings.ReplaceAll(value, `\`, "/")
	if epub := strings.Index(strings.ToLower(value), ".epub/"); epub >= 0 {
		return strings.TrimPrefix(value[epub+len(".epub/"):], "/")
	}
	return filepath.Base(filepath.FromSlash(value))
}
