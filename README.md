# OA-Satzsystem

Das OA-Satzsystem ist eine plattformübergreifende Open-Source-Anwendung zur
Erstellung wissenschaftlicher Publikationen. Aus XML-Dateien in BITS-Struktur
erzeugt es Print-PDF, Web-PDF und EPUB. Dafür sind keine Kenntnisse der
zugrunde liegenden Satzwerkzeuge erforderlich.

Die Ausgabe basiert auf standardisierten Stylesheets. Gestaltungsvorgaben
können über die Konfigurationsdateien im Ordner `Stylesheets` angepasst werden.

## Anwendung

Fertige Pakete für Windows, Linux und macOS stehen unter
[Releases](https://github.com/lilj4ck64/OA-Produktionssystem/releases) zur
Verfügung. Sie enthalten alle benötigten Werkzeuge; eine separate Installation
von Go oder Java ist nicht erforderlich.

Nach dem Entpacken wird die Anwendung über `OA-Satzsystem` beziehungsweise
`OA-Satzsystem.exe` gestartet. Die Bedienoberfläche öffnet sich im Browser.
Dort kann ein Projektordner oder eine ZIP-Datei ausgewählt und anschließend in
den gewünschten Formaten ausgegeben werden. Die fertigen Dateien werden im
Ordner `Outputs` neben der Anwendung gespeichert.

Der Ordner `Example/Musterbuch` enthält ein vollständiges Beispielprojekt.

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
```

Unterstützte Formate sind `print-pdf`, `web-pdf` und `epub`. Wird kein
Ausgabeordner angegeben, legt das Programm die Dateien im Unterordner
`Outputs` des Projekts ab.

Beispiel:

```powershell
oa build Example/Musterbuch --format print-pdf --format web-pdf --format epub
```

Eine Übersicht aller Befehle zeigt `oa help`.

## Entwicklung

Für die Entwicklung werden Go gemäß `go.mod` und JDK 21 benötigt. Die
Java-Bibliotheken und die gebündelte Laufzeitumgebung werden einmalig mit
Gradle bereitgestellt:

```powershell
cd java-toolchain
.\gradlew.bat syncRuntimeLibs jlinkRuntime
cd ..
go run ./cmd/oa gui
```

Unter Linux und macOS wird `./gradlew` anstelle von `gradlew.bat` verwendet.

## Lizenz

Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Das OA-Satzsystem ist freie Software und wird unter der GNU General Public
License Version 3 veröffentlicht. Weitere Informationen enthält die Datei
[LICENSE](LICENSE).
