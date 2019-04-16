defmodule Elixoids.Server.WebsocketNewsHandler do
  @moduledoc """
  Websocket Handler. Receives strings from the game and publishes them to the subscriber.
  """

  import Logger

  @ms_between_frames div(1000, 4)

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 60 * 1000}

  def init(req, _opts) do
    {:cowboy_websocket, req, [], @opts}
  end

  def websocket_init(_state) do
    {:ok, _pid} = Elixoids.News.subscribe(0)
    [:ws_connection, :news] |> inspect |> info()
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, []}
  end

  def websocket_terminate(_reason, _req, _state) do
    [:ws_disconnect, :news] |> inspect |> info()
    :ok
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  # No news to transmit
  def websocket_info({:timeout, _ref, _}, []) do
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, []}
  end

  # News to transmit
  def websocket_info({:timeout, _ref, _}, state) do
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:reply, {:text, format(state)}, []}
  end

  # Record news event
  def websocket_info({:news, news}, state) do
    {:ok, [news | state]}
  end

  def websocket_info(_, state) do
    {:ok, state}
  end

  defp format(lines), do: lines |> Enum.reverse  |> Enum.join("\n")
end
