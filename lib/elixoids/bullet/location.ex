defmodule Elixoids.Bullet.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON
  import Elixoids.World.RoundDP

  @type t :: %{pid: pid(), id: integer(), pos: Elixoids.World.Point.t(), shooter: String.t()}

  defstruct pid: nil, id: 0, shooter: "", pos: nil

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{id: id, pos: pos}) do
      %{x: x, y: y} = round_dp(pos)
      [id, x, y]
    end
  end
end
