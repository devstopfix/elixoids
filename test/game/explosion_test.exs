defmodule Game.ExplosionTest do
  use ExUnit.Case, async: true
  doctest Game.Explosion

  alias Game.Explosion, as: Explosion

  @t_past 1_471_605_231_831
  @t_future 2_271_605_231_831

  test "Default explosion struct" do
    ex = %Explosion{}

    assert 0.0 = ex.x
    assert 0.0 = ex.y
  end

  test "Convert struct to state sent to client" do
    ex = Explosion.at_xy(1.0, 2.0)
    assert [1.0, 2.0] == Explosion.to_state(ex)
  end
end
