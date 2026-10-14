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

type apiPathRedaction struct {
	path        string
	replacement string
}

func apiToolFailure(tool string, result java.Result, runErr error, redactions ...apiPathRedaction) error {
	diagnostics := decodeAPIDiagnostics(result.Stdout)
	if len(diagnostics) > 0 {
		lines := make([]string, 0, len(diagnostics))
		for _, diagnostic := range diagnostics {
			diagnostic = redactAPIDiagnostic(diagnostic, redactions)
			lines = append(lines, fmt.Sprintf("%s: %s", tool, formatAPIDiagnostic(diagnostic)))
		}
		return toolDiagnosticsError{lines: lines}
	}

	var exitErr *exec.ExitError
	if runErr != nil && !errors.As(runErr, &exitErr) {
		// os/exec errors can contain the absolute path of the Java runtime.
		return fmt.Errorf("%s konnte nicht ausgeführt werden", tool)
	}
	return fmt.Errorf("%s: Verarbeitung fehlgeschlagen", tool)
}

func redactAPIDiagnostic(diagnostic apiDiagnostic, redactions []apiPathRedaction) apiDiagnostic {
	for _, redaction := range redactions {
		diagnostic.File = replacePrivatePath(diagnostic.File, redaction.path, redaction.replacement)
		diagnostic.Message = replacePrivatePath(diagnostic.Message, redaction.path, redaction.replacement)
	}
	return diagnostic
}

type toolDiagnosticsError struct {
	lines []string
}

func (e toolDiagnosticsError) Error() string {
	return strings.Join(e.lines, "\n")
}

func (e toolDiagnosticsError) UserErrorLines() []string {
	return append([]string(nil), e.lines...)
}

// UserErrorLines returns all independently actionable tool diagnostics even
// when another layer has wrapped the build error with additional context.
func UserErrorLines(err error) ([]string, bool) {
	var diagnostics interface{ UserErrorLines() []string }
	if !errors.As(err, &diagnostics) {
		return nil, false
	}
	return diagnostics.UserErrorLines(), true
}

func decodeAPIDiagnostics(output string) []apiDiagnostic {
	data := []byte(strings.TrimSpace(output))
	var diagnostics []apiDiagnostic
	if err := json.Unmarshal(data, &diagnostics); err == nil {
		return validAPIDiagnostics(diagnostics)
	}
	var diagnostic apiDiagnostic
	if err := json.Unmarshal(data, &diagnostic); err == nil {
		return validAPIDiagnostics([]apiDiagnostic{diagnostic})
	}
	return nil
}

func validAPIDiagnostics(diagnostics []apiDiagnostic) []apiDiagnostic {
	result := make([]apiDiagnostic, 0, len(diagnostics))
	for _, diagnostic := range diagnostics {
		if strings.TrimSpace(diagnostic.Message) != "" {
			result = append(result, diagnostic)
		}
	}
	return result
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
