# Einfache Roadmap zum MVP

Arbeite die Schritte der Reihe nach ab. Beginne den nächsten Schritt erst,
wenn das jeweilige Ergebnis funktioniert.

Das MVP ist eine Go-Anwendung mit:

- lokaler CLI,
- lokaler Browser-GUI,
- kleinem Servermodus mit Login,
- Print-PDF, Web-PDF und EPUB,
- automatisch gebauten Releases für Windows, Linux und macOS,
- gebündelter minimaler JRE, FOP, Saxon und EPUBCheck.

## Schritt 1 – Aktuellen Stand sichern

### Erledigen

- [x] Projekt in ein Git-Repository übernehmen.
- [x] Einen neuen Entwicklungsbranch anlegen.
- [x] Das Musterbuch und seine aktuellen PDF-/EPUB-Ausgaben sichern.
- [x] Hashes der aktuellen Ausgaben speichern.
- [x] Python, Shellskripte und Batchdateien noch nicht löschen. Sie dienen
      vorübergehend als Referenz für den alten Ablauf.
- [x] MOBI und Kindlegen ausdrücklich aus dem MVP ausschließen.
- [x] Zielplattformen festlegen:
      Windows x64, Linux x64 und macOS ARM64.

### Fertig, wenn

Das Musterbuch und seine bisherigen Ergebnisse sicher versioniert sind und
jederzeit zum Vergleich bereitstehen.

## Schritt 2 – Go-Grundgerüst erstellen

### Erledigen

- [x] Go-Modul initialisieren.
- [x] `cmd/oa/main.go` anlegen.
- [x] Die Befehle `version` und `doctor` implementieren.
- [x] Folgende minimale Struktur erstellen:

```text
cmd/oa/main.go
internal/build/
internal/project/
internal/java/
resources/
tests/
go.mod
go.sum
```

- [x] Für die erste Version die Go-Standardbibliothek verwenden. Noch kein
      großes CLI- oder Webframework auswählen.

`oa doctor` soll zunächst Betriebssystem, Architektur, Anwendungsversion und
gefundene Ressourcen anzeigen.

### Fertig, wenn

```text
go test ./...
go run ./cmd/oa version
go run ./cmd/oa doctor
```

ohne Fehler funktionieren.

## Schritt 3 – Java-Werkzeuge über Gradle beziehen

### Erledigen

- [x] Unter `java-toolchain/` einen kleinen Gradle-Build mit Kotlin DSL
      anlegen.
- [x] Gradle Wrapper einchecken.
- [x] FOP, Saxon HE und EPUBCheck mit festen Versionen deklarieren.
- [x] Dependency Locking aktivieren.
- [x] Eine Gradle-Aufgabe `syncRuntimeLibs` erstellen.
- [x] Diese Aufgabe kopiert alle benötigten JARs nach `build/stage/lib/`.
- [x] Drittanbieterlizenzen erfassen.
- [x] Keine JAR-Dateien mehr manuell ins Repository kopieren.

Verwende zunächst ein aktuelles vollständiges JDK. Die minimale JRE wird erst
gebaut, wenn alle drei Werkzeuge sicher funktionieren.

### Fertig, wenn

Gradle reproduzierbar ein `lib/`-Verzeichnis erzeugt und FOP, Saxon sowie
EPUBCheck jeweils ihre Version ausgeben können.

## Schritt 4 – Go-Buildkern für PDFs entwickeln

### Erledigen

- [x] Projektpfad und erwartete XML-Datei in Go prüfen.
- [x] Pfade absolut auflösen und auf das Projektverzeichnis begrenzen.
- [x] Einen gemeinsamen Java-Prozessadapter mit `os/exec` implementieren.
- [x] Java ohne Shell und mit einzelnen Argumenten starten.
- [x] stdout, stderr, Exitcode und Dauer erfassen.
- [x] Abbruch und Zeitlimit über `context.Context` unterstützen.
- [x] Für jeden Build ein neues temporäres Arbeitsverzeichnis verwenden.
- [x] FOP direkt über `org.apache.fop.cli.Main` starten.
- [x] Zuerst Print-PDF erzeugen.
- [x] Danach Web-PDF über denselben Code mit anderer FOP-Konfiguration
      ergänzen.
- [x] Erzeugte PDFs auf Existenz und sinnvolle Größe prüfen.
- [x] Ergebnisse erst nach erfolgreicher Prüfung in den Zielordner verschieben.

### Fertig, wenn

```text
oa build Projekte/Musterbuch --format print-pdf --format web-pdf
```

beide PDFs ohne Shell- oder Batchskript erzeugt und ein fehlgeschlagener Build
keine vorhandene gültige Ausgabe überschreibt.

## Schritt 5 – EPUB in Go und Saxon umsetzen

### Erledigen

