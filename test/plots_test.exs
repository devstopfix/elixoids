defmodule Elixoids.PlotsTest do
  use ExUnit.Case, async: false

  alias Elixoids.Space
  import Gnuplot

  @tag :gnuplot
  test "Sound panning bathtub curves" do
    for p <- [3,5,7], do: assert {:ok, _ } = plot([
      [:set, :title, "Pan curves"],
      ~w(set style line 1 lc rgb '#000000')a,
      [:plot, -1..1, 'x**' ++ inspect(p), :ls, 1]
    ])
  end

  @tag :gnuplot
  test "Sound panning function" do
    xs = Enum.take_every(0..4000, 50)

    assert {:ok, _cmd} =
             plot(
               [
                 [:set, :title, "Sound panning"],
                 ~w(set style line 1 lc rgb '#000000' pt 2)a,
                 [:plot, "-", :title, "frac_x(x)", :with, :points, :ls, 1]
               ],
               [for(x <- xs, do: [x, Space.frac_x(x)])]
             )
  end

  @tag :gnuplot
  test "Ship spawning locations" do
    ps = for _ <- 1..100, do: Space.random_grid_point()

    assert {:ok, _cmd} =
             plot(
               [
                 [:set, :title, "Ship grid points"],
                 [:set, :key, :left, :top],
                 [:set, :xrange, 0..4000],
                 [:set, :yrange, 0..2250],
                 ~w(set style line 1 lc rgb '#000000' pt 10)a,
                 [:plot, "-", :title, "Ship", :with, :points, :ls, 1]
               ],
               [for(%{x: x, y: y} <- ps, do: [x, y])]
             )
  end

  @tag :gnuplot
  test "Asteroid spawning locations" do
    ps = for _ <- 1..100, do: Space.random_point_on_border()

    assert {:ok, _cmd} =
             plot(
               [
                 [:set, :title, "Asteroid starting points"],
                 [:set, :key, :left, :top],
                 ~w(set style line 1 lc rgb '#000000' pt 7)a,
                 [:plot, "-", :title, "Asteroid", :with, :points, :ls, 1]
               ],
               [for(%{x: x, y: y} <- ps, do: [x, y])]
             )
  end
end
