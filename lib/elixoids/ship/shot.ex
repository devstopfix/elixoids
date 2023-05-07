defmodule Elixoids.Ship.Shot do
  @moduledoc "Firing sound"

  import Elixoids.News, only: [publish_audio: 2]
  alias Elixoids.Api.SoundEvent

  def fire_sound(%{game_id: game_id} = ship) do
    pan = 0.0
    e = SoundEvent.fire(pan)
    publish_audio(game_id, e)
    ship
  end
end
