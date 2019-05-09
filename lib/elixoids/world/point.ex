defmodule Elixoids.World.Point do
  @moduledoc "(x,y) position in 2D, origin is at bottom left, units are meters."

  alias Elixoids.World.RoundDP

  @type t :: %{x: number(), y: number()}

  defstruct x: 0.0, y: 0.0

  @doc "Translation"
  @spec translate(t(), number(), number()) :: t()
  def translate(p, dx, dy), do: %{p | x: p.x + dx, y: p.y + dy}

  @spec distance_between(t(), t()) :: float()
  def distance_between(%{x: x1, y: y1}, %{x: x2, y: y2}) do
    :math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
  end

  @spec move(t(), number(), number()) :: t()
  def move(p, theta, distance) do
    translate(p, :math.cos(theta) * distance, :math.sin(theta) * distance)
  end

  defimpl RoundDP, for: __MODULE__ do
    @doc "Round position accurate to cm"
    def round_dp(%{x: x, y: y} = p), do: %{p | x: Float.round(x, 2), y: Float.round(y, 2)}
  end
end
