defmodule World.VelocityTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest World.Velocity

  alias World.Velocity, as: Velocity

  test "Stationary" do
    v = %Velocity{}
    assert 0.0 = v.speed
  end

  test "Random Velocity" do
    v1 = Velocity.random_direction_with_speed(10.0)
    v2 = Velocity.random_direction_with_speed(10.0)
    assert 10.0 = v1.speed
    assert 10.0 = v2.speed
    assert v1.theta != v2.theta
  end

  test "Wrap angle" do
    assert 0.0 == Velocity.wrap_angle(0.0)
  end

  test "Wrap negative angle" do
    assert :math.pi() == Velocity.wrap_angle(-1 * :math.pi())
  end

  test "Wrap overflow angle" do
    assert :math.pi() == Velocity.wrap_angle(3 * :math.pi())
  end

  property :double_velocity_doubles_speed do
    for_all {speed} in {real()} do
      v1 = Velocity.random_direction_with_speed(speed)
      assert v1.speed == speed

      v2 = Velocity.double(v1)

      assert v2.speed == speed * 2
      assert v1.theta == v2.theta
    end
  end

  test :fork_velocity do
    v = Velocity.north()

    vl = Velocity.fork(v, 0.2)
    vr = Velocity.fork(v, -0.2)

    assert vl.speed == v.speed
    assert vr.speed == v.speed

    assert vl.theta > v.theta
    assert vr.theta < v.theta
  end
end
