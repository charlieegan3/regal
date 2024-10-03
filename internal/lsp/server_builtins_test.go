package lsp

import (
	"context"
	"testing"
)

// https://github.com/StyraInc/regal/issues/679
func TestProcessBuiltinUpdateExitsOnMissingFile(t *testing.T) {
	t.Parallel()

	ls := NewLanguageServer(context.Background(), &LanguageServerOptions{
		ErrorLog: newTestLogger(t),
	})

	if err := ls.processHoverContentUpdate(context.Background(), "file://missing.rego", "foo"); err != nil {
		t.Fatal(err)
	}

	if l := len(ls.cache.GetAllBuiltInPositions()); l != 0 {
		t.Errorf("expected builtin positions to be empty, got %d items", l)
	}

	contents, ok := ls.cache.GetFileContents("file://missing.rego")
	if ok {
		t.Errorf("expected file contents to be empty, got %s", contents)
	}

	if len(ls.cache.GetAllFiles()) != 0 {
		t.Errorf("expected files to be empty, got %v", ls.cache.GetAllFiles())
	}
}