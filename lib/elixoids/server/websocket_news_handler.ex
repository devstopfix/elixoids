defmodule Elixoids.Server.WebsocketNewsHandler do
  @moduledoc """
  Receives strings from the game and publishes them to the subscriber as Server Sent Events.
  """

  @behaviour :cowboy_handler

  def init(req0 = %{bindings: %{game: game}}, _opts) do
    with {game_id, ""} <- Integer.parse(game),
         {:ok, _pid} <- Elixoids.News.subscribe(game_id),
         req <- :cowboy_req.stream_reply(200, %{"content-type" => "text/event-stream"}, req0) do
      {:cowboy_loop, req, game}
    else
      :error -> {:stop, req0, []}
    end
  end

  # Forward news event to client
  def info({:news, news}, req, state) when is_binary(news) do
    :ok = :cowboy_req.stream_events(%{data: to_charlist(news)}, :nofin, req)
    {:ok, req, state}
  end

  def info(_, req, state), do: {:ok, req, state}
end
