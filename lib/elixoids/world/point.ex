defmodule Elixoids.World.Point do
  @moduledoc "(x,y) position in 2D, origin is at bottom left, units are meters."

  alias Elixoids.World.RoundDP

  @type t :: %{x: float(), y: float()}

  defstruct x: 0.0, y: 0.0

  @doc "Translation"
  def translate(p, dx, dy) do
    %{p | x: p.x + dx, y: p.y + dy}
  end

  @ms_in_s 1000.0

  @doc """
  Apply velocity v to point p.
  TODO move velocity out
  """
  def apply_velocity(p, v, delta_t_ms) do
    dx = :math.cos(v.theta) * v.speed * delta_t_ms / @ms_in_s
    dy = :math.sin(v.theta) * v.speed * delta_t_ms / @ms_in_s
    translate(p, dx, dy)
  end

  @doc """
  Distance between two points (Pythagoras)
  # TODO convert to points
  """
  def distance(x1, y1, x2, y2) do
    :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
  end

  defimpl RoundDP, for: __MODULE__ do
    @doc "Round position accruate to cm"
    def round_dp(%{x: x, y: y} = p), do: %{p | x: Float.round(x, 2), y: Float.round(y, 2)}
  end
end
