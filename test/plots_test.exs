defmodule Elixoids.PlotsTest do
  use ExUnit.Case, async: false

  alias Elixoids.Space
  import Gnuplot

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
