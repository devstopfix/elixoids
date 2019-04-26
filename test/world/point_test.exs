defmodule World.PointTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.World.Point
  alias World.Velocity, as: Velocity

  property :apply_velocity_to_point do
    for_all {x, y, theta, speed} in {real(), real(), real(), real()} do
      p1 = %Point{x: x, y: y}
      v = %Velocity{theta: theta, speed: speed}
      p2 = Point.apply_velocity(p1, v, 1)
      assert p2.x != p1.x
    end
  end

  test :move_point_by_velocity do
    p1 = %Point{x: 10.0, y: 10.0}
    v = %Velocity{theta: :math.pi() / 8, speed: 10.0}
    p2 = Point.apply_velocity(p1, v, 1000)
    assert p2.x == 19.238795325112868
    assert p2.y == 13.826834323650898
  end
end
