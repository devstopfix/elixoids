defmodule Elixoids.SpaceTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest Elixoids.Space

  alias Elixoids.Space, as: Space
  alias World.Point, as: Point

  property :wrap_any_point_into_screen do
    for_all {x, y} in {real, real} do
      p = %Point{x: x, y: y}
      p2 = Space.wrap(p)
      assert p2.x >= p.x
      assert p2.y >= 0.0
    end
  end

  test "Random point" do
    p1 = Space.random_point
    p2 = Space.random_point
    assert p1.x != p2.x
    assert p1.y != p2.y
  end

  test "Random_point_on_border" do
    p1 = Space.random_point_on_border
    p2 = Space.random_point_on_border
    assert p1.x != p2.x
    assert p1.y != p2.y

    assert (p1.x == 0.0) || (p2.x == 0.0)
    assert (p1.y == 0.0) || (p2.y == 0.0)
  end
	
end