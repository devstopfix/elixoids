defmodule Elixir.Translate do
  @moduledoc """
  Translate the game state and center it over a co-ordinate.
  """

  alias Bullet.Server, as: Bullet
  alias World.Point
  alias World.Velocity

  @doc """
      {:ok, game} = Elixoids.Game.Supervisor.start_game([fps: 4, asteroids: 2])
      Game.Server.show(game)
      Game.Server.spawn_player(game, "OUR")
      Game.Server.state_of_ship(game, "OUR")
  """
  @spec asteroids_relative(list(map()), float(), float()) :: list(list())
  def asteroids_relative(rocks, ship_x, ship_y) do
    rocks
    |> Enum.map(fn a -> asteroid_relative(a, ship_x, ship_y) end)
    |> Enum.filter(fn s -> Bullet.in_range?(List.last(s)) end)
  end

  defp asteroid_relative(asteroid, ox, oy) do
    %{id: id, pos: %{x: ax, y: ay}, radius: r} = asteroid

    d = Point.distance(ox, oy, ax, ay)

    theta = :math.atan2(ay - oy, ax - ox)

    theta
    |> Velocity.wrap_angle()
    |> Velocity.round_theta()

    [id, theta, r, Point.round(d)]
  end

  def ships_relative(ships, ship_x, ship_y) do
    ships
    |> Enum.map(fn s -> ship_relative(s, ship_x, ship_y) end)
    |> Enum.filter(fn s -> Bullet.in_range?(List.last(s)) end)
  end

  defp ship_relative(ship, ox, oy) do
    {_, tag, sx, sy, _, _, _} = ship

    d = Point.distance(ox, oy, sx, sy)

    theta = :math.atan2(sy - oy, sx - ox)

    theta
    |> Velocity.wrap_angle()
    |> Velocity.round_theta()

    [tag, theta, Point.round(d)]
  end
end
