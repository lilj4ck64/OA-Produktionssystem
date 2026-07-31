# OA-Satzsystem

Das OA-Satzsystem erzeugt aus einem XML-Projekt Print-PDF, Web-PDF und EPUB.
Es ist bewusst als kleines lokales Werkzeug und als gemeinsamer Server für ein
kleines, vertrauenswürdiges Team ausgelegt.

Der dauerhafte Zustand liegt ausschließlich im Dateisystem. Es gibt keine
Datenbank, Benutzerverwaltung oder persistente Jobhistorie.

## Entwicklung

Benötigt werden Go gemäß `go.mod` und ein aktuelles JDK. Die Java-Bibliotheken
für FOP, Saxon HE und EPUBCheck werden einmalig bereitgestellt:

```powershell
cd java-toolchain
.\gradlew.bat syncRuntimeLibs
cd ..
```

Unter Linux oder macOS wird `./gradlew` verwendet.

## CLI

```text
oa version
oa doctor
oa validate <projekt>
oa build <projekt> --format <format> [--format <format> ...] [--output <ordner>]
oa gui [--workspace <ordner>]
oa serve --workspace <ordner> [--listen <adresse>]
```

Unterstützte Formate sind `print-pdf`, `web-pdf` und `epub`. Ohne `--output`
werden Ergebnisse nach `<projekt>/Outputs/` geschrieben.

```powershell
go run ./cmd/oa build Projekte/Musterbuch `
  --format print-pdf --format web-pdf --format epub
```

## Lokale Browser-GUI

```powershell
go run ./cmd/oa gui
```

Die GUI bindet nur an `127.0.0.1`, öffnet den Standardbrowser und beendet sich
nach dem Schließen des letzten Tabs. Ohne `--workspace` verwendet sie einen
temporären Arbeitsordner. Mit `--workspace` bleiben importierte Projekte und
Ausgaben zwischen Starts erhalten.

Projekte können über die lokale Verzeichnisfreigabe oder als ZIP importiert
werden. Der Workspace hat diese einfache Struktur:

```text
<workspace>/
└── projects/
    └── <projekt>/
        ├── Strukturierte_Daten/
        ├── Media/
        └── Outputs/
```

## Kleiner gemeinsamer Server

```powershell
go run ./cmd/oa serve --workspace .server-workspace
```

Standardmäßig ist der Server unter `http://127.0.0.1:8080` erreichbar. Alle
Personen verwenden denselben Workspace und sehen dieselben Projekte,
Buildaufträge und Ausgaben. Es läuft höchstens ein Build gleichzeitig; weitere
Buildversuche werden mit einer verständlichen Meldung abgelehnt.

Jobs und Logs existieren nur im Arbeitsspeicher. Nach einem Neustart ist die
Historie leer. Projektquellen und fertige Dateien bleiben im Workspace
erhalten. Ein Backup besteht deshalb nur aus einer Kopie des Workspace.

### Zugriffsschutz

Der Server enthält absichtlich keine eigene Benutzerverwaltung. Er ist für
höchstens sechs vertrauenswürdige Personen in einem kontrollierten Umfeld
gedacht.

- Für rein lokalen Betrieb bleibt die Standardadresse `127.0.0.1:8080`.
- Für entfernten Zugriff ist ein privates Netz/VPN oder ein authentifizierender
  HTTPS-Reverse-Proxy erforderlich.
- Der OA-Port darf nicht ungeschützt ins Internet gestellt werden.

Eine Nginx-Beispielkonfiguration mit HTTP-Basic-Authentifizierung liegt unter
`resources/nginx-oa.conf.example`. Die Zugangsdaten werden dort außerhalb der
OA-Anwendung verwaltet. Eine Bindung wie `--listen 0.0.0.0:8080` darf nur in
einem entsprechend geschützten privaten Netz oder VPN verwendet werden.

## Exitcodes

| Code | Bedeutung |
|---:|---|
| 0 | Befehl erfolgreich |
| 1 | Laufzeit-, Ressourcen- oder Buildfehler |
| 2 | ungültiger CLI-Aufruf |
| 3 | ungültiges Projekt |

## Releasepakete

Die GitHub-Action baut bei einem Tag `v*` native Pakete mit Go-Anwendung,
Java-Runtime, Bibliotheken, Stylesheets und gemeinsamen Ressourcen. Auf dem
Zielsystem werden daher weder Go noch Java noch Gradle benötigt.

## Bewusste Grenzen

- eine einzelne Anwendungsinstanz;
- ein Build zur Zeit;
- ein gemeinsamer Workspace ohne private Benutzerbereiche;
- keine Datenbank und keine dauerhafte Jobhistorie;
- keine eigene Authentifizierung;
- keine verteilten Worker oder horizontale Skalierung.
