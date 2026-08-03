package gui

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func createServerArea(parent string) (string, string, error) {
	parent, err := filepath.Abs(parent)
	if err != nil {
		return "", "", fmt.Errorf("temporären Serverbereich auflösen: %w", err)
	}
	parent = filepath.Clean(parent)
	if err := os.MkdirAll(parent, 0o755); err != nil {
		return "", "", fmt.Errorf("Elternverzeichnis für Serverbereich anlegen: %w", err)
	}
	if err := cleanupOrphanedServerAreas(parent, time.Now()); err != nil {
		return "", "", err
	}
	area, err := os.MkdirTemp(parent, serverAreaPrefix+"*")
	if err != nil {
		return "", "", fmt.Errorf("temporären Serverbereich anlegen: %w", err)
	}
	marker := filepath.Join(area, serverAreaMarker)
	if err := os.WriteFile(marker, []byte(serverAreaMarkerValue), 0o600); err != nil {
		_ = os.RemoveAll(area)
		return "", "", fmt.Errorf("Serverbereich markieren: %w", err)
	}
	return area, marker, nil
}

func cleanupOrphanedServerAreas(parent string, now time.Time) error {
	entries, err := os.ReadDir(parent)
	if err != nil {
		return fmt.Errorf("alte Serverbereiche auflisten: %w", err)
	}
	for _, entry := range entries {
		if !strings.HasPrefix(entry.Name(), serverAreaPrefix) || entry.Type()&os.ModeSymlink != 0 || !entry.IsDir() {
			continue
		}
		area := filepath.Join(parent, entry.Name())
		marker := filepath.Join(area, serverAreaMarker)
		info, err := os.Lstat(marker)
		if err != nil || !info.Mode().IsRegular() || now.Sub(info.ModTime()) < serverAreaStaleAfter {
			continue
		}
		content, err := os.ReadFile(marker)
		if err != nil || string(content) != serverAreaMarkerValue {
			continue
		}
		relative, err := filepath.Rel(parent, area)
		if err != nil || relative == "." || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
			return fmt.Errorf("unsicherer verwaister Serverbereich: %s", area)
		}
		if err := os.RemoveAll(area); err != nil {
			return fmt.Errorf("verwaisten Serverbereich löschen: %w", err)
		}
	}
	return nil
}

func (s *Server) maintainTemporaryData(ctx context.Context, marker string) {
	ticker := time.NewTicker(defaultCleanupInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case now := <-ticker.C:
			_ = os.Chtimes(marker, now, now)
			s.cleanupExpiredJobs(now)
			s.cleanupStaleProjects(now)
		}
	}
}

func (s *Server) cleanupExpiredJobs(now time.Time) {
	type candidate struct {
		id   string
		path string
	}
	s.mu.Lock()
	var candidates []candidate
	for id, job := range s.jobs {
		if !job.cleaning && !job.expiresAt.IsZero() && !now.Before(job.expiresAt) && job.activeDownloads == 0 {
			job.cleaning = true
			candidates = append(candidates, candidate{id: id, path: filepath.Join(s.artifactRoot, id)})
		}
	}
	s.mu.Unlock()
	for _, item := range candidates {
		if err := os.RemoveAll(item.path); err != nil {
			s.mu.Lock()
			if job := s.jobs[item.id]; job != nil {
				job.cleaning = false
			}
			s.mu.Unlock()
			continue
		}
		s.mu.Lock()
		if job := s.jobs[item.id]; job != nil && job.cleaning {
			delete(s.jobs, item.id)
		}
		s.mu.Unlock()
	}
}

func (s *Server) cleanupStaleProjects(now time.Time) {
	retention := s.projectRetention
	if retention <= 0 {
		retention = defaultProjectRetention
	}
	s.projectMu.Lock()
	defer s.projectMu.Unlock()
	active := make(map[string]bool)
	s.mu.RLock()
	for _, job := range s.jobs {
		if job.Status == "wartet" || job.Status == "läuft" {
			active[filepath.Clean(job.projectDir)] = true
		}
	}
	s.mu.RUnlock()
	entries, err := os.ReadDir(s.projectsDir)
	if err != nil {
		return
	}
	for _, entry := range entries {
		if !entry.IsDir() || entry.Type()&os.ModeSymlink != 0 || strings.HasPrefix(entry.Name(), ".") {
			continue
		}
		path := filepath.Join(s.projectsDir, entry.Name())
		info, err := entry.Info()
		if err == nil && !active[filepath.Clean(path)] && now.Sub(info.ModTime()) >= retention {
			_ = os.RemoveAll(path)
		}
	}
}
