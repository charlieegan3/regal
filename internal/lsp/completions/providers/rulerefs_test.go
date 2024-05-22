package providers

import (
	"slices"
	"testing"

	"github.com/styrainc/regal/internal/lsp/cache"
	"github.com/styrainc/regal/internal/lsp/completions/refs"
	"github.com/styrainc/regal/internal/lsp/types"
	"github.com/styrainc/regal/internal/parse"
)

func TestRuleFromImportedPackageRefs(t *testing.T) {
	t.Parallel()

	c := cache.NewCache()

	currentlyEditingFileContents := `package example

	import data.foo
	import data.bar
	import data.baz`

	regoFiles := map[string]string{
		"file:///foo/foo.rego": `package foo

bar := true
`,
		"file:///bar/bar.rego": `package bar

import rego.v1

default allow := false

allow if input.admin
`,
		"file:///baz/baz.rego": `package baz

funkyfunc(x) := true
`,
		"file:///not/imported.rego": `package notimported

deny := false
`,
		"file:///example.rego": currentlyEditingFileContents,
	}

	for uri, contents := range regoFiles {
		mod, err := parse.Module(uri, contents)
		if err != nil {
			t.Fatalf("Unexpected error when parsing %s contents: %v", uri, err)
		}

		c.SetModule(uri, mod)

		c.SetFileRefs(uri, refs.ForModule(mod))
	}

	c.SetFileContents("file:///example.rego", currentlyEditingFileContents+"\n\nallow if ")

	p := &RuleFromImportedPackageRefs{}

	completionParams := types.CompletionParams{
		TextDocument: types.TextDocumentIdentifier{
			URI: "file:///example.rego",
		},
		Position: types.Position{
			Line:      6,
			Character: 8,
		},
	}

	completions, err := p.Run(c, completionParams, nil)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	expectedRefs := []string{"foo.bar", "bar.allow", "baz.funkyfunc"}
	slices.Sort(expectedRefs)

	foundRefs := make([]string, len(completions))

	for i, c := range completions {
		foundRefs[i] = c.Label
	}

	slices.Sort(foundRefs)

	if !slices.Equal(expectedRefs, foundRefs) {
		t.Fatalf("Expected completions to be %v, got: %v", expectedRefs, foundRefs)
	}
}
