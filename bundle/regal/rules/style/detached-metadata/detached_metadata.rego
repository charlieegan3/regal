# METADATA
# description: Detached metadata annotation
package regal.rules.style["detached-metadata"]

import rego.v1

import data.regal.ast
import data.regal.result
import data.regal.util

report contains violation if {
	some block in ast.comments.blocks

	startswith(trim_space(block[0].text), "METADATA")

	last_row := util.to_location_object(regal.last(block).location).row

	# no need to +1 the index here as rows start counting from 1
	trim_space(input.regal.file.lines[last_row]) == ""

	annotation := annotation_at_row(util.to_location_object(block[0].location).row)
	annotation.scope != "document"

	violation := result.fail(rego.metadata.chain(), result.location(block[0]))
}

annotation_at_row(row) := annotation if {
	some annotation in input.annotations

	util.to_location_object(annotation.location).row == row
}