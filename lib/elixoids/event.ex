defmodule Elixoids.Event do
  @moduledoc """
  Logic to dispatch game events to processes.
  """

  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Ship.Server, as: Ship
  import Elixoids.News

  @asteroid "ASTEROID"

  def asteroid_hit_ship(game_id, %{pid: asteroid_pid, radius: radius}, %{
        id: ship_id,
        tag: tag,
        pos: pos
      }) do
    Ship.hyperspace(ship_id)
    Elixoids.Game.Server.explosion(game_id, pos, radius)
    Asteroid.destroyed(asteroid_pid)
    publish_news(game_id, [@asteroid, "hit", tag])
  end

  def bullet_hit_ship(game_id, %{pid: bullet_pid, shooter: shooter_tag}, %{
        id: ship_id,
        tag: victim_tag
      }) do
    Process.exit(bullet_pid, :shutdown)
    publish_news(game_id, [shooter_tag, "shot", victim_tag])
    Ship.bullet_hit_ship(ship_id, shooter_tag)
  end

  def bullet_hit_asteroid(
        game_id,
        %{pid: bullet_pid, shooter: shooter_tag, pos: pos},
        %{pid: asteroid_pid, radius: radius}
      ) do
    Process.exit(bullet_pid, :shutdown)
    Asteroid.destroyed(asteroid_pid)
    Elixoids.Game.Server.explosion(game_id, pos, radius)
    publish_news(game_id, [shooter_tag, "shot", @asteroid])
  end
end
