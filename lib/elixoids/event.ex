defmodule Elixoids.Event do
  @moduledoc """
  Logic to dispatch game events to processes.
  """

  alias Asteroid.Server, as: Asteroid
  import Elixoids.News

  @asteroid "ASTEROID"

  def asteroid_hit_ship(game_id, %{pid: asteroid_pid}, %{
        pid: ship_pid,
        tag: tag,
        pos: %{x: x, y: y}
      }) do
    Ship.Server.hyperspace(ship_pid)
    Game.Server.explosion(game_id, x, y)
    Asteroid.destroyed(asteroid_pid)
    publish_news(game_id, [@asteroid, "hit", tag])
  end

  def bullet_hit_ship(game_id, %{pid: bullet_pid, shooter: shooter_tag}, %{
        pid: ship_pid,
        tag: victim_tag,
        pos: %{x: x, y: y}
      }) do
    Process.exit(bullet_pid, :shutdown)
    Game.Server.explosion(game_id, x, y)
    Ship.Server.hyperspace(ship_pid)
    publish_news(game_id, [shooter_tag, "kills", victim_tag])
  end

  def bullet_hit_asteroid(
        game_id,
        %{pid: bullet_pid, shooter: shooter_tag, pos: %{x: x, y: y}},
        %{pid: asteroid_pid}
      ) do
    Process.exit(bullet_pid, :shutdown)
    Asteroid.destroyed(asteroid_pid)
    Game.Server.explosion(game_id, x, y)
    publish_news(game_id, [shooter_tag, "shot", @asteroid])
  end
end
