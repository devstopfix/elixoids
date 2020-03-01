defmodule Elixoids.Test.Generators do
  alias Elixoids.World.Point
  import :triq_dom, except: [atom: 0], only: :functions

  # Floats

  defp to_float(i), do: i * 1.0

  defp small_float, do: 0..10 |> Enum.map(&to_float/1) |> oneof()

  defp mid_float, do: 0..120 |> Enum.map(&to_float/1) |> oneof()

  defp world_float,
    do:
      float()
      |> bind(&abs/1)
      |> suchthat(fn f -> f < 2000.0 end)

  defp gen_world_float,
    do: oneof([oneof([0.0]), small_float(), mid_float(), world_float()])

  # Positions in the world

  def gen_point,
    do: bind([gen_world_float(), gen_world_float()], fn [x, y] -> %Point{x: x, y: y} end)

  # Angles

  defp major_angle,
    do:
      [0.0, 1.0, 2.0, 3.0]
      |> oneof()
      |> bind(fn n -> n * :math.pi() / 2.0 end)

  defp any_angle, do: float() |> bind(fn f -> :math.fmod(f, :math.pi()) end)

  def gen_theta, do: oneof([oneof([0.0]), major_angle(), any_angle()])

  def gen_game_id,
    do:
      oneof([
        oneof([0, 1]),
        pos_integer()
      ])
end
