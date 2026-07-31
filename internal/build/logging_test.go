package build

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"oa-satzsystem/internal/java"
)

func TestToolResultIsForwardedToContextLogger(t *testing.T) {
	var messages []string
	ctx := WithLogger(context.Background(), func(message string) {
		messages = append(messages, message)
	})

	logToolResult(ctx, "EPUBCheck", java.Result{
		Stdout:   "No errors or warnings detected.",
		Stderr:   "detail from stderr",
		ExitCode: 0,
		Duration: 1250 * time.Millisecond,
	}, nil)

	if len(messages) != 1 {
		t.Fatalf("messages = %v", messages)
	}
	for _, want := range []string{"EPUBCheck: erfolgreich", "1.25s", "No errors", "detail from stderr"} {
		if !strings.Contains(messages[0], want) {
			t.Errorf("message %q does not contain %q", messages[0], want)
		}
	}

	logToolResult(ctx, "FOP", java.Result{ExitCode: 2}, errors.New("failed"))
	if len(messages) != 2 || !strings.Contains(messages[1], "fehlgeschlagen (Exitcode 2)") {
		t.Fatalf("failure message = %v", messages)
	}
}
