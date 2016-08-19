defmodule Game.ExplosionTest do
  use ExUnit.Case, async: true
  doctest Game.Explosion

  alias Game.Explosion, as: Explosion

  @t_past   1471605231831
  @t_future 2271605231831

  test "Default explosion struct" do
    ex = %Explosion{}

    assert 0.0 = ex.x
    assert 0.0 = ex.y

    assert ex.at > @t_past 
  end

  test "Explosion at" do
    ex = Explosion.at_xy(1.0, 2.0)

    assert 1.0 = ex.x
    assert 2.0 = ex.y
  end

  test "Filter expired explosions" do
    ex1 = %Explosion{at: @t_past}
    ex2 = %Explosion{}
  	ex3 = %Explosion{at: @t_future}

    assert [ex2, ex3] == Explosion.filter_expired_explosions([ex1, ex2, ex3])
  end

  test "Convert struct to state sent to client" do
    ex = Explosion.at_xy(1.0, 2.0)
    assert [1.0, 2.0] == Explosion.to_state(ex)
  end

end
