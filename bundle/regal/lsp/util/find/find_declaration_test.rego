package regal.lsp.util.find_test

import data.regal.lsp.testing
import data.regal.lsp.util.find
import data.regal.lsp.util.range

test_declaration_at_position[name] if {
	some name, tc in {
		"assign": {
			"snippet": `r if {
	x := input.a
	x@ == 1
}`,
			"declared": [3, 1],
		},
		"declared after": {
			"snippet": `r := x@ if {
	x := input.a
}`,
			"declared": [3, 1],
		},
		"itself": {
			"snippet": `r if {
	x@ := input.a
	x == 1
}`,
			"declared": [3, 1],
		},
	}

	[tdp, module] := testing.at_cursor(tc.snippet)

	[decl, _] := find.declaration_at_position
		with input as tdp
		with data.workspace.parsed["file:///p.rego"] as module

	start := range.parse(decl.location).start
	[start.line, start.character] == tc.declared
}

test_declaration_at_position_not_a_variable if {
	[tdp, module] := testing.at_cursor(`r if {
	input.a@ == 1
}`)

	not find.declaration_at_position
		with input as tdp
		with data.workspace.parsed["file:///p.rego"] as module
}
