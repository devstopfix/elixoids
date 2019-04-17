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
    Game.Server.explosion(game_id, x, y)
    Game.Server.asteroid_hit(game_id, asteroid_pid)
    publish_news(game_id, [shooter_tag, "shot", "ASTEROID"])
  end
end
