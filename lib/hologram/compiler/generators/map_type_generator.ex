defmodule Hologram.Compiler.MapTypeGenerator do
  alias Hologram.Compiler.{Context, Generator, MapKeyGenerator}

  def generate(data, %Context{} = context, opts) do
    "{ type: 'map', data: #{generate_data(data, context, opts)} }"
  end

  def generate_data(data, %Context{} = context, opts) do
    fields =
      Enum.map(data, fn {k, v} ->
        "'#{MapKeyGenerator.generate(k, context)}': #{Generator.generate(v, context, opts)}"
      end)
      |> Enum.join(", ")

    if fields != "" do
      "{ #{fields} }"
    else
      "{}"
    end
  end
end
