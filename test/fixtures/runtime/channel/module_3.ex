defmodule Hologram.Test.Fixtures.Runtime.Module3 do
  def command(:test_command, _params) do
    {:test_action, a: 1, b: 2}
  end
end
