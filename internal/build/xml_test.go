package build

import (
	"strings"
	"testing"
)

func TestNeutralizeExternalDOCTYPE(t *testing.T) {
	source := "<?xml version=\"1.0\"?>\n<!DOCTYPE book PUBLIC \"id\"\n \"https://example.invalid/book.dtd\">\n<book/>"
	result, err := neutralizeDOCTYPE([]byte(source))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(result), "<!DOCTYPE") || !strings.Contains(string(result), "<book/>") {
		t.Fatalf("unexpected result: %q", result)
	}
	if strings.Count(string(result), "\n") != strings.Count(source, "\n") {
		t.Fatal("neutralizing DOCTYPE changed line count")
	}
}

func TestNeutralizeDOCTYPEIgnoresCommentedDeclaration(t *testing.T) {
	source := "<!-- <!DOCTYPE book SYSTEM \"book.dtd\"> -->\n<book/>"
	result, err := neutralizeDOCTYPE([]byte(source))
	if err != nil {
		t.Fatal(err)
	}
	if string(result) != source {
		t.Fatalf("commented declaration changed: %q", result)
	}
}

func TestNeutralizeDOCTYPERejectsUnclosedDeclaration(t *testing.T) {
	if _, err := neutralizeDOCTYPE([]byte("<!DOCTYPE book")); err == nil {
		t.Fatal("expected error for unclosed DOCTYPE")
	}
}
