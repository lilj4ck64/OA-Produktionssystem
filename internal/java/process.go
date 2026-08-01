// Package java starts Java tools directly, without a command shell.
package java

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os/exec"
	"strings"
	"sync"
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
	return r.RunWithOutput(ctx, dir, nil, args...)
}

// RunWithOutput additionally forwards complete stdout and stderr lines while
// the process is running. The returned Result still contains both full streams
// so command-line errors retain their complete diagnostics.
func (r Runner) RunWithOutput(ctx context.Context, dir string, output func(string), args ...string) (Result, error) {
	executable := r.Executable
	if executable == "" {
		executable = "java"
	}
	var stdout, stderr bytes.Buffer
	cmd := exec.CommandContext(ctx, executable, args...)
	configureCommand(cmd)
	cmd.Dir = dir
	streamOutput := output
	if output != nil {
		var outputMu sync.Mutex
		streamOutput = func(line string) {
			outputMu.Lock()
			defer outputMu.Unlock()
			output(line)
		}
	}
	stdoutLines := newLineWriter(streamOutput)
	stderrLines := newLineWriter(streamOutput)
	cmd.Stdout = io.MultiWriter(&stdout, stdoutLines)
	cmd.Stderr = io.MultiWriter(&stderr, stderrLines)

	started := time.Now()
	err := cmd.Run()
	stdoutLines.Flush()
	stderrLines.Flush()
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

type lineWriter struct {
	output func(string)
	buffer []byte
}

func newLineWriter(output func(string)) *lineWriter {
	return &lineWriter{output: output}
}

func (w *lineWriter) Write(data []byte) (int, error) {
	if w.output == nil {
		return len(data), nil
	}
	w.buffer = append(w.buffer, data...)
	for {
		index := bytes.IndexByte(w.buffer, '\n')
		if index < 0 {
			break
		}
		w.emit(w.buffer[:index])
		w.buffer = w.buffer[index+1:]
	}
	return len(data), nil
}

func (w *lineWriter) Flush() {
	if len(w.buffer) > 0 {
		w.emit(w.buffer)
		w.buffer = nil
	}
}

func (w *lineWriter) emit(data []byte) {
	line := strings.TrimSuffix(decodeToolOutput(data), "\r")
	if strings.TrimSpace(line) != "" {
		w.output(line)
	}
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
