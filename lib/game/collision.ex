defmodule Game.Collision do
  
  @moduledoc """
  Simplistic collision detections.
  We use points (bullets) inside circles (ships)
  """

  def bullet_hits_ship?(bullet, ship) do
    {_bullet_id, bx, by} = bullet
    {_ship_id, _tag, sx, sy, sr, _, _} = ship
    d = sr * sr
    (((bx - sx) * (bx - sx)) + ((by - sy) * (by - sy))) < d
  end

  @doc """
  Return a tuple of {bullet_id, ship_id} for each collision.
  """
  def detect_bullets_hitting_ships(bullets, ships) do
    for b <- bullets, s <- ships, bullet_hits_ship?(b,s), 
      do: {elem(b, 0), elem(s, 0)}
  end

  def bullet_hits_asteroid?(bullet, asteroid) do
    {_bullet_id, bx, by} = bullet
    {_asteroid_id, ax, ay, ar, } = asteroid
    d = ar * ar
    (((bx - ax) * (bx - ax)) + ((by - ay) * (by - ay))) < d
  end

  @doc """
  Return a tuple of {bullet_id, asteroid_id} for each collision.
  """
  def detect_bullets_hitting_asteroids(bullets, asteroids) do
    for b <- bullets, a <- asteroids, bullet_hits_asteroid?(b,a), 
      do: {elem(b, 0), elem(a, 0)}
  end

  @doc """
  List of bullets to stop.
  """
  def unique_bullets(collisions) do
    collisions
    |> Enum.map(fn {b,_} -> b end)
    |> Enum.uniq
  end

  @doc """
  List of targets to destroy
  """
  def unique_targets(collisions) do
    collisions
    |> Enum.map(fn {_,s} -> s end)
    |> Enum.uniq
  end

end