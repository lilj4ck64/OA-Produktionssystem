package build

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"oa-satzsystem/internal/java"
)

const schXsltCLIJARPrefix = "cli-"

type applicationLayout struct {
	resources string
	lib       string
}

// resolveLayout hides the only important directory difference between a
// developer checkout and an installed release from the rest of the builder.
func resolveLayout(root string) applicationLayout {
	// Release archives keep all immutable data beside the executable.
	packagedResources := filepath.Join(root, "resources")
	packagedLib := filepath.Join(root, "lib")
	if isDirectory(filepath.Join(packagedResources, "Stylesheets")) && isDirectory(packagedLib) {
		return applicationLayout{resources: packagedResources, lib: packagedLib}
	}

	// The repository layout remains convenient for development and tests.
	return applicationLayout{
		resources: root,
		lib:       filepath.Join(root, "java-toolchain", "build", "stage", "lib"),
	}
}

func (e Engine) javaRunner(root string) java.Runner {
	// A caller-supplied Java executable is useful in tests. Otherwise prefer the
	// small runtime shipped with the application and fall back to system Java
	// only while developing from source.
	if e.Java.Executable != "" {
		return e.Java
	}
	name := "java"
	if filepath.Separator == '\\' {
		name = "java.exe"
	}
	bundled := filepath.Join(root, "runtime", "bin", name)
	if info, err := os.Stat(bundled); err == nil && info.Mode().IsRegular() {
		return java.Runner{Executable: bundled}
	}
	return e.Java
}

func isDirectory(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

// sharedJavaClasspath returns the libraries used by the regular Java tools.
// SchXslt's CLI artifact is deliberately omitted: it is a fat JAR containing
// its own unsigned Saxon classes and is run in isolation by ValidateXML. Mixing
// it with the separately signed Saxon JAR makes the JVM reject the package.
func sharedJavaClasspath(libDir string) (string, error) {
	entries, err := os.ReadDir(libDir)
	if err != nil {
		return "", fmt.Errorf("Java-Bibliotheksverzeichnis lesen: %w", err)
	}
	var jars []string
	for _, entry := range entries {
		name := entry.Name()
		if !entry.Type().IsRegular() || !strings.HasSuffix(strings.ToLower(name), ".jar") {
			continue
		}
		if strings.HasPrefix(name, schXsltCLIJARPrefix) {
			continue
		}
		jars = append(jars, filepath.Join(libDir, name))
	}
	if len(jars) == 0 {
		return "", fmt.Errorf("keine Java-Bibliotheken in %s gefunden", libDir)
	}
	sort.Strings(jars)
	return strings.Join(jars, string(os.PathListSeparator)), nil
}
