package build

import (
	"os"
	"path/filepath"

	"oa-satzsystem/internal/java"
)

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
