# Technische Analyse und vereinfachte MVP-Strategie

## Ziel

Das OA-Satzsystem soll aus einer BITS-XML-Datei und den zugehörigen Ressourcen
Print-PDF, Web-PDF und EPUB erzeugen.

Das MVP gilt als erreicht, wenn:

- eine lokale CLI funktioniert,
- eine lokale grafische Oberfläche funktioniert,
- dieselbe Anwendung als kleiner Server mit Weboberfläche funktioniert,
- der Endanwender weder Go noch Java, Gradle, Docker oder andere Werkzeuge
  installieren muss,
- für Windows, macOS und Linux automatisch selbstenthaltende Releases gebaut
  werden,
- jedes Release FOP, Saxon, EPUBCheck und eine minimale Java-Runtime enthält.

## Bewusste Entscheidungen

### Go ist die einzige Anwendungslogik

Der vorhandene Python-Code war nur ein Test und wird nicht weiterverwendet.
Die neue Anwendung wird in Go geschrieben.

Go übernimmt:

- CLI und Kommandozeilenargumente,
- lokale und serverseitige Weboberfläche,
- Projektprüfung,
- Verzeichnis- und Dateiverarbeitung,
- Erzeugen des EPUB-ZIP-Containers,
- Start und Überwachung der Java-Prozesse,
- Fortschritt, Logs und Fehlerbehandlung,
- lokale Jobverwaltung,
- im Servermodus zusätzlich Authentifizierung und Benutzerzuordnung.

### Shell- und Batchskripte werden entfernt

Die Dateien `*.sh` und `*.bat` sollen nicht repariert oder als langfristige
Schnittstelle erhalten werden. Ihre Aufgaben werden direkt in Go umgesetzt.

Java-Prozesse werden mit `os/exec` und getrennten Argumenten gestartet. Es wird
keine Shell dazwischengeschaltet. Dadurch entfallen:

- unterschiedliche Windows-/Unix-Skripte,
- Abhängigkeiten von Bash, ZIP, `cp`, `rm`, `open` oder 7-Zip,
- Probleme mit Leerzeichen und Shell-Sonderzeichen,
- viele plattformspezifische Fehlerquellen.

### Gradle verwaltet nur die Java-Toolchain

Gradle ist nicht Teil der Anwendungslogik. Es soll ausschließlich:

- FOP, Saxon und EPUBCheck mit ihren transitiven Abhängigkeiten beziehen,
- Versionen und Abhängigkeiten sperren,
- die JAR-Dateien in ein Release-Verzeichnis kopieren,
- eine minimale Java-Runtime mit `jlink` erzeugen,
- bei Bedarf das vollständige Distributionsverzeichnis zusammenstellen.

Gradle eignet sich hierfür besser als Maven, weil das Projekt keine eigentliche
Java-Anwendung baut, sondern eine benutzerdefinierte Distribution aus Go-Binary,
Java-Runtime, JARs und Ressourcen erzeugt. Maven wäre ebenfalls möglich, würde
für diesen Anwendungsfall aber keinen deutlichen Vorteil bringen.

Die Gradle-Konfiguration soll klein bleiben. Ein einzelnes
`build.gradle.kts`, `settings.gradle.kts`, der Gradle Wrapper und eine
Dependency-Lockdatei reichen zunächst aus.

### Eine Weboberfläche für lokal und Server

Es wird kein zusätzliches natives GUI-Framework in das MVP aufgenommen.

Die Go-Anwendung stellt zwei Betriebsarten bereit:

```text
oa gui
oa serve
```

`oa gui` startet den HTTP-Server ausschließlich auf `127.0.0.1`, wählt einen
freien Port und öffnet den Standardbrowser. HTML, CSS und JavaScript werden mit
`go:embed` in das Go-Binary eingebettet.

Eine Browserseite kann aus Sicherheitsgründen keinen beliebigen lokalen
Ordnerpfad an die Go-Anwendung übergeben. Deshalb verwendet die lokale GUI
einen festen Anwendungs-Workspace und importiert Projekte per ZIP bzw.
Drag-and-drop.
Die CLI darf weiterhin direkt mit einem vorhandenen Projektordner arbeiten.

`oa serve` verwendet dieselben Seiten und Anwendungsfälle, ergänzt aber:

