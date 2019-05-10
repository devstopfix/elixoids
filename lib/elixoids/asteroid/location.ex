defmodule Elixoids.Asteroid.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON

  @type t :: %{
          pid: pid(),
          id: integer(),
          pos: Elixoids.World.Point.t(),
          radius: float()
        }

  defstruct pid: nil, id: 0, pos: nil, radius: 0.0

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: %{x: x, y: y}, radius: radius}) do
      [id, Float.round(x, 2), Float.round(y, 2), Float.round(radius)]
    end
  end
end
