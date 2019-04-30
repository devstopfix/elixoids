defmodule Elixoids.World do
  @moduledoc "Structs and Protocols required to build the game world"

  defprotocol RoundDP do
    @doc "Floats are stored in full precision, but rounded before transmitting to clients"
    def round_dp(s)
  end
end
