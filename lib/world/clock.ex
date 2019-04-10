defmodule World.Clock do
  @moduledoc """
  Functions that deal with time.
  """

  # 60 FPS
  @default_fps 60

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
    now_ms() - t
  end

  @doc """
  Return true if t is in the past, otherwise false
  """
  def past?(t) do
    t < now_ms()
  end

  @doc """
  Sleep time between frames required to run at standard frame rate.
  """
  def ms_between_frames(fps \\ @default_fps) do
    div(1000, fps)
  end
end
