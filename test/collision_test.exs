defmodule Elixoids.CollisionTest do
  # Run large tests with mix test test/collision_test.exs --include large

  use ExUnit.Case, async: true
  use ExCheck
  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Collision.Server, as: Collision
  alias Elixoids.Ship.Location, as: ShipLoc
  import Elixoids.Const
  import Elixoids.Test.Generators
  require Elixoids.Collision.Server

  property :check_point_generator do
    for_all p in gen_point() do
      assert p.x >= 0.0
      assert p.y >= 0.0
    end
  end

  @tag iterations: 1000
  property :check_angle_generator do
    max_radians = 2.0 * :math.pi()

    for_all t in gen_theta() do
      assert t >= 0.0
      assert t < max_radians
    end
  end

  property :check_multipler_generator do
    for_all m in larger_radius() do
      assert m >= 1.01
    end
  end

  property :check_frac_generator do
    for_all f in smaller_radius() do
      assert f >= 0.0
      assert f <= 0.99
    end
  end

  @tag iterations: 10
  property :bullet_in_center_of_ship_hit do
    for_all {p, game_id} in {gen_point(), gen_game_id()} do
      Process.flag(:trap_exit, true)
      bullet = %BulletLoc{pos: [p], pid: self(), shooter: "KIL"}
      ship = %ShipLoc{pos: p, radius: ship_radius_m(), tag: "VIC"}
      assert [collision] = Collision.collision_check([], [bullet], [ship], game_id)
      assert_receive {:EXIT, _, {:shutdown, :detonate}}
      assert {:bullet_hit_ship, bullet, ship, game_id} == collision
    end
  end

  @tag iterations: 1_000, large: true
  property :bullet_inside_ship_hit do
    for_all {{ps, pb, ship_r}, game_id} in {point_inside_ship(), gen_game_id()} do
      bullet = %BulletLoc{pos: [pb], shooter: "KIL"}
      ship = %ShipLoc{pos: ps, radius: ship_r, tag: "VIC"}
      collisions = Collision.collision_check([], [bullet], [ship], game_id)
      assert [{:bullet_hit_ship, bullet, ship, game_id}] == collisions
    end
  end

  @tag iterations: 1_000, large: true
  property :bullet_misses_ship do
    for_all {ps, pb, ship_r} in point_outside_ship() do
      bullet = %BulletLoc{pos: [pb]}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      assert [] == Collision.collision_check([], [bullet], [ship])
    end
  end

  @tag iterations: 10
  property :bullet_in_center_of_asteroid_hit do
    for_all {p, r, game_id} in {gen_point(), asteroid_radius(), gen_game_id()} do
      bullet = %BulletLoc{pos: [p]}
      asteroid = %AsteroidLoc{pos: p, radius: r}

      assert [{:bullet_hit_asteroid, bullet, asteroid, game_id}] ==
               Collision.collision_check([asteroid], [bullet], [], game_id)
    end
  end

  @tag iterations: 1_000, large: true
  property :bullet_inside_asteroid_hit do
    for_all {{pa, pb, r}, game_id} in {point_inside_asteroid(), gen_game_id()} do
      bullet = %BulletLoc{pos: [pb]}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.collision_check([asteroid], [bullet], [], game_id)
      assert [{:bullet_hit_asteroid, bullet, asteroid, game_id}] == collisions
    end
  end

  @tag iterations: 1_000, large: true
  property :bullet_misses_asteroid do
    for_all {pa, pb, r} in point_outside_asteroid() do
      bullet = %BulletLoc{pos: [pb]}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      assert [] == Collision.collision_check([asteroid], [bullet], [])
    end
  end

  @tag iterations: 1_000, large: true
  property :bullet_hits_asteroids_before_ships do
    for_all {{pa, pb, r}, ships, game_id} in {point_inside_asteroid(), list(gen_ship()),
             gen_game_id()} do
      bullet = %BulletLoc{pos: [pb]}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.collision_check([asteroid], [bullet], ships, game_id)
      assert [{:bullet_hit_asteroid, bullet, asteroid, game_id}] == collisions
    end
  end

  @tag iterations: 1_000, large: true
  property :asteroid_hits_ship do
    for_all {[p1: ps, r1: rs, p2: pa, r2: ra], game_id} in {ship_overlapping_asteroid(),
             gen_game_id()} do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}

      assert [{:asteroid_hit_ship, asteroid, ship, game_id}] ==
               Collision.collision_check([asteroid], [], [ship], game_id)
    end
  end

  @tag iterations: 1_000, large: true
  property :ship_hits_ship do
    for_all {[p1: p1, r1: r1, p2: p2, r2: r2], game_id} in {ship_overlapping_ship(),
             gen_game_id()} do
      s1 = %ShipLoc{pos: p1, radius: r1, tag: saucer_tag()}
      s2 = %ShipLoc{pos: p2, radius: r2, tag: "OTH"}

      assert [{:ship_hit_ship, s1, s2, game_id}] ==
               Collision.collision_check([], [], [s1, s2], game_id)
    end
  end

  @tag iterations: 1_000, large: true
  property :ship_misses_ship do
    for_all [p1: p1, r1: r1, p2: p2, r2: r2] in ship_non_overlapping_ship() do
      s1 = %ShipLoc{pos: p1, radius: r1, tag: saucer_tag()}
      s2 = %ShipLoc{pos: p2, radius: r2, tag: "OTH"}

      assert [] ==
               Collision.collision_check([], [], [s1, s2])
    end
  end

  @tag iterations: 1_000, large: true
  property :asteroid_misses_ship do
    for_all [p1: ps, r1: rs, p2: pa, r2: ra] in ship_non_overlapping_asteroid() do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}
      assert [] == Collision.collision_check([asteroid], [], [ship])
    end
  end

  # Asteroid is removed from collision detection with ships
  @tag iterations: 1_000, large: true
  property :bullet_hits_asteroid_before_asteroid_hit_ships do
    for_all {{pa, pb, r}, ships, game_id} in {point_inside_asteroid(), list(gen_ship()),
             gen_game_id()} do
      bullet = %BulletLoc{pos: [pb]}
      asteroid = %AsteroidLoc{pos: pa, radius: r}

      assert [{:bullet_hit_asteroid, bullet, asteroid, game_id}] ==
               Collision.collision_check([asteroid], [bullet], ships, game_id)
    end
  end

  @tag iterations: 100
  property :random_tests do
    for_all {as, bs, ss, game_id} in {list(gen_asteroid()), list(gen_bullet()), list(gen_ship()),
             gen_game_id()} do
      collisions = Collision.collision_check(as, bs, ss, game_id)

      collisions
      |> Enum.map(fn {e, _, _, ^game_id} ->
        assert e == :bullet_hit_asteroid or e == :bullet_hit_ship or e == :asteroid_hit_ship
      end)
      |> Enum.all?()
    end
  end

  @tag iterations: 10
  property :bullet_can_hit_multiple_ships do
    for_all {{ps, pb, ship_r}, ships} in {point_inside_ship(), list(gen_ship())} do
      bullet = %BulletLoc{pos: [pb]}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      collisions = Collision.collision_check([], [bullet], [ship | ships])

      assert Enum.count(collisions) >= 1
      Enum.all?(for {:bullet_hit_ship, b, _} <- collisions, do: assert(b == bullet))
    end
  end

  property :test_square_macro_1 do
    for_all i in pos_integer() do
      assert i * i == Collision.sq(i)
    end
  end

  property :test_square_macro_2 do
    for_all {a, b} in {pos_integer(), pos_integer()} do
      assert (a + b) * (a + b) == Collision.sq(a + b)
    end
  end

  @tag iterations: 1_000
  property :line_inside_circle_hit do
    for_all {c, {p1, p2}} in such_that({_c, {pp1, pp2}} in line_inside_asteroid() when pp1 != pp2) do
      assert true == Collision.line_segment_intersects_circle?([p1, p2], c)
    end
  end

  @tag iterations: 1_000
  property :line_crossing_circle_hit do
    for_all {c, {p1, p2}} in line_intersecting_asteroid() do
      assert Collision.line_segment_intersects_circle?([p1, p2], c)
    end
  end

  @tag iterations: 1_000
  property :line_impaling_circle_hit do
    for_all {c, {p1, p2}} in line_impaling_asteroid() do
      assert Collision.line_segment_intersects_circle?([p1, p2], c)
    end
  end

  # TODO generator can create lines that touch the circle!
  # @tag iterations: 10_000
  # property :line_outside_circle_miss do
  #   for_all {c, {p1, p2}} in line_outside_asteroid() do
  #     refute Collision.line_segment_intersects_circle?([p1, p2], c)
  #   end
  # end

  # Legacy unit tests

  test "No collision between asteroid and rock" do
    ship = %ShipLoc{pos: %{x: 1020, y: 0.0}, radius: 20}
    asteroid = %{id: 2, pos: %{x: 899.0, y: 0}, radius: 80}

    assert false == Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between touching asteroid and ship" do
    ship = %ShipLoc{pos: %{x: 1020.0, y: 0}, radius: 20, tag: "AAA"}
    asteroid = %{id: 2, pos: %{x: 920.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between overlapping asteroid and ship" do
    ship = %ShipLoc{pos: %{x: 1000.0, y: 0}, radius: 20, tag: "AAA"}
    asteroid = %{id: 2, pos: %{x: 1000.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Detect overlapping asteroid and ship" do
    ship = %ShipLoc{pos: %{x: 1000.0, y: 0}, radius: 20, tag: "AAA"}

    asteroid1 = %{id: 73, pos: %{x: 1000.0, y: 0}, radius: 80, pid: self()}
    asteroid2 = %{id: 99, pos: %{x: 1000.0, y: 200}, radius: 80, pid: self()}

    assert [collision] = Collision.collision_check([asteroid1, asteroid2], [], [ship])
    assert {:asteroid_hit_ship, ^asteroid1, ^ship, _} = collision
    assert_receive {_, :destroyed}
  end

  test "No collision" do
    bullets = [
      %{id: 869, pos: [%{x: 1408.1, y: 427.8}], pid: self()},
      %{id: 687, pos: [%{x: 500.8, y: 500.4}], pid: self()}
    ]

    ships = [
      %ShipLoc{pos: %{x: 120.3, y: 864.4}, radius: 20, tag: "AAA"},
      %ShipLoc{pos: %{x: 545.6, y: 757.5}, radius: 20, tag: "AAA"}
    ]

    assert [] == Collision.collision_check([], bullets, ships)
  end

  test "Collision between bullet and ship" do
    bullet = %BulletLoc{pos: [%{x: 5, y: 5}], pid: self()}
    ship = %ShipLoc{pos: %{x: 4, y: 4}, radius: 20, tag: "AAA", pid: self()}

    assert Collision.bullet_hits_ship?(bullet, ship)
  end

  test "Collision between bullet and asteroid" do
    asteroid = %{id: 2, pos: %{x: 4.0, y: 4.0}, radius: 20}

    assert Collision.bullet_hits_asteroid?(%BulletLoc{pos: [%{x: 5, y: 5}]}, asteroid)
  end

  test "No Collision" do
    ship = %ShipLoc{pos: %{x: 4, y: 4}, radius: 20, tag: "AAA"}
    refute Collision.bullet_hits_ship?(%BulletLoc{pos: [%{x: 50, y: 50}]}, ship)
    refute Collision.bullet_hits_ship?(%BulletLoc{pos: [%{x: 0, y: 50}]}, ship)
    refute Collision.bullet_hits_ship?(%BulletLoc{pos: [%{x: 50, y: 0}]}, ship)
  end
end
