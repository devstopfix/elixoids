defmodule Elixoids.Asteroid.Location do
  @moduledoc false

  alias Elixoids.Api.State.{PlayerJSON, WorldJSON}

  defstruct pid: nil, id: 0, pos: nil, radius: 0.0

  defimpl PlayerJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: %{x: x, y: y}, radius: radius}) do
      [id, x, y, radius]
    end
  end

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: %{x: x, y: y}, radius: radius}) do
      [id, x, y, radius]
    end
  end
end
