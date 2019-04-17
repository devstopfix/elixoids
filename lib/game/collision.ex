defmodule Game.Collision do
  @moduledoc """
  Simplistic collision detections.
  Runs as a separate process to avoid slowing game loop in busy screens.
  Tests everything against everything else - no bounding boxes or culling.
  """

  use GenServer
  import Elixoids.Event

  def start_link(game_id) when is_integer(game_id) do
    GenServer.start_link(__MODULE__, {:ok, game_id}, [])
  end

  @doc """
  Square a number.
  """
  defmacro sq(n) do
    quote do
      unquote(n) * unquote(n)
    end
  end

  @doc """
  We use points (bullets) inside circles (ships)
  """
  def bullet_hits_ship?(bullet, ship) do
    %{pos: %{x: bx, y: by}} = bullet
    %{pos: %{x: sx, y: sy}, radius: sr} = ship

    sq(bx - sx) + sq(by - sy) < sq(sr)
  end

  @doc """
  Return a tuple of {bullet_id, ship_id} for each collision.
  A single bullet can only hit a single ship
  """
  def detect_bullets_hitting_ships(bullets, ships) do
    l = for b <- bullets, s <- ships, bullet_hits_ship?(b, s), do: {b, s}
    Enum.uniq_by(l, fn {b, _s} -> b.pid end)
  end

  def bullet_hits_asteroid?(bullet, asteroid) do
    %{pos: %{x: bx, y: by}} = bullet
    %{pos: %{x: ax, y: ay}, radius: ar} = asteroid

    sq(bx - ax) + sq(by - ay) < sq(ar)
  end

  @doc """
  Return a tuple of {bullet_id, asteroid_id} for each collision.
  A single bullet can only hit a single asteroid
  """
  def detect_bullets_hitting_asteroids(bullets, asteroids) do
    l = for b <- bullets, a <- asteroids, bullet_hits_asteroid?(b, a), do: {b, a}

    Enum.uniq_by(l, fn {b, _a} -> b.pid end)
  end

  @doc """
  List of bullets (bullet_ids) to stop.
  """
  def unique_bullets(collisions) do
    collisions |> Enum.map(fn {b, _} -> b end) |> Enum.uniq()
  end

  @doc """
  List of targets (ship_ids) to destroy
  """
  def unique_targets(collisions) do
    collisions
    |> Enum.map(fn {_, s} -> s end)
    |> Enum.uniq()
  end

  @doc """
  Test if two circles touch or overlap by comparing
  distances between their centres
  """
  def asteroid_hits_ship?(asteroid, ship) do
    %{pos: %{x: ax, y: ay}, radius: ar} = asteroid
    %{pos: %{x: sx, y: sy}, radius: sr} = ship

    :math.sqrt(sq(ax - sx) + sq(ay - sy)) <= sr + ar
  end

  @doc """
  Return a tuple of {asteroid_id, ship_id} for each collision.
  """
  def detect_asteroids_hitting_ships(asteroids, ships) do
    l = for a <- asteroids, s <- ships, asteroid_hits_ship?(a, s), do: {a, s}
    Enum.uniq_by(l, fn {_a, s} -> s end)
  end

  # GenServer

  def init({:ok, game_id}) do
    {:ok, game_id}
  end

  def collision_tests(pid, game) do
    GenServer.cast(pid, {:collision_tests, game})
  end

  # Collisions

  def handle_cast({:collision_tests, game}, game_id) do
    check_for_collisions(game, game_id)
    {:noreply, game_id}
  end

  defp check_for_collisions(game, game_id) do
    # TODO move to game process (remove spawns)
    all_asteroids = Map.values(game.state.asteroids) |> remove_spawns()
    all_bullets = Map.values(game.state.bullets) |> remove_spawns()
    all_ships = Map.values(game.state.ships) |> remove_spawns()

    bullet_ships = detect_bullets_hitting_ships(all_bullets, all_ships)
    # List of {BulletLoc, Ship Tuple}
    handle_bullets_hitting_ships(game, bullet_ships, game_id)

    all_asteroids
    |> detect_asteroids_hitting_ships(all_ships)
    |> handle_asteroid_hitting_ships(game_id)

    bullet_asteroids = detect_bullets_hitting_asteroids(all_bullets, all_asteroids)
    handle_bullets_hitting_asteroids(game, bullet_asteroids, game_id)

    dud_bullets =
      Enum.uniq(
        unique_bullets(bullet_ships) ++
          unique_bullets(bullet_asteroids)
      )

    stop_bullets(dud_bullets)
  end

  defp remove_spawns(xs), do: Enum.reject(xs, fn b -> b == :spawn end)

  defp handle_asteroid_hitting_ships(asteroid_ships, game_id) do
    Enum.map(asteroid_ships, fn {a, s} -> asteroid_hit_ship(game_id, a, s) end)
  end

  # List of {BulletLoc, Ship Tuple}

  defp handle_bullets_hitting_ships(game, bullet_ships, game_id) do
    Enum.each(bullet_ships, fn {b, s} ->
      Game.Server.say_player_shot_ship(game_id, b.id, s.id)
    end)

    bullet_ships
    |> unique_bullets
    |> Enum.each(fn b ->
      %{pos: %{x: x, y: y}} = game.state.bullets[b.pid]
      Game.Server.explosion(game_id, x, y)
    end)

    Enum.each(bullet_ships, fn {_, s} ->
      # TODO send this to the ship, not the game
      # TODO this should be the full ship pid
      Ship.Server.hyperspace(s.pid)
    end)
  end

  defp handle_bullets_hitting_asteroids(_game, bullet_asteroids, game_id) do
    bullet_asteroids
    |> unique_bullets
    |> Enum.each(fn b -> Game.Server.say_player_shot_asteroid(game_id, b.id) end)

    bullet_asteroids
    |> unique_targets
    |> Enum.each(fn %{pid: asteroid_pid, pos: %{x: x, y: y}} ->
      Game.Server.explosion(game_id, x, y)
      Game.Server.asteroid_hit(game_id, asteroid_pid)
    end)
  end

  defp stop_bullets(bullets) do
    Enum.each(bullets, fn b ->
      Process.exit(b.pid, :normal)
    end)
  end
end
