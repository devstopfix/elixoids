defmodule Elixoids.World.Clock do
  @moduledoc false

  @doc """
  Current OS time in milliseconds since 1970.
  """
  def now_ms, do: :os.system_time(:milli_seconds)

  @doc """
  Return number of milliseconds between given time t and now
  """
  def since(t), do: now_ms() - t

  @doc """
  Return true if t is in the past, otherwise false
  """
  def past?(t), do: t < now_ms()

  @doc """
  Seconds to milliseconds.
  """
  def s_to_ms(s), do: trunc(s * 1000.0)
end
