defmodule Elixoids.Server.WebsocketNewsHandler do
  @moduledoc """
  Websocket Handler. Queries the game state at 12fps
  and publishes it over the websocket.
  """

  # 4 FPS
  @ms_between_frames div(1000, 4)

  @behaviour :cowboy_websocket_handler

  def init({_tcp, _http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_TransportName, req, _opts) do
    IO.puts("Sending NEWS from PID #{inspect(self())}")
    :erlang.start_timer(1000, self(), [])
    {:ok, req, :undefined_state}
  end

  # Required callback.  Put any essential clean-up here.
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  def websocket_handle({:text, _content}, req, state) do
    {:reply, {:text, "Ignored"}, req, state}
  end

  def websocket_handle(_data, req, state) do
    {:ok, req, state}
  end

  def websocket_info({_timeout, _ref, _foo}, req, state) do
    lines = :news |> Game.Events.flush() |> Enum.join("\n")

    :erlang.start_timer(@ms_between_frames, self(), [])

    {:reply, {:text, lines}, req, state}
  end

  # fallback message handler 
  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end
end
