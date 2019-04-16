defmodule Elixoids.Game.Heartbeat do
  @moduledoc """
  Heatbeat behaviour for actors that need to update their state
  at regular intervals (e.g. 60fps)

  Actors that use this module must implement:

      def handle_tick(pid, elapsed_ms, state)

  where

  * `pid` is the process pid
  * `elapsed_ms` is the number of milliseconds past since last event
  * `state` is the process state

  The method should return:

  * `{:ok, new_state}` and the heartbeats will continue
  * any other valid response for `handle_info` which will end the heartbeats e.g. `{:stop, :normal, state}`

  """

  defmacro __using__(_opts) do
    quote do
      @fps 60
      @ms_between_ticks div(1000, @fps)
      def start_heartbeat(pid \\ self()), do: Process.send(pid, :tick, [])

      def handle_info(:tick, state = %{clock_ms: clock_ms}) do
        delta_t_ms = World.Clock.since(clock_ms)

        case handle_tick(self(), delta_t_ms, state) do
          {:ok, new_state} ->
            next_heartbeat()
            {:noreply, %{new_state | clock_ms: World.Clock.now_ms()}}

          other ->
            other
        end
      end

      def handle_info(:tick, state) do
        next_heartbeat()
        {:noreply, Map.put(state, :clock_ms, World.Clock.now_ms())}
      end

      defp next_heartbeat do
        Process.send_after(self(), :tick, @ms_between_ticks)
      end
    end
  end
end
