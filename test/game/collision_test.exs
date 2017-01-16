defmodule Game.CollisionTest do
  use ExUnit.Case, async: true
  use ExCheck

  doctest Game.Collision

  #alias Game.Collision, as: Collision
  alias Asteroid.Server, as: Asteroid

  # Size of world
  @width 4000.0 # 4km
  @height 2000.0

  @ship_radius_m 20

  # Depth of tree. TODO test most efficient depth
  @quadtree_depths 2..4 |> Enum.to_list

  @asteroid_radii Asteroid.asteroid_radii()

  require Record
  #@type asteroid ::  record(:asteroid, x: integer, y: integer)
  #@type point :: record(X: integer, Y: integer)

  # Create an asteroid anywhere in the world and place a ship in close proximity,
  # test it always collides
  @tag iterations: 100
  property :asteroid_overlapping_ship_collides do
    for_all {x, y, asteroid_width, depth, dx, dy} in {pos_integer(), pos_integer(), elements(@asteroid_radii), elements(@quadtree_depths), int(-@ship_radius_m,@ship_radius_m), int(-@ship_radius_m,@ship_radius_m)} do
      qt = :erlquad.new(0,0,min(@width, @width+x),min(@height,@height+y), depth)
      asteroid = {:asteroid, x, y, asteroid_width}
      getoutline = fn {:asteroid, x, y, s} -> {x-s/2,y-s/2,x+s/2,y+s/2} end
      world = :erlquad.objects_add([asteroid], getoutline, qt)
      {sx,sy} = {x+dx, y+dy}
      assert [asteroid] == :erlquad.area_query(sx-@ship_radius_m,sy-@ship_radius_m,sx+@ship_radius_m,sy+@ship_radius_m,world)
    end
  end

  # TODO bullet hitting asteroid (point inside bounding box)
  @tag iterations: 100
  property :bullets_inside_asteroid_collides do
    smallest_asteroid=Enum.min(@asteroid_radii)
    for_all {x, y, asteroid_width, depth, dx, dy} in {pos_integer(), pos_integer(), elements(@asteroid_radii), elements(@quadtree_depths), int(-smallest_asteroid,smallest_asteroid), int(-smallest_asteroid,smallest_asteroid)} do
      qt = :erlquad.new(0,0,min(@width, @width+x),min(@height,@height+y), depth)
      asteroid = {:asteroid, x, y, asteroid_width}
      getoutline = fn {:asteroid, x, y, s} -> {x-s/2,y-s/2,x+s/2,y+s/2} end
      world = :erlquad.objects_add([asteroid], getoutline, qt)
      {bx,by} = {x+dx, y+dy}
      assert [asteroid] == :erlquad.area_query(bx,by,bx,by,world)
    end
  end

  # TODO bullet hitting ship (point inside circle)

  # TODO ship overlapping ship (hyperspace both)

#  test "No collision between asteroid and rock" do
#    ship =     {1, "AAA", 1020.0, 0,  20, 5.8957, "FFFFFF"}
#    asteroid = {2,         899.0, 0,  80}
#
#    assert false == Collision.asteroid_hits_ship?(asteroid, ship)
#  end
#
#  test "Collision between touching asteroid and rock" do
#    ship =     {1, "AAA", 1020.0, 0,  20.0, 5.8957, "FFFFFF"}
#    asteroid = {2,         920.0, 0,  80.0}
#
#    assert Collision.asteroid_hits_ship?(asteroid, ship)
#  end
#
#  test "Collision between overlapping asteroid and rock" do
#    ship =     {1, "AAA", 1000.0, 0,  20, 5.8957, "FFFFFF"}
#    asteroid = {2,        1000.0, 0,  80}
#
#    assert Collision.asteroid_hits_ship?(asteroid, ship)
#  end
#
#  test "Detect between overlapping asteroid and rock" do
#    ships =     [{51, "AAA", 1000.0, 0,  20, 5.8957, "FFFFFF"}]
#    asteroids = [{73,        1000.0, 0,  80},
#                 {99,        1000.0, 200, 80}]
#
#    assert [{73,51}] == Collision.detect_asteroids_hitting_ships(asteroids, ships)
#  end
#
#  test "No collision" do
#    bullets = [{6869, 1408.1, 427.8},
#               {6870, 534.8, 1690.4}]
#    ships = [{1, "AAA", 120.3, 864.4, 20, 5.8957, "FFFFFF"},
#             {2, "BBB", 545.6, 757.5, 20, 0.5861, "FFFFFF"}]
#
#    assert [] = Collision.detect_bullets_hitting_ships(bullets, ships)
#  end
#
#  test "Collision between bullet and one of two ships" do
#    bullets = [{869, 1408.1, 427.8},
#               {666,  500.8, 500.4}]
#    ships = [{1, "AAA", 500.3, 501.4, 20, 5.8957, "FFFFFF"},
#             {2, "BBB", 500.6, 501.5, 20, 0.5861, "FFFFFF"}]
#
#    assert [{666,1}] = Collision.detect_bullets_hitting_ships(bullets, ships)
#  end
#
#  test "Collision between bullet and ship" do
#    assert Collision.bullet_hits_ship?({0, 5, 5}, {0,"", 4, 4, 20, 0, ""})
#  end
#
#  test "Collision between bullet and asteroid" do
#    assert Collision.bullet_hits_asteroid?({0, 5, 5}, {1, 4, 4, 20})
#  end
#
#  test "No Collision" do
#    refute Collision.bullet_hits_ship?({0, 50, 50}, {1, "", 4, 4, 20, 0, ""})
#    refute Collision.bullet_hits_ship?({0,  0, 50}, {2, "", 4, 4, 20, 0, ""})
#    refute Collision.bullet_hits_ship?({0, 50,  0}, {3, "", 4, 4, 20, 0, ""})
#  end
#
#  test "Unique bullets" do
#    assert [1, 2] == Collision.unique_bullets([{1,3},{2,4},{1,5}])
#  end
#
#  test "Unique ships" do
#    assert [3, 4, 5] == Collision.unique_targets([{1,3},{2,4},{1,5}])
#  end

end
