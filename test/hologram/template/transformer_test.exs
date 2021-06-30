defmodule Hologram.Template.TransformerTest do
  use Hologram.TestCase, async: true

  alias Hologram.Compiler.IR.{ModuleAttributeOperator}
  alias Hologram.Template.{Parser, Transformer}
  alias Hologram.Template.VirtualDOM.{Component, Expression, ElementNode, TextNode}

  describe "transform/2" do
    test "list of nodes" do
      html = "<div></div><span></span>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected =
        [
          %ElementNode{
            attrs: %{},
            children: [],
            tag: "div"
          },
          %ElementNode{
            attrs: %{},
            children: [],
            tag: "span"
          }
        ]

      assert result == expected
    end

    test "component node without children" do
      html = "<Prefix.Module></Prefix.Module>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [%Component{children: [], module: [:Prefix, :Module]}]

      assert result == expected
    end

    test "component node with children" do
      html = "<Prefix.Module><div></div><span></span></Prefix.Module>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected =
        [
          %Component{
            children: [
              %ElementNode{
                attrs: %{},
                children: [],
                tag: "div"
              },
              %ElementNode{
                attrs: %{},
                children: [],
                tag: "span"
              }
            ],
            module: [:Prefix, :Module]
          }
        ]

      assert result == expected
    end

    test "element node without children, without attrs" do
      html = "<div></div>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{},
          children: [],
          tag: "div"
        }
      ]

      assert result == expected
    end

    test "element node without children, with attrs" do
      html = "<div id=\"test-id\" class=\"test-class\"></div>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{"class" => "test-class", "id" => "test-id"},
          children: [],
          tag: "div"
        }
      ]

      assert result == expected
    end

    test "element node with children, without attrs" do
      html = "<div><h1><span></span></h1></div>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{},
          children: [
            %ElementNode{
              attrs: %{},
              children: [
                %ElementNode{attrs: %{}, children: [], tag: "span"}
              ],
              tag: "h1"
            }
          ],
          tag: "div"
        }
      ]

      assert result == expected
    end

    test "element node with children, with attrs" do
      html = """
      <div class="class_1"><h1><span class="class_2" id="id_2"></span></h1></div>
      """

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{"class" => "class_1"},
          children: [
            %ElementNode{
              attrs: %{},
              children: [
                %ElementNode{
                  attrs: %{"class" => "class_2", "id" => "id_2"},
                  children: [],
                  tag: "span"
                }
              ],
              tag: "h1"
            }
          ],
          tag: "div"
        },
        %TextNode{content: "\n"}
      ]

      assert result == expected
    end

    test "text node" do
      html = "<div>test_text</div>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{},
          children: [
            %TextNode{content: "test_text"}
          ],
          tag: "div"
        }
      ]

      assert result == expected
    end

    test "expression interpolation in attrs" do
      html = """
      <div class="class_1" :if={{ @var_1 }} id="id_1" :show={{ @var_2 }}>
        <h1>
          <span class="class_2" :if={{ @var_3 }} id="id_2" :show={{ @var_4 }}></span>
        </h1>
      </div>
      """

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{
            ":if" => %Expression{ir: %ModuleAttributeOperator{name: :var_1}},
            ":show" => %Expression{ir: %ModuleAttributeOperator{name: :var_2}},
            "class" => "class_1",
            "id" => "id_1"
          },
          children: [
            %TextNode{content: "\n  "},
            %ElementNode{
              attrs: %{},
              children: [
                %TextNode{content: "\n    "},
                %ElementNode{
                  attrs: %{
                    ":if" => %Expression{ir: %ModuleAttributeOperator{name: :var_3}},
                    ":show" => %Expression{ir: %ModuleAttributeOperator{name: :var_4}},
                    "class" => "class_2",
                    "id" => "id_2"
                  },
                  children: [],
                  tag: "span"
                },
                %TextNode{content: "\n  "}
              ],
              tag: "h1"
            },
            %TextNode{content: "\n"}
          ],
          tag: "div"
        },
        %TextNode{content: "\n"}
      ]

      assert result == expected
    end

    test "expression interpolation in text" do
      html = "<div>test_1{{ @x1 }}test_2{{ @x2 }}test_3</div>"

      result =
        Parser.parse!(html)
        |> Transformer.transform()

      expected = [
        %ElementNode{
          attrs: %{},
          children: [
            %TextNode{content: "test_1"},
            %Expression{
              ir: %ModuleAttributeOperator{name: :x1}
            },
            %TextNode{content: "test_2"},
            %Expression{
              ir: %ModuleAttributeOperator{name: :x2}
            },
            %TextNode{content: "test_3"}
          ],
          tag: "div"
        }
      ]

      assert result == expected
    end
  end
end
