defmodule Elixoids.World.Testcard do
  @moduledoc "Starts a game where the entities form a test card layout"

  alias Elixoids.Asteroid.Rock
  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Ship.Server, as: Ship
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity
  import Elixoids.Game.Supervisor, only: [start_game: 1]
  import Elixoids.Space

  def start_testcard do
    [asteroids: 0]
    |> start_game()
    |> corners()
    |> this_way_up
    |> middle()
    |> compass
    |> large_ship
    |> asteroid_sizes()
  end

  defp middle(game = {_, _, game_id}) do
    [w, h] = dimensions()
    stationary_asteroid(game_id, %Point{x: w / 2, y: h / 2}, 5.0)
    game
  end

  defp compass(game = {_, _, game_id}) do
    [w, h] = dimensions()
    r = h / 4
    origin = %Point{x: w / 2, y: h / 2}

    Enum.each(compass_points(), fn {tag, theta} ->
      p = Velocity.apply_velocity(origin, %{theta: theta, speed: r}, 1000)
      ship(game_id, p, tag, theta)
    end)

    game
  end

  defp large_ship(game = {_, _, game_id}) do
    [w, h] = dimensions()
    p = %Point{x: w * 0.8, y: h / 2}
    north = :math.pi() / 2
    ship(game_id, p, "BFG", north, h / 8)
    ship(game_id, p, "COG", north, 2.0)
    game
  end

  defp this_way_up(game = {_, _, game_id}) do
    [w, h] = dimensions()
    p = %Point{x: w * 0.5, y: h * 0.95}
    north = :math.pi() / 2
    ship(game_id, Point.translate(p, -60, 0), "THI", north)
    ship(game_id, Point.translate(p, 0, 0), "SWA", north)
    ship(game_id, Point.translate(p, 60, 0), "YUP", north)
    game
  end

  defp corners(game = {_, _, game_id}) do
    dimensions()
    |> corner_points()
    |> Enum.each(fn p -> stationary_asteroid(game_id, p) end)

    game
  end

  defp asteroid_sizes(game = {_, _, game_id}) do
    [w, h] = dimensions()
    box = %Point{x: w * 0.1, y: h * 0.8}
    asteroid_boxes(game_id, box, 240.0, 120.0)

    game
  end

  defp corner_points([w, h]) do
    for x <- [0, w], y <- [0, h], do: %Point{x: x, y: y}
  end

  defp stationary_asteroid(game_id, p, r \\ 120.0) do
    asteroid(game_id, p, r, %Velocity{})
  end

  defp asteroid_drifting_west(game_id, p, r) do
    asteroid(game_id, p, r, %Velocity{theta: :math.pi(), speed: 1.0})
  end

  defp asteroid(game_id, p, r, v) do
    rock = %Rock{pos: p, velocity: v, radius: r}
    {:ok, pid} = Asteroid.start_link(%{id: game_id}, rock)
    Game.link(game_id, pid)
  end

  defp asteroid_boxes(game_id, box, box_width, radius) do
    asteroid_box(game_id, box, box_width, radius)

    if radius > 15.0 do
      asteroid_boxes(game_id, Point.translate(box, box_width, 0), box_width, radius / 2.0)
    end
  end

  defp asteroid_box(game_id, p, box_width, radius) do
    diameter = radius * 2
    fit = trunc(box_width / diameter)
    fit = 0..(fit - 1)

    points =
      for x <- fit,
          y <- fit,
          do: Point.translate(p, radius + x * radius * 2, radius + y * radius * 2)

    # points = Enum.take(points, 16)
    Enum.map(points, fn p -> asteroid_drifting_west(game_id, p, radius) end)
  end

  defp ship(game_id, pos, tag, theta, radius \\ 20.0) do
    {:ok, pid, ship_id} = Ship.start_link(%{id: game_id}, tag, %{pos: pos, radius: radius})
    Game.link(game_id, pid)
    Ship.new_heading(ship_id, theta)
  end

  defp compass_points do
    points = ~w(E ENE NE NNE N NNW NW WNW W WSW SW SSW S SSE SE ESE)
    n_points = Enum.count(points)

    points
    |> Enum.with_index()
    |> Enum.map(fn {p, n} -> {p, :math.pi() * 2 * n / n_points} end)
  end
end
