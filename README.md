# OA-Satzsystem

Das OA-Satzsystem ist eine plattformübergreifende Open-Source-Anwendung zur
Erstellung wissenschaftlicher Publikationen. Aus XML-Dateien in BITS-Struktur
erzeugt es Print-PDF, Web-PDF und EPUB. Dafür sind keine Kenntnisse der
zugrunde liegenden Satzwerkzeuge erforderlich.

Die Ausgabe basiert auf standardisierten Stylesheets. Gestaltungsvorgaben
können über die Konfigurationsdateien im Ordner `Stylesheets` angepasst werden.

## Anwendung

Veröffentlichte Pakete stehen unter
[Releases](https://github.com/lilj4ck64/OA-Produktionssystem/releases) für
Windows x64, Linux x64 und macOS ARM64 zur Verfügung. Sie enthalten alle
benötigten Werkzeuge; eine separate Installation von Go oder Java ist nicht
erforderlich.

Nach dem Entpacken wird die lokale Anwendung über `OA-Satzsystem`
beziehungsweise `OA-Satzsystem.exe` gestartet. Die Bedienoberfläche öffnet sich
im Browser. Dort kann ein Projektordner direkt oder alternativ als ZIP-Datei
importiert werden. Die fertigen Dateien werden im Ordner `Outputs` neben der
Anwendung gespeichert. Vollständige Logs liegen im Ordner `Log` als
`Projektname_Datum_Uhrzeit.log`.

Nach einem Build lassen sich Print- und Web-PDF direkt in der Ergebnisansicht
prüfen. Für EPUB steht eine integrierte Vorschau mit Abschnittsnavigation und
Schriftgrößenwahl bereit.

Die Server-GUI akzeptiert ausschließlich ZIP-Dateien. Uploads sind auf 2 GiB,
einzelne entpackte Dateien auf 1 GiB, der gesamte entpackte Inhalt auf 8 GiB und
Archive auf 100.000 Einträge begrenzt. Publikationsdateien und Logs werden dort
zum Download angeboten; ein Log steht auch bei fehlgeschlagenen Builds oder
Importen bereit, sofern es erfolgreich gespeichert werden konnte.

Der Ordner `Example/Musterbuch` enthält ein vollständiges Beispielprojekt.

Beim Import wird ein Projekt nur übernommen, wenn seine Dateistruktur passt und
die XML-Validierung erfolgreich ist. Andernfalls öffnet die GUI das
Validierungslog.

## Projektstruktur

Ein Projekt muss den gleichen Namen wie seine XML-Datei tragen:

```text
Musterbuch/
├── Strukturierte_Daten/
│   └── Musterbuch.xml
└── Media/
    └── Images/
```

## Kommandozeile

Neben der grafischen Oberfläche steht das Programm `oa` für die
Kommandozeile zur Verfügung:

```text
oa validate <projekt>
oa build <projekt> --format <format> [--format <format> ...] [--output <ordner>]
oa gui
oa serve [--listen <loopback-adresse:port>]
```

Unterstützte Formate sind `print-pdf`, `web-pdf` und `epub`. Wird kein
Ausgabeordner angegeben, legt das Programm die Dateien im Unterordner
`Outputs` des Projekts ab.

Beispiel:

```powershell
oa build Example/Musterbuch --format print-pdf --format web-pdf --format epub
```

`oa gui` startet die lokale Browseroberfläche. `oa serve` startet die
ZIP-basierte Server-GUI standardmäßig auf `127.0.0.1:8080`; aus
Sicherheitsgründen werden nur Loopback-Adressen wie `127.0.0.1`, `localhost`
oder `::1` akzeptiert. Eine Übersicht aller Befehle zeigt `oa help`.

## Validierung

Importe und `oa validate` prüfen zuerst die Projektstruktur. Anschließend wird
die XML-Datei gegen die fest mitgelieferte BITS-2.2-DTD und danach gegen
`Schema/schematron.sch` validiert. Eine `DOCTYPE`-Angabe in der XML-Datei wird
ignoriert; maßgeblich ist immer
`Schema/BITS-2-2-DTD/BITS-book2-2.dtd`.

## Entwicklung

Für die Entwicklung werden Go gemäß `go.mod` und JDK 21 benötigt. Die
Java-Bibliotheken und die gebündelte Laufzeitumgebung werden einmalig mit
Gradle bereitgestellt. Die BITS-2.2-DTD wird dabei von der offiziellen
NLM-Quelle heruntergeladen und lokal in `Schema/BITS-2-2-DTD` entpackt:

```powershell
cd java-toolchain
.\gradlew.bat syncRuntimeLibs jlinkRuntime syncBitsDtd
cd ..
go run ./cmd/oa gui
```

Unter Linux und macOS wird `./gradlew` anstelle von `gradlew.bat` verwendet.
Die heruntergeladene DTD wird nicht mit Git versioniert. Nach einem frischen
Checkout kann sie jederzeit separat wiederhergestellt werden:

```powershell
cd java-toolchain
.\gradlew.bat syncBitsDtd
```

## Lizenz

Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Das OA-Satzsystem ist freie Software und wird unter der GNU General Public
License Version 3 veröffentlicht. Weitere Informationen enthält die Datei
[LICENSE](LICENSE).
