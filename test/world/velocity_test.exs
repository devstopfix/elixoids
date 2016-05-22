defmodule IEEE.MacTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest World.Velocity
  alias World.Velocity, as: Velocity

  test "stationary" do
    v = %Velocity{}

    assert 0.0 = v.speed
  end

end