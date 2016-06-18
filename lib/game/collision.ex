defmodule Game.Collision do
  
  @moduledoc """
  Simplistic collision detections.
  We use points (bullets) inside circles (ships)
  """

  def collision?(bullet, ship) do
    {bullet_id, bx, by} = bullet
    {ship_id, _tag, sx, sy, sr, _, _} = ship
    d = sr * sr
    (((bx - sx) * (bx - sx)) + ((by - sy) * (by - sy))) < d
  end

  def detect_bullets_hitting_ships(bullets, ships) do
    for b <- bullets, s <- ships, collision?(b,s), do: {elem(b, 0), elem(s, 0)}
  end

  def unique_bullets(collisions) do
    collisions
    |> Enum.map(fn {b,_} -> b end)
    |> Enum.uniq
  end

  def unique_ships(collisions) do
    collisions
    |> Enum.map(fn {_,s} -> s end)
    |> Enum.uniq
  end

end