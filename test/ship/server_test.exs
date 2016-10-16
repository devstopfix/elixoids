defmodule Ship.ServerTest do
  use ExUnit.Case, async: false
  use ExCheck
  doctest Ship.Server

<<<<<<< HEAD
  alias Ship.Server, as: Ship

  # Test that we can rotate from any starting angle to any finishing angle
  # within the maximum turn duration of a Ship (3 seconds)
  property :rotate_ship_completely do
    for_all {theta, target_theta} in {int(-6,6), int(0,6)} do
      ship = %{theta: theta, target_theta: target_theta}

      rotated_ship = Ship.rotate_ship(ship, 3 * 1000)

      assert rotated_ship.theta == target_theta
    end
  end

  # Test that any rotation within a single frame takes the shortest path
  property :rotate_ship_takes_shortest_path do
    for_all {theta, target_theta} in {int(-6,6), int(0,6)} do
      ship = %{theta: theta, target_theta: target_theta}

      rotated_ship = Ship.rotate_ship(ship, 16)

      original_delta = abs(theta-target_theta)
      final_delta = abs(rotated_ship.theta-target_theta)

      assert final_delta < original_delta
    end
  end

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
    {:ok, ship} = Ship.start_link(1, "PLY")
    {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)

    Ship.new_heading(ship, 0.0)
    :timer.sleep(10)
    {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)
  end

  test "Rotate clockwise" do
    {:ok, game} = Game.Server.start_link
    {:ok, ship} = Ship.start_link(1, "PLY")
    {_pos, 0.0, "PLY", false} = Ship.nose_tag(ship)

    Ship.new_heading(ship, 0.785)
    Ship.move(ship, 1000.0, game)
    {_pos, 0.785, "PLY", _} = Ship.nose_tag(ship)
  end

  test "Rotate clockwise and then counter-clockwise" do
    {:ok, game} = Game.Server.start_link
    {:ok, ship} = Ship.start_link(1, "PLY")
    {_pos, 0.0, "PLY", false} = Ship.nose_tag(ship)

    Ship.new_heading(ship, 0.785)
    Ship.move(ship, 1000.0, game)
    {_pos, 0.785, "PLY", _} = Ship.nose_tag(ship)

    Ship.new_heading(ship, 0.0)
    Ship.move(ship, 1000.0, game)
    {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)
  end
=======
#  alias Ship.Server, as: Ship

  # TODO convert this to callbacks

  # test "New player points east" do
  #   {:ok, ship} = Ship.start_link(1, self(), "AAA")
  #   {_pos, 0.0, "AAA", _} = Ship.nose_tag(ship)    
  # end

  # test "Retrive nose of ship and its tag" do
  #   {:ok, ship} = Ship.start_link(1, self(), "AAA")
  #   {_pos, _theta, tag, _} = Ship.nose_tag(ship)
  #   assert "AAA" == tag
  # end

  # test "Hyperspace moves ship but keeps identify" do
  #   {:ok, ship} = Ship.start_link(1, self(), "TAG")
  #   {p1, theta1, "TAG", _} = Ship.nose_tag(ship)
  #   Ship.hyperspace(ship)
  #   {p2, theta2, "TAG", _} = Ship.nose_tag(ship)

  #   assert p1 != p2
  #   assert theta1 != theta2
  # end

  # test "Test firing laser" do
  #   {:ok, ship} = Ship.start_link(1, self(), "AAA")
  #   {_pos, _theta, "AAA", _} = Ship.nose_tag(ship)

  #   :timer.sleep(800)
  #   {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

  #   Ship.fire(ship)
  #   :timer.sleep(10)
  #   {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)

  #   :timer.sleep(800)
  #   {_pos, _theta, "AAA", true} = Ship.nose_tag(ship)

  #   Ship.hyperspace(ship)
  #   {_pos, _theta, "AAA", false} = Ship.nose_tag(ship)
  # end

  # test "Stationary" do
  #   {:ok, ship} = Ship.start_link(1, self(), "PLY")
  #   {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)

  #   Ship.new_heading(ship, 0.0)
  #   :timer.sleep(10)
  #   {_pos, 0.0, "PLY", _} = Ship.nose_tag(ship)
  # end

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
>>>>>>> master

end
