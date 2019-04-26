defmodule Elixoids.CollisionTest do
  # Run large tests with mix test test/collision_test.exs --include large

  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.Collision.Server, as: Collision
  alias Elixoids.World.Point

  import Elixoids.Test.Generators

  require Elixoids.Collision.Server

  test "No collision between asteroid and rock" do
    ship = %ShipLoc{pos: %{x: 1020, y: 0.0}, radius: 20}
    asteroid = %{id: 2, pos: %{x: 899.0, y: 0}, radius: 80}

    assert false == Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between touching asteroid and rock" do
    ship = %ShipLoc{pos: %{x: 1020.0, y: 0}, radius: 20, tag: "AAA"}
    asteroid = %{id: 2, pos: %{x: 920.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Collision between overlapping asteroid and rock" do
    ship = %ShipLoc{pos: %{x: 1000.0, y: 0}, radius: 20, tag: "AAA"}
    asteroid = %{id: 2, pos: %{x: 1000.0, y: 0}, radius: 80}

    assert Collision.asteroid_hits_ship?(asteroid, ship)
  end

  test "Detect between overlapping asteroid and rock" do
    ship = %ShipLoc{pos: %{x: 1000.0, y: 0}, radius: 20, tag: "AAA"}

    asteroid1 = %{id: 73, pos: %{x: 1000.0, y: 0}, radius: 80}
    asteroid2 = %{id: 99, pos: %{x: 1000.0, y: 200}, radius: 80}

    assert [{:asteroid_hit_ship, asteroid1, ship}] ==
             Collision.collision_check([asteroid1, asteroid2], [], [ship])
  end

  test "No collision" do
    bullets = [
      %{id: 869, pos: %{x: 1408.1, y: 427.8}, pid: self()},
      %{id: 687, pos: %{x: 500.8, y: 500.4}, pid: self()}
    ]

    ships = [
      %ShipLoc{pos: %{x: 120.3, y: 864.4}, radius: 20, tag: "AAA"},
      %ShipLoc{pos: %{x: 545.6, y: 757.5}, radius: 20, tag: "AAA"}
    ]

    assert [] == Collision.collision_check([], bullets, ships)
  end

  test "Collision between bullet and ship" do
    ship = %ShipLoc{pos: %{x: 4, y: 4}, radius: 20, tag: "AAA"}

    assert Collision.bullet_hits_ship?(%{pos: %{x: 5, y: 5}}, ship)
  end

  test "Collision between bullet and asteroid" do
    asteroid = %{id: 2, pos: %{x: 4.0, y: 4.0}, radius: 20}

    assert Collision.bullet_hits_asteroid?(%{pos: %{x: 5, y: 5}}, asteroid)
  end

  test "No Collision" do
    ship = %ShipLoc{pos: %{x: 4, y: 4}, radius: 20, tag: "AAA"}
    refute Collision.bullet_hits_ship?(%{pos: %{x: 50, y: 50}}, ship)
    refute Collision.bullet_hits_ship?(%{pos: %{x: 0, y: 50}}, ship)
    refute Collision.bullet_hits_ship?(%{pos: %{x: 50, y: 0}}, ship)
  end

  # Generators

  defp asteroid_radius, do: :triq_dom.oneof([120.0, 60.0, 30.0, 15.0])

  @ship_radius_m 20.0
  defp ship_radius, do: :triq_dom.oneof([@ship_radius_m])

  ## Angles

  def major_angle,
    do:
      [0.0, 1.0, 2.0, 3.0]
      |> :triq_dom.oneof()
      |> :triq_dom.bind(fn n -> n * :math.pi() / 2.0 end)

  def any_angle, do: :triq_dom.float() |> :triq_dom.bind(fn f -> :math.fmod(f, :math.pi()) end)

  def theta, do: :triq_dom.oneof([:triq_dom.oneof([0.0]), major_angle(), any_angle()])

  # 0..0.99
  defp smaller_radius,
    do:
      0..99
      |> Enum.to_list()
      |> :triq_dom.oneof()
      |> :triq_dom.bind(fn i -> i / 100.0 end)

  # > 1.01
  defp larger_radius,
    do:
      :triq_dom.float()
      |> :triq_dom.bind(fn f -> abs(f) + 1.01 end)

  # Generate a circle and a point offset from the centre of the circle
  defp point_circle(sizes, delta_r) do
    [gen_point(), theta(), sizes, delta_r]
    |> :triq_dom.bind(fn [p, t, r, dr] ->
      dx = :math.cos(t) * (r * dr)
      dy = :math.sin(t) * (r * dr)
      {p, %Point{x: p.x + dx, y: p.y + dy}, r}
    end)
  end

  defp point_inside_ship, do: point_circle(ship_radius(), smaller_radius())
  defp point_outside_ship, do: point_circle(ship_radius(), larger_radius())

  defp point_inside_asteroid, do: point_circle(asteroid_radius(), smaller_radius())
  defp point_outside_asteroid, do: point_circle(asteroid_radius(), larger_radius())

  defp circles(size1, size2, delta_r) do
    [gen_point(), size1, size2, theta(), delta_r]
    |> :triq_dom.bind(fn [p, r1, r2, t, dr] ->
      d = (r1 + r2) * dr
      dx = :math.cos(t) * d
      dy = :math.sin(t) * d
      [p1: p, r1: r1, p2: %Point{x: p.x + dx, y: p.y + dy}, r2: r2]
    end)
  end

  defp ship_overlapping_asteroid, do: circles(ship_radius(), asteroid_radius(), smaller_radius())

  defp ship_non_overlapping_asteroid,
    do: circles(ship_radius(), asteroid_radius(), larger_radius())

  defp gen_asteroid,
    do:
      [gen_point(), asteroid_radius()]
      |> :triq_dom.bind(fn [p, r] -> %AsteroidLoc{pos: p, radius: r} end)

  defp gen_ship,
    do:
      [gen_point(), ship_radius()] |> :triq_dom.bind(fn [p, r] -> %ShipLoc{pos: p, radius: r} end)

  defp gen_bullet,
    do: [gen_point()] |> :triq_dom.bind(fn [p] -> %BulletLoc{pos: p} end)

  property :check_point_generator do
    for_all p in gen_point() do
      assert p.x >= 0.0
      assert p.y >= 0.0
    end
  end

  property :check_angle_generator do
    for_all t in theta() do
      assert t >= -3.2
      assert t <= 6.3
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

  @tag iterations: 10000, large: true
  property :bullet_in_center_of_ship_hit do
    for_all p in gen_point() do
      bullet = %BulletLoc{pos: p}
      ship = %ShipLoc{pos: p, radius: @ship_radius_m}
      assert [{:bullet_hit_ship, bullet, ship}] == Collision.collision_check([], [bullet], [ship])
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_inside_ship_hit do
    for_all {ps, pb, ship_r} in point_inside_ship() do
      bullet = %BulletLoc{pos: pb}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      collisions = Collision.collision_check([], [bullet], [ship])
      assert [{:bullet_hit_ship, bullet, ship}] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_misses_ship do
    for_all {ps, pb, ship_r} in point_outside_ship() do
      bullet = %BulletLoc{pos: pb}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      assert [] == Collision.collision_check([], [bullet], [ship])
    end
  end

  @tag iterations: 5000, large: true
  property :bullet_inside_asteroid_hit do
    for_all {pa, pb, r} in point_inside_asteroid() do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.collision_check([asteroid], [bullet], [])
      assert [{:bullet_hit_asteroid, bullet, asteroid}] == collisions
    end
  end

  @tag iterations: 5000, large: true
  property :bullet_misses_asteroid do
    for_all {pa, pb, r} in point_outside_asteroid() do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      assert [] == Collision.collision_check([asteroid], [bullet], [])
    end
  end

  @tag iterations: 1000, large: true
  property :bullet_hits_asteroids_before_ships do
    for_all {{pa, pb, r}, ships} in {point_inside_asteroid(), list(gen_ship())} do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.collision_check([asteroid], [bullet], ships)
      assert [{:bullet_hit_asteroid, bullet, asteroid}] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :asteroid_hits_ship do
    for_all [p1: ps, r1: rs, p2: pa, r2: ra] in ship_overlapping_asteroid() do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}

      assert [{:asteroid_hit_ship, asteroid, ship}] ==
               Collision.collision_check([asteroid], [], [ship])
    end
  end

  @tag iterations: 10000, large: true
  property :asteroid_misses_ship do
    for_all [p1: ps, r1: rs, p2: pa, r2: ra] in ship_non_overlapping_asteroid() do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}
      assert [] == Collision.collision_check([asteroid], [], [ship])
    end
  end

  # Asteroid is removed from collision detection with ships
  @tag iterations: 1000, large: true
  property :bullet_hits_asteroid_before_asteroid_hit_ships do
    for_all {{pa, pb, r}, ships} in {point_inside_asteroid(), list(gen_ship())} do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.collision_check([asteroid], [bullet], ships)
      assert [{:bullet_hit_asteroid, bullet, asteroid}] == collisions
    end
  end

  @tag iterations: 100, large: true
  property :random_tests do
    for_all {as, bs, ss} in {list(gen_asteroid()), list(gen_bullet()), list(gen_ship())} do
      collisions = Collision.collision_check(as, bs, ss)

      collisions
      |> Enum.map(fn {e, _, _} ->
        assert e == :bullet_hit_asteroid or e == :bullet_hit_ship or e == :asteroid_hit_ship
      end)
      |> Enum.all?()
    end
  end

  @tag iterations: 10
  property :bullet_can_hit_multiple_ships do
    for_all {{ps, pb, ship_r}, ships} in {point_inside_ship(), list(gen_ship())} do
      bullet = %BulletLoc{pos: pb}
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
end
