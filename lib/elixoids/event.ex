defmodule Elixoids.Event do
  @moduledoc """
  Logic to dispatch game events to processes.
  """

  import Elixoids.News

  def asteroid_hit_ship(game_id, %{pid: asteroid_pid, pos: %{x: x, y: y}}, %{
        pid: ship_pid,
        tag: tag
      }) do
    Ship.Server.hyperspace(ship_pid)
    Game.Server.explosion(game_id, x, y)
    # TODO send to Asteroid
    Game.Server.asteroid_hit(game_id, asteroid_pid)
    publish_news(game_id, ["ASTEROID", "hit", tag])
  end
end
