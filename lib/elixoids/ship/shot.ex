defmodule Elixoids.Ship.Shot do
  @moduledoc "Firing sound"

  alias Elixoids.Api.SoundEvent
  alias Elixoids.Space
  import Elixoids.News, only: [publish_audio: 2]

  def fire_sound(%{game_id: game_id, pos: %{x: x}} = ship) do
    e = x |> Space.frac_x() |> SoundEvent.fire()
    publish_audio(game_id, e)
    ship
  end
end
