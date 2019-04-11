defmodule Elixoids.Server.WebsocketGameHandler do
  @moduledoc """
  Websocket Handler. Queries the game state at 24fps
  and publishes it to subscriber.

  1 hour idle timeout.
  """

  import Logger

  @ms_between_frames div(1000, 24)
  @pause_ms 1000
  @opts %{idle_timeout: 60 * 60 * 1000, compress: false}
  @explosions_per_frame 2

  @behaviour :cowboy_handler

  def init(req, _state) do
    [:http_connection, :game] |> inspect |> info()
    {:cowboy_websocket, req, [], @opts}
  end

  def websocket_init(_state) do
    {:ok, _pid} = Elixoids.News.subscribe(0)
    [:ws_connection, :game] |> inspect |> info()
    :erlang.start_timer(@pause_ms, self(), [])
    {:ok, []}
  end

  def terminate(_reason, _state) do
    [:ws_disconnect, :game] |> inspect |> info()
    :ok
  end

  def websocket_handle({:text, _ignore}, state) do
    {:ok, state}
  end

  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  def websocket_info({:timeout, _ref, _}, explosions) do
    :erlang.start_timer(@ms_between_frames, self(), [])
    game_state = Game.Server.state(:game)
    game_state_explosions = Map.put(game_state, :x, Enum.take(explosions, @explosions_per_frame))

    case Jason.encode(game_state_explosions) do
      {:ok, message} -> {:reply, {:text, message}, Enum.drop(explosions, @explosions_per_frame)}
      {:error, _} -> {:ok, explosions}
    end
  end

  def websocket_info({:explosion, x = [_, _]}, state) do
    {:ok, [x | state]}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end
end
