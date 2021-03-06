defmodule Hologram.Features.EventsTest do
  use Hologram.E2ECase, async: true

  @moduletag :e2e

  feature "click event", %{session: session} do
    session
    |> visit("/e2e/page-2")
    |> click(css("#button"))

    |> assert_has(css("#text", text: "test updated text"))
  end
end
