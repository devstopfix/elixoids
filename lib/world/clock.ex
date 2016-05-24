defmodule World.Clock do
  
  @moduledoc """
  Functions that deal with time.
  """

  @doc """
  Current OS time in milliseconds since 1970.
  """
  def now_ms do
    :os.system_time(:milli_seconds)
  end

end