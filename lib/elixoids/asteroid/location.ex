defmodule Elixoids.Asteroid.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON
  import Elixoids.World.RoundDP

  @type t :: %{
          pid: pid(),
          id: integer(),
          pos: Elixoids.World.Point.t(),
          radius: float()
        }

  defstruct pid: nil, id: 0, pos: nil, radius: 0.0

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: pos, radius: radius}) do
      %{x: x, y: y} = round_dp(pos)
      [id, x, y, radius]
    end
  end
end
