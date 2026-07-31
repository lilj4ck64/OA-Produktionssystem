# OA-Satzsystem

Das OA-Satzsystem erzeugt aus einem XML-Projekt Print-PDF, Web-PDF und EPUB.
Der normale Buildpfad besteht aus der Go-CLI und den über Gradle
bereitgestellten Java-Bibliotheken für FOP, Saxon HE und EPUBCheck.

## Voraussetzungen für die Entwicklung

- Go gemäß `go.mod`
- ein aktuelles JDK

Die Java-Bibliotheken werden einmalig reproduzierbar bereitgestellt:

```powershell
cd java-toolchain
.\gradlew.bat syncRuntimeLibs
cd ..
```

Unter Linux oder macOS wird stattdessen `./gradlew syncRuntimeLibs` verwendet.

## CLI

Während der Entwicklung werden die Befehle mit `go run ./cmd/oa` aufgerufen:

```text
oa version
oa doctor
oa validate <projekt>
oa build <projekt> --format <format> [--format <format> ...] [--output <ordner>]
oa gui [--workspace <ordner>]
oa serve --data-dir <ordner> [--listen <adresse>]
oa admin init --data-dir <ordner> --username <name>
```

Unterstützte Formate sind `print-pdf`, `web-pdf` und `epub`. Optionen dürfen
vor oder nach dem Projektpfad stehen. Ohne `--output` werden alle Ergebnisse
getrennt von den Quellen in `<projekt>/Outputs/` abgelegt:

```text
<projekt>/Outputs/<projekt>-print.pdf
<projekt>/Outputs/<projekt>-web.pdf
<projekt>/Outputs/<projekt>.epub
```

Ein vollständiger Build:

```powershell
go run ./cmd/oa build Projekte/Musterbuch `
  --format print-pdf `
  --format web-pdf `
  --format epub
```

Ein abweichender Zielordner:

```powershell
go run ./cmd/oa build Projekte/Musterbuch --format epub --output .tmp/ausgabe
```

## Lokale Browser-GUI

Die GUI wird lokal gestartet und öffnet automatisch den Standardbrowser:

```powershell
go run ./cmd/oa gui
```

Der Server bindet ausschließlich an `127.0.0.1` und wählt einen freien Port.
Importierte Projekte liegen standardmäßig in einem temporären Workspace, der
beim Schließen des letzten GUI-Tabs oder beim Beenden mit `Strg+C` automatisch
gelöscht wird. Der lokale GUI-Prozess erkennt geschlossene Browser-Tabs und
beendet sich nach einer kurzen Karenzzeit selbst; Reloads und Navigationen
innerhalb der GUI halten ihn aktiv. Sollen Importe
zwischen mehreren GUI-Starts erhalten bleiben, kann mit
`oa gui --workspace <ordner>` bewusst ein dauerhafter Speicherort gewählt
werden. Wenn der Browser die File-System-Access-API bereitstellt, kann
**Projektordner auswählen** verwendet werden. Die GUI liest den freigegebenen Ordner ein und schreibt
erfolgreiche Ergebnisse anschließend direkt in dessen Unterordner `Outputs`.
Der Browser fragt nötigenfalls erneut nach der Schreibfreigabe. Der Import ist
weiterhin eine isolierte Arbeitskopie; Quelldateien im gewählten Ordner werden
nie von der Anwendung verändert.

Browser ohne File-System-Access-API verwenden den ZIP-Import als Fallback. Die
ZIP-Datei darf entweder den Projektordner selbst oder direkt dessen Inhalt
enthalten. Ergebnislinks bleiben verfügbar, falls der Browser das direkte
Schreiben ablehnt. Im persistenten Servermodus sind aus Sicherheits- und
Kompatibilitätsgründen ausschließlich ZIP-Uploads und geschützte Downloads
vorgesehen.

## Persistenter Servermodus

Der Servermodus verwendet dieselben Seiten und denselben Buildkern wie die
lokale GUI, speichert Projekte, Jobs und Artefakte aber dauerhaft. Vor dem
ersten Start muss einmalig ein Administrator angelegt werden. Das Passwort
wird verdeckt abgefragt und weder als Befehlszeilenargument noch als
Standardzugang ausgeliefert:

```powershell
go run ./cmd/oa admin init --data-dir .server-data --username admin
```

Danach wird der Server mit demselben Datenverzeichnis gestartet:

```powershell
go run ./cmd/oa serve --data-dir .server-data
```

Standardmäßig ist der Server unter `http://127.0.0.1:8080` erreichbar. Eine
andere Bindeadresse kann beispielsweise mit `--listen 127.0.0.1:9090`
festgelegt werden. Im Datenverzeichnis liegen `server.db`, importierte
Projekte sowie isolierte Job- und Artefaktordner. Die In-Process-Queue umfasst
maximal 16 wartende Aufträge und zwei Worker. Unterbrochene Aufträge erscheinen
nach einem Neustart als `abgebrochen`.

