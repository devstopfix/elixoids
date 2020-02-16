defmodule World.AngleTest do
  use ExUnit.Case, async: true

  import Elixoids.World.Angle

  test "Wrap angle" do
    assert 0.0 == normalize_radians(0.0)
  end

  test "Wrap negative angle" do
    assert :math.pi() == normalize_radians(-1 * :math.pi())
  end

  test "Wrap overflow angle" do
    assert :math.pi() == normalize_radians(3 * :math.pi())
  end
end
