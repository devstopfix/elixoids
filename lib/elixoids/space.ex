defmodule Elixoids.Space do

  @moduledoc """
  Define the play area (world) in which the Game is played.
  All units are in metres.
  """

  #alias World.Position, as: Position

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

  # TODO try with pattern matching
  defp wrap_x p do
  	{x,_y} = p
  	cond do
  	  x < 0.0    -> %{p | x: x + @width }
  	  x > @width -> %{p | x: x - @width }
  	  true       -> p
  	end
  end

  defp wrap_y p do
  	{_x,y} = p
  	cond do
  	  y < 0.0     -> %{p | y: y + @height}
  	  y > @height -> %{p | y: y - @height}
  	  true        -> p
  	end
  end

  def inside? p do
  	{x, y} = p
  	(x >= 0.0) && (x < @width) && (y >= 0.0) && (y < @height)
  end

end