defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  doctest Ship.Server

  alias Ship.Server, as: Ship

  test "New player points north" do
    {:ok, ship} = Ship.start_link(1, self(), "AAA")
    {_pos, 0.0, "AAA", _} = Ship.nose_tag(ship)    
  end

  test "Retrive nose of ship and its tag" do
    {:ok, ship} = Ship.start_link(1, self(), "AAA")
    {_pos, _theta, tag, _} = Ship.nose_tag(ship)
    assert "AAA" == tag
  end

  test "Hyperspace moves ship but keeps identify" do
    {:ok, ship} = Ship.start_link(1, self(), "TAG")
    {p1, theta1, "TAG", _} = Ship.nose_tag(ship)
    Ship.hyperspace(ship)
    {p2, theta2, "TAG", _} = Ship.nose_tag(ship)

    assert p1 != p2
    assert theta1 != theta2
  end

  test "Test firing laser" do
    {:ok, ship} = Ship.start_link(1, self(), "AAA")
    {_pos, _theta, "AAA", _} = Ship.nose_tag(ship)

    :timer.sleep(800)
    {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

    Ship.fire(ship)
    :timer.sleep(10)
    {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)

    :timer.sleep(800)
    {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

    Ship.hyperspace(ship)
    {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)
  end

  test "Stationary" do
    {:ok, ship} = Ship.start_link(1, self(), "PLY")
    {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)

    Ship.new_heading(ship, 0.0)
    :timer.sleep(10)
    {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)
  end

  # test "Rotate clockwise" do
  #   {:ok, game} = Game.Server.start_link
  #   {:ok, ship} = Ship.start_link(1, game, "PLY")
  #   {_pos, 0.0, "PLY", false} = Ship.nose_tag(ship)

  #   Ship.new_heading(ship, 0.785)
  #   Ship.move(ship, 1000.0, game)
  #   {_pos, 0.785, "PLY", _} = Ship.nose_tag(ship)
  # end

  # test "Rotate clockwise and then counter-clockwise" do
  #   {:ok, game} = Game.Server.start_link
  #   {:ok, ship} = Ship.start_link(1, game, "PLY")
  #   {_pos, 0.0, "PLY", false} = Ship.nose_tag(ship)

  #   Ship.new_heading(ship, 0.785)
  #   :timer.sleep(1000)
  #   {_pos, 0.785, "PLY", _} = Ship.nose_tag(ship)

  #   Ship.new_heading(ship, 0.0)
  #   :timer.sleep(1000)
  #   {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)
  # end

end
