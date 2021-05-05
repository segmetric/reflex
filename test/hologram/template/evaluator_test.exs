defmodule Hologram.Template.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Hologram.Template.Evaluator
  alias Hologram.Compiler.AST.ModuleAttributeOperator

  test "module attribute" do
    state = %{a: 123}
    ast = %ModuleAttributeOperator{name: :a}

    result = Evaluator.evaluate(ast, state)
    expected = 123

    assert result == expected
  end
end