defmodule World.PointTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest World.Point

  alias World.Point, as: Point
  alias World.Velocity, as: Velocity

  test "Origin" do
    p = %Point{}
    assert 0.0 = p.x
    assert 0.0 = p.y
  end

  property :move_point do
    for_all {x, y, dx, dy} in {real(), real(), real(), real()} do
      p1 = %Point{x: x, y: y}
      p2 = Point.move(p1, dx, dy)
      assert p2.x == p1.x + dx
      assert p2.y == p1.y + dy
    end
  end

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

  test "Move point East" do
    p1 = %Point{x: 10.0, y: 10.0}
    v = %Velocity{theta: 0, speed: 10.0}
    p2 = Point.apply_velocity(p1, v, 1000)
    assert p2.x == 20.0
    assert p2.y == 10.0
  end
end
