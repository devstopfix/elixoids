defmodule World.Point do
  @moduledoc """
  The (x,y) position in 2D. Origin is at bottom left.
  """

  defstruct x: 0.0, y: 0.0

  @ms_in_s 1000.0

  @doc """
  Move point p by (dx,dy).
  """
  def move(p, dx, dy) do
    %{p | x: p.x + dx, y: p.y + dy}
  end

  @doc """
  Apply velocity v to point p.
  """
  def apply_velocity(p, v, delta_t_ms) do
    dx = :math.cos(v.theta) * v.speed * delta_t_ms / @ms_in_s
    dy = :math.sin(v.theta) * v.speed * delta_t_ms / @ms_in_s
    move(p, dx, dy)
  end

  @doc """
  Round ordinate to 1dp.
  """
  def round(o) do
    Float.round(o, 1)
  end

  @doc """
  Distance between two points (Pythagoras)
  """
  def distance(x1, y1, x2, y2) do
    :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
  end
end
