# Tests

Die schnellen Komponenten- und CLI-Tests laufen mit:

```text
go test ./...
```

Der separate Integrationstest baut das Musterbuch vollständig als Print-PDF,
Web-PDF und EPUB. Dabei wird das EPUB durch den regulären Buildpfad auch mit
EPUBCheck validiert:

```text
go test -tags=integration ./tests -v
```

Voraussetzung sind eine Java-Laufzeit und die zuvor bereitgestellten
Java-Bibliotheken:

```text
cd java-toolchain
.\gradlew.bat syncRuntimeLibs  (Windows)
./gradlew syncRuntimeLibs      (Linux/macOS)
```

Die mit `jlink` erzeugte minimale Runtime wird explizit getestet, indem
`OA_JAVA` auf deren Java-Binary zeigt:

```powershell
$env:JAVA_HOME = "C:\Pfad\zu\jdk-21"
.\java-toolchain\gradlew.bat -p java-toolchain `
  syncRuntimeLibs jlinkRuntime
$env:OA_JAVA = (Resolve-Path `
  ".\java-toolchain\build\stage\runtime\bin\java.exe")
go test -tags=integration ./tests -v
```