- Login,
- Benutzerzuordnung,
- persistente Jobs,
- Upload und Download,
- serverseitiges Datenverzeichnis,
- Begrenzung paralleler Builds.

So gibt es nur eine GUI-Codebasis und keine getrennte Desktop- und
Serveroberfläche.

### Noch keine allgemeine TOML-Projektkonfiguration

Ein öffentliches TOML-Schema ist vor dem MVP nicht sinnvoll. Es ist noch nicht
klar, welche Einstellungen Anwender tatsächlich benötigen.

Für das MVP gelten:

- feste und dokumentierte Projektstruktur,
- Buildoptionen als CLI-Optionen bzw. GUI-Felder,
- bestehende XSLT-/FOP-Konfigurationen bleiben zunächst erhalten,
- optionale Projekt-Overrides dürfen in einem festgelegten Unterordner liegen,
- Servereinstellungen kommen aus CLI-Optionen und Umgebungsvariablen.

Im Go-Code soll trotzdem früh ein kleines internes `BuildOptions`-Modell
existieren. Das verhindert hartcodierte Optionen, ohne bereits ein dauerhaftes
Dateiformat festzulegen.

## Wichtigste Probleme der aktuellen Version

### 1. Stark veraltete Java-Runtime

Unter `Werkzeuge/Java/` liegt Java `1.7.0_07` aus dem Jahr 2012 einschließlich
eines alten Windows-Installers. Diese Runtime darf nicht in ein neues Release
übernommen werden.

**Lösung:**

- aktuelle LTS-Java-Version für den Build festlegen,
- minimale Runtime je Betriebssystem mit `jlink` erzeugen,
- Runtime zusammen mit der Anwendung ausliefern,
- Java-Version regelmäßig über automatisierte Dependency-Updates erneuern.

