defmodule Elixir.Translate do
  @moduledoc """
  Translate the game state and center it over a co-ordinate.
  """

  alias Bullet.Server, as: Bullet
  alias Elixoids.World.Point
  alias Elixoids.World.Polar
  alias World.Velocity

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

    p = Polar.subtract(pos, origin)
    # TODO round angle

    [id, p.theta, r, round_cm(p.distance)]
  end

  def ships_relative(ships, origin) do
    ships
    |> Enum.map(fn s -> ship_relative(s, origin) end)
    |> Enum.filter(fn s -> Bullet.in_range?(List.last(s)) end)
  end

  defp ship_relative(%{tag: tag, pos: pos}, origin) do
    p = Polar.subtract(pos, origin)
    # TODO round angle

    [tag, p.theta, round_cm(p.distance)]
  end

  # TODO move rounding to Polar.round_dp
  defp round_cm(x), do: Float.round(x, 2)
end
