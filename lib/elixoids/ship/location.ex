defmodule Elixoids.Ship.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON

  defstruct pid: nil, id: 0, tag: "", pos: nil, theta: 0.0, radius: 0.0, color: "FFFFFF"

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{
          tag: tag,
          pos: %{x: x, y: y},
          theta: theta,
          radius: radius,
          color: color
        }) do
      [tag, x, y, radius, theta, color]
    end
  end
end
