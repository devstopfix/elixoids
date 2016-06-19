defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  doctest Bullet.Server

  alias Ship.Server, as: Ship

  test "Retrive nose of ship and its tag" do
    {:ok, ship} = Ship.start_link(1, "AAA")
    {_pos, _theta, tag} = Ship.nose_tag(ship)
    assert "AAA" == tag
  end

end