- [x] Saxon direkt aus Go starten.
- [x] Projekt und Ausgabeziel als XSLT-Parameter übergeben.
- [x] Alle `xsl:result-document`-Ausgaben im temporären Jobverzeichnis halten.
- [x] Aus XML-Werten erzeugte Dateinamen validieren oder sicher abbilden.
- [x] Bilder, CSS und Fonts mit Go kopieren.
- [x] EPUB mit Go `archive/zip` erzeugen.
- [x] `mimetype` als ersten und unkomprimierten ZIP-Eintrag schreiben.
- [x] `META-INF` und `OEBPS` deterministisch hinzufügen.
- [x] EPUBCheck nach jedem Build ausführen.
- [x] EPUB nur bei erfolgreicher Prüfung veröffentlichen.

### Fertig, wenn

```text
oa build Projekte/Musterbuch --format epub
```

ohne 7-Zip und ohne Shellskript ein EPUB erzeugt, das EPUBCheck besteht.

## Schritt 6 – CLI abschließen und Altlasten entfernen

### Erledigen

- [x] Diese Befehle fertigstellen:

```text
oa validate <projekt>
oa build <projekt> --format ...
oa doctor
oa version
```

- [x] Verständliche Fehlermeldungen und stabile Exitcodes definieren.
- [x] `--output` ergänzen.
- [x] Print-PDF, Web-PDF und EPUB gemeinsam auswählbar machen.
- [x] CLI-Nutzung dokumentieren.
- [x] Nun die alten `.sh`- und `.bat`-Dateien löschen.
- [x] Python-Testdatei, Python-Anleitung und `requirements.txt` löschen.
- [x] Alte Java-7-Runtime, Java-Installer, 7-Zip und Kindlegen löschen.
- [x] Nicht mehr benötigte Xalan-/Xerces-Duplikate entfernen.
- [x] Generierte Outputs von regulären Projektquellen trennen.

### Fertig, wenn

Ein einzelner CLI-Aufruf alle drei Formate erzeugt und der normale Buildpfad
keine Python-, Shell-, Batch- oder 7-Zip-Abhängigkeit mehr besitzt.

## Schritt 7 – Die wichtigsten Tests ergänzen

### Erledigen

- [x] Test für fehlende XML-Datei.
- [x] Test für Pfade mit `..` und absolute Pfade.
- [x] Test für fehlgeschlagenen Java-Prozess.
- [x] Test für Timeout und Abbruch.
- [x] Test für EPUB-ZIP-Reihenfolge und unkomprimiertes `mimetype`.
- [x] Vollständiger Integrationsbuild des Musterbuchs.
- [x] EPUBCheck im Integrationstest.
- [x] PDFs auf Existenz, Mindestgröße und Lesbarkeit prüfen.

### Fertig, wenn

`go test ./...` die Go-Logik prüft und ein separater Integrationstest das
Musterbuch vollständig erzeugt.

## Schritt 8 – Lokale Browser-GUI bauen

### Erledigen

- [x] Einfache serverseitige HTML-Templates erstellen.
- [x] HTML, CSS und JavaScript mit `go:embed` einbetten.
- [x] `oa gui` implementieren.
- [x] Nur an `127.0.0.1` und einen freien Port binden.
- [x] Standardbrowser öffnen.
- [x] Standardmäßig einen automatisch bereinigten temporären Workspace und
      optional einen festen Workspace über `--workspace` verwenden.
- [x] Projektimport per ZIP bzw. Drag-and-drop implementieren.
- [x] Formatauswahl, Fortschritt, Logs und Ergebnislinks anzeigen.
- [x] Dieselben Go-Buildfunktionen wie die CLI verwenden.

Eine Browserseite kann keinen beliebigen lokalen Ordnerpfad an den Go-Prozess
übergeben. Deshalb importiert die GUI Projekte in ihren Workspace. Die CLI kann
weiterhin direkt mit beliebigen Projektordnern arbeiten.

Noch kein React, Desktop-WebView, Login oder Datenbank einführen.

### Fertig, wenn

Ein Nutzer das Musterbuch ohne Terminal importieren, prüfen, bauen und die
Ergebnisse öffnen kann.

## Schritt 9 – Minimale JRE und automatische lokale Releases

### Erledigen

- [x] Benötigte Java-Module mit `jdeps` ermitteln.
- [x] Mit `jlink` eine minimale Runtime erzeugen.
- [x] Dynamisch geladene FOP-/Font-/Grafikmodule praktisch testen.
- [x] Die vollständige Pipeline nur mit dieser Runtime ausführen.
- [x] GitHub-Actions-Matrix für Windows x64, Linux x64 und macOS ARM64
      anlegen.
- [x] Auf jedem nativen Runner Go-Binary, JARs und Runtime bauen.
- [x] Ressourcen und Lizenzen kopieren.
- [x] Musterbuch mit dem fertigen Paket als Smoke-Test bauen.
- [x] Distributionsarchiv und SHA-256-Prüfsumme erzeugen.
- [x] Bei Tags `v*` automatisch ein GitHub Release erstellen.

### Erwartete Artefakte

```text
oa-satzsystem-<version>-windows-x64.zip
oa-satzsystem-<version>-linux-x64.tar.gz
oa-satzsystem-<version>-macos-arm64.tar.gz
SHA256SUMS
```

