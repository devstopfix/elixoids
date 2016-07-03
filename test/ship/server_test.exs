defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  doctest Ship.Server

  alias Ship.Server, as: Ship

  test "New player points north" do
    {:ok, ship} = Ship.start_link(1, "AAA")
    {_pos, 0.0, "AAA", _} = Ship.nose_tag(ship)    
  end

  test "Retrive nose of ship and its tag" do
    {:ok, ship} = Ship.start_link(1, "AAA")
    {_pos, _theta, tag, _} = Ship.nose_tag(ship)
    assert "AAA" == tag
  end

  test "Hyperspace moves ship but keeps identify" do
    {:ok, ship} = Ship.start_link(1, "TAG")
    {p1, theta1, "TAG", _} = Ship.nose_tag(ship)
    Ship.hyperspace(ship)
    {p2, theta2, "TAG", _} = Ship.nose_tag(ship)

    assert p1 != p2
    assert theta1 != theta2
  end

  test "Valid player tags" do
    assert Ship.valid_player_tag?("AAA")
    assert Ship.valid_player_tag?("ZZZ")
  end

  test "Invalid player tags" do
    refute Ship.valid_player_tag?("AA")
    refute Ship.valid_player_tag?("ZZZZ")
    refute Ship.valid_player_tag?("A1A")
  end

  test "Test firing laser" do
    {:ok, ship} = Ship.start_link(1, "AAA")
    {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)

    :timer.sleep(300)
    {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

    Ship.fire(ship)
    :timer.sleep(10)
    {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)

    :timer.sleep(300)
    {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

    Ship.hyperspace(ship)
    {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)
  end

end
