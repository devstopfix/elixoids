defmodule Elixoids.Api.State do
  @moduledoc """
  Send minumal JSON lists of state, not maps
  """

  defprotocol PlayerJSON do
    def to_json_list(m)
  end

  defprotocol WorldJSON do
    def to_json_list(m)
  end
end
