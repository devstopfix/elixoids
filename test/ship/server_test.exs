defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  doctest Bullet.Server

  alias Ship.Server, as: Ship


  test "Nose of ship is temporatily the centre" do
    {:ok, ship} = Ship.start_link(1)
    #Ship.position(ship, self())
    #receive do
    #  {:position}
    #end
    {pos, theta} = Ship.nose(ship)
    refute 0.0 == theta
    refute [] == pos
  end

end
