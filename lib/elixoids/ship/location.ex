defmodule Elixoids.Ship.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON

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
          pos: %{x: x, y: y},
          theta: theta,
          radius: radius
        }) do
      [tag, Float.round(x, 2), Float.round(y, 2), Float.round(radius), Float.round(theta, 3)]
    end
  end
end
