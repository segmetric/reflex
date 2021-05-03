defmodule Hologram.Transpiler.ModuleGenerator do
  alias Hologram.Transpiler.AST.Function
  alias Hologram.Transpiler.FunctionGenerator
  alias Hologram.Transpiler.Helpers

  def generate(ast, name) do
    context = [class_name: Helpers.class_name(name)]

    functions =
      aggregate_functions(ast)
      |> Enum.map(fn {k, v} -> FunctionGenerator.generate(k, v, context) end)
      |> Enum.join("\n")

    """
    class #{context[:class_name]} {

    #{functions}
    }
    """
  end

  defp aggregate_functions(module) do
    Enum.reduce(module.functions, %{}, fn expr, acc ->
      case expr do
        %Function{name: name} = fun ->
          if Map.has_key?(acc, name) do
            Map.put(acc, name, acc[name] ++ [fun])
          else
            Map.put(acc, name, [fun])
          end

        # TODO: determine what's this case for, comment and test it
        _ ->
          acc
      end
    end)
  end
end
