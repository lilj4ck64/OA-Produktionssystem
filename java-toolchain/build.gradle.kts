import org.gradle.api.tasks.JavaExec
import org.gradle.api.tasks.Sync
import org.gradle.api.attributes.Bundling
import org.gradle.api.attributes.Category
import org.gradle.api.attributes.LibraryElements
import org.gradle.api.attributes.Usage
import org.gradle.api.attributes.java.TargetJvmEnvironment

plugins {
    base
}

val fopVersion = "2.11"
val saxonVersion = "12.9"
val epubCheckVersion = "5.3.0"

val runtimeLibs = configurations.create("runtimeLibs") {
    description = "JARs required to run FOP, Saxon HE, and EPUBCheck"
    isCanBeConsumed = false
    isCanBeResolved = true
    attributes {
        attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage.JAVA_RUNTIME))
        attribute(Category.CATEGORY_ATTRIBUTE, objects.named(Category.LIBRARY))
        attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements.JAR))
        attribute(Bundling.BUNDLING_ATTRIBUTE, objects.named(Bundling.EXTERNAL))
        attribute(
            TargetJvmEnvironment.TARGET_JVM_ENVIRONMENT_ATTRIBUTE,
            objects.named(TargetJvmEnvironment.STANDARD_JVM),
        )
    }
}

dependencies {
    runtimeLibs("org.apache.xmlgraphics:fop:$fopVersion")
    runtimeLibs("net.sf.saxon:Saxon-HE:$saxonVersion")
    runtimeLibs("org.w3c:epubcheck:$epubCheckVersion") {
        exclude(group = "org.slf4j", module = "slf4j-nop")
    }
    // EPUBCheck otherwise contributes slf4j-nop, which silently discards all
    // FOP page, image and warning messages needed by the GUI build log.
    runtimeLibs("org.slf4j:slf4j-simple:1.7.36")
}

dependencyLocking {
    lockAllConfigurations()
}

val syncRuntimeLibs = tasks.register<Sync>("syncRuntimeLibs") {
    group = "distribution"
    description = "Synchronizes all Java runtime JARs into build/stage/lib."
    from(runtimeLibs)
    into(layout.buildDirectory.dir("stage/lib"))
}

fun registerVersionTask(
    taskName: String,
    toolName: String,
    mainClassName: String,
    arguments: List<String>,
) = tasks.register<JavaExec>(taskName) {
    group = "verification"
    description = "Prints the $toolName version."
    dependsOn(syncRuntimeLibs)
    classpath = fileTree(layout.buildDirectory.dir("stage/lib")) {
        include("*.jar")
    }
    mainClass.set(mainClassName)
    args(arguments)
}

val fopVersionTask = registerVersionTask(
    taskName = "fopVersion",
    toolName = "Apache FOP",
    mainClassName = "org.apache.fop.cli.Main",
    arguments = listOf("-version"),
)

val saxonVersionTask = registerVersionTask(
    taskName = "saxonVersion",
    toolName = "Saxon HE",
    mainClassName = "net.sf.saxon.Version",
    arguments = emptyList(),
)

val epubCheckVersionTask = registerVersionTask(
    taskName = "epubCheckVersion",
    toolName = "EPUBCheck",
    mainClassName = "com.adobe.epubcheck.tool.Checker",
    arguments = listOf("--version"),
)

tasks.register("verifyToolVersions") {
    group = "verification"
    description = "Runs the version command for all staged Java tools."
    dependsOn(fopVersionTask, saxonVersionTask, epubCheckVersionTask)
}

val runtimeModulesFile = layout.buildDirectory.file("stage/runtime-modules.txt")

tasks.register<Exec>("analyzeRuntimeModules") {
    group = "distribution"
    description = "Uses jdeps to determine the Java modules referenced by all runtime JARs."
    dependsOn(syncRuntimeLibs)
    inputs.files(runtimeLibs)
    outputs.file(runtimeModulesFile)

    doFirst {
        val executable = file(
            "${System.getProperty("java.home")}/bin/jdeps${if (System.getProperty("os.name").startsWith("Windows")) ".exe" else ""}",
        )
        require(executable.isFile) { "jdeps not found in the Gradle JDK: $executable" }
        val destination = runtimeModulesFile.get().asFile
        destination.parentFile.mkdirs()
        standardOutput = destination.outputStream()
        commandLine(
            executable,
            "--ignore-missing-deps",
            "--multi-release",
            "base",
            "--print-module-deps",
            *runtimeLibs.files.sortedBy { it.name }.toTypedArray(),
        )
    }
    doLast {
        val destination = runtimeModulesFile.get().asFile
        val modules = destination.readLines()
            .map(String::trim)
            .lastOrNull { it.matches(Regex("[a-zA-Z0-9.,]+")) }
            ?: error("jdeps did not report Java modules")
        destination.writeText(modules + "\n")
        logger.lifecycle("jdeps modules: $modules")
    }
}

tasks.register<Exec>("jlinkRuntime") {
    group = "distribution"
    description = "Creates the minimal native Java runtime in build/stage/runtime."
    dependsOn("analyzeRuntimeModules")
    inputs.file(runtimeModulesFile)
    outputs.dir(layout.buildDirectory.dir("stage/runtime"))

    doFirst {
        val suffix = if (System.getProperty("os.name").startsWith("Windows")) ".exe" else ""
        val executable = file("${System.getProperty("java.home")}/bin/jlink$suffix")
        require(executable.isFile) { "jlink not found in the Gradle JDK: $executable" }

        // jdeps cannot see reflection and service-provider loading. These
        // modules cover FOP font/image codecs, Saxon XML handling and HTTPS.
        val dynamicModules = setOf(
            "java.logging",
            "java.management",
            "java.naming",
            "java.net.http",
            "java.xml",
            "jdk.crypto.ec",
            "jdk.xml.dom",
        )
        val detected = runtimeModulesFile.get().asFile.readText().trim()
            .split(",")
            .filter(String::isNotBlank)
        val modules = (detected + dynamicModules).toSortedSet().joinToString(",")
        val destination = layout.buildDirectory.dir("stage/runtime").get().asFile
        delete(destination)
        commandLine(
            executable,
            "--add-modules",
            modules,
            "--bind-services",
            "--no-header-files",
            "--no-man-pages",
            "--strip-debug",
            "--compress=zip-6",
            "--output",
            destination,
        )
        logger.lifecycle("jlink modules: $modules")
    }
}
