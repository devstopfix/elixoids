defmodule Elixoids.World.PointTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.World.Point
  alias Elixoids.World.Velocity
  import Elixoids.Test.Generators

  property :apply_velocity_to_point do
    for_all {p1, theta, speed} in {gen_point(), real(), real()} do
      v = %Velocity{theta: theta, speed: speed}
      p2 = Velocity.apply_velocity(p1, v, 1)
      assert p2.x != p1.x
    end
  end

  test :move_point_by_velocity do
    p1 = %Point{x: 10.0, y: 10.0}
    v = %Velocity{theta: :math.pi() / 8, speed: 10.0}
    p2 = Velocity.apply_velocity(p1, v, 1000)
    assert p2.x == 19.238795325112868
    assert p2.y == 13.826834323650898
  end
end
