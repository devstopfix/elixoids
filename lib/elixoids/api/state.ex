defmodule Elixoids.Api.State do
  @moduledoc """
  Send minumal JSON lists of state, not maps
  """

  defprotocol PlayerJSON do
    def to_json_list(m)
  end

  defimpl PlayerJSON, for: Tuple do
    # TODO replace with state records
    def to_json_list(t), do: Tuple.to_list(t)
  end

  defimpl PlayerJSON, for: Atom do
    def to_json_list(:spawn), do: [0, 0, 0]
    # TODO remove once we filter out spawns in game state call from UI!
  end
end
