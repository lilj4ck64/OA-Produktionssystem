package gui

import (
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"
)

// Run starts the GUI with a process-owned temporary project area on loopback
// and opens it in the default browser.
func Run(ctx context.Context, root string, stdout io.Writer) (returnErr error) {
	workspace, err := os.MkdirTemp("", "oa-gui-workspace-*")
	if err != nil {
		return fmt.Errorf("temporären GUI-Arbeitsbereich anlegen: %w", err)
	}
	defer func() {
		if err := os.RemoveAll(workspace); err != nil && returnErr == nil {
			returnErr = fmt.Errorf("temporären GUI-Arbeitsbereich löschen: %w", err)
		}
	}()
	server, err := newServer(root, filepath.Join(workspace, "projects"))
	if err != nil {
		return err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return fmt.Errorf("lokalen GUI-Port öffnen: %w", err)
	}
	httpServer := &http.Server{Handler: server, ReadHeaderTimeout: 5 * time.Second}
	address := "http://" + listener.Addr().String()
	server.localHost = listener.Addr().String()
	server.outputRoot = filepath.Join(root, "Outputs")
	server.temporaryProjects = true
	server.lifecycle = newLocalLifecycle(2*time.Minute, 4*time.Second)
	workerCtx, stopWorker := context.WithCancel(ctx)
	server.startWorker(workerCtx)
	defer func() {
		stopWorker()
		server.workerWG.Wait()
	}()
	defer func() {
		server.stopRequests()
		_ = httpServer.Close()
		server.requestWG.Wait()
	}()
	fmt.Fprintf(stdout, "OA-GUI läuft unter %s\nTemporärer Projektbereich: %s\nZum Beenden Browser-Tab schließen oder Strg+C drücken.\n", address, workspace)
	go server.lifecycle.watch(ctx)
	go func() {
		select {
		case <-ctx.Done():
		case <-server.lifecycle.done:
		}
		server.stopRequests()
		shutdown, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_ = httpServer.Shutdown(shutdown)
	}()
	go func() {
		if err := openBrowser(address); err != nil {
			log.Printf("Browser konnte nicht automatisch geöffnet werden: %v", err)
		}
	}()
	err = httpServer.Serve(listener)
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}

// RunServer starts the shared UI in a process-owned temporary area without
// opening a browser. Access control belongs to the private network, VPN or an
// authenticating service in front of this deliberately small server.
func RunServer(ctx context.Context, root, address string, stdout io.Writer) error {
	return runServerIn(ctx, root, os.TempDir(), address, stdout)
}

func runServerIn(ctx context.Context, root, tempParent, address string, stdout io.Writer) (returnErr error) {
	serverArea, marker, err := createServerArea(tempParent)
	if err != nil {
		return err
	}
	defer func() {
		if err := os.RemoveAll(serverArea); err != nil && returnErr == nil {
			returnErr = fmt.Errorf("temporären Serverbereich löschen: %w", err)
		}
	}()
	server, err := newServer(root, filepath.Join(serverArea, "projects"))
	if err != nil {
		return err
	}
	server.artifactRoot = filepath.Join(serverArea, "artifacts")
	server.temporaryProjects = true
	if err := os.MkdirAll(server.artifactRoot, 0o755); err != nil {
		return fmt.Errorf("temporären Downloadbereich anlegen: %w", err)
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("Serveradresse öffnen: %w", err)
	}
	httpServer := &http.Server{
		Handler: server, ReadHeaderTimeout: 5 * time.Second,
		WriteTimeout: 15 * time.Minute, IdleTimeout: 60 * time.Second,
	}
	workerCtx, stopWorker := context.WithCancel(ctx)
	server.startWorker(workerCtx)
	go server.maintainTemporaryData(workerCtx, marker)
	defer func() {
		stopWorker()
		server.workerWG.Wait()
	}()
	defer func() {
		server.stopRequests()
		_ = httpServer.Close()
		server.requestWG.Wait()
	}()
	fmt.Fprintf(stdout, "OA-Server läuft unter http://%s\nTemporärer Serverbereich: %s\nBeenden mit Strg+C.\n", listener.Addr(), serverArea)
	go func() {
		<-ctx.Done()
		server.stopRequests()
		shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = httpServer.Shutdown(shutdown)
	}()
	err = httpServer.Serve(listener)
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}

func openBrowser(address string) error {
	var command string
	var args []string
	switch runtime.GOOS {
	case "windows":
		command, args = "rundll32", []string{"url.dll,FileProtocolHandler", address}
	case "darwin":
		command, args = "open", []string{address}
	default:
		command, args = "xdg-open", []string{address}
	}
	return exec.Command(command, args...).Start()
}
