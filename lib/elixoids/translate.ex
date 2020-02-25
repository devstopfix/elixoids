defmodule Elixoids.Translate do
  @moduledoc """
  Translate the game state to the position of a ship.
  """

  alias Elixoids.Bullet.Server, as: Bullet
  alias Elixoids.World.Point
  alias Elixoids.World.Polar

  @doc """
  Translate asteroids in game relative to ship.
  """
  @spec asteroids_relative(list(map()), Point.t()) :: list(list())
  def asteroids_relative(rocks, origin) do
    rocks
    |> Enum.map(fn a -> asteroid_relative(a, origin) end)
    |> Enum.filter(fn [_, _, _, d] -> Bullet.in_range?(d) end)
  end

  defp asteroid_relative(asteroid, origin) do
    %{id: id, pos: pos, radius: r} = asteroid
    %{theta: theta, distance: distance} = pos |> Polar.subtract(origin)
    [id, Float.round(theta, 3), r, Float.round(distance)]
  end

  def ships_relative(ships, origin) do
    ships
    |> Enum.map(fn s -> ship_relative(s, origin) end)
    |> Enum.filter(fn [_, _, d] -> Bullet.in_range?(d) end)
  end

  defp ship_relative(%{tag: tag, pos: pos}, origin) do
    %{theta: theta, distance: distance} = pos |> Polar.subtract(origin)
    [tag, Float.round(theta, 3), Float.round(distance)]
  end
end
