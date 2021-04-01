defmodule Hologram.TemplateEngine.AST do
  defmodule ComponentNode do
    defstruct module: nil, children: nil
  end

  defmodule TagNode do
    defstruct tag: nil, children: nil
  end
end