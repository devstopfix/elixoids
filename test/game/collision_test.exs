defmodule Game.CollisionTest do
  use ExUnit.Case, async: true
  use ExCheck

  doctest Game.Collision

  alias Game.Collision, as: Collision

  test "No collision between asteroid and rock" do
    ship =     {1, "AAA", 1020.0, 0,  20, 5.8957, "FFFFFF"}
    asteroid = {2,         899.0, 0,  80}

    assert false == Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between touching asteroid and rock" do
    ship =     {1, "AAA", 1020.0, 0,  20.0, 5.8957, "FFFFFF"}
    asteroid = {2,         920.0, 0,  80.0}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between overlapping asteroid and rock" do
    ship =     {1, "AAA", 1000.0, 0,  20, 5.8957, "FFFFFF"}
    asteroid = {2,        1000.0, 0,  80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Detect between overlapping asteroid and rock" do
    ships =     [{51, "AAA", 1000.0, 0,  20, 5.8957, "FFFFFF"}]
    asteroids = [{73,        1000.0, 0,  80},
                 {99,        1000.0, 200, 80}]

    assert [{73,51}] == Collision.detect_asteroids_hitting_ships(asteroids, ships)
  end

  test "No collision" do
    bullets = [{6869, 1408.1, 427.8}, 
               {6870, 534.8, 1690.4}]
    ships = [{1, "AAA", 120.3, 864.4, 20, 5.8957, "FFFFFF"}, 
             {2, "BBB", 545.6, 757.5, 20, 0.5861, "FFFFFF"}]

    assert [] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision between bullet and one of two ships" do
    bullets = [{869, 1408.1, 427.8}, 
               {666,  500.8, 500.4}]
    ships = [{1, "AAA", 500.3, 501.4, 20, 5.8957, "FFFFFF"}, 
             {2, "BBB", 500.6, 501.5, 20, 0.5861, "FFFFFF"}]

    assert [{666,1}] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision between bullet and ship" do
    assert Collision.bullet_hits_ship?({0, 5, 5}, {0,"", 4, 4, 20, 0, ""})
  end

  test "Collision between bullet and asteroid" do
    assert Collision.bullet_hits_asteroid?({0, 5, 5}, {1, 4, 4, 20})
  end

  test "No Collision" do
    refute Collision.bullet_hits_ship?({0, 50, 50}, {1, "", 4, 4, 20, 0, ""})
    refute Collision.bullet_hits_ship?({0,  0, 50}, {2, "", 4, 4, 20, 0, ""})
    refute Collision.bullet_hits_ship?({0, 50,  0}, {3, "", 4, 4, 20, 0, ""})
  end

  test "Unique bullets" do
    assert [1, 2] == Collision.unique_bullets([{1,3},{2,4},{1,5}]) 
  end

  test "Unique ships" do
    assert [3, 4, 5] == Collision.unique_targets([{1,3},{2,4},{1,5}]) 
  end

  property :square_number_with_macro do
    for_all {x, y} in {int, int} do
      assert ((x - y) * (x - y)) == Collision.sq(x - y)
    end
  end  

end
