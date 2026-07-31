package java

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"
)

func TestRunnerCapturesProcessData(t *testing.T) {
	args := []string{"-test.run=TestProcessHelper", "--", "exit"}
	result, err := (Runner{Executable: os.Args[0]}).Run(context.Background(), t.TempDir(), args...)
	if err == nil {
		t.Fatal("Run() succeeded, want exit error")
	}
	if result.ExitCode != 7 || !strings.Contains(result.Stdout, "stdout") || !strings.Contains(result.Stderr, "stderr") {
		t.Fatalf("Run() result = %#v", result)
	}
	if result.Duration <= 0 {
		t.Fatalf("Run() duration = %s", result.Duration)
	}
}

func TestRunnerDecodesWindows1252ProcessData(t *testing.T) {
	args := []string{"-test.run=TestProcessHelper", "--", "windows-1252"}
	result, err := (Runner{Executable: os.Args[0]}).Run(context.Background(), t.TempDir(), args...)
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}
	if result.Stdout != "Prüfungen.\n" || result.Stderr != "Größe\n" {
		t.Fatalf("Run() output = stdout %q, stderr %q", result.Stdout, result.Stderr)
	}
	if strings.ContainsRune(result.Stdout+result.Stderr, '�') {
		t.Fatalf("Run() output contains replacement character: %#v", result)
	}
}

func TestRunnerCancellation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	args := []string{"-test.run=TestProcessHelper", "--", "sleep"}
	_, err := (Runner{Executable: os.Args[0]}).Run(ctx, t.TempDir(), args...)
	if err != context.DeadlineExceeded {
		t.Fatalf("Run() error = %v, want deadline exceeded", err)
	}
}

func TestRunnerExplicitCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	args := []string{"-test.run=TestProcessHelper", "--", "sleep"}
	_, err := (Runner{Executable: os.Args[0]}).Run(ctx, t.TempDir(), args...)
	if err != context.Canceled {
		t.Fatalf("Run() error = %v, want canceled", err)
	}
}

func TestProcessHelper(t *testing.T) {
	for i, arg := range os.Args {
		if arg != "--" || i+1 >= len(os.Args) {
			continue
		}
		switch os.Args[i+1] {
		case "exit":
			fmt.Fprintln(os.Stdout, "stdout")
			fmt.Fprintln(os.Stderr, "stderr")
			os.Exit(7)
		case "sleep":
			time.Sleep(10 * time.Second)
			os.Exit(0)
		case "windows-1252":
			_, _ = os.Stdout.Write([]byte{'P', 'r', 0xfc, 'f', 'u', 'n', 'g', 'e', 'n', '.', '\n'})
			_, _ = os.Stderr.Write([]byte{'G', 'r', 0xf6, 0xdf, 'e', '\n'})
			os.Exit(0)
		}
	}
}
