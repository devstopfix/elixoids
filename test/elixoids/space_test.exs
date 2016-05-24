defmodule Elixoids.SpaceTest do
  use ExUnit.Case, async: true
  use ExCheck
  doctest Elixoids.Space

  alias Elixoids.Space, as: Space
  alias World.Position, as: Position

  property :wrap do
    for_all {x, y} in {real, real} do
      p = %World.Position{x: x, y: y}
      assert Space.inside? p
    end
  end
	
end