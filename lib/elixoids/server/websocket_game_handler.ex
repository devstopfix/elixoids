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

  @behaviour :cowboy_handler


  def init(req, _state) do
    [:http_connection, :game] |> inspect |> Logger.info()
    {:cowboy_websocket, req, [], @opts}
  end

  def websocket_init(_state) do
    [:ws_connection, :game] |> inspect |> Logger.info()
    :erlang.start_timer(@pause_ms, self(), [])
    {:ok, Game.State.initial()}
  end

  def terminate(_reason, _state) do
    [:ws_disconnect, :game] |> inspect |> Logger.info()
    :ok
  end

  def websocket_handle({:text, _ignore}, state) do
    {:ok, state}
  end

  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  def websocket_info({_timeout, _ref, _}, prev_state) do
    :erlang.start_timer(@ms_between_frames, self(), [])

    game_state = Game.Server.state(:game)
    transmit = Game.State.deduplicate(game_state, prev_state)
    case Poison.encode(transmit) do
      {:ok, message} -> {:reply, {:text, message}, game_state}
      {:error, _} -> {:ok, game_state}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end
end
