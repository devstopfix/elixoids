defmodule Elixoids.Bullet.Location do
  @moduledoc false

  defstruct pid: nil, id: 0, shooter: "", pos: nil

  defimpl Elixoids.Api.State.PlayerJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: %{x: x, y: y}}) do
      [id, x, y]
    end
  end
end