`jlink` erzeugt aus ausgewählten Java-Modulen ein eigenes Runtime-Image. Dieses
Image ist plattformspezifisch und muss daher in den jeweiligen
GitHub-Actions-Runnern gebaut werden:
[Oracle jlink](https://docs.oracle.com/en/java/javase/11/tools/jlink.html).

### 2. Defekte und widersprüchliche Skripte

Die vorhandenen Skripte sind nicht zuverlässig plattformübergreifend:

- Shellskripte verwenden unquotierte Projektpfade.
- Der zentrale Shellworkflow löscht Ergebnisse mit `rm -rf`.
- Batchskripte erwarten eine nicht gesetzte Variable `%Projektname%`.
- `02_pdf-print.bat` enthält einen fehlerhaften Stylesheetpfad.
- `04_epub.bat` verweist auf ein nicht vorhandenes Saxon-Verzeichnis.
- Skripte kopieren aus `Fonts/`, obwohl global nur `Shared/Fonts/` existiert.
- Linux/macOS-Kommandos wie `open` oder `zip` werden vorausgesetzt.
- Fehler einzelner Befehle führen nicht sicher zu einem fehlgeschlagenen Job.

**Lösung:** Skripte nicht weiterentwickeln, sondern ihre fachlichen Schritte
einzeln nach Go übertragen und anschließend löschen.

### 3. Fremdwerkzeuge und Projektdateien sind vermischt

`Werkzeuge/` enthält eine vollständige alte Java-Installation, mehrere
XML-Parser, doppelte Bibliotheken, 7-Zip, Kindlegen und verschiedene
plattformabhängige Programme. Generierte Musterbuch-Ausgaben liegen direkt
neben den Quellen.

**Lösung:**

- nur FOP, Saxon und EPUBCheck als relevante Java-Werkzeuge übernehmen,
- 7-Zip durch Go `archive/zip` ersetzen,
- Kindlegen und MOBI aus dem MVP entfernen,
- Java-Installer, alte Runtime, Xalan-/Xerces-Duplikate und tote Werkzeuge
  entfernen,
- Quellen, Buildoutputs und Release-Artefakte klar trennen,
- Fremdlizenzen und Versionsinformationen automatisch ins Release kopieren.

### 4. Keine sichere und atomare Buildausführung

Aktuell wird direkt in den endgültigen Ausgabeordner geschrieben. Der zentrale
Workflow löscht vorherige Ergebnisse. Bei einem Fehler können gültige
Ergebnisse verloren gehen oder unvollständige neue Dateien zurückbleiben.

**Lösung:**

Jeder Build arbeitet in einem eigenen temporären Verzeichnis:

```text
data/work/<job-id>/
```

Erst wenn alle gewählten Formate erzeugt und geprüft wurden, werden sie nach

```text
data/projects/<project-id>/builds/<build-id>/
```

verschoben. Ein fehlgeschlagener Build darf den letzten erfolgreichen Build
nicht verändern.

### 5. Erfolg wird nicht ausreichend geprüft

Ein Prozess mit Exitcode 0 bedeutet noch nicht, dass ein korrektes Artefakt
entstanden ist. Die aktuelle Verarbeitung überprüft erzeugte Dateien nicht
systematisch.

**Lösung:**

- erwartete Datei muss existieren und darf nicht leer sein,
- EPUB wird immer mit EPUBCheck geprüft,
- PDF wird mindestens geöffnet, auf Seitenzahl geprüft und auf schwerwiegende
  FOP-Warnungen untersucht,
- jeder Schritt liefert einen eigenen Status und verständliche Fehlermeldung,
- nur vollständig geprüfte Artefakte werden veröffentlicht.

EPUBCheck wird offiziell als Kommandozeilenwerkzeug und Java-Bibliothek
bereitgestellt und ist über Maven Central verfügbar:
[EPUBCheck](https://github.com/w3c/epubcheck).

### 6. Pfade und XML-Werte werden nicht ausreichend begrenzt

Projektname, XML-Inhalte und Ressourcen können in Dateipfade einfließen.
Besonders `xsl:result-document` erzeugt mehrere EPUB-Dateien und verwendet
teilweise Werte aus dem XML für Dateinamen.

**Lösung für das MVP:**

- intern zufällige Job-IDs statt Benutzernamen als Arbeitsverzeichnis,
- alle Pfade mit `filepath.Abs` und `filepath.Rel` gegen das Jobverzeichnis
  prüfen,
- erlaubte Dateinamen zentral bereinigen,
- absolute Pfade und `..` ablehnen,
- Uploadarchive kontrolliert in Go entpacken,
- externe XML-Entitäten und Netzwerkzugriffe deaktivieren,
- Java-Prozesse mit Zeitlimit und festem Arbeitsverzeichnis starten.

Im lokalen Modus sind diese Regeln ebenfalls sinnvoll. Im Servermodus sind sie
verpflichtend.

### 7. Keine reproduzierbaren Releases

Es gibt keine Builddefinition für eine vollständige Anwendung, keine
automatischen Plattform-Releases, keine Dependency Locks und keine
systematischen Smoke-Tests.

**Lösung:** GitHub Actions baut auf einem Versionstag jede Zielplattform
separat und veröffentlicht nur getestete Artefakte.

## Vereinfachte Zielarchitektur

```text
                         +----------------+
                         |   CLI-Befehle  |
                         +-------+--------+
                                 |
               +-----------------v-----------------+
               |          Go Build-Service         |
               | Validierung, Jobs, Logs, Outputs  |
               +--+-------------+-------------+----+
                  |             |             |
                  v             v             v
               Saxon           FOP        EPUBCheck
                  \             |             /
                   +---- gebündelte JRE -----+

               +-----------------------------+
               | eingebettete Weboberfläche |
               +-------------+---------------+
                             |
                   +---------+---------+
                   |                   |
                oa gui             oa serve
                localhost          Servermodus
```

### Vorgeschlagene Befehle

```text
oa build <projektpfad> --format print-pdf --format web-pdf --format epub
oa validate <projektpfad>
oa gui
oa serve
oa doctor
oa version
```

`oa doctor` soll die gebündelte Java-Runtime, alle JARs, Schreibrechte und
Werkzeugversionen prüfen. Das vereinfacht Support und Release-Smoke-Tests.

### Vorgeschlagene Projektstruktur

```text
.
├── cmd/oa/                    # Einstiegspunkt
├── internal/
│   ├── build/                 # Ablauf und Jobstatus
│   ├── project/               # Projektprüfung
│   ├── java/                  # FOP/Saxon/EPUBCheck-Aufrufe
│   ├── epub/                  # ZIP-Erzeugung
│   ├── web/                   # lokale und Server-Weboberfläche
│   ├── auth/                  # nur Servermodus
│   └── storage/               # lokale/Server-Datenablage
├── web/                       # eingebettetes HTML/CSS/JS
├── resources/
│   ├── xslt/
│   ├── styles/
│   ├── fonts/
│   └── profiles/
├── java-toolchain/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── gradlew
│   ├── gradlew.bat
│   └── gradle/
├── examples/Musterbuch/
├── tests/
├── packaging/
└── .github/workflows/
```

Für das erste MVP kann diese Struktur noch kleiner beginnen. Neue Pakete sollen
erst entstehen, wenn eine Datei oder Verantwortung tatsächlich zu groß wird.

## Zusammenspiel von Go und Java

Go startet die gebündelte Java-Runtime direkt:

```text
<app>/runtime/bin/java
```

Die drei relevanten Schritte sind:

1. Saxon transformiert BITS-XML und erzeugt die EPUB-Inhalte.
2. FOP erzeugt Print- und Web-PDF.
3. EPUBCheck validiert das von Go gepackte EPUB.

FOP kann ohne seine Shellskripte über
`org.apache.fop.cli.Main` gestartet werden:
[Apache FOP – Running FOP](https://xmlgraphics.apache.org/fop/trunk/running.html).

Für das MVP ist ein separater Java-Wrapper nicht zwingend nötig. Go kann die
offiziellen Main-Klassen direkt aufrufen. Erst wenn sichere Resolver oder
komplexere Integration über CLI-Optionen nicht sauber umsetzbar sind, ist ein
kleines Java-Runner-Modul gerechtfertigt.

## Releaseformat

### Kein erzwungenes Single-File-Paket

Eine wirklich einzelne Datei pro Betriebssystem ist mit einer Java-Runtime
unnötig kompliziert. Empfohlen wird ein selbstenthaltendes App-Verzeichnis:

```text
oa-satzsystem/
├── oa bzw. oa.exe
├── runtime/
├── lib/
├── resources/
└── licenses/
```

Dieses Verzeichnis wird als ZIP, TAR oder Installer ausgeliefert. Der
Endanwender installiert trotzdem keine zusätzliche Software.

Runtime und JARs in das Go-Binary einzubetten und beim Start zu extrahieren
wäre möglich, bringt aber Nachteile:

- längerer erster Start,
- doppelter Speicherbedarf,
- schwierigere Updates und Signaturen,
- mehr temporäre Dateien,
- mögliche Warnungen von Virenscannern.

### Zielplattformen

Für das MVP sollte die Plattformliste bewusst klein sein:

- Windows x64,
- Linux x64,
- macOS ARM64,
- optional macOS x64, wenn reale Nutzer dies benötigen.

Jede Plattform erhält ein eigenes Release. Eine minimale JRE ist
plattformabhängig und wird auf dem passenden GitHub-Runner erzeugt.

### GitHub-Actions-Release

Bei einem Tag wie `v0.1.0`:

1. Go-Tests ausführen.
2. Java-Abhängigkeiten mit Gradle und Lockdatei auflösen.
3. minimale JRE mit `jlink` erzeugen.
4. Go-Binary für den Runner bauen.
5. Ressourcen und Lizenzen kopieren.
6. Musterbuch vollständig erzeugen.
7. EPUBCheck und einfache PDF-Prüfung ausführen.
8. Distributionsarchiv bauen.
9. SHA-256-Prüfsumme erzeugen.
10. Artefakte in einem GitHub Release veröffentlichen.

Gradles Distribution Plugin kann Anwendungsdateien und unterstützende Dateien
als ZIP/TAR zusammenstellen:
[Gradle Distribution Plugin](https://docs.gradle.org/current/userguide/distribution_plugin.html).
Für reproduzierbare Java-Abhängigkeiten soll Dependency Locking aktiviert
werden:
[Gradle Dependency Locking](https://docs.gradle.org/current/userguide/dependency_locking.html).

Signierung und macOS-Notarisierung können nach dem ersten technischen MVP
ergänzt werden, gehören aber vor einer breiten öffentlichen Verteilung zur
Produktreife.

## Lokaler Modus

### CLI

Die CLI ist die erste Oberfläche und Referenzimplementierung. Alle späteren
Oberflächen rufen dieselben Go-Funktionen auf.

In der CLI wählt der lokale Nutzer ein Projektverzeichnis und einen Ausgabeort.
Die CLI kann dafür direkte Pfade verwenden. Die Anwendung verwendet keine
Datenbank und benötigt keine Anmeldung.

### GUI

`oa gui`:

- bindet nur an `127.0.0.1`,
- verwendet einen zufälligen freien Port,
- öffnet den Standardbrowser,
- verwendet einen festen Workspace im Benutzer-Datenverzeichnis,
- importiert Projekte per ZIP bzw. Drag-and-drop,
- zeigt Fortschritt und Logs,
- bietet Artefakte zum Öffnen an,
- beendet den lokalen Server beim Programmende.

Die HTML-, CSS- und JavaScript-Dateien werden mit Go eingebettet:
[Go embed](https://pkg.go.dev/embed).

## Servermodus

Der Servermodus soll für wenige Nutzer bewusst klein bleiben.

### MVP-Funktionen

- Login und Logout,
- Benutzerrollen `admin` und `user`,
- Projekt als ZIP hochladen,
- Formate auswählen und Build starten,
- Status und Log anzeigen,
- eigene Artefakte herunterladen,
- eigene Builds löschen,
- Admin kann Benutzer anlegen/deaktivieren.

### Einfache Technik

- Go `net/http` oder ein kleiner HTTP-Router,
- serverseitig gerenderte HTML-Templates,
- SQLite,
- Jobqueue als begrenzter Go-Channel,
- ein oder wenige lokale Worker,
- Dateien auf dem Serverdateisystem.

Für das MVP sind kein React, Redis, PostgreSQL, Kubernetes, Microservices oder
eine verteilte Queue erforderlich.

### Unverzichtbare Sicherheit

Auch ein kleiner Server braucht:

- Passworthashes mit Argon2id oder bcrypt,
- sichere Session-Cookies,
- CSRF-Schutz,
- Login-Rate-Limit,
- Upload- und Speicherlimits,
- sichere ZIP-Extraktion,
- Job-Timeouts,
- Berechtigungsprüfung bei jedem Download,
- Betrieb hinter HTTPS.

Der Server soll standardmäßig nur an Loopback binden. Öffentliches TLS wird
zunächst durch einen Reverse Proxy bereitgestellt. Eigene automatische
Zertifikatsverwaltung ist kein MVP-Bestandteil.

## Was ausdrücklich nicht zum MVP gehört

- native Desktop-GUI zusätzlich zur Weboberfläche,
- TOML-Schema für alle Layoutparameter,
- Plugin-System,
- MOBI und Kindlegen,
- verteilte Worker,
- Redis oder PostgreSQL,
- Kubernetes,
- Mandantenfähigkeit,
- SSO/OIDC,
- automatische Updates im Client,
- visuelle PDF-Diff-Plattform,
- vollständige Online-Projektbearbeitung.

Diese Punkte dürfen erst aufgenommen werden, wenn ein tatsächlicher Bedarf
entsteht.

## Definition of Done für das MVP

Das MVP ist fertig, wenn:

- `oa build` Print-PDF, Web-PDF und EPUB ohne Shellskript erzeugt,
- `oa gui` lokal im Browser vollständig funktioniert,
- `oa serve` für wenige Benutzer mit Anmeldung funktioniert,
- alle drei Modi denselben Go-Build-Service verwenden,
- Saxon, FOP und EPUBCheck über die gebündelte Runtime laufen,
- der Rechner des Endanwenders kein vorinstalliertes Java oder Go benötigt,
- Builds in isolierten Arbeitsverzeichnissen laufen,
- fehlgeschlagene Builds keine gültigen Ausgaben überschreiben,
- EPUBCheck automatisch ausgeführt wird,
- manipulierte ZIP-Pfade das Arbeitsverzeichnis nicht verlassen können,
- GitHub Actions für jede unterstützte Plattform ein getestetes Release baut,
- jedes Release Runtime, JARs, Ressourcen, Lizenzen und Prüfsumme enthält,
- das Musterbuch in jedem Release-Workflow erfolgreich gebaut wird.

## Wichtigste Leitlinie

Das MVP benötigt keine große Plattformarchitektur. Es benötigt einen
zuverlässigen Go-Build-Service, eine kleine gemeinsame Weboberfläche und eine
reproduzierbar gebaute Java-Toolchain.

Die Reihenfolge ist entscheidend:

1. Buildpipeline in Go,
2. CLI,
3. lokale Web-GUI,
4. Releases,
5. Servermodus und Authentifizierung.

Jede Stufe verwendet die bereits getestete vorherige Stufe und führt keine
zweite Implementierung derselben Fachlogik ein.
