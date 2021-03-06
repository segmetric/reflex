defmodule Hologram.Compiler.GeneratorTest do
  use Hologram.TestCase, async: true

  alias Hologram.Compiler.{Context, Generator}

  alias Hologram.Compiler.IR.{
    AdditionOperator,
    AtomType,
    BinaryType,
    BooleanType,
    DotOperator,
    FunctionCall,
    IntegerType,
    ListType,
    MapType,
    ModuleAttributeOperator,
    ModuleDefinition,
    StringType,
    StructType,
    TupleType,
    Variable
  }

  @context %Context{module: nil, uses: [], imports: [], aliases: [], attributes: []}

  describe "types" do
    test "atom" do
      ir = %AtomType{value: :test}
      result = Generator.generate(ir, @context)
      assert result == "{ type: 'atom', value: 'test' }"
    end

    test "boolean" do
      ir = %BooleanType{value: true}
      result = Generator.generate(ir, @context)
      assert result == "{ type: 'boolean', value: true }"
    end

    test "integer" do
      ir = %IntegerType{value: 123}
      result = Generator.generate(ir, @context)
      assert result == "{ type: 'integer', value: 123 }"
    end

    test "list" do
      ir = %ListType{data: [%IntegerType{value: 123}]}
      result = Generator.generate(ir, @context)
      assert result == "{ type: 'list', data: [ { type: 'integer', value: 123 } ] }"
    end

    test "map" do
      ir = %MapType{data: [{%AtomType{value: :a}, %IntegerType{value: 1}}]}

      result = Generator.generate(ir, @context)
      expected = "{ type: 'map', data: { '~atom[a]': { type: 'integer', value: 1 } } }"

      assert result == expected
    end

    test "string" do
      ir = %StringType{value: "Test"}
      result = Generator.generate(ir, @context)

      assert result == "{ type: 'string', value: 'Test' }"
    end

    test "struct" do
      ir = %StructType{
        data: [{%AtomType{value: :a}, %IntegerType{value: 1}}],
        module: Abc.Bcd
      }

      result = Generator.generate(ir, @context)

      expected =
        "{ type: 'struct', module: 'Elixir_Abc_Bcd', data: { '~atom[a]': { type: 'integer', value: 1 } } }"

      assert result == expected
    end

    test "tuple" do
      ir = %TupleType{data: []}

      result = Generator.generate(ir, @context)
      expected = "{ type: 'tuple', data: [] }"

      assert result == expected
    end
  end

  describe "operators" do
    test "addition" do
      ir = %AdditionOperator{
        left: %IntegerType{value: 1},
        right: %IntegerType{value: 2}
      }

      result = Generator.generate(ir, @context)

      expected = "Elixir_Kernel.$add({ type: 'integer', value: 1 }, { type: 'integer', value: 2 })"

      assert result == expected
    end

    test "dot" do
      ir = %DotOperator{
        left: %Variable{name: :x},
        right: %AtomType{value: :a}
      }

      result = Generator.generate(ir, @context)
      expected = "Elixir_Kernel.$dot(x, { type: 'atom', value: 'a' })"

      assert result == expected
    end

    test "module attribute" do
      ir = %ModuleAttributeOperator{name: :x}

      result = Generator.generate(ir, @context)
      expected = "$state.data['~atom[x]']"

      assert result == expected
    end
  end

  describe "definitions" do
    test "module" do
      ir = %ModuleDefinition{
        aliases: [],
        attributes: [],
        functions: [],
        imports: [],
        module: Test
      }

      result = Generator.generate(ir, @context)
      expected = "window.Elixir_Test = class Elixir_Test {\n\n\n}\n"

      assert result == expected
    end
  end

  describe "other" do
    test "sigil_H" do
      ir =
        %FunctionCall{
          function: :sigil_H,
          module: Hologram.Runtime.Commons,
          params: [
            %BinaryType{
              parts: [
                %StringType{value: "test"}
              ]
            },
            %ListType{data: []}
          ]
        }

      result = Generator.generate(ir, @context)
      expected = "[{ type: 'text', content: 'test' }]"

      assert result == expected
    end

    test "function call" do
      ir = %FunctionCall{
        function: :abc,
        module: Test,
        params: [%IntegerType{value: 1}]
      }

      result = Generator.generate(ir, @context)
      expected = "Elixir_Test.abc({ type: 'integer', value: 1 })"

      assert result == expected
    end

    test "variable, placeholder" do
      ir = %Variable{name: :test}

      result = Generator.generate(ir, @context, placeholder: true)
      expected = "{ type: 'placeholder' }"

      assert result == expected
    end

    test "variable, not placeholder" do
      ir = %Variable{name: :test}

      result = Generator.generate(ir, @context)
      expected = "test"

      assert result == expected
    end
  end
end
