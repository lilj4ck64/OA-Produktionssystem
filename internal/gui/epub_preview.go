package gui

import (
	"archive/zip"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"html"
	"io"
	"mime"
	"net/http"
	"net/url"
	"path"
	"strings"
)

const maxEPUBPreviewEntrySize = 128 << 20

type epubContainer struct {
	Rootfiles []struct {
		FullPath string `xml:"full-path,attr"`
	} `xml:"rootfiles>rootfile"`
}

type epubPackage struct {
	Title    string `xml:"metadata>title"`
	Manifest []struct {
		ID        string `xml:"id,attr"`
		Href      string `xml:"href,attr"`
		MediaType string `xml:"media-type,attr"`
	} `xml:"manifest>item"`
	Spine []struct {
		IDRef string `xml:"idref,attr"`
	} `xml:"spine>itemref"`
}

type epubPreviewManifest struct {
	Title string               `json:"title"`
	Spine []epubPreviewSection `json:"spine"`
}

type epubPreviewSection struct {
	Label string `json:"label"`
	URL   string `json:"url"`
}

func (s *Server) epubPreview(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "Nur GET und HEAD sind erlaubt.", http.StatusMethodNotAllowed)
		return
	}
	parts := strings.SplitN(strings.TrimPrefix(r.URL.Path, "/epub-preview/"), "/", 3)
	if len(parts) < 2 || parts[0] == "" {
		http.NotFound(w, r)
		return
	}
	artifact, ok := s.acquireEPUBArtifact(parts[0])
	if !ok {
		http.NotFound(w, r)
		return
	}
	defer s.releaseArtifact(parts[0])

	switch {
	case len(parts) == 2 && parts[1] == "manifest":
		s.serveEPUBManifest(w, r, parts[0], artifact.path)
	case len(parts) == 2 && parts[1] == "document":
		s.serveEPUBDocument(w, r, parts[0], artifact.path, r.URL.Query().Get("path"))
	case len(parts) == 3 && parts[1] == "content":
		s.serveEPUBEntry(w, r, artifact.path, parts[2])
	default:
		http.NotFound(w, r)
	}
}

func (s *Server) serveEPUBManifest(w http.ResponseWriter, r *http.Request, jobID, artifactPath string) {
	manifest, err := readEPUBPreviewManifest(artifactPath)
	if err != nil {
		http.Error(w, "EPUB-Vorschau konnte nicht gelesen werden.", http.StatusUnprocessableEntity)
		return
	}
	prefix := "/epub-preview/" + url.PathEscape(jobID) + "/document?path="
	for index := range manifest.Spine {
		manifest.Spine[index].URL = prefix + url.QueryEscape(manifest.Spine[index].URL)
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "private, no-store")
	if r.Method == http.MethodHead {
		return
	}
	_ = json.NewEncoder(w).Encode(manifest)
}

func (s *Server) serveEPUBDocument(w http.ResponseWriter, r *http.Request, jobID, artifactPath, entryName string) {
	entryName, ok := cleanEPUBPath(entryName)
	if !ok || !strings.EqualFold(path.Ext(entryName), ".xhtml") {
		http.NotFound(w, r)
		return
	}
	archive, err := zip.OpenReader(artifactPath)
	if err != nil {
		http.Error(w, "EPUB-Vorschau konnte nicht geöffnet werden.", http.StatusUnprocessableEntity)
		return
	}
	defer archive.Close()
	document, err := readEPUBEntry(archive.File, entryName, maxEPUBPreviewEntrySize)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	baseURL := "/epub-preview/" + url.PathEscape(jobID) + "/content/"
	if directory := path.Dir(entryName); directory != "." {
		baseURL += escapeEPUBPath(directory) + "/"
	}
	document = injectEPUBBase(document, baseURL)
	setEPUBContentHeaders(w, "text/html; charset=utf-8", uint64(len(document)))
	if r.Method != http.MethodHead {
		_, _ = w.Write(document)
	}
}

func (s *Server) serveEPUBEntry(w http.ResponseWriter, r *http.Request, artifactPath, entryName string) {
	entryName, ok := cleanEPUBPath(entryName)
	if !ok {
		http.NotFound(w, r)
		return
	}
	archive, err := zip.OpenReader(artifactPath)
	if err != nil {
		http.Error(w, "EPUB-Vorschau konnte nicht geöffnet werden.", http.StatusUnprocessableEntity)
		return
	}
	defer archive.Close()
	entry := findEPUBEntry(archive.File, entryName)
	if entry == nil || entry.FileInfo().IsDir() || entry.UncompressedSize64 > maxEPUBPreviewEntrySize {
		http.NotFound(w, r)
		return
	}
	contentType := mime.TypeByExtension(strings.ToLower(path.Ext(entryName)))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	if r.Method == http.MethodHead {
		setEPUBContentHeaders(w, contentType, entry.UncompressedSize64)
		return
	}
	reader, err := entry.Open()
	if err != nil {
		http.Error(w, "EPUB-Inhalt konnte nicht geöffnet werden.", http.StatusUnprocessableEntity)
		return
	}
	defer reader.Close()
	setEPUBContentHeaders(w, contentType, entry.UncompressedSize64)
	_, _ = io.Copy(w, reader)
}

