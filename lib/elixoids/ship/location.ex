defmodule Elixoids.Ship.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON
  import Elixoids.World.RoundDP

  @type t :: %{
          pid: pid(),
          id: integer(),
          tag: String.t(),
          pos: Elixoids.World.Point.t(),
          theta: float(),
          radius: float()
        }

  defstruct pid: nil, id: 0, tag: "", pos: nil, theta: 0.0, radius: 0.0

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{
          tag: tag,
          pos: pos,
          theta: theta,
          radius: radius
        }) do
      %{x: x, y: y} = round_dp(pos)
      [tag, x, y, radius, theta]
    end
  end
end