Administratoren können nach der Anmeldung unter **Benutzer verwalten** wenige
Benutzer mit der Rolle `user` anlegen und deaktivieren. Benutzer sehen nur
ihre eigenen Projekte, Jobs und Downloads. Passwörter werden mit bcrypt
(Kostenfaktor 12) gespeichert. Sitzungen laufen nach zwölf Stunden ab;
Session-Tokens liegen nur gehasht in SQLite. Alle schreibenden Aktionen sind
CSRF-geschützt. Jobs werden nach zehn Minuten
abgebrochen; dadurch wird auch ein hängender Java-Unterprozess beendet.

### HTTPS-Reverse-Proxy

`oa serve` bindet standardmäßig ausschließlich an `127.0.0.1:8080`. Für einen
Zugriff aus dem Netz soll TLS an einem Reverse-Proxy enden; die OA-Anwendung
bleibt dabei auf Loopback. Eine Nginx-Beispielkonfiguration liegt unter
[`resources/nginx-oa.conf.example`](resources/nginx-oa.conf.example). Passe
Domain und Zertifikatspfade an. Bei HTTPS setzt die Anwendung das
Session-Cookie zusätzlich auf `Secure`; `HttpOnly` und `SameSite=Strict` sind
immer aktiv. Betreibe den HTTP-Port nicht direkt in einem fremden Netz.

### Backup und Restore

Ein konsistentes Offline-Backup umfasst immer das gesamte Datenverzeichnis,
also SQLite-Datenbank, Projekte und Jobartefakte:

1. Server mit `Strg+C` beenden.
2. Das komplette Verzeichnis `.server-data` an einen geschützten Ort kopieren
   oder archivieren, beispielsweise mit
   `Compress-Archive .server-data oa-backup.zip`.
3. Server erst nach erfolgreicher Kopie wieder starten.

Für ein Restore den Server ebenfalls beenden, das vorhandene Datenverzeichnis
sicher umbenennen und das vollständige Backup unter dem ursprünglichen Namen
wiederherstellen. Danach `oa serve` mit diesem Verzeichnis starten und Login,
Projektliste sowie einen Download prüfen. Datenbank und Dateiordner dürfen
nicht aus unterschiedlichen Sicherungszeitpunkten gemischt werden.

## Exitcodes

| Code | Bedeutung |
|---:|---|
| 0 | Befehl erfolgreich |
| 1 | Laufzeit-, Ressourcen- oder Buildfehler |
| 2 | ungültiger CLI-Aufruf |
| 3 | ungültiges Projekt |

## Tests

```powershell
go test ./...
go run ./cmd/oa validate Projekte/Musterbuch
go run ./cmd/oa serve --data-dir .server-data-test --listen 127.0.0.1:8080
```

Für einen realen Smoke-Test aller Formate siehe den vollständigen Buildaufruf
oben. Das EPUB wird dabei automatisch mit EPUBCheck geprüft; PDFs werden vor
dem Veröffentlichen auf Größe und PDF-Header geprüft.

## Native Releasepakete

Die GitHub-Action `.github/workflows/release.yml` baut native Pakete für
Windows x64, Linux x64 und macOS ARM64. Jedes Archiv enthält neben der
Kommandozeilenanwendung `oa` einen direkt startbaren GUI-Starter namens
`OA-Satzsystem` (unter Windows `OA-Satzsystem.exe`), eine mit `jdeps`/`jlink`
erzeugte Java-21-Runtime, alle JARs und Ressourcen.
Auf dem Zielsystem werden daher weder Go noch Java oder Gradle
benötigt.

Vor dem Archivieren baut jeder native Runner das Musterbuch mit der
paketierten Runtime als Print-PDF, Web-PDF und EPUB. Bei einem Tag `v*` werden
die drei Archive und die gemeinsame Datei `SHA256SUMS` automatisch als GitHub
Release veröffentlicht.

Die minimale Runtime kann lokal mit demselben JDK erzeugt werden:

```powershell
$env:JAVA_HOME = "C:\Pfad\zu\jdk-21"
.\java-toolchain\gradlew.bat -p java-toolchain `
  syncRuntimeLibs jlinkRuntime
```

## Bekannte Einschränkungen

- Der direkte lokale Ordnerzugriff benötigt die File-System-Access-API.
  Unterstützt der gewählte Browser sie nicht, nutzt die GUI ZIP und
  Ergebnislinks.
- Die lokale Browser-GUI arbeitet absichtlich mit einer Kopie des Projekts.
  Nur fertige Dateien werden nach Browserfreigabe in `Outputs`
  zurückgeschrieben; Änderungen an Quelldateien sind nicht vorgesehen.
- Der Servermodus ist für kleine Installationen mit einer einzelnen
  Anwendungsinstanz und zwei parallelen Build-Workern ausgelegt, nicht für
  verteilten Betrieb.
- Das Schließen des letzten lokalen GUI-Tabs beendet auch den GUI-Prozess.
  Ein zu diesem Zeitpunkt laufender Build wird daher abgebrochen; während
  eines Builds muss der Tab geöffnet bleiben.
