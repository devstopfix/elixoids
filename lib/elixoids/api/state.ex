defmodule Elixoids.Api.State do
  @moduledoc """
  Send minumal JSON lists of state, not maps
  """

  defprotocol WorldJSON do
    def to_json_list(m)
  end
end
