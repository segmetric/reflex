defmodule Hologram.Compiler.Builder do
  alias Hologram.Compiler.Processor
  alias Hologram.Compiler.Eliminator
  alias Hologram.Compiler.Generator

  def build(module) do
    Processor.compile(module)
    |> Eliminator.eliminate(module)
    |> Enum.reduce("", fn {_, module_ast}, acc ->
      acc <> "\n" <> Generator.generate(module_ast)
    end)
  end
end