defmodule Elixoids.Explosion.Location do
  @moduledoc false

  alias Elixoids.Api.State.WorldJSON

  defstruct x: 0, y: 0

  defimpl WorldJSON, for: __MODULE__ do
    def to_json_list(%{x: x, y: y}) do
      [x, y]
    end
  end
end
