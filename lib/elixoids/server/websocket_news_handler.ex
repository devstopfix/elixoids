defmodule Elixoids.Server.WebsocketNewsHandler do
  @moduledoc """
  Websocket Handler. Receives strings from the game and publishes them to the subscriber.
  """

  import Logger

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 60 * 1000}

  def init(req, _opts) do
    {:cowboy_websocket, req, [], @opts}
  end

  def websocket_init(_state) do
    # TODO game from URL
    {:ok, _pid} = Elixoids.News.subscribe(0)
    [:ws_connection, :news] |> inspect |> info()
    {:ok, []}
  end

  def websocket_terminate(_reason, _req, _state) do
    [:ws_disconnect, :news] |> inspect |> info()
    :ok
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  # Forward news event to client
  def websocket_info({:news, news}, state) when is_binary(news) do
    {:reply, {:text, news}, state}
  end

  def websocket_info(_, state) do
    {:ok, state}
  end
end
