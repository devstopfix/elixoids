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
    assert :math.pi == Velocity.wrap_angle( -1 * :math.pi)
  end

  test "Wrap overflow angle" do
    assert :math.pi == Velocity.wrap_angle( 3 * :math.pi)
  end

end