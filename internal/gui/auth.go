package gui

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"html/template"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	_ "modernc.org/sqlite"
)

const (
	roleAdmin       = "admin"
	roleUser        = "user"
	sessionCookie   = "oa_session"
	loginCSRFCookie = "oa_login_csrf"
	sessionLifetime = 12 * time.Hour
)

var usernamePattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{2,63}$`)

var dummyPasswordHash = func() string {
	hash, _ := bcrypt.GenerateFromPassword([]byte("not-a-real-user-password"), 12)
	return string(hash)
}()

type User struct {
	ID       int64
	Username string
	Role     string
}

type authContextKey int

const (
	userContextKey authContextKey = iota
	csrfContextKey
)

func requestUser(r *http.Request) *User {
	user, _ := r.Context().Value(userContextKey).(*User)
	return user
}

func requestCSRF(r *http.Request) string {
	value, _ := r.Context().Value(csrfContextKey).(string)
	return value
}

func (s *Server) authorizeRequest(w http.ResponseWriter, r *http.Request) bool {
	// Static files and the login page are public. Every other server-mode route
	// needs a live session, and every state-changing request needs the secret
	// CSRF value associated with that session.
	if strings.HasPrefix(r.URL.Path, "/static/") || r.URL.Path == "/login" {
		return true
	}
	user, csrf, err := s.sessionUser(r)
	if err != nil {
		if strings.HasPrefix(r.URL.Path, "/api/") || strings.HasPrefix(r.URL.Path, "/artifacts/") {
			http.Error(w, "Anmeldung erforderlich.", http.StatusUnauthorized)
		} else {
			http.Redirect(w, r, "/login", http.StatusSeeOther)
		}
		return false
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead && r.Method != http.MethodOptions {
		provided := r.Header.Get("X-CSRF-Token")
		if provided == "" {
			provided = r.FormValue("csrf_token")
		}
		if !constantEqual(csrf, provided) {
			http.Error(w, "Ungültiges CSRF-Token.", http.StatusForbidden)
			return false
		}
	}
	updated := r.WithContext(context.WithValue(r.Context(), userContextKey, user))
	updated = updated.WithContext(context.WithValue(updated.Context(), csrfContextKey, csrf))
	*r = *updated
	return true
}

func (s *Server) sessionUser(r *http.Request) (*User, string, error) {
	// Only a hash of the random browser token is stored in SQLite. A stolen
	// database therefore does not directly contain usable session cookies.
	cookie, err := r.Cookie(sessionCookie)
	if err != nil || len(cookie.Value) < 32 {
		return nil, "", errors.New("keine Sitzung")
	}
	hash := tokenHash(cookie.Value)
	var user User
	var csrf, expires string
	err = s.persistent.db.QueryRow(`SELECT u.id,u.username,u.role,se.csrf_token,se.expires_at
		FROM sessions se JOIN users u ON u.id=se.user_id
		WHERE se.token_hash=? AND u.active=1`, hash).Scan(&user.ID, &user.Username, &user.Role, &csrf, &expires)
	if err != nil {
		return nil, "", err
	}
	expiry, err := time.Parse(time.RFC3339Nano, expires)
	if err != nil || time.Now().After(expiry) {
		_, _ = s.persistent.db.Exec(`DELETE FROM sessions WHERE token_hash=?`, hash)
		return nil, "", errors.New("Sitzung abgelaufen")
	}
	return &user, csrf, nil
}

func (s *Server) login(w http.ResponseWriter, r *http.Request) {
	if s.persistent == nil {
		http.NotFound(w, r)
		return
	}
	if r.Method == http.MethodGet {
		token := randomToken(24)
		http.SetCookie(w, &http.Cookie{Name: loginCSRFCookie, Value: token, Path: "/login", HttpOnly: true, SameSite: http.SameSiteStrictMode, Secure: secureRequest(r), MaxAge: 600})
		s.render(w, "login", struct{ CSRF, Error string }{CSRF: token, Error: r.URL.Query().Get("error")})
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Nur GET und POST sind erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	csrfCookie, err := r.Cookie(loginCSRFCookie)
	if err != nil || !constantEqual(csrfCookie.Value, r.FormValue("csrf_token")) {
		http.Error(w, "Ungültiges CSRF-Token.", http.StatusForbidden)
		return
	}
	username := strings.TrimSpace(r.FormValue("username"))
	var id int64
	var hash string
	err = s.persistent.db.QueryRow(`SELECT id,password_hash FROM users WHERE username=? COLLATE NOCASE AND active=1`, username).Scan(&id, &hash)
	if err != nil {
		hash = dummyPasswordHash
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(r.FormValue("password"))) != nil || err != nil {
		http.Redirect(w, r, "/login?error="+template.URLQueryEscaper("Benutzername oder Passwort ist falsch."), http.StatusSeeOther)
		return
	}
	if err := s.startSession(w, r, id); err != nil {
		http.Error(w, "Sitzung konnte nicht erstellt werden.", http.StatusInternalServerError)
		return
	}
	http.SetCookie(w, &http.Cookie{Name: loginCSRFCookie, Value: "", Path: "/login", MaxAge: -1, HttpOnly: true, SameSite: http.SameSiteStrictMode, Secure: secureRequest(r)})
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func (s *Server) startSession(w http.ResponseWriter, r *http.Request, userID int64) error {
	token, csrf := randomToken(32), randomToken(32)
	if token == "" || csrf == "" {
		return errors.New("Zufallsquelle nicht verfügbar")
	}
	now := time.Now().UTC()
	_, _ = s.persistent.db.Exec(`DELETE FROM sessions WHERE expires_at<=?`, now.Format(time.RFC3339Nano))
	_, err := s.persistent.db.Exec(`INSERT INTO sessions(token_hash,user_id,csrf_token,expires_at,created_at) VALUES(?,?,?,?,?)`,
		tokenHash(token), userID, csrf, now.Add(sessionLifetime).Format(time.RFC3339Nano), now.Format(time.RFC3339Nano))
	if err != nil {
		return err
	}
	http.SetCookie(w, &http.Cookie{Name: sessionCookie, Value: token, Path: "/", HttpOnly: true, SameSite: http.SameSiteStrictMode, Secure: secureRequest(r), MaxAge: int(sessionLifetime.Seconds())})
	return nil
}

func (s *Server) logout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Nur POST ist erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	if cookie, err := r.Cookie(sessionCookie); err == nil {
		_, _ = s.persistent.db.Exec(`DELETE FROM sessions WHERE token_hash=?`, tokenHash(cookie.Value))
	}
	http.SetCookie(w, &http.Cookie{Name: sessionCookie, Value: "", Path: "/", MaxAge: -1, HttpOnly: true, SameSite: http.SameSiteStrictMode, Secure: secureRequest(r)})
	http.Redirect(w, r, "/login", http.StatusSeeOther)
}

type adminUserView struct {
	ID       int64
	Username string
	Role     string
	Active   bool
}

func (s *Server) adminUsers(w http.ResponseWriter, r *http.Request) {
	current := requestUser(r)
	if current == nil || current.Role != roleAdmin {
		http.Error(w, "Nur Administratoren dürfen Benutzer verwalten.", http.StatusForbidden)
		return
	}
	if r.Method == http.MethodPost {
		action := r.FormValue("action")
		switch action {
		case "create":
			if err := s.createUser(r.FormValue("username"), r.FormValue("password"), roleUser); err != nil {
				http.Redirect(w, r, "/admin/users?error="+template.URLQueryEscaper(err.Error()), http.StatusSeeOther)
				return
			}
		case "deactivate":
			var id int64
			if _, err := fmt.Sscan(r.FormValue("user_id"), &id); err != nil || id == current.ID {
				http.Error(w, "Ungültiger Benutzer.", http.StatusBadRequest)
				return
			}
			result, err := s.persistent.db.Exec(`UPDATE users SET active=0 WHERE id=? AND role='user'`, id)
			if err != nil {
				http.Error(w, "Benutzer konnte nicht deaktiviert werden.", http.StatusInternalServerError)
				return
			}
			if changed, _ := result.RowsAffected(); changed == 1 {
				_, _ = s.persistent.db.Exec(`DELETE FROM sessions WHERE user_id=?`, id)
			}
		default:
			http.Error(w, "Unbekannte Aktion.", http.StatusBadRequest)
			return
		}
		http.Redirect(w, r, "/admin/users", http.StatusSeeOther)
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "Nur GET und POST sind erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	rows, err := s.persistent.db.Query(`SELECT id,username,role,active FROM users ORDER BY username COLLATE NOCASE`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	var users []adminUserView
	for rows.Next() {
		var item adminUserView
		if err := rows.Scan(&item.ID, &item.Username, &item.Role, &item.Active); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		users = append(users, item)
	}
	s.render(w, "admin", struct {
		Users    []adminUserView
		CSRF     string
		Username string
		Error    string
	}{users, requestCSRF(r), current.Username, r.URL.Query().Get("error")})
}

func (s *Server) createUser(username, password, role string) error {
	// bcrypt intentionally makes each password guess expensive. The database
	// receives only the resulting one-way hash, never the original password.
	if !usernamePattern.MatchString(username) {
		return fmt.Errorf("Benutzername: 3–64 Zeichen; erlaubt sind Buchstaben, Ziffern, Punkt, Minus und Unterstrich")
	}
	if role != roleAdmin && role != roleUser {
		return fmt.Errorf("ungültige Rolle")
	}
	if len(password) < 12 || len(password) > 1024 {
		return fmt.Errorf("Passwort muss 12 bis 1024 Zeichen lang sein")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	if err != nil {
		return fmt.Errorf("Passwort hashen: %w", err)
	}
	_, err = s.persistent.db.Exec(`INSERT INTO users(username,password_hash,role,active,created_at) VALUES(?,?,?,?,?)`,
		username, string(hash), role, 1, time.Now().UTC().Format(time.RFC3339Nano))
	if err != nil {
		return fmt.Errorf("Benutzer konnte nicht angelegt werden (Name bereits vergeben?)")
	}
	return nil
}

// CreateInitialAdmin creates the one and only bootstrap administrator. It
// intentionally refuses to run once an administrator exists.
func CreateInitialAdmin(dataDir, username, password string) error {
	absolute, err := filepath.Abs(dataDir)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(absolute, 0o755); err != nil {
		return err
	}
	db, err := sql.Open("sqlite", filepath.Join(absolute, "server.db"))
	if err != nil {
		return err
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	templates, err := template.New("empty").Parse("")
	if err != nil {
		return err
	}
	s := &Server{persistent: &persistentState{db: db, dataDir: absolute}, templates: templates}
	if err := s.initializeDatabase(); err != nil {
		return err
	}
	var count int
	if err := db.QueryRow(`SELECT count(*) FROM users WHERE role='admin'`).Scan(&count); err != nil {
		return err
	}
	if count != 0 {
		return fmt.Errorf("ein initialer Administrator existiert bereits")
	}
	if err := s.createUser(strings.TrimSpace(username), password, roleAdmin); err != nil {
		return err
	}
	var adminID int64
	if err := db.QueryRow(`SELECT id FROM users WHERE username=?`, strings.TrimSpace(username)).Scan(&adminID); err != nil {
		return err
	}
	// Legacy data from step 10 had no owner. The first admin safely adopts it.
	_, _ = db.Exec(`UPDATE projects SET owner_id=? WHERE owner_id IS NULL`, adminID)
	_, _ = db.Exec(`UPDATE jobs SET owner_id=? WHERE owner_id IS NULL`, adminID)
	return nil
}

func randomToken(bytes int) string {
	buffer := make([]byte, bytes)
	if _, err := rand.Read(buffer); err != nil {
		return ""
	}
	return hex.EncodeToString(buffer)
}

func tokenHash(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

func constantEqual(a, b string) bool {
	if len(a) != len(b) || len(a) == 0 {
		return false
	}
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}

func secureRequest(r *http.Request) bool {
	return r.TLS != nil || strings.EqualFold(r.Header.Get("X-Forwarded-Proto"), "https")
}
