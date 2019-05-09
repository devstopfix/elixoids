defmodule Elixoids.Api.State do
  @moduledoc "Send minimal JSON lists of state, not maps with long keys"

  defprotocol WorldJSON do
    @dialyzer {:nowarn_function, __protocol__: 1}
    def to_json_list(m)
  end
end
