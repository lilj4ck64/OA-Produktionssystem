//go:build !windows

package java

import "os/exec"

// Linux and macOS do not create a separate console window for a child process.
func configureCommand(_ *exec.Cmd) {}
