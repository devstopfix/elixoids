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
  Return number of milliseconds between given time t and now
  """
  def since(t) do
    now_ms - t
  end

  @doc """
  Return true if t is in the past, otherwise false
  """
  def past?(t) do
  	t < now_ms
  end

end
