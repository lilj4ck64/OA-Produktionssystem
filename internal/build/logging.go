package build

import (
	"context"
	"fmt"
	"time"

	"oa-satzsystem/internal/java"
)

// LogFunc receives user-visible progress and diagnostics from the build tools.
// Keeping it on the context lets CLI callers ignore it while each GUI job can
// attach its own logger to the same Engine.Build API.
type LogFunc func(string)

type logContextKey struct{}

// WithLogger returns a build context that forwards tool output to logger.
func WithLogger(ctx context.Context, logger LogFunc) context.Context {
	if logger == nil {
		return ctx
	}
	return context.WithValue(ctx, logContextKey{}, logger)
}

// Log appends a message to the logger attached to ctx, if one exists.
func Log(ctx context.Context, message string) {
	if logger, ok := ctx.Value(logContextKey{}).(LogFunc); ok && logger != nil {
		logger(message)
	}
}

func logToolStart(ctx context.Context, tool, action string) {
	Log(ctx, fmt.Sprintf("%s: %s", tool, action))
}

func logToolResult(ctx context.Context, tool string, result java.Result, runErr error) {
	status := "erfolgreich"
	if runErr != nil {
		status = fmt.Sprintf("fehlgeschlagen (Exitcode %d)", result.ExitCode)
	}
	Log(ctx, fmt.Sprintf("%s: %s nach %s.", tool, status, result.Duration.Round(time.Millisecond)))
}

func logToolOutput(ctx context.Context, tool string) func(string) {
	return func(line string) { Log(ctx, tool+": "+line) }
}
