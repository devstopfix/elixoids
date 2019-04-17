defmodule Elixoids.Ship.Location do
  @moduledoc false

  defstruct pid: nil, id: 0, tag: "", pos: nil, theta: 0.0, radius: 0.0, color: "FFFFFF"

  defimpl Elixoids.Api.State.JSON, for: __MODULE__ do
    def to_json_list(%{
          id: id,
          tag: tag,
          pos: %{x: x, y: y},
          theta: theta,
          radius: radius,
          color: color
        }) do
      [id, tag, x, y, radius, theta, color]
    end
  end
end
