defmodule Game.Collision do
  @moduledoc """
  Simplistic collision detections.
  Runs as a separate process to avoid slowing game loop in busy screens.
  Tests everything against everything else - no bounding boxes or culling.
  """

  use GenServer

  def start_link(game_pid) do
    GenServer.start_link(__MODULE__, {:ok, game_pid}, [])
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
    {_ship_id, _tag, sx, sy, sr, _, _} = ship

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
    {_asteroid_id, ax, ay, ar} = asteroid

    sq(bx - ax) + sq(by - ay) < sq(ar)
  end

  @doc """
  Return a tuple of {bullet_id, asteroid_id} for each collision.
  A single bullet can only hit a single asteroid
  """
  def detect_bullets_hitting_asteroids(bullets, asteroids) do
    l = for b <- bullets, a <- asteroids, bullet_hits_asteroid?(b, a), do: {b, a}

    Enum.uniq_by(l, fn {b, _s} -> b.pid end)
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
    {_asteroid_id, ax, ay, ar} = asteroid
    {_ship_id, _tag, sx, sy, sr, _, _} = ship

    :math.sqrt(sq(ax - sx) + sq(ay - sy)) <= sr + ar
  end

  @doc """
  Return a tuple of {asteroid_id, ship_id} for each collision.
  """
  def detect_asteroids_hitting_ships(asteroids, ships) do
    l = for a <- asteroids, s <- ships, asteroid_hits_ship?(a, s), do: {elem(a, 0), elem(s, 0)}
    Enum.uniq_by(l, fn {_a, s} -> s end)
  end

  # GenServer

  def init({:ok, game_pid}) do
    {:ok, game_pid}
  end

  def collision_tests(pid, game) do
    GenServer.cast(pid, {:collision_tests, game})
  end

  # Collisions

  def handle_cast({:collision_tests, game}, game_pid) do
    check_for_collisions(game, game_pid)
    {:noreply, game_pid}
  end

  defp check_for_collisions(game, game_pid) do
    all_asteroids = Map.values(game.state.asteroids)
    # TODO move to game process
    all_bullets = Map.values(game.state.bullets) |> Enum.reject(fn b -> b == :spawn end)
    all_ships = Map.values(game.state.ships)

    bullet_ships = detect_bullets_hitting_ships(all_bullets, all_ships)
    # List of {BulletLoc, Ship Tuple}
    handle_bullets_hitting_ships(game, bullet_ships, game_pid)

    all_asteroids
    |> detect_asteroids_hitting_ships(all_ships)
    |> handle_asteroid_hitting_ships(game_pid)

    bullet_asteroids = detect_bullets_hitting_asteroids(all_bullets, all_asteroids)
    handle_bullets_hitting_asteroids(game, bullet_asteroids, game_pid)

    dud_bullets =
      Enum.uniq(
        unique_bullets(bullet_ships) ++
          unique_bullets(bullet_asteroids)
      )

    stop_bullets(dud_bullets)
  end

  defp handle_asteroid_hitting_ships(asteroid_ships, game_pid) do
    Enum.map(asteroid_ships, fn {a, s} ->
      Game.Server.say_ship_hit_by_asteroid(game_pid, s)
      Game.Server.hyperspace_ship(game_pid, s)
      Game.Server.asteroid_hit(game_pid, a)
    end)
  end

  # List of {BulletLoc, Ship Tuple}

  defp handle_bullets_hitting_ships(game, bullet_ships, game_pid) do
    Enum.each(bullet_ships, fn {b, s} ->
      Game.Server.say_player_shot_ship(game_pid, b.id, s)
    end)

    bullet_ships
    |> unique_bullets
    |> Enum.each(fn b ->
      %{pos: %{x: x, y: y}} = game.state.bullets[b.pid]
      Game.Server.explosion(game_pid, x, y)
    end)

    Enum.each(bullet_ships, fn {_, s} ->
      # TODO send this to the ship, not the game
      # TODO this should be the full ship pid
      Game.Server.hyperspace_ship(game_pid, elem(s, 0))
    end)
  end

  defp handle_bullets_hitting_asteroids(_game, bullet_asteroids, game_pid) do
    bullet_asteroids
    |> unique_bullets
    |> Enum.each(fn b -> Game.Server.say_player_shot_asteroid(game_pid, b.id) end)

    bullet_asteroids
    |> unique_targets
    |> Enum.each(fn {asteroid_id, x, y, _r} ->
      # {asteroid_id, x, y, _r} = game.state.asteroids[hd(a)]
      Game.Server.explosion(game_pid, x, y)
      Game.Server.asteroid_hit(game_pid, asteroid_id)
    end)
  end

  defp stop_bullets(bullets) do
    Enum.each(bullets, fn b ->
      Process.exit(b.pid, :normal)
    end)
  end
end
