defmodule Elixoids.Server.WebsocketNewsHandler do
  @moduledoc """
  Receives strings from the game and publishes them to the subscriber.
  """

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 60 * 1000}

  def init(req = %{bindings: %{game: game}}, _opts) do
    {:cowboy_websocket, req, game, @opts}
  end

  def websocket_init(game) do
    with {game_id, ""} <- Integer.parse(game),
         {:ok, _pid} <- Elixoids.News.subscribe(game_id) do
      {:ok, []}
    else
      :error -> {:stop, []}
    end
  end

  def websocket_terminate(_reason, _req, _state), do: :ok

  def websocket_handle(_data, state), do: {:ok, state}

  # Forward news event to client
  def websocket_info({:news, news}, state) when is_binary(news) do
    {:reply, {:text, news}, state}
  end

  def websocket_info(_, state), do: {:ok, state}
end
