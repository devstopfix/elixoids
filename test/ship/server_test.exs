defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  doctest Bullet.Server

  alias Ship.Server, as: Ship

  test "Retrive nose of ship and its tag" do
    {:ok, ship} = Ship.start_link(1, "AAA")
    {_pos, _theta, tag} = Ship.nose_tag(ship)
    assert "AAA" == tag
  end

  test "Hyperspace moves ship but keeps identify" do
    {:ok, ship} = Ship.start_link(1, "TAG")
    {p1, theta1, "TAG"} = Ship.nose_tag(ship)
    Ship.hyperspace(ship)
    {p2, theta2, "TAG"} = Ship.nose_tag(ship)

    assert p1 != p2
    assert theta1 != theta2
  end

end
