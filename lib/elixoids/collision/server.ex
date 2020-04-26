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

    _events = collision_check(asteroids, bullets, ships, game_id)

    {:noreply, game_id}
  end

  def collision_check(asteroids, bullets, ships, game_id \\ -1) do
    tally = [a: MapSet.new(asteroids), b: MapSet.new(bullets), s: MapSet.new(ships), hits: []]

    [_, _, _, hits: events] =
      tally
      |> check_bullets_hit_asteroids(game_id)
      |> check_bullets_hit_ships(game_id)
      |> check_asteroids_hit_ships(game_id)
      |> check_saucer_hit_ships(game_id)

    events
  end

  defp check_bullets_hit_asteroids(tally = [a: as, b: bs, s: _, hits: _], game_id) do
    hits =
      for b <- bs,
          a <- as,
          bullet_hits_asteroid?(b, a),
          do: dispatch({:bullet_hit_asteroid, b, a, game_id})

    Enum.reduce(hits, tally, fn hit = {_, b, a, _}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: MapSet.delete(as, a), b: MapSet.delete(bs, b), s: ss, hits: [hit | hits]]
    end)
  end

  defp check_bullets_hit_ships(tally = [a: _, b: bs, s: ss, hits: _], game_id) do
    hits =
      for b <- bs,
          s <- ss,
          bullet_hits_ship?(b, s),
          do: dispatch({:bullet_hit_ship, b, s, game_id})

    Enum.reduce(hits, tally, fn hit = {_, b, s, _}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: as, b: MapSet.delete(bs, b), s: MapSet.delete(ss, s), hits: [hit | hits]]
    end)
  end

  defp check_asteroids_hit_ships(tally = [a: as, b: _, s: ss, hits: _], game_id) do
    hits =
      for a <- as,
          s <- ss,
          asteroid_hits_ship?(a, s),
          do: dispatch({:asteroid_hit_ship, a, s, game_id})

    Enum.reduce(hits, tally, fn hit = {_, a, s, _}, [a: as, b: bs, s: ss, hits: hits] ->
      [a: MapSet.delete(as, a), b: bs, s: MapSet.delete(ss, s), hits: [hit | hits]]
    end)
  end

  defp check_saucer_hit_ships(tally = [a: _, b: _, s: ss, hits: _], game_id) do
    case ships_tagged_saucer(ss) do
      {[], _} ->
        tally

      {[saucer], ships} ->
        hits =
          for s <- ships,
              ship_hits_ship?(s, saucer),
              do: dispatch({:ship_hit_ship, saucer, s, game_id})

        Keyword.update(tally, :hits, [], &(&1 ++ hits))
    end
  end

  defp ships_tagged_saucer(ss), do: Enum.split_with(ss, fn %{tag: tag} -> tag == @saucer_tag end)

  defp dispatch({_, %{pid: nil}, _, _} = event), do: event

  defp dispatch({:bullet_hit_ship, _b, _s, _game_id} = event) do
    spawn(fn -> bullet_hit_ship(event) end)
    event
  end

  defp dispatch({:bullet_hit_asteroid, _b, _a, _game_id} = event) do
    spawn(fn -> bullet_hit_asteroid(event) end)
    event
  end

  defp dispatch({:asteroid_hit_ship, _a, _s, _game_id} = event) do
    spawn(fn -> asteroid_hit_ship(event) end)
    event
  end

  defp dispatch({:ship_hit_ship, _s1, _s2, _game_id} = event) do
    spawn(fn -> ship_hit_ship(event) end)
    event
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
  def bullet_hits_ship?(%{pos: bullet}, ship) do
    point_inside_circle?(bullet, ship)
  end

  def bullet_hits_asteroid?(%{pos: bullet}, asteroid) do
    point_inside_circle?(bullet, asteroid)
  end

  def point_inside_circle?(%{x: px, y: py}, %{pos: %{x: cx, y: cy}, radius: r}) do
    sq(px - cx) + sq(py - cy) < sq(r)
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

  # https://stackoverflow.com/a/1084899/3366
  def line_segment_intersects_circle?(
        {%{x: ex, y: ey} = p1, %{x: lx, y: ly} = p2},
        %{
          pos: %{x: cx, y: cy},
          radius: r
        } = o
      ) do
    d = {lx - ex, ly - ey}
    f = {ex - cx, ey - cy}

    a = dot(d, d)
    b = 2 * dot(f, d)
    c = dot(f, f) - r * r

    discriminant = b * b - 4 * a * c

    if discriminant < 0 || a == 0 do
      false
    else
      discriminant = :math.sqrt(discriminant)
      t1 = (-b - discriminant) / (2 * a)
      t2 = (-b + discriminant) / (2 * a)

      cond do
        t1 >= 0 && t1 <= 1 -> true
        t2 >= 0 && t2 <= 1 -> true
        true -> point_inside_circle?(p1, o) || point_inside_circle?(p2, o)
      end
    end
  end

  defp dot({a1, a2}, {b1, b2}), do: a1 * b1 + a2 * b2
end
