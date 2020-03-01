defmodule Elixoids.Event do
  @moduledoc """
  Logic to dispatch game events to processes.
  """

  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Ship.Server, as: Ship
  import Elixoids.News

  @asteroid "ASTEROID"

  def asteroid_hit_ship(
        {_, %{pid: asteroid_pid, radius: radius},
         %{
           id: ship_id,
           tag: tag,
           pos: pos
         }, game_id}
      ) do
    Ship.hyperspace(ship_id)
    Game.explosion(game_id, pos, radius)
    Asteroid.destroyed(asteroid_pid)
    publish_news(game_id, [@asteroid, "hit", tag])
  end

  def bullet_hit_ship(
        {_, %{pid: bullet_pid, shooter: shooter_tag},
         %{
           id: ship_id,
           tag: victim_tag
         }, game_id}
      ) do
    Process.exit(bullet_pid, {:shutdown, :detonate})
    publish_news(game_id, [shooter_tag, "shot", victim_tag])
    Ship.bullet_hit_ship(ship_id, shooter_tag)
  end

  def bullet_hit_asteroid(
        {_, %{pid: bullet_pid, shooter: shooter_tag, pos: pos},
         %{pid: asteroid_pid, radius: radius}, game_id}
      ) do
    Process.exit(bullet_pid, {:shutdown, :detonate})
    Asteroid.destroyed(asteroid_pid)
    Game.explosion(game_id, pos, radius)
    radius_s = radius |> round() |> Integer.to_string()
    publish_news(game_id, [shooter_tag, "shot", @asteroid, radius_s])
  end

  def ship_hit_ship(
        {_,
         %{
           id: ship1_id,
           tag: tag1,
           pos: pos1,
           radius: radius1
         },
         %{
           id: ship2_id,
           tag: tag2,
           pos: pos2,
           radius: radius2
         }, game_id}
      ) do
    Ship.hyperspace(ship1_id)
    Ship.hyperspace(ship2_id)
    Game.explosion(game_id, pos1, radius1)
    Game.explosion(game_id, pos2, radius2)
    publish_news(game_id, [tag1, "hit", tag2])
  end
end
