defmodule Elixir.Translate do
  @moduledoc """
  Translate the game state to the position of a ship.
  """

  alias Bullet.Server, as: Bullet
  alias Elixoids.World.Point
  alias Elixoids.World.Polar
  import Elixoids.World.RoundDP

  @doc """
  Translate asteroids in game relative to ship.
  """
  @spec asteroids_relative(list(map()), Point.t()) :: list(list())
  def asteroids_relative(rocks, origin) do
    rocks
    |> Enum.map(fn a -> asteroid_relative(a, origin) end)
    |> Enum.filter(fn s -> Bullet.in_range?(List.last(s)) end)
  end

  defp asteroid_relative(asteroid, origin) do
    %{id: id, pos: pos, radius: r} = asteroid
    p = pos |> Polar.subtract(origin) |> round_dp()
    [id, p.theta, r, p.distance]
  end

  def ships_relative(ships, origin) do
    ships
    |> Enum.map(fn s -> ship_relative(s, origin) end)
    |> Enum.filter(fn s -> Bullet.in_range?(List.last(s)) end)
  end

  defp ship_relative(%{tag: tag, pos: pos}, origin) do
    p = pos |> Polar.subtract(origin) |> round_dp()
    [tag, p.theta, p.distance]
  end
end
