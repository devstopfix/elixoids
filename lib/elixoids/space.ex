defmodule Elixoids.Space do
  @moduledoc """
  Define the play area (world) in which the Game is played.
  All units are in metres.
  """

  alias World.Point

  # The ratio of the play area
  @ratio 16.0 / 9.0

  # 4km
  @width 4000.0
  @height @width / @ratio
  @half_width @width / 2.0

  @doc """
  Wrap point p so that its coordinates remain inside the world.
  """
  def wrap(p), do: p |> wrap_x |> wrap_y

  defp wrap_x(p) do
    cond do
      p.x < 0.0 -> %{p | x: p.x + @width}
      p.x > @width -> %{p | x: p.x - @width}
      true -> p
    end
  end

  defp wrap_y(p) do
    cond do
      p.y < 0.0 -> %{p | y: p.y + @height}
      p.y > @height -> %{p | y: p.y - @height}
      true -> p
    end
  end

  def random_point do
    %Point{x: :rand.uniform() * @width, y: :rand.uniform() * @height}
  end

  def random_point_on_border do
    if :rand.uniform() * @ratio < 1.0 do
      %Point{x: :rand.uniform() * @width, y: 0.0}
    else
      %Point{x: 0.0, y: :rand.uniform() * @height}
    end
  end

  def dimensions, do: [@width, @height]

  # Points on a grid

  @grid_points 7
  @gx @width / @grid_points
  @gy @height / @grid_points

  def rand_grid_index do
    :rand.uniform(@grid_points - 1)
  end

  def rand_grid_position(grid_size_px) do
    perturb = :rand.normal() * (grid_size_px / 8.0)
    grid_size_px * rand_grid_index() + perturb
  end

  def random_grid_point do
    x = rand_grid_position(@gx)
    y = rand_grid_position(@gy)
    %Point{x: x, y: y}
  end

  @doc """
  Return the x ordinate as a fraction -1..1 of the screen width
  """
  def frac_x(x) do
    cond do
      x < 0.0 -> 0.0
      x > @width -> 0.0
      true -> (x - @half_width) / @half_width
    end
    |> Float.round(2)
  end
end
