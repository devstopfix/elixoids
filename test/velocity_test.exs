defmodule Elixoids.World.VelocityTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.World.Velocity

  test "Stationary" do
    assert %{speed: 0.0} = %Velocity{}
  end

  property :double_velocity_doubles_speed do
    for_all {speed} in {real()} do
      v1 = Velocity.random_velocity(speed)
      assert v1.speed == speed

      v2 = Velocity.double_speed(v1)

      assert v2.speed == speed * 2
      assert v1.theta == v2.theta
    end
  end

  test :fork_velocity do
    v = Velocity.north()

    vl = Velocity.rotate(v, 0.2)
    vr = Velocity.rotate(v, -0.2)

    assert vl.speed == v.speed
    assert vr.speed == v.speed

    assert vl.theta > v.theta
    assert vr.theta < v.theta
  end
end
