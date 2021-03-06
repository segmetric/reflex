defmodule Hologram.Component do
  defmacro __using__(_) do
    quote do
      import Hologram.Component
      import Hologram.Runtime.Commons, only: [sigil_H: 2]
    end
  end
end
