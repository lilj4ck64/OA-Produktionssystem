# Java toolchain: third-party notices

The runtime JARs are downloaded from Maven Central by Gradle. No downloaded
JAR is committed to this repository.

## Direct dependencies

| Component | Version | License | Project |
| --- | ---: | --- | --- |
| Apache FOP | 2.11 | Apache License 2.0 | <https://xmlgraphics.apache.org/fop/> |
| Saxon-HE | 12.9 | Mozilla Public License 2.0 | <https://www.saxonica.com/> |
| EPUBCheck | 5.3.0 | BSD 3-Clause License | <https://www.w3.org/publishing/epubcheck/> |

These components pull in further runtime dependencies. The exact, locked
dependency set is recorded in `gradle.lockfile`. Running
`./gradlew writeRuntimeManifest` also writes the resolved inventory to
`build/stage/licenses/runtime-components.txt`.

Before distributing a release, copy the license and notice files required by
every entry in that inventory into the release's `licenses/` directory. This
repository file is an inventory and attribution record; it does not replace
the license texts shipped by the upstream projects.
