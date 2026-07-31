// Package java starts Java tools directly, without a command shell.
package java

import (
	"bytes"
	"context"
	"errors"
	"os/exec"
	"time"
)

// Result records all observable data from a Java process.
type Result struct {
	Stdout   string
	Stderr   string
	ExitCode int
	Duration time.Duration
}

// Runner invokes a Java executable.
type Runner struct {
	Executable string
}

// Run starts Java with discrete arguments and observes cancellation via ctx.
func (r Runner) Run(ctx context.Context, dir string, args ...string) (Result, error) {
	executable := r.Executable
	if executable == "" {
		executable = "java"
	}
	var stdout, stderr bytes.Buffer
	cmd := exec.CommandContext(ctx, executable, args...)
	cmd.Dir = dir
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	started := time.Now()
	err := cmd.Run()
	result := Result{
		Stdout:   stdout.String(),
		Stderr:   stderr.String(),
		ExitCode: -1,
		Duration: time.Since(started),
	}
	if cmd.ProcessState != nil {
		result.ExitCode = cmd.ProcessState.ExitCode()
	}
	if ctxErr := ctx.Err(); ctxErr != nil {
		return result, ctxErr
	}
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return result, err
		}
		return result, err
	}
	return result, nil
}
