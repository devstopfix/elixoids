defmodule Elixoids.Space do

  @moduledoc """
  Define the play area (world) in which the Game is played.
  All units are in metres.
  """

  alias World.Point, as: Point

  # The ratio of the play area
  @ratio 16.0 / 9.0

  @width 4000.0 # 4km
  @height @width / @ratio


  @doc """
  Wrap point p so that its coordinates remain inside the world.
  """
  def wrap p do
    p
    |> wrap_x
    |> wrap_y  	
  end

  defp wrap_x(p) do
  	cond do
  	  p.x < 0.0    -> %{p| x: p.x + @width}
  	  p.x > @width -> %{p| x: p.x - @width}
  	  true         -> p
  	end
  end

  defp wrap_y(p) do
  	cond do
  	  p.y < 0.0     -> %{p | y: p.y + @height}
  	  p.y > @height -> %{p | y: p.y - @height}
  	  true          -> p
  	end
  end

  def random_point do
    %Point{x: (:rand.uniform * @width), y: (:rand.uniform * @height) }
  end

end