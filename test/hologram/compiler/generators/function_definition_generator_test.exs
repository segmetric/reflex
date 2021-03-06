defmodule Hologram.Compiler.FunctionDefinitionGeneratorTest do
  use Hologram.TestCase, async: true
  alias Hologram.Compiler.{Context, FunctionDefinitionGenerator}

  @context %Context{
    module: nil,
    uses: [],
    imports: [],
    aliases: [],
    attributes: []
  }

  # cases:
  # has args, no args
  # single variant, multiple variants
  # has vars, no vars
  # variable access, map access
  # only return statement, expression + return statement

  test "no args, no vars, only return statement" do
    code = """
    def test, do: nil
    """

    ir = ir(code)
    variants = [ir]

    result = FunctionDefinitionGenerator.generate(ir.name, variants, @context)

    expected = """
    static test() {
    if (Hologram.patternMatchFunctionArgs([], arguments)) {
    return { type: 'atom', value: '' };
    }
    else {
    console.debug(arguments)
    throw 'No match for the function call'
    }
    }
    """

    assert result == expected
  end

  test "has args, has vars, single variant, variable access" do
    code = """
    def test(x), do: nil
    """

    ir = ir(code)
    variants = [ir]

    result = FunctionDefinitionGenerator.generate(ir.name, variants, @context)

    expected = """
    static test() {
    if (Hologram.patternMatchFunctionArgs([{ type: 'placeholder' }], arguments)) {
    let x = arguments[0];
    return { type: 'atom', value: '' };
    }
    else {
    console.debug(arguments)
    throw 'No match for the function call'
    }
    }
    """

    assert result == expected
  end

  test "multiple variants, map access, expression + return statement" do
    code = """
    defmodule Test do
      def test(1), do: nil

      def test(%{a: x}) do
        1
        2
      end
    end
    """

    ir = ir(code)
    variants = ir.functions
    name = :test

    result = FunctionDefinitionGenerator.generate(name, variants, @context)

    expected = """
    static test() {
    if (Hologram.patternMatchFunctionArgs([{ type: 'integer', value: 1 }], arguments)) {
    return { type: 'atom', value: '' };
    }
    else if (Hologram.patternMatchFunctionArgs([{ type: 'map', data: { '~atom[a]': { type: 'placeholder' } } }], arguments)) {
    let x = arguments[0].data['~atom[a]'];
    { type: 'integer', value: 1 };
    return { type: 'integer', value: 2 };
    }
    else {
    console.debug(arguments)
    throw 'No match for the function call'
    }
    }
    """

    assert result == expected
  end
end
