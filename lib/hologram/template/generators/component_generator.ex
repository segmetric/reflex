defmodule Hologram.Template.ComponentGenerator do
  alias Hologram.Compiler.Helpers
  alias Hologram.Template.{Builder, Generator}

  def generate(module) do
    class_name = Helpers.class_name(module)

    children_js =
      Builder.build(module)
      |> Generator.generate()

    "{ type: 'component', module: '#{class_name}', children: #{children_js} }"
  end
end
