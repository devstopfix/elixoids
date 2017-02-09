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
    %Point{x: (:rand.uniform * @width), y: (:rand.uniform * @height)}
  end

  def random_point_on_border() do
    if :rand.uniform * @ratio < 1.0 do
      %Point{x: (:rand.uniform * @width), y: 0.0}
    else
      %Point{x: 0.0, y: (:rand.uniform * @height)}
    end
  end

  def random_central_point do
    x = Float.ceil((@width  / 2) + (:rand.normal * (@width  / 8.0)))
    y = Float.ceil((@height / 2) + (:rand.normal * (@height / 8.0)))
    %Point{x: x, y: y}
  end

  def dimensions do
    [@width, @height]
  end

  # Points on a grid

  @grid_points 7
  @gx @width / @grid_points
  @gy @height / @grid_points

  def rand_grid_index do
    :rand.uniform(@grid_points - 1)
  end

  def rand_grid_position(grid_size_px) do
    perturb = :rand.normal * (grid_size_px / 8.0)
    (grid_size_px * rand_grid_index()) + perturb
  end

  def random_grid_point do
    x = rand_grid_position(@gx)
    y = rand_grid_position(@gy)
    %Point{x: x, y: y}
  end

end
