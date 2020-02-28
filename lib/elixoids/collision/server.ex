defmodule Elixoids.Collision.Server do
  @moduledoc """
  Simplistic collision detections.
  Runs as a separate process to avoid slowing game loop in busy screens.
  Tests everything against everything else - no bounding boxes or culling.
  A bullet may take out multiple ships, or multiple asteroids, but not both a ship and an asteroid
  """

  use GenServer

  alias Elixoids.Game.Snapshot
  import Elixoids.Const, only: [saucer_tag: 0]
  import Elixoids.Event

  @saucer_tag saucer_tag()

  def start_link(game_id) when is_integer(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via(game_id))
  end

  def collision_tests(game_id, game) do
    GenServer.cast(via(game_id), {:collision_tests, game})
  end

  defp via(game_id), do: {:via, Registry, {Registry.Elixoids.Collisions, {game_id}}}

  # GenServer

  def init(args), do: {:ok, args}

  # Collisions

  def handle_cast({:collision_tests, game}, game_id) do
    %Snapshot{asteroids: asteroids, bullets: bullets, ships: ships} = game

    events = collision_check(asteroids, bullets, ships)
    dispatch(game_id, events)

    {:noreply, game_id}
  end

  # TODO refector this to either be a dispatch function or a collector function
  def collision_check(asteroids, bullets, ships) do
    tally = [a: MapSet.new(asteroids), b: MapSet.new(bullets), s: MapSet.new(ships), hits: []]

    [_, _, _, hits: events] =
      tally
      |> check_bullets_hit_asteroids
      |> check_bullets_hit_ships
      |> check_asteroids_hit_ships
      |> check_saucer_hit_ships

    events
  end

  defp check_bullets_hit_asteroids(tally = [a: as, b: bs, s: _, hits: _]) do
    hits = for b <- bs, a <- as, bullet_hits_asteroid?(b, a), do: {:bullet_hit_asteroid, b, a}

    Enum.reduce(hits, tally, fn hit = {_, b, a}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: MapSet.delete(as, a), b: MapSet.delete(bs, b), s: ss, hits: [hit | hits]]
    end)
  end

  defp check_bullets_hit_ships(tally = [a: _, b: bs, s: ss, hits: _]) do
    hits = for b <- bs, s <- ss, bullet_hits_ship?(b, s), do: {:bullet_hit_ship, b, s}

    Enum.reduce(hits, tally, fn hit = {_, b, s}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: as, b: MapSet.delete(bs, b), s: MapSet.delete(ss, s), hits: [hit | hits]]
    end)
  end

  defp check_asteroids_hit_ships(tally = [a: as, b: _, s: ss, hits: _]) do
    hits = for a <- as, s <- ss, asteroid_hits_ship?(a, s), do: {:asteroid_hit_ship, a, s}

    Enum.reduce(hits, tally, fn hit = {_, a, s}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: MapSet.delete(as, a), b: bs, s: MapSet.delete(ss, s), hits: [hit | hits]]
    end)
  end

  defp check_saucer_hit_ships(tally = [a: _, b: _, s: ss, hits: _]) do
    if saucer = Enum.find(ss, fn %{tag: tag} -> tag == @saucer_tag end) do
      players = Enum.reject(ss, fn %{tag: tag} -> tag == @saucer_tag end)
      hits = for s <- players, ship_hits_ship?(s, saucer), do: {:ship_hit_ship, saucer, s}
      Keyword.update(tally, :hits, [], &(&1 ++ hits))
    else
      tally
    end
  end

  defp dispatch(_game_id, []), do: true

  defp dispatch(game_id, [{:bullet_hit_ship, b, s} | events]) do
    bullet_hit_ship(game_id, b, s)
    dispatch(game_id, events)
  end

  defp dispatch(game_id, [{:bullet_hit_asteroid, b, a} | events]) do
    bullet_hit_asteroid(game_id, b, a)
    dispatch(game_id, events)
  end

  defp dispatch(game_id, [{:asteroid_hit_ship, a, s} | events]) do
    asteroid_hit_ship(game_id, a, s)
    dispatch(game_id, events)
  end

  defp dispatch(game_id, [{:ship_hit_ship, s1, s2} | events]) do
    ship_hit_ship(game_id, s1, s2)
    dispatch(game_id, events)
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

  def bullet_hits_asteroid?(bullet, asteroid) do
    %{pos: %{x: bx, y: by}} = bullet
    %{pos: %{x: ax, y: ay}, radius: ar} = asteroid

    sq(bx - ax) + sq(by - ay) < sq(ar)
  end

  @doc """
  Test if two circles touch or overlap by comparing
  distances between their centres
  """
  def asteroid_hits_ship?(asteroid, ship) do
    %{pos: %{x: ax, y: ay}, radius: ar} = asteroid
    %{pos: %{x: sx, y: sy}, radius: sr} = ship

    sq(ax - sx) + sq(ay - sy) <= sq(sr + ar)
  end

  def ship_hits_ship?(s1, s2) do
    %{pos: %{x: s1x, y: s1y}, radius: s1r} = s1
    %{pos: %{x: s2x, y: s2y}, radius: s2r} = s2
    sq(s2x - s1x) + sq(s2y - s1y) < sq(s1r + s2r)
  end
end
