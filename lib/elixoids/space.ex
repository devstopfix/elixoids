defmodule Elixoids.Space do
  @moduledoc """
  Define the play area (world) in which the Game is played.
  All units are in metres.
  """

  alias Elixoids.World.Point
  import Elixoids.Const

  # The ratio of the play area
  @ratio world_ratio()

  @width world_width_m()
  @height @width / @ratio

  @border @width / 100

  @min_x -@border
  @max_x @width + @border

  @min_y -@border
  @max_y @height + @border

  @doc """
  Wrap point p so that its coordinates remain inside the world.
  """
  def wrap(p), do: p |> wrap_x |> wrap_y

  defp wrap_x(p) do
    cond do
      p.x < @min_x -> %{p | x: p.x + @width + @border + @border}
      p.x > @max_x -> %{p | x: p.x - @width - @border - @border}
      true -> p
    end
  end

  defp wrap_y(p) do
    cond do
      p.y < @min_y -> %{p | y: p.y + @height + @border + @border}
      p.y > @max_y -> %{p | y: p.y - @height - @border - @border}
      true -> p
    end
  end

  def random_point do
    %Point{x: :rand.uniform() * @width, y: :rand.uniform() * @height}
  end

  def random_point_on_vertical_edge do
    %Point{x: 0.0, y: :rand.uniform() * @height}
  end

  def random_point_on_border do
    if :rand.uniform() * @ratio < 1.0 do
      %Point{x: :rand.uniform() * @width, y: 0.0}
    else
      random_point_on_vertical_edge()
    end
  end

  def dimensions, do: [@width, @height]

  # Points on a grid

  @grid_points 8

  defp rand_grid_position(size_px, grid_count) do
    grid_size = size_px / grid_count
    p = :rand.uniform(grid_count - 1)
    x = grid_size * p
    perturb = :rand.normal() * grid_size / @grid_points
    x + perturb
  end

  @grid_points 8

  def random_grid_point do
    x = rand_grid_position(@width, @grid_points)
    y = rand_grid_position(@height, @grid_points - 2)
    %Point{x: x, y: y}
  end
end
