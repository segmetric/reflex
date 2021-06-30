defmodule Hologram.Template.ComponentRenderer do
  alias Hologram.Compiler.Helpers
  alias Hologram.Template.{Parser, Renderer, Transformer}

  def render(module, state) do
    Helpers.fully_qualified_module(module)
    |> apply(:template, [])
    |> Parser.parse!()
    |> Transformer.transform()
    |> Renderer.render(state)
  end
end