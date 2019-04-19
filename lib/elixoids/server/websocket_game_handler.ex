defmodule Elixoids.Server.WebsocketGameHandler do
  @moduledoc """
  Websocket Handler. Queries the game state at 24fps
  and publishes it to subscriber.

  1 hour idle timeout.
  """

  alias Elixoids.Api.State

  import Logger

  @fps 24
  @ms_between_frames div(1000, @fps)
  @pause_ms 1000
  @opts %{idle_timeout: 60 * 60 * 1000, compress: false}
  @explosions_per_frame 5

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

    # TODO game id should be in WS URL and the state
    game_state =
      0
      |> Game.Server.state()
      |> Map.put(:x, Enum.take(explosions, @explosions_per_frame))
      |> convert()

    case Jason.encode(game_state) do
      {:ok, message} -> {:reply, {:text, message}, []}
      {:error, _} -> {:ok, explosions}
    end
  end

  def websocket_info({:explosion, x}, state) do
    {:ok, [x | state]}
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  defp convert(game_state) do
    game_state
    |> Map.update(:a, [], &to_json/1)
    |> Map.update(:b, [], &to_json/1)
    |> Map.update(:s, [], &to_json/1)
    |> Map.update(:x, [], &to_json/1)
  end

  defp to_json(xs), do: Enum.map(xs, fn m -> State.WorldJSON.to_json_list(m) end)
end
