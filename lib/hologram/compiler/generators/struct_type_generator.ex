defmodule Hologram.Compiler.StructTypeGenerator do
  alias Hologram.Compiler.Helpers
  alias Hologram.Compiler.MapTypeGenerator

  def generate(module, data, context) do
    module_name = Helpers.module_name(module)
    data = MapTypeGenerator.generate_data(data, context)

    "{ type: 'struct', module: '#{module_name}', data: #{data} }"
  end
end