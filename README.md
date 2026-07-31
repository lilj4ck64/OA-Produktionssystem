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
beim normalen Beenden mit `Strg+C` automatisch gelöscht wird. Sollen Importe
zwischen mehreren GUI-Starts erhalten bleiben, kann mit
`oa gui --workspace <ordner>` bewusst ein dauerhafter Speicherort gewählt
werden. Ein Projekt wird als ZIP-Datei importiert; die ZIP-Datei darf entweder
den Projektordner selbst oder direkt dessen Inhalt enthalten. Anschließend
kann das Projekt geprüft und in einem oder mehreren Formaten gebaut werden.
Fortschritt, Buildmeldungen und Ergebnislinks werden im Browser angezeigt.

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
```

Für einen realen Smoke-Test aller Formate siehe den vollständigen Buildaufruf
oben. Das EPUB wird dabei automatisch mit EPUBCheck geprüft; PDFs werden vor
dem Veröffentlichen auf Größe und PDF-Header geprüft.

## Native Releasepakete

Die GitHub-Action `.github/workflows/release.yml` baut native Pakete für
Windows x64, Linux x64 und macOS ARM64. Jedes Archiv enthält die Go-Anwendung,
eine mit `jdeps`/`jlink` erzeugte Java-21-Runtime, alle JARs, Ressourcen und
Lizenzen. Auf dem Zielsystem werden daher weder Go noch Java oder Gradle
benötigt.

Vor dem Archivieren baut jeder native Runner das Musterbuch mit der
paketierten Runtime als Print-PDF, Web-PDF und EPUB. Bei einem Tag `v*` werden
die drei Archive und die gemeinsame Datei `SHA256SUMS` automatisch als GitHub
Release veröffentlicht.

Die minimale Runtime kann lokal mit demselben JDK erzeugt werden:

```powershell
$env:JAVA_HOME = "C:\Pfad\zu\jdk-21"
.\java-toolchain\gradlew.bat -p java-toolchain `
  syncRuntimeLibs writeRuntimeManifest jlinkRuntime
```

## Lizenz

Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM. Veröffentlicht unter
der GNU General Public License Version 3; siehe `01_LICENSE`.
