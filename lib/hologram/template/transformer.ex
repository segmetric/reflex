defmodule Hologram.Template.Transformer do
  alias Hologram.Template.AST.{ComponentNode, Expression, TagNode, TextNode}
  alias Hologram.Template.Interpolator
  alias Hologram.Compiler.{Parser, Transformer}

  def transform(ast, aliases \\ %{})

  def transform(nodes, aliases) when is_list(nodes) do
    Enum.map(nodes, fn node -> transform(node, aliases) end)
  end

  def transform({type, attrs, children}, aliases) do
    children =
      Enum.map(children, fn child -> transform(child, aliases) end)
      |> Interpolator.interpolate()

    attrs =
      Enum.map(attrs, fn {key, value} ->
        regex = ~r/^{{(.+)}}$/

        value =
          case Regex.run(regex, value) do
            [_, code] ->
              ast =
                Parser.parse!(code)
                |> Hologram.Compiler.Transformer.transform()

              %Expression{ast: ast}

            _ ->
              value
          end

        {key, value}
      end)
      |> Enum.into(%{})

    case resolve_node_type(type, aliases) do
      :tag ->
        %TagNode{tag: type, attrs: attrs, children: children}
        # TODO: imlement
        # :module ->
        #   %ComponentNode{module: module, children: children}
    end
  end

  def transform(ast, _aliases) when is_binary(ast) do
    %TextNode{text: ast}
  end

  # TODO: implement
  defp resolve_node_type(type, aliases) do
    :tag
  end
end