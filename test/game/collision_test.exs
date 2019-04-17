defmodule Game.CollisionTest do
  use ExUnit.Case, async: true

  doctest Game.Collision

  alias Game.Collision, as: Collision

  test "No collision between asteroid and rock" do
    ship = {1, "AAA", 1020.0, 0, 20, 5.8957, "FFFFFF"}
    asteroid = %{id: 2, pos: %{x: 899.0, y: 0}, radius: 80}

    assert false == Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between touching asteroid and rock" do
    ship = {1, "AAA", 1020.0, 0, 20.0, 5.8957, "FFFFFF"}
    asteroid = %{id: 2, pos: %{x: 920.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between overlapping asteroid and rock" do
    ship = {1, "AAA", 1000.0, 0, 20, 5.8957, "FFFFFF"}
    asteroid = %{id: 2, pos: %{x: 1000.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Detect between overlapping asteroid and rock" do
    ship = {51, "AAA", 1000.0, 0, 20, 5.8957, "FFFFFF"}

    asteroid1 = %{id: 73, pos: %{x: 1000.0, y: 0}, radius: 80}
    asteroid2 = %{id: 99, pos: %{x: 1000.0, y: 200}, radius: 80}

    asteroids = [asteroid1, asteroid2]

    assert [{asteroid1, ship}] == Collision.detect_asteroids_hitting_ships(asteroids, [ship])
  end

  test "No collision" do
    bullets = [
      %{id: 869, pos: %{x: 1408.1, y: 427.8}, pid: self()},
      %{id: 687, pos: %{x: 500.8, y: 500.4}, pid: self()}
    ]

    ships = [
      {1, "AAA", 120.3, 864.4, 20, 5.8957, "FFFFFF"},
      {2, "BBB", 545.6, 757.5, 20, 0.5861, "FFFFFF"}
    ]

    assert [] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision between bullet and one of two ships" do
    bullets = [
      %{id: 869, pos: %{x: 1408.1, y: 427.8}, pid: self()},
      %{id: 666, pos: %{x: 500.8, y: 500.4}, pid: self()}
    ]

    ship_1 = {1, "AAA", 500.3, 501.4, 20, 5.8957, "FFFFFF"}

    ships = [
      ship_1,
      {2, "BBB", 500.6, 501.5, 20, 0.5861, "FFFFFF"}
    ]

    assert [{%{id: 666}, ship_1}] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision between bullet and ship" do
    assert Collision.bullet_hits_ship?(%{pos: %{x: 5, y: 5}}, {0, "", 4, 4, 20, 0, ""})
  end

  test "Collision between bullet and asteroid" do
    asteroid = %{id: 2, pos: %{x: 4.0, y: 4.0}, radius: 20}

    assert Collision.bullet_hits_asteroid?(%{pos: %{x: 5, y: 5}}, asteroid)
  end

  test "No Collision" do
    refute Collision.bullet_hits_ship?(%{pos: %{x: 50, y: 50}}, {1, "", 4, 4, 20, 0, ""})
    refute Collision.bullet_hits_ship?(%{pos: %{x: 0, y: 50}}, {2, "", 4, 4, 20, 0, ""})
    refute Collision.bullet_hits_ship?(%{pos: %{x: 50, y: 0}}, {3, "", 4, 4, 20, 0, ""})
  end

  test "Unique ships" do
    assert [3, 4, 5] == Collision.unique_targets([{1, 3}, {2, 4}, {1, 5}])
  end
end
