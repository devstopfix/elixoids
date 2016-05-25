defmodule World.PositionTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest World.Position

  alias World.Position, as: Position

  test "Origin" do
    p = %Position{}
    assert 0.0 = p.x
    assert 0.0 = p.y
  end

  property :move_point do
    for_all {x, y, dx, dy} in {real, real, real, real} do
      p1 = %Position{x: x, y: y}
      p2 = Position.move(p1, dx, dy)
      assert p2.x == p1.x + dx
      assert p2.y == p1.y + dy
    end
  end  

end