func setEPUBContentHeaders(w http.ResponseWriter, contentType string, size uint64) {
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Content-Length", fmt.Sprint(size))
	w.Header().Set("Cache-Control", "private, max-age=300")
	w.Header().Set("X-Frame-Options", "SAMEORIGIN")
	w.Header().Set("Content-Security-Policy", "default-src 'self' data:; script-src 'none'; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-src 'none'; frame-ancestors 'self'; form-action 'none'; connect-src 'none'")
}

func injectEPUBBase(document []byte, baseURL string) []byte {
	lower := strings.ToLower(string(document))
	headStart := strings.Index(lower, "<head")
	if headStart < 0 {
		return document
	}
	headEnd := strings.Index(lower[headStart:], ">")
	if headEnd < 0 {
		return document
	}
	position := headStart + headEnd + 1
	base := `<base href="` + html.EscapeString(baseURL) + `">`
	result := make([]byte, 0, len(document)+len(base))
	result = append(result, document[:position]...)
	result = append(result, base...)
	result = append(result, document[position:]...)
	return result
}

func readEPUBPreviewManifest(filename string) (epubPreviewManifest, error) {
	archive, err := zip.OpenReader(filename)
	if err != nil {
		return epubPreviewManifest{}, err
	}
	defer archive.Close()

	containerData, err := readEPUBEntry(archive.File, "META-INF/container.xml", 1<<20)
	if err != nil {
		return epubPreviewManifest{}, err
	}
	var container epubContainer
	if err := xml.Unmarshal(containerData, &container); err != nil || len(container.Rootfiles) == 0 {
		return epubPreviewManifest{}, fmt.Errorf("ungültiger EPUB-Container")
	}
	opfPath, ok := cleanEPUBPath(container.Rootfiles[0].FullPath)
	if !ok {
		return epubPreviewManifest{}, fmt.Errorf("ungültiger OPF-Pfad")
	}
	opfData, err := readEPUBEntry(archive.File, opfPath, 8<<20)
	if err != nil {
		return epubPreviewManifest{}, err
	}
	var publication epubPackage
	if err := xml.Unmarshal(opfData, &publication); err != nil {
		return epubPreviewManifest{}, err
	}
	items := make(map[string]string, len(publication.Manifest))
	for _, item := range publication.Manifest {
		if item.MediaType != "application/xhtml+xml" {
			continue
		}
		href, err := resolveEPUBHref(path.Dir(opfPath), item.Href)
		if err == nil {
			items[item.ID] = href
		}
	}
	result := epubPreviewManifest{Title: strings.TrimSpace(publication.Title)}
	for _, reference := range publication.Spine {
		href := items[reference.IDRef]
		if href == "" {
			continue
		}
		label := epubDocumentTitle(archive.File, href)
		if label == "" {
			label = reference.IDRef
		}
		result.Spine = append(result.Spine, epubPreviewSection{Label: label, URL: href})
	}
	if len(result.Spine) == 0 {
		return epubPreviewManifest{}, fmt.Errorf("EPUB enthält keinen lesbaren Spine")
	}
	return result, nil
}

func resolveEPUBHref(base, href string) (string, error) {
	parsed, err := url.Parse(href)
	if err != nil || parsed.IsAbs() || parsed.Host != "" {
		return "", fmt.Errorf("ungültiger EPUB-Verweis")
	}
	decoded, err := url.PathUnescape(parsed.Path)
	if err != nil {
		return "", err
	}
	resolved, ok := cleanEPUBPath(path.Join(base, decoded))
	if !ok {
		return "", fmt.Errorf("ungültiger EPUB-Pfad")
	}
	return resolved, nil
}

func cleanEPUBPath(name string) (string, bool) {
	if name == "" || strings.Contains(name, "\\") || strings.HasPrefix(name, "/") {
		return "", false
	}
	cleaned := path.Clean(name)
	if cleaned == "." || cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return "", false
	}
	return cleaned, true
}

func escapeEPUBPath(name string) string {
	parts := strings.Split(name, "/")
	for index := range parts {
		parts[index] = url.PathEscape(parts[index])
	}
	return strings.Join(parts, "/")
}

func findEPUBEntry(files []*zip.File, name string) *zip.File {
	for _, file := range files {
		if file.Name == name {
			return file
		}
	}
	return nil
}

func readEPUBEntry(files []*zip.File, name string, limit uint64) ([]byte, error) {
	entry := findEPUBEntry(files, name)
	if entry == nil || entry.UncompressedSize64 > limit {
		return nil, fmt.Errorf("EPUB-Eintrag fehlt oder ist zu groß: %s", name)
	}
	reader, err := entry.Open()
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(io.LimitReader(reader, int64(limit)+1))
}

func epubDocumentTitle(files []*zip.File, name string) string {
	data, err := readEPUBEntry(files, name, 4<<20)
	if err != nil {
		return ""
	}
	var document struct {
		Title string `xml:"head>title"`
	}
	if xml.Unmarshal(data, &document) != nil {
		return ""
	}
	return strings.TrimSpace(document.Title)
}
