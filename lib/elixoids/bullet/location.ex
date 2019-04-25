defmodule Elixoids.Bullet.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON

  @type t :: %{pid: pid(), id: integer(), pos: World.Point.t(), shooter: String.t()}

  defstruct pid: nil, id: 0, shooter: "", pos: nil

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: %{x: x, y: y}}) do
      [id, x, y]
    end
  end
end
