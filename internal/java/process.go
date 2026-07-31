// Package java starts Java tools directly, without a command shell.
package java

import (
	"bytes"
	"context"
	"errors"
	"os/exec"
	"time"
	"unicode/utf8"
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
		Stdout:   decodeToolOutput(stdout.Bytes()),
		Stderr:   decodeToolOutput(stderr.Bytes()),
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

// decodeToolOutput keeps the Java tool boundary UTF-8 clean. The bundled
// tools normally emit UTF-8, but a JVM using the Windows system code page can
// write Windows-1252 instead (for example 0xfc for „ü“). Converting that byte
// directly to a Go string produces the replacement character in job logs.
func decodeToolOutput(data []byte) string {
	if utf8.Valid(data) {
		return string(data)
	}

	runes := make([]rune, 0, len(data))
	for _, b := range data {
		if b < 0x80 || b >= 0xa0 {
			runes = append(runes, rune(b))
			continue
		}
		runes = append(runes, windows1252Control[b-0x80])
	}
	return string(runes)
}

var windows1252Control = [...]rune{
	'€', '', '‚', 'ƒ', '„', '…', '†', '‡',
	'ˆ', '‰', 'Š', '‹', 'Œ', '', 'Ž', '',
	'', '‘', '’', '“', '”', '•', '–', '—',
	'˜', '™', 'š', '›', 'œ', '', 'ž', 'Ÿ',
}
