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

end