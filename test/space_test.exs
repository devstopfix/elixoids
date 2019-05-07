defmodule Elixoids.SpaceTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest Elixoids.Space

  alias Elixoids.Space, as: Space

  test "Random_point_on_border" do
    p1 = Space.random_point_on_border()
    p2 = Space.random_point_on_border()

    assert p1.x != p2.x || p1.y != p2.y

    assert p1.x == 0.0 || p1.y == 0.0
    assert p2.x == 0.0 || p2.y == 0.0
  end

  test "Random grid point" do
    p1 = Space.random_grid_point()
    p2 = Space.random_grid_point()
    assert p1.x != p2.x
    assert p1.y != p2.y

    assert p1.x > 0
    assert p1.y > 0
    assert p2.x > 0
    assert p2.y > 0
  end
end
