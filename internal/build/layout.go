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
