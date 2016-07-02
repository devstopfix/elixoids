defmodule Game.Ticker do
  
  @moduledoc """
  Sends move events to a Game process at a specified FPS
  """

  @doc """
  This process with send a `tick` event to a `Game.Server`
  at the given fps rate.

  `fps` must be an integer between 1 and 60.
  """
  def start_link(game_pid, fps) do
    sleep_ms = fps_to_ms(fps)
    spawn_link(fn -> loop(game_pid, sleep_ms) end)
  end

  def loop(game_pid, sleep_ms) do
    Game.Server.tick(game_pid)
    receive do
      {:stop} -> :stopped;
    after
      sleep_ms -> loop(game_pid, sleep_ms)
    end
  end

  @doc """
  Calculate the number of ms to sleep in order to run
  at the given frame rate.

      > fps_to_ms(60)
      16
  """
  def fps_to_ms(fps) do
    div(1000, fps)
  end

end
