defmodule Elixoids.Ship.Targets do
  @moduledoc "Targets available to a Ship"

  alias Elixoids.World.Point

  @type t :: %{theta: float(), rocks: list(), ships: list(), origin: Point.t()}

  defstruct theta: 0.0, rocks: [], ships: [], origin: %Point{}
end
