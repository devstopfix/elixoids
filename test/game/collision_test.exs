defmodule Game.CollisionTest do
  use ExUnit.Case, async: false
  doctest Game.Collision

  alias Game.Collision, as: Collision

  test "No collision" do
    bullets = [{6869, 1408.1, 427.8}, 
               {6870, 534.8, 1690.4}]
    ships = [{1, "AAA", 120.3, 864.4, 20, 5.8957, "FFFFFF"}, 
             {2, "BBB", 545.6, 757.5, 20, 0.5861, "FFFFFF"}]

    assert [] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision" do
    assert Collision.bullet_hits_ship?({0, 5, 5}, {0,"", 4, 4, 20, 0, ""})
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

end
