defmodule Elixoids.Asteroid.Rock do
  @moduledoc "Attributes of an asteroid"

  alias Elixoids.World.Point
  alias Elixoids.World.Velocity

  defstruct pos: nil, velocity: %Velocity{}, radius: 0.0

  # 45º
  @quarter_pi_radians :math.pi() / 4.0

  @doc """
  Cleave the rock into 2 pieces
  """
  def cleave(rock), do: Enum.map(angle_offsets(), &new(&1, rock))

  defp halve(a), do: %{a | radius: a.radius / 2.0}

  defp angle_offsets, do: [@quarter_pi_radians, -@quarter_pi_radians]

  defp new(delta_theta, rock) do
    rock
    |> redirect(delta_theta)
    |> halve()
    |> bump()
    |> speedup()
  end

  defp redirect(rock, delta_theta) do
    update_in(rock.velocity, &Velocity.rotate(&1, delta_theta))
  end

  defp speedup(a), do: update_in(a.velocity, &Velocity.double_speed(&1))

  defp bump(a = %{radius: radius, velocity: %{theta: theta}}) do
    update_in(a.pos, &Point.move(&1, theta, radius))
  end
end
