package regal.lsp.util.references_test

import data.regal.lsp.testing
import data.regal.lsp.util.references

test_references_var_from_use[name] if {
	some name, tc in {
		"some": {
			"snippet": `r if {
	some x
	input[x]
	x@ == 1
}`,
			"declaration": [3, 6],
			"uses": [[4, 7], [5, 1]],
		},
		"some in": {
			"snippet": `r if {
	some x in input.xs
	x@ == 1
}`,
			"declaration": [3, 6],
			"uses": [[4, 1]],
		},
		"every": {
			"snippet": `r if {
	every x in input.xs {
		x@ == 1
	}
}`,
			"declaration": [3, 7],
			"uses": [[4, 2]],
		},
	}

	[tdp, module] := testing.at_cursor(tc.snippet)

	refs := references.refs
		with input as object.union(tdp, {"params": {"context": {"includeDeclaration": true}}})
		with data.workspace.parsed["file:///p.rego"] as module

	declared := [array.flatten([tc.declaration, references.kind_write])]
	used := [array.flatten([use, references.kind_read]) | some use in tc.uses]

	refs == {{
		"uri": "file:///p.rego",
		"range": {"start": {"line": line, "character": col}, "end": {"line": line, "character": col + 1}},
		"kind": kind,
	} |
		some locations in [declared, used]
		some [line, col, kind] in locations
	}
}
