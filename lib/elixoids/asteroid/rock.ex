defmodule Elixoids.Asteroid.Rock do
  @moduledoc "Attributes of an asteroid"

  alias Elixoids.World.Point
  alias World.Velocity

  defstruct pos: nil, velocity: nil, radius: 0.0

  # 45º
  @quarter_pi_radians :math.pi() / 4.0

  @doc """
  Cleave the rock into n pieces
  """
  # @spec cleave(map(), integer()) :: map()
  def cleave(rock, _n) do
    angle_offsets()
    |> Enum.map(&new(&1, rock))
  end

  defp halve(a, d \\ 2.0) do
    %{a | radius: a.radius / d}
  end

  defp angle_offsets, do: [@quarter_pi_radians, -@quarter_pi_radians]

  defp new(delta_theta, rock) do
    rock
    |> redirect(delta_theta)
    |> halve()
    |> bump()
    |> speedup()
  end

  defp redirect(rock, delta_theta) do
    update_in(rock.velocity, &Velocity.fork(&1, delta_theta))
  end

  defp speedup(a) do
    update_in(a.velocity, &Velocity.double(&1))
  end

  # Bump the asteroid in the direction it is facing, by half its radius
  defp bump(a) do
    t_ms = a.radius / a.velocity.speed * 1000 / 1.8
    update_in(a.pos, &Point.apply_velocity(&1, a.velocity, t_ms))
  end
end
