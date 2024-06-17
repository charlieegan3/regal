package rego

import (
	"context"
	"errors"
	"fmt"

	"github.com/open-policy-agent/opa/ast"
	"github.com/open-policy-agent/opa/rego"

	"github.com/styrainc/regal/internal/lsp/types"
	"github.com/styrainc/regal/internal/parse"
)

type BuiltInCall struct {
	Builtin  *ast.Builtin
	Location *ast.Location
	Args     []*ast.Term
}

func PositionFromLocation(loc *ast.Location) types.Position {
	return types.Position{
		Line:      uint(loc.Row - 1),
		Character: uint(loc.Col - 1),
	}
}

func LocationFromPosition(pos types.Position) *ast.Location {
	return &ast.Location{
		Row: int(pos.Line + 1),
		Col: int(pos.Character + 1),
	}
}

// AllBuiltinCalls returns all built-in calls in the module, excluding operators
// and any other function identified by an infix.
func AllBuiltinCalls(module *ast.Module) []BuiltInCall {
	builtinCalls := make([]BuiltInCall, 0)

	callVisitor := ast.NewGenericVisitor(func(x interface{}) bool {
		var terms []*ast.Term

		switch node := x.(type) {
		case ast.Call:
			terms = node
		case *ast.Expr:
			if call, ok := node.Terms.([]*ast.Term); ok {
				terms = call
			}
		default:
			return false
		}

		if len(terms) == 0 {
			return false
		}

		if b, ok := BuiltIns[terms[0].Value.String()]; ok {
			// Exclude operators and similar builtins
			if b.Infix != "" {
				return false
			}

			builtinCalls = append(builtinCalls, BuiltInCall{
				Builtin:  b,
				Location: terms[0].Location,
				Args:     terms[1:],
			})
		}

		return false
	})

	callVisitor.Walk(module)

	return builtinCalls
}

// ParseToInput parse a rego policy and returns it parsed with Regal additions
// to be used as input for evaluation.
func ParseToInput(path, content string, context map[string]any) (map[string]any, error) {
	module, err := parse.Module(path, content)
	if err != nil {
		return nil, fmt.Errorf("failed parsing module: %w", err)
	}

	input, err := parse.PrepareAST(path, content, module)
	if err != nil {
		return nil, fmt.Errorf("failed preparing input: %w", err)
	}

	return SetInputContext(input, context), nil
}

func SetInputContext(input map[string]any, context map[string]any) map[string]any {
	if regal, ok := input["regal"].(map[string]any); ok {
		regal["context"] = context
	}

	return input
}

func QueryRegalBundle(input map[string]any, pq rego.PreparedEvalQuery) (map[string]any, error) {
	result, err := pq.Eval(context.Background(), rego.EvalInput(input))
	if err != nil {
		return nil, fmt.Errorf("failed evaluating query: %w", err)
	}

	if len(result) == 0 {
		return nil, errors.New("expected result from evaluation, didn't get it")
	}

	return result[0].Bindings, nil
}
