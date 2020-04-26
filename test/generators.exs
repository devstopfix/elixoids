defmodule Elixoids.Test.Generators do
  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Ship.Location, as: ShipLoc
  alias Elixoids.World.Point
  import :triq_dom, except: [atom: 0], only: :functions
  import Elixoids.Const, only: [asteroid_radius_m: 0, ship_radius_m: 0]
  import Elixoids.World.Angle, only: [normalize_radians: 1]

  # Floats

  defp to_float(i), do: i * 1.0

  defp range_float(r), do: Enum.map(r, &to_float/1)

  defp small_float, do: range_float(0..10) |> elements()

  defp mid_float, do: range_float(0..trunc(asteroid_radius_m())) |> elements()

  defp world_float,
    do:
      float()
      |> bind(&abs/1)
      |> suchthat(fn f -> f < 2000.0 end)

  defp gen_world_float,
    do: oneof([return(0.0), small_float(), mid_float(), world_float()])

  # Positions in the world

  def gen_point,
    do: bind([gen_world_float(), gen_world_float()], fn [x, y] -> %Point{x: x, y: y} end)

  # Angles

  defp normalize(r), do: r |> normalize_radians() |> Float.floor(4)

  defp major_angle,
    do: bind(int(1, 12), fn n -> normalize(n * :math.pi() / 6.0) end)

  defp any_angle, do: float() |> bind(fn f -> normalize(:math.fmod(f, :math.pi())) end)

  def gen_theta, do: oneof([elements([0.0, :math.pi()]), major_angle(), any_angle()])

  def gen_game_id,
    do:
      oneof([
        elements([0, 1]),
        pos_integer()
      ])

  # Collisions

  def asteroid_radius,
    do:
      asteroid_radius_m()
      |> Stream.iterate(&(&1 / 2.0))
      |> Enum.take(4)
      |> :triq_dom.elements()

  def ship_radius, do: :triq_dom.return(ship_radius_m())

  # 0..0.99
  def smaller_radius,
    do:
      0..99
      |> Enum.to_list()
      |> :triq_dom.elements()
      |> :triq_dom.bind(fn i -> i / 100.0 end)

  # > 1.1
  def larger_radius, do: :triq_dom.bind(:triq_dom.float(), fn f -> abs(f) + 1.1 end)

  # 1.05 .. ~2.0
  def double_radius,
    do: :triq_dom.bind(:triq_dom.float(), fn f -> 1.1 + abs(f) * 0.2 - trunc(abs(f)) end)

  # Generate a circle and a point offset from the centre of the circle
  defp point_circle(radii, delta_r) do
    [gen_point(), gen_theta(), radii, delta_r]
    |> :triq_dom.bind(fn [p, t, r, dr] ->
      dx = Float.floor(:math.cos(t) * (r * dr), 1)
      dy = Float.floor(:math.sin(t) * (r * dr), 1)
      {p, Point.translate(p, dx, dy), r}
    end)
  end

  # Generate a circle and two points offset from the centre of the circle
  defp points_circle(radii, {delta_r1, delta_r2}, tangential \\ false) do
    [gen_point(), radii, delta_r1, gen_theta(), delta_r2, gen_theta()]
    |> :triq_dom.bind(fn [p, r, dr1, t0, dr2, t1] ->
      t2 = if tangential, do: t0, else: t1
      dx1 = Float.floor(:math.cos(t0) * (r * dr1), 1)
      dy1 = Float.floor(:math.sin(t0) * (r * dr1), 1)
      dx2 = Float.floor(:math.cos(t2) * (r * dr2), 1)
      dy2 = Float.floor(:math.sin(t2) * (r * dr2), 1)

      {%{pos: p, radius: r}, {Point.translate(p, dx1, dy1), Point.translate(p, dx2, dy2)}}
    end)
  end

  defp points_impale_circle(radii) do
    [gen_point(), radii, gen_theta(), gen_theta(), larger_radius(), larger_radius()]
    |> :triq_dom.bind(fn [p, r, t0, t, dr1, dr2] ->
      ox = Float.floor(:math.cos(t0) * (r * 0.5), 1)
      oy = Float.floor(:math.sin(t0) * (r * 0.5), 1)
      dx1 = Float.floor(:math.cos(t) * (r * dr1), 1)
      dy1 = Float.floor(:math.sin(t) * (r * dr1), 1)
      dx2 = Float.floor(:math.cos(t) * (r * -dr2), 1)
      dy2 = Float.floor(:math.sin(t) * (r * -dr2), 1)
      p2 = Point.translate(p, ox, oy)
      {%{pos: p, radius: r}, {Point.translate(p2, dx1, dy1), Point.translate(p2, dx2, dy2)}}
    end)
  end

  defp circles(size1, size2, delta_r) do
    [gen_point(), size1, size2, gen_theta(), delta_r]
    |> :triq_dom.bind(fn [p, r1, r2, t, dr] ->
      d = (r1 + r2) * dr
      dx = :math.cos(t) * d
      dy = :math.sin(t) * d
      [p1: p, r1: r1, p2: Point.translate(p, dx, dy), r2: r2]
    end)
  end

  def point_inside_ship, do: point_circle(ship_radius(), smaller_radius())
  def point_outside_ship, do: point_circle(ship_radius(), larger_radius())

  def point_inside_asteroid, do: point_circle(asteroid_radius(), smaller_radius())
  def point_outside_asteroid, do: point_circle(asteroid_radius(), larger_radius())

  def ship_overlapping_asteroid, do: circles(ship_radius(), asteroid_radius(), smaller_radius())

  def ship_overlapping_ship, do: circles(ship_radius(), ship_radius(), smaller_radius())

  def ship_non_overlapping_asteroid,
    do: circles(ship_radius(), asteroid_radius(), larger_radius())

  def ship_non_overlapping_ship,
    do: circles(ship_radius(), ship_radius(), larger_radius())

  def gen_asteroid,
    do:
      [gen_point(), asteroid_radius()]
      |> :triq_dom.bind(fn [p, r] -> %AsteroidLoc{pos: p, radius: r} end)

  def gen_ship,
    do:
      [gen_point(), ship_radius()] |> :triq_dom.bind(fn [p, r] -> %ShipLoc{pos: p, radius: r} end)

  def gen_bullet,
    do: [gen_point()] |> :triq_dom.bind(fn [p] -> %BulletLoc{pos: p} end)

  def line_inside_asteroid,
    do: points_circle(asteroid_radius(), {smaller_radius(), smaller_radius()})

  def line_intersecting_asteroid,
    do: points_circle(asteroid_radius(), {smaller_radius(), double_radius()})

  def line_impaling_asteroid,
    do: points_impale_circle(asteroid_radius())

  def line_outside_asteroid,
    do: points_circle(asteroid_radius(), {double_radius(), larger_radius()}, true)
end
