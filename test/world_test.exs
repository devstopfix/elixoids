defmodule Elixoids.WorldTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.World.Point
  import Elixoids.Test.Generators

  test "Origin" do
    p = %Point{}
    assert 0.0 = p.x
    assert 0.0 = p.y
  end

  defmacro approx_eq(f1, f2) do
    quote do
      abs(unquote(f2) - unquote(f1)) <= 0.00001
    end
  end

  property :translate_point do
    for_all {p1, dx, dy} in {gen_point(), float(), float()} do
      p2 = Point.translate(p1, dx, dy)
      assert p2.x == p1.x + dx
      assert p2.y == p1.y + dy
      p3 = Point.translate(p2, -dx, -dy)
      assert approx_eq(p3.x, p1.x)
      assert approx_eq(p3.y, p1.y)
    end
  end
end
