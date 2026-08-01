//go:build windows

package java

import (
	"os/exec"
	"syscall"
)

// A windowsgui parent has no console. Without HideWindow, starting java.exe can
// briefly create one of its own, which looks like a flashing black window.
func configureCommand(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
}
