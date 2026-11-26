# METADATA
# description: Common functions for finding AST elements at a given position
# schemas:
#   - input: schema.regal.lsp.common
package regal.lsp.util.find

import data.regal.ast
import data.regal.lsp.location
import data.regal.lsp.util.range

# METADATA
# description: |
#   find the function argument at the given position, if any, either where it is declared
#   or where it is used in the rule
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
arg_at_position := [term, rule_index] if {
	[var, rule_index] := var_at_position

	not startswith(var.value, "$")

	args := data.workspace.parsed[input.params.textDocument.uri].rules[rule_index].head.args

	walk(args, [_, term])

	term.value == var.value
	term.type == "var"
}

# METADATA
# description: find the variable at input.params.position, and the index of its rule, if any
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
var_at_position := [var, rule_index] if {
	[rule, rule_index] := rule_at_position

	walk(rule, [_, var])

	var.type == "var"
	range.contains_position(range.parse(var.location), input.params.position)
}

# METADATA
# description: find the variable declared by assignment at input.params.position, if any
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
assign_var_at_position := [var, rule_index] if {
	[var, rule_index] := var_at_position

	not startswith(var.value, "$")

	ast.found.vars[rule_index].assign[_].value == var.value
}

# METADATA
# description: find the rule at input.params.position if any
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
rule_at_position := [rule, rule_index] if {
	some rule_index, rule in data.workspace.parsed[input.params.textDocument.uri].rules

	range.contains_position(range.parse(rule.location), input.params.position)
}

# METADATA
# description: find the package whose name is at input.params.position, if any
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
package_at_position := pkg if {
	pkg := data.workspace.parsed[input.params.textDocument.uri].package

	range.contains_position(range.spanning(pkg.path), input.params.position)
}

# METADATA
# description: find the import statement at input.params.position, if any
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
import_at_position := imp if {
	some imp in data.workspace.parsed[input.params.textDocument.uri].imports

	range.contains_position(range.parse(imp.path.location), input.params.position)
}

# METADATA
# description: |
#   find the import statement at input.params.position, if the position is on its alias.
#   The alias has no location in the AST, so it is found in the text following the import path.
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
import_alias_at_position := imp if {
	some imp in data.workspace.parsed[input.params.textDocument.uri].imports

	imp.alias

	path_end := range.parse(imp.path.location).end

	input.params.position.line == path_end.line

	rest := substring(input.regal.file.lines[path_end.line], path_end.character, -1)
	start := path_end.character + count(regex.find_n(`^\s+as\s+`, rest, 1)[0])

	input.params.position.character >= start
	input.params.position.character <= start + count(imp.alias)
}

# METADATA
# description: |
#   find the declaration of the variable at the given position, and the index of its rule, if any. This is the
#   variable itself where it is declared, or else the nearest declaration before it, or the first one after it.
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
declaration_at_position := [ast.declaration_of(rule_index, var), rule_index] if [var, rule_index] := var_at_position

# METADATA
# description: |
#   find the `some`-declared variable the variable at the given position is declared by, if any.
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
some_var_at_position := [var, rule_index] if {
	[var, rule_index] := declaration_at_position

	some kind in ["some", "somein"]
	var in ast.found.vars[rule_index][kind]
}

# METADATA
# description: |
#   find the `every`-declared variable the variable at the given position is declared by, if any.
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
every_var_at_position := [var, every_terms] if {
	[var, rule_index] := declaration_at_position

	some every_terms in ast.found.every[rule_index]
	some kind in ["key", "value"]
	var == every_terms[kind]
}

# METADATA
# description: |
#   find the variable declared inside a comprehension that the variable at the given position is declared by,
#   if any.
# schemas:
#   - input.params: schema.regal.lsp.textdocumentposition
comprehension_var_at_position := [var, comp] if {
	[var, rule_index] := declaration_at_position

	some comp in ast.found.comprehensions[rule_index]
	var in _comp_declared_vars(comp.value.body)
}

_comp_declared_vars(body) := [v |
	some expr in body
	some symbol in expr.terms.symbols
	some v in array.slice(symbol.value, 1, 100)
	v.type == "var"
	not startswith(v.value, "$")
]
