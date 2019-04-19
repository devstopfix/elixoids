defmodule Elixoids.Collision.Server do
  @moduledoc """
  Simplistic collision detections.
  Runs as a separate process to avoid slowing game loop in busy screens.
  Tests everything against everything else - no bounding boxes or culling.
  """

  use GenServer

  alias Elixoids.Game.Snapshot
  import Elixoids.Event

  def start_link(game_id) when is_integer(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  @spec collision_tests(integer(), Snapshopt.t()) :: :ok
  def collision_tests(game_id, game) do
    GenServer.cast(via(game_id), {:collision_tests, game})
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

  def init(args), do: {:ok, args}

  # Collisions

  def handle_cast({:collision_tests, game}, game_id) do
    check_for_collisions(game, game_id)
    {:noreply, game_id}
  end

  defp check_for_collisions(game, game_id) do
    %Snapshot{asteroids: asteroids, bullets: bullets, ships: ships} = game

    bullet_ships = detect_bullets_hitting_ships(bullets, ships)
    # List of {BulletLoc, Ship Tuple}
    handle_bullets_hitting_ships(game, bullet_ships, game_id)

    asteroids
    |> detect_asteroids_hitting_ships(ships)
    |> handle_asteroid_hitting_ships(game_id)

    bullet_asteroids = detect_bullets_hitting_asteroids(bullets, asteroids)
    handle_bullets_hitting_asteroids(bullet_asteroids, game_id)

    # TODO we could not check bullets against ships and rocks
  end

  defp handle_asteroid_hitting_ships(asteroid_ships, game_id) do
    Enum.map(asteroid_ships, fn {a, s} -> asteroid_hit_ship(game_id, a, s) end)
  end

  # List of {BulletLoc, Ship Tuple}

  defp handle_bullets_hitting_ships(_game, bullet_ships, game_id) do
    bullet_ships
    |> bullets_hit_single_target()
    |> Enum.each(fn {b, s} -> bullet_hit_ship(game_id, b, s) end)
  end

  defp handle_bullets_hitting_asteroids(bullet_asteroids, game_id) do
    bullet_asteroids
    |> bullets_hit_single_target()
    |> Enum.each(fn {b, a} -> bullet_hit_asteroid(game_id, b, a) end)
  end

  defp bullets_hit_single_target(bxs) do
    bxs
    |> Enum.group_by(fn {b, _} -> b end)
    |> Map.values()
    |> Enum.map(&List.first/1)
  end

  defp via(game_id), do: {:via, Registry, {Registry.Elixoids.Collisions, {game_id}}}
end
