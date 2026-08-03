package gui

import (
	"context"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

type localLifecycle struct {
	mu               sync.Mutex
	clients          map[string]localClient
	seenClient       bool
	heartbeatTimeout time.Duration
	closeGrace       time.Duration
	done             chan struct{}
	once             sync.Once
}

type localClient struct {
	deadline time.Time
	closing  bool
}

func newLocalLifecycle(heartbeatTimeout, closeGrace time.Duration) *localLifecycle {
	return &localLifecycle{
		clients: make(map[string]localClient), heartbeatTimeout: heartbeatTimeout,
		closeGrace: closeGrace, done: make(chan struct{}),
	}
}

func (l *localLifecycle) heartbeat(id string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.seenClient = true
	if client, exists := l.clients[id]; exists && client.closing {
		return
	}
	l.clients[id] = localClient{deadline: time.Now().Add(l.heartbeatTimeout)}
}

func (l *localLifecycle) closing(id string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.seenClient = true
	l.clients[id] = localClient{deadline: time.Now().Add(l.closeGrace), closing: true}
}

func (l *localLifecycle) watch(ctx context.Context) {
	interval := l.closeGrace / 4
	if interval <= 0 || interval > time.Second {
		interval = time.Second
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case now := <-ticker.C:
			l.mu.Lock()
			for id, client := range l.clients {
				if !now.Before(client.deadline) {
					delete(l.clients, id)
				}
			}
			finished := l.seenClient && len(l.clients) == 0
			l.mu.Unlock()
			if finished {
				l.once.Do(func() { close(l.done) })
				return
			}
		}
	}
}

func (s *Server) localSessionHeartbeat(w http.ResponseWriter, r *http.Request) {
	s.localSession(w, r, false)
}

func (s *Server) localSessionClose(w http.ResponseWriter, r *http.Request) {
	s.localSession(w, r, true)
}

func (s *Server) localSession(w http.ResponseWriter, r *http.Request, closing bool) {
	if s.lifecycle == nil {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 256))
	id := strings.TrimSpace(string(body))
	if err != nil || id == "" || len(id) > 128 {
		http.Error(w, "Ungültige lokale Sitzung.", http.StatusBadRequest)
		return
	}
	if closing {
		s.lifecycle.closing(id)
	} else {
		s.lifecycle.heartbeat(id)
	}
	w.WriteHeader(http.StatusNoContent)
}
