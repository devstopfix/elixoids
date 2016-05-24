defmodule World.VelocityTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest World.Velocity

  alias World.Velocity, as: Velocity

  test "Stationary" do
    v = %Velocity{}

    assert 0.0 = v.speed
  end

end