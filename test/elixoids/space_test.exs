defmodule Elixoids.SpaceTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest Elixoids.Space

  alias Elixoids.Space, as: Space
  alias World.Position, as: Position

  property :wrap_any_point_into_screen do
    for_all {x, y} in {real, real} do
      p = %Position{x: x, y: y}
      p2 = Space.wrap(p)
      assert p2.x >= p.x
      assert p2.y >= 0.0
    end
  end
	
end