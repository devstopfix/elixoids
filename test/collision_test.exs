defmodule Elixoids.CollisionTest do

  # Run large tests with mix test test/collision_test.exs --include large

  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.Collision.Server, as: Collision
  alias World.Point

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

    asteroids = [asteroid1, asteroid2]

    assert [{asteroid1, ship}] == Collision.detect_asteroids_hitting_ships(asteroids, [ship])
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

    assert [] = Collision.detect_bullets_hitting_ships(bullets, ships)
  end

  test "Collision between bullet and one of two ships" do
    bullets = [
      %{id: 869, pos: %{x: 1408.1, y: 427.8}, pid: self()},
      %{id: 666, pos: %{x: 500.8, y: 500.4}, pid: self()}
    ]

    ship_1 = %ShipLoc{pos: %{x: 500.3, y: 501.4}, radius: 20, tag: "AAA"}
    ship_2 = %ShipLoc{pos: %{x: 500.5, y: 501.5}, radius: 20, tag: "BBB"}

    ships = [
      ship_1,
      ship_2
    ]

    assert [{%{id: 666}, ship_1}] = Collision.detect_bullets_hitting_ships(bullets, ships)
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

  test "Unique ships" do
    assert [3, 4, 5] == Collision.unique_targets([{1, 3}, {2, 4}, {1, 5}])
  end


  ## Game constants

  @ship_radius_m 20.0

  # Generators

  defp asteroid_radius, do: :triq_dom.oneof([120.0, 60.0, 30.0, 15.0])
  defp ship_radius_m, do: :triq_dom.oneof([@ship_radius_m])

  ## Angles

  def major_angle, do: [0.0, 1.0, 2.0, 3.0] |> :triq_dom.oneof() |> :triq_dom.bind(fn n -> n * :math.pi / 2.0 end)

  def any_angle, do: :triq_dom.float() |> :triq_dom.bind(fn f -> :math.fmod(f, :math.pi) end)

  def theta, do: :triq_dom.oneof([:triq_dom.oneof([0.0]), major_angle(), any_angle()])

  ## Points

  defp to_float(i), do: i * 1.0

  defp small_float, do: 0..10 |> Enum.map(&to_float/1) |> :triq_dom.oneof()

  defp mid_float, do: 0..120 |> Enum.map(&to_float/1) |> :triq_dom.oneof()

  defp world_float, do:
    :triq_dom.float()
    |> :triq_dom.suchthat(fn f -> f < 2000.0 end)
    |> :triq_dom.bind(&abs/1)

  defp position, do: :triq_dom.oneof([:triq_dom.oneof([0.0]), small_float(), mid_float(), world_float()])

  defp point, do: :triq_dom.bind([position(), position()], fn [x,y] -> %Point{x: x, y: y} end)

  # 0..0.99
  defp frac, do:
    0..99
    |> Enum.to_list
    |> :triq_dom.oneof
    |> :triq_dom.bind(fn i -> i / 100.0 end)

  # > 1.1
  defp multiplier, do:
    :triq_dom.float()
    |> :triq_dom.bind(fn f -> abs(f) + 1.1 end)

  # Generate a circle and a point inside that circle
  defp point_inside_circle(sizes) do
    [point(), theta(), sizes, frac()]
    |> :triq_dom.bind(fn [p, t, r, f] ->
      dx = :math.cos(t) * r * f
      dy = :math.sin(t) * r * f
      {p, %Point{x: p.x + dx, y: p.y + dy}, r }
    end)
  end

  # Generate a circle and a point outside that circle
  defp point_outside_circle(sizes) do
    [point(), theta(), sizes, multiplier()]
    |> :triq_dom.bind(fn [p, t, r, m] ->
      dx = :math.cos(t) * r * m
      dy = :math.sin(t) * r * m
      {p, %Point{x: p.x + dx, y: p.y + dy}, r }
    end)
  end

  defp point_inside_ship, do: point_inside_circle(:triq_dom.oneof([@ship_radius_m]))
  defp point_outside_ship, do: point_outside_circle(:triq_dom.oneof([@ship_radius_m]))

  defp point_inside_asteroid, do: point_inside_circle(asteroid_radius())
  defp point_outside_asteroid, do: point_outside_circle(asteroid_radius())


  defp overlapping_circles(size1, size2) do
    [point(), size1, size2, theta(), frac()]
    |> :triq_dom.bind(fn [p, r1, r2, t, f] ->
      r = (r1 + r2) * f
      dx = :math.cos(t) * r
      dy = :math.sin(t) * r
      [p1: p, r1: r1, p2: %Point{x: p.x + dx, y: p.y + dy}, r2: r2]
    end)
  end

  defp non_overlapping_circles(size1, size2) do
    [point(), size1, size2, theta(), multiplier()]
    |> :triq_dom.bind(fn [p, r1, r2, t, m] ->
      r = (r1 + r2) * m
      dx = :math.cos(t) * r
      dy = :math.sin(t) * r
      [p1: p, r1: r1, p2: %Point{x: p.x + dx, y: p.y + dy}, r2: r2]
    end)
  end


  defp ship_overlapping_asteroid, do: overlapping_circles(ship_radius_m(), asteroid_radius())

  defp ship_non_overlapping_asteroid, do: non_overlapping_circles(ship_radius_m(), asteroid_radius())

  property :check_generators do
    for_all p in point() do
      assert p.x >= 0.0
      assert p.y >= 0.0
    end
    for_all t in theta() do
      assert t >= -3.2
      assert t <= 6.3
    end
    for_all m in multiplier() do
      assert m >= 1.1
    end
  end

  property :bullet_in_center_of_ship_hit do
    for_all p in point() do
      bullet = %BulletLoc{pos: p}
      ship = %ShipLoc{pos: p, radius: @ship_radius_m}

      collisions = Collision.detect_bullets_hitting_ships([bullet], [ship])

      assert [{bullet, ship}] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_inside_ship_hit do
    for_all {ps, pb, ship_r} in point_inside_ship() do
      bullet = %BulletLoc{pos: pb}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      collisions = Collision.detect_bullets_hitting_ships([bullet], [ship])
      assert [{bullet, ship}] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_misses_ship do
    for_all {ps, pb, ship_r} in point_outside_ship() do
      bullet = %BulletLoc{pos: pb}
      ship = %ShipLoc{pos: ps, radius: ship_r}
      collisions = Collision.detect_bullets_hitting_ships([bullet], [ship])
      assert [] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_inside_asteroid_hit do
    for_all {pa, pb, r} in point_inside_asteroid() do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      collisions = Collision.detect_bullets_hitting_asteroids([bullet], [asteroid])
      assert [{bullet, asteroid}] == collisions
    end
  end

  @tag iterations: 10000, large: true
  property :bullet_misses_asteroid do
    for_all {pa, pb, r} in point_outside_asteroid() do
      bullet = %BulletLoc{pos: pb}
      asteroid = %AsteroidLoc{pos: pa, radius: r}
      assert [] == Collision.detect_bullets_hitting_asteroids([bullet], [asteroid])
    end
  end


  @tag iterations: 10000, large: true
  property :asteroid_hits_ship do
    for_all [p1: ps, r1: rs, p2: pa, r2: ra] in ship_overlapping_asteroid() do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}
      assert [{asteroid, ship}] == Collision.detect_asteroids_hitting_ships([asteroid], [ship])
    end
  end

  @tag iterations: 10000, large: true
  property :asteroid_misses_ship do
    for_all [p1: ps, r1: rs, p2: pa, r2: ra] in ship_non_overlapping_asteroid() do
      asteroid = %AsteroidLoc{pos: pa, radius: ra}
      ship = %ShipLoc{pos: ps, radius: rs}
      assert [] == Collision.detect_asteroids_hitting_ships([asteroid], [ship])
    end
  end

end
