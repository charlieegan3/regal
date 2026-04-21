package regal.lsp.testlocations_test

import data.regal.lsp.testlocations

test_multiple_test_rules if {
	policy := `package foo_test

test_1 if {
	1 == 2
}

test_2 if true

  test_3 if {
	1 == 2
	2 == 1
}
`

	result := testlocations.result with input as object.union(
		regal.parse_module("file://foo/foo_test.rego", policy),
		{"regal": {"file": {"root": "/foo"}}},
	)

	exp := {
		{
			"package_path": ["foo_test"],
			"package": "data.foo_test",
			"name": "foo_test",
			"root": "/foo",
			"type": "package",
			"location": {
				"col": 1, "row": 1, "end": {"col": 8, "row": 1},
				"file": "file://foo/foo_test.rego",
				"text": "package foo_test",
			},
		},
		{
			"package_path": ["foo_test"],
			"package": "data.foo_test",
			"name": "test_1",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 1, "row": 3, "end": {"col": 7, "row": 3},
				"file": "file://foo/foo_test.rego",
				"text": "test_1 if {",
			},
		},
		{
			"package_path": ["foo_test"],
			"package": "data.foo_test",
			"name": "test_2",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 1, "row": 7, "end": {"col": 7, "row": 7},
				"file": "file://foo/foo_test.rego",
				"text": "test_2 if true",
			},
		},
		{
			"package_path": ["foo_test"],
			"package": "data.foo_test",
			"name": "test_3",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 3, "row": 9, "end": {"col": 9, "row": 9},
				"file": "file://foo/foo_test.rego",
				"text": "  test_3 if {",
			},
		},
	}

	exp == result
}

test_no_test_rules if {
	policy := `package foo_test`

	result := testlocations.result with input as object.union(
		regal.parse_module("file://foo/foo_test.rego", policy),
		{"regal": {"file": {"root": "/foo"}}},
	)

	set() == result
}

test_non_test_package if {
	policy := `package foo

test_foo if true
`

	result := testlocations.result with input as object.union(
		regal.parse_module("file:///foo/foo.rego", policy),
		{"regal": {"file": {"root": "/foo"}}},
	)

	exp := {
		{
			"package_path": ["foo"],
			"package": "data.foo",
			"name": "foo",
			"root": "/foo",
			"type": "package",
			"location": {
				"col": 1, "row": 1, "end": {"col": 8, "row": 1},
				"file": "file:///foo/foo.rego",
				"text": "package foo",
			},
		},
		{
			"package_path": ["foo"],
			"package": "data.foo",
			"name": "test_foo",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 1,
				"row": 3,
				"end": {
					"col": 9,
					"row": 3,
				},
				"file": "file:///foo/foo.rego",
				"text": "test_foo if true",
			},
		},
	}

	print(exp)
	print(result)

	exp == result
}

test_funny_test_names_package if {
	policy := `package foo

foo.bar.test_me if {
	false
}

foo.bar.test_me.baz if {
	false
}
`

	result := testlocations.result with input as object.union(
		regal.parse_module("file:///foo/foo.rego", policy),
		{"regal": {"file": {"root": "/foo"}}},
	)

	exp := {
		{
			"package_path": ["foo"],
			"package": "data.foo",
			"name": "foo",
			"root": "/foo",
			"type": "package",
			"location": {
				"col": 1, "row": 1, "end": {"col": 8, "row": 1},
				"file": "file:///foo/foo.rego",
				"text": "package foo",
			},
		},
		{
			"package_path": ["foo"],
			"package": "data.foo",
			"name": "foo.bar.test_me",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 1,
				"row": 3,
				"end": {"col": 16, "row": 3},
				"file": "file:///foo/foo.rego",
				"text": "foo.bar.test_me if {",
			},
		},
		{
			"package_path": ["foo"],
			"package": "data.foo",
			"name": "foo.bar.test_me.baz",
			"root": "/foo",
			"type": "rule",
			"location": {
				"col": 1,
				"row": 7,
				"end": {"col": 20, "row": 7},
				"file": "file:///foo/foo.rego",
				"text": "foo.bar.test_me.baz if {",
			},
		},
	}

	print(result)
	print(exp)

	exp == result
}
