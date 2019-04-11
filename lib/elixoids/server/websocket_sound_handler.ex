defmodule Elixoids.Server.WebsocketSoundHandler do
  @moduledoc """
  Websocket Handler. Queries the game state at 12fps
  and publishes the sounds to the subscriber.
  """

  import Logger

  @ms_between_frames div(1000, 12)
  @opts %{idle_timeout: 60 * 60 * 1000}

  @behaviour :cowboy_handler

  def init(req, _opts) do
    {:cowboy_websocket, req, [], @opts}
  end

  @doc """
  Client connects here. State is the set of explosions sent to the client recently.
  """
  def websocket_init(_state) do
    {:ok, _pid} = Elixoids.News.subscribe(0)
    [:ws_connection, :audio] |> inspect |> Logger.info()
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, []}
  end

  def websocket_terminate(_reason, _req, _state) do
    [:ws_disconnect, :audio] |> inspect |> Logger.info()
    :ok
  end

  def websocket_handle(_data, state) do
    {:ok, state}
  end

  @doc """
  Perodically query the game state, deduplicate explosions,
  and push to the client.
  """

  def websocket_info({:timeout, _ref, _}, []) do
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, []}
  end

  def websocket_info({:timeout, _ref, _}, state) do
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:reply, {:text, format(state)}, []}
  end

  def websocket_info({:audio, sound}, state) do
    {:ok, [sound | state]}
  end

  def websocket_info(_, state) do
    {:ok, state}
  end

  defp format(state) do
    case Jason.encode(state) do
      {:ok, message} -> message
    end
  end
end
