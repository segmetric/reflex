defmodule Holograf.Transpiler.TransformerTest do
  use ExUnit.Case

  import Holograf.Transpiler.Parser, only: [parse!: 1]

  alias Holograf.Transpiler.AST.{AtomType, BooleanType, IntegerType, StringType}
  alias Holograf.Transpiler.AST.MapType
  alias Holograf.Transpiler.AST.MatchOperator
  alias Holograf.Transpiler.AST.MapAccess
  alias Holograf.Transpiler.AST.Variable
  alias Holograf.Transpiler.Transformer

  describe "primitives" do
    test "atom" do
      ast = parse!(":test")
      assert Transformer.transform(ast) == %AtomType{value: :test}
    end

    test "boolean" do
      ast = parse!("true")
      assert Transformer.transform(ast) == %BooleanType{value: true}
    end

    test "integer" do
      ast = parse!("1")
      assert Transformer.transform(ast) == %IntegerType{value: 1}
    end

    test "string" do
      ast = parse!("\"test\"")
      assert Transformer.transform(ast) == %StringType{value: "test"}
    end
  end

  describe "data structures" do
    test "map, empty" do
      result =
        parse!("%{}")
        |> Transformer.transform()

      expected = %MapType{data: []}

      assert result == expected
    end

    test "map, not nested" do
      result =
        parse!("%{a: 1, b: 2}")
        |> Transformer.transform()

      expected = %MapType{
        data: [
          {%AtomType{value: :a}, %IntegerType{value: 1}},
          {%AtomType{value: :b}, %IntegerType{value: 2}}
        ]
      }

      assert result == expected
    end

    test "map, nested" do
      result =
        parse!("%{a: 1, b: %{c: 2, d: %{e: 3, f: 4}}}")
        |> Transformer.transform()

      expected = %MapType{
        data: [
          {%AtomType{value: :a}, %IntegerType{value: 1}},
          {%AtomType{value: :b},
           %MapType{
             data: [
               {%AtomType{value: :c}, %IntegerType{value: 2}},
               {%AtomType{value: :d},
                %MapType{
                  data: [
                    {%AtomType{value: :e}, %IntegerType{value: 3}},
                    {%AtomType{value: :f}, %IntegerType{value: 4}}
                  ]
                }}
             ]
           }}
        ]
      }

      assert result == expected
    end
  end

  describe "operators" do
    test "match operator, simple" do
      result =
        parse!("x = 1")
        |> Transformer.transform()

      expected = %MatchOperator{
        bindings: [[%Variable{name: :x}]],
        left: %Variable{name: :x},
        right: %IntegerType{value: 1}
      }

      assert result == expected
    end

    test "match operator, map, not nested" do
      result =
        parse!("%{a: x, b: y} = %{a: 1, b: 2}")
        |> Transformer.transform()

      expected =
        %MatchOperator{
          bindings: [
            [
              %Variable{name: :x},
              %MapAccess{key: %AtomType{value: :a}}
            ],
            [
              %Variable{name: :y},
              %MapAccess{key: %AtomType{value: :b}}
            ]
          ],
          left: %MapType{
            data: [
              {%AtomType{value: :a}, %Variable{name: :x}},
              {%AtomType{value: :b}, %Variable{name: :y}}
            ]
          },
          right: %MapType{
            data: [
              {%AtomType{value: :a}, %IntegerType{value: 1}},
              {%AtomType{value: :b}, %IntegerType{value: 2}}
            ]
          }
        }

      assert result == expected
    end

    test "match operator, map, nested" do
      code = "%{a: 1, b: %{p: x, r: 4}, c: 3, d: %{m: 0, n: y}} = %{a: 1, b: %{p: 9, r: 4}, c: 3, d: %{m: 0, n: 8}}"

      result =
        parse!(code)
        |> Transformer.transform()

      expected =
        %MatchOperator{
          bindings: [
            [
              %Variable{name: :x},
              %MapAccess{key: %AtomType{value: :b}},
              %MapAccess{key: %AtomType{value: :p}}
            ],
            [
              %Variable{name: :y},
              %MapAccess{key: %AtomType{value: :d}},
              %MapAccess{key: %AtomType{value: :n}}
            ]
          ],
          left: %MapType{
            data: [
              {%AtomType{value: :a}, %IntegerType{value: 1}},
              {
                %AtomType{value: :b},
                %MapType{
                  data: [
                    {%AtomType{value: :p}, %Variable{name: :x}},
                    {%AtomType{value: :r}, %IntegerType{value: 4}}
                  ]
                }},
              {%AtomType{value: :c}, %IntegerType{value: 3}},
              {%AtomType{value: :d},
                %MapType{
                  data: [
                    {%AtomType{value: :m},
                    %IntegerType{value: 0}},
                    {%AtomType{value: :n},
                    %Variable{name: :y}}
                  ]
                }}
            ]
          },
          right: %MapType{
            data: [
              {%AtomType{value: :a}, %IntegerType{value: 1}},
              {%AtomType{value: :b},
                %MapType{
                  data: [
                    {%AtomType{value: :p},
                    %IntegerType{value: 9}},
                    {%AtomType{value: :r},
                    %IntegerType{value: 4}}
                  ]
                }},
              {%AtomType{value: :c}, %IntegerType{value: 3}},
              {%AtomType{value: :d},
                %MapType{
                  data: [
                    {%AtomType{value: :m},
                    %IntegerType{value: 0}},
                    {%AtomType{value: :n},
                    %IntegerType{value: 8}}
                  ]
                }}
            ]
          }
        }

      assert result == expected
    end
  end

  describe "other" do
    test "variable" do
      ast = parse!("x")
      assert Transformer.transform(ast) == %Variable{name: :x}
    end
  end
end
