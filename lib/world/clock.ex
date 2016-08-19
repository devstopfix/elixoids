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

  @doc """
  Return true if t is in the past, otherwise false
  """
  def past?(t) do
  	t < now_ms
  end

end