Jedes Paket enthält:

```text
oa bzw. oa.exe
runtime/
lib/
resources/
licenses/
README.md
```

### Fertig, wenn

Eine saubere VM ohne Java, Go oder Gradle kann das Paket entpacken und über CLI
sowie lokale GUI alle Formate erzeugen.

## Schritt 10 – Kleinen Servermodus ergänzen

### Erledigen

- [ ] `oa serve` implementieren.
- [ ] Dieselben HTML-Seiten und Buildfunktionen wie bei `oa gui` verwenden.
- [ ] Serverdaten in einem expliziten Datenverzeichnis speichern.
- [ ] SQLite für Benutzer, Projekte, Jobs und Artefakte verwenden.
- [ ] Eine begrenzte In-Process-Jobqueue einführen.
- [ ] Für jeden Job ein isoliertes Arbeitsverzeichnis verwenden.
- [ ] Nur ZIP-Uploads akzeptieren.
- [ ] Uploadgröße, Dateianzahl und entpackte Gesamtgröße begrenzen.
- [ ] Absolute Archivpfade, `..`, Symlinks und Sonderdateien ablehnen.
- [ ] Laufende Jobs nach einem Neustart als abgebrochen markieren.

Noch kein Redis, PostgreSQL, Dockerzwang oder verteilter Worker.

### Fertig, wenn

Ein hochgeladenes Musterbuch als persistenter Job gebaut wird und nach einem
Serverneustart weiterhin sichtbar ist.

## Schritt 11 – Login und Serversicherheit ergänzen

### Erledigen

- [ ] Rollen `admin` und `user` einführen.
- [ ] Initialen Admin über einen einmaligen CLI-Befehl anlegen.
- [ ] Passwörter mit Argon2id oder bcrypt hashen.
- [ ] Sichere Session-Cookies verwenden.
- [ ] CSRF-Schutz ergänzen.
- [ ] Loginversuche begrenzen.
- [ ] Bei Projekten, Jobs und Downloads immer den Besitzer prüfen.
- [ ] Adminseite für das Anlegen und Deaktivieren weniger Benutzer erstellen.
- [ ] Keine Standardzugangsdaten ausliefern.
- [ ] `oa serve` standardmäßig nur an `127.0.0.1` binden.
- [ ] Beispielkonfiguration für einen HTTPS-Reverse-Proxy dokumentieren.
- [ ] Jobzeitlimits und Uploadlimits aktivieren.
- [ ] Backup und Restore von SQLite und Datenverzeichnis dokumentieren.

### Fertig, wenn

Zwei Testbenutzer nur ihre eigenen Projekte und Artefakte sehen, ein
deaktivierter Benutzer sich nicht mehr anmelden kann und ein hängender
Java-Prozess automatisch beendet wird.

## Schritt 12 – MVP veröffentlichen

### Erledigen

- [ ] CLI auf allen Zielplattformen testen.
- [ ] Lokale GUI auf allen Zielplattformen testen.
- [ ] Servermodus mit mindestens zwei Benutzern testen.
- [ ] Drittanbieterlizenzen kontrollieren.
- [ ] bekannte Einschränkungen dokumentieren.
- [ ] Version `v0.1.0` taggen.
- [ ] GitHub Actions alle Releasepakete bauen lassen.
- [ ] Releasepakete nochmals auf sauberen Systemen prüfen.

### MVP ist fertig, wenn

- [ ] Print-PDF, Web-PDF und EPUB funktionieren.
- [ ] EPUB besteht EPUBCheck.
- [ ] CLI und beide Webmodi verwenden denselben Go-Buildkern.
- [ ] Keine Python-, Shell- oder Batch-Buildlogik mehr existiert.
- [ ] Keine alte Java-Runtime, 7-Zip oder Kindlegen enthalten ist.
- [ ] Die minimale JRE und alle Java-Abhängigkeiten enthalten sind.
- [ ] Endanwender nichts zusätzlich installieren müssen.
- [ ] GitHub Releases für alle Zielplattformen automatisch erzeugt werden.
- [ ] Fehlgeschlagene Builds keine gültigen Ergebnisse überschreiben.
- [ ] Serverbenutzer nur ihre eigenen Daten sehen.

## Bewusst erst nach dem MVP

- TOML-Projektkonfiguration,
- native Desktop-GUI,
- automatische Clientupdates,
- SSO,
- PostgreSQL oder Redis,
- verteilte Worker,
- Plugin-System,
- MOBI,
- Online-XSLT-Editor,
- komplexe Rollenverwaltung.

## Dein sinnvoller erster Umsetzungsschritt

Bearbeite zunächst nur Schritt 1 bis 3. Danach führe aus Go ausschließlich die
FOP-Versionsausgabe aus.

Wenn diese Kette funktioniert, ist das technische Fundament bewiesen:

```text
Go → Gradle-bereitgestellte JARs → Java → FOP
```

Erst danach beginnst du mit dem echten PDF-Build.
