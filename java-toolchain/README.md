# OA Java toolchain

This Gradle build downloads the Java tools required by OA with fixed and locked
versions. A full JDK is currently required.

On Linux or macOS:

```sh
./gradlew syncRuntimeLibs writeRuntimeManifest jlinkRuntime
./gradlew verifyToolVersions
```

On Windows:

```powershell
.\gradlew.bat syncRuntimeLibs writeRuntimeManifest jlinkRuntime
.\gradlew.bat verifyToolVersions
```

Generated JARs live in `build/stage/lib/` and are intentionally ignored by
Git. `jdeps` writes the detected module list to
`build/stage/runtime-modules.txt`; `jlinkRuntime` combines it with the modules
needed by dynamically loaded font, image, XML and security providers and
creates `build/stage/runtime/`. Use JDK 21, which is also fixed in the release
workflow.

Update dependencies deliberately by changing the version in
`build.gradle.kts`, then regenerate the lock file:

```powershell
.\gradlew.bat dependencies --configuration runtimeLibs --write-locks
```
