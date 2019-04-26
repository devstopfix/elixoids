defmodule Elixoids.Asteroid.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON
  alias Elixoids.World.Velocity
  import Elixoids.World.RoundDP

  @type t :: %{
          pid: pid(),
          id: integer(),
          pos: World.Point.t(),
          radius: float(),
          velocity: Velocity.t()
        }

  defstruct pid: nil, id: 0, pos: nil, radius: 0.0, velocity: nil

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: pos, radius: radius}) do
      %{x: x, y: y} = round_dp(pos)
      [id, x, y, radius]
    end
  end
end
