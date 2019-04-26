defmodule Elixoids.Test.Generators do
  alias Elixoids.World.Point
  import :triq_dom, except: [atom: 0], only: :functions

  # Floats

  defp to_float(i), do: i * 1.0

  defp small_float, do: 0..10 |> Enum.map(&to_float/1) |> :triq_dom.oneof()

  defp mid_float, do: 0..120 |> Enum.map(&to_float/1) |> :triq_dom.oneof()

  defp world_float,
    do:
      :triq_dom.float()
      |> :triq_dom.bind(&abs/1)
      |> :triq_dom.suchthat(fn f -> f < 2000.0 end)

  defp gen_world_float,
    do: :triq_dom.oneof([:triq_dom.oneof([0.0]), small_float(), mid_float(), world_float()])

  def gen_point,
    do:
      :triq_dom.bind([gen_world_float(), gen_world_float()], fn [x, y] -> %Point{x: x, y: y} end)
end
