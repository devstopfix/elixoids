defmodule Elixoids.Game.Snapshot do
  @moduledoc """
  Snapshot of the game state. Used by collision detection and UI processes.
  """

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Ship.Location, as: ShipLoc

  @type t :: %{
          required(:asteroids) => list(AsteroidLoc.t()),
          required(:bullets) => list(BulletLoc.t()),
          required(:ships) => list(ShipLoc.t())
        }

  defstruct asteroids: [], bullets: [], ships: []
end
