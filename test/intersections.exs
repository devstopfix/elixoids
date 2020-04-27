#
# Chart our intersection generators.
#
#    MIX_ENV=test mix run test/intersections.exs
#
Code.require_file("test/generators.exs")

defmodule Elixoids.Intersections do
  @moduledoc "Chart intersection generators"

  import :triq_dom, except: [atom: 0], only: :functions
  import Elixoids.Collision.Server, only: [line_segment_intersects_circle?: 2]
  import Elixoids.Const, only: [asteroid_radius_m: 0]

  import Elixoids.Test.Generators,
    only: [
      line_inside_asteroid: 0,
      line_impaling_asteroid: 0,
      line_intersecting_asteroid: 0,
      line_outside_asteroid: 0
    ]

  import Gnuplot

  @lc_hit 7
  @lc_miss 6
  @num_plots 1..6
  @plot_layout '2,3'

  defp draw(title, datasets) do
    x = trunc(asteroid_radius_m()) + 10

    ps =
      Enum.map(@num_plots, fn _ ->
        plots([
          # ["-", :u, '1:2:3:1', :with, :circles, :linecolor, :variable, :notitle],
          ["-", :with, :circles, :linecolor, :variable, :notitle],
          ["-", :w, :lines, :linecolor, :variable, :notitle]
        ])
      end)

    {:ok, _cmd} =
      plot(
        [
          [:set, :title, title],
          [:set, :xrange, -x..x],
          [:set, :yrange, -x..x],
          [:set, :multiplot, :layout, @plot_layout]
        ] ++ ps,
        datasets
      )
  end

  defp circle({%{pos: %{x: x, y: y}, radius: r}, _, true}), do: [x, y, r, @lc_hit]
  defp circle({%{pos: %{x: x, y: y}, radius: r}, _, false}), do: [x, y, r, @lc_miss]

  defp line({_, {%{x: x1, y: y1}, %{x: x2, y: y2}}, intersects}) do
    col = if intersects, do: @lc_hit, else: @lc_miss
    [[x1, y1, col], [x2, y2, col], [], []]
  end

  defp test({c, {p1, p2}} = t), do: Tuple.append(t, line_segment_intersects_circle?([p1, p2], c))

  defp dataset(generator, n) do
    data = sample(generator) |> Enum.take(n) |> Enum.map(&test/1)
    [Enum.map(data, &circle/1), Enum.flat_map(data, &line/1)]
  end

  defp chart(title, generator) do
    datasets = Enum.flat_map(@num_plots, fn n -> dataset(generator, n) end)
    draw(title, datasets)
  end

  def main() do
    chart("Bullet missing asteroid", &line_outside_asteroid/0)
    chart("Bullet intersecting asteroid", &line_intersecting_asteroid/0)
    chart("Bullet inside asteroid", &line_inside_asteroid/0)
    chart("Bullet impaling asteroid", &line_impaling_asteroid/0)
  end
end

Elixoids.Intersections.main()
