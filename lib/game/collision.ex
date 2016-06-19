defmodule Game.Collision do

  @moduledoc """
  Simplistic collision detections.
  """

  @doc """
  Square a number.
  """
  defmacro sq(n) do
    quote do
      (unquote(n) * unquote(n))
    end
  end

  @doc """
  We use points (bullets) inside circles (ships)
  """
  def bullet_hits_ship?(bullet, ship) do
    {_bullet_id, bx, by} = bullet
    {_ship_id, _tag, sx, sy, sr, _, _} = ship

    (sq(bx - sx) + sq(by - sy)) < sq(sr)
  end

  @doc """
  Return a tuple of {bullet_id, ship_id} for each collision.
  """
  def detect_bullets_hitting_ships(bullets, ships) do
    l = for b <- bullets, s <- ships, bullet_hits_ship?(b,s), 
      do: {elem(b, 0), elem(s, 0)}
    Enum.uniq_by(l, fn {b,_s} -> b end)
  end

  def bullet_hits_asteroid?(bullet, asteroid) do
    {_bullet_id, bx, by} = bullet
    {_asteroid_id, ax, ay, ar,} = asteroid

    (sq(bx - ax) + sq(by - ay)) < sq(ar)
  end

  @doc """
  Return a tuple of {bullet_id, asteroid_id} for each collision.
  """
  def detect_bullets_hitting_asteroids(bullets, asteroids) do
    l = for b <- bullets, a <- asteroids, bullet_hits_asteroid?(b,a), 
      do: {elem(b, 0), elem(a, 0)}
    Enum.uniq_by(l, fn {b,_s} -> b end)
  end

  @doc """
  List of bullets (bullet_ids) to stop.
  """
  def unique_bullets(collisions) do
    collisions
    |> Enum.map(fn {b,_} -> b end)
    |> Enum.uniq
  end

  @doc """
  List of targets (ship_ids) to destroy
  """
  def unique_targets(collisions) do
    collisions
    |> Enum.map(fn {_,s} -> s end)
    |> Enum.uniq
  end

  @doc """
  Test if two circles touch or overlap by comparing
  distances between their centres
  """
  def asteroid_hits_ship?(asteroid, ship) do
    {_asteroid_id, ax, ay, ar,} = asteroid
    {_ship_id, _tag, sx, sy, sr, _, _} = ship

    (sq(ax - sx) + sq(ay - sy)) < (sq(sr) + sq(ar))
  end

end