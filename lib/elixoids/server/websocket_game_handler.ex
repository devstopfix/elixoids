defmodule Elixoids.Server.WebsocketGameHandler do
  @moduledoc """
  Websocket Handler for the graphics engine. Queries the game state at 30fps
  and publishes it to subscriber. Should the call from this process to the game
  process fail, the connection will close and the client is expected to reconnect.
  """

  alias Elixoids.Api.State
  alias Elixoids.Game.Server, as: Game

  @fps 30
  @ms_between_frames div(1000, @fps)
  @pause_ms 1000
  @opts %{idle_timeout: 60 * 60 * 1000, compress: false}
  @explosions_per_frame 7

  @behaviour :cowboy_handler

  def init(req = %{bindings: %{game: game}}, _state) do
    {:cowboy_websocket, req, game, @opts}
  end

  def websocket_init(game) do
    with {game_id, ""} <- Integer.parse(game),
         {:ok, _pid} <- Elixoids.News.subscribe(game_id),
         state <- %{game_id: game_id, explosions: []},
         _ref <- :erlang.start_timer(@pause_ms, self(), state) do
      {:ok, state}
    else
      :error -> {:stop, game}
    end
  end

  def terminate(_reason, _state), do: :ok

  def websocket_handle({:text, _ignore}, state), do: {:ok, state}

  def websocket_handle(_inframe, state), do: {:ok, state}

  def websocket_info({:timeout, _ref, _}, %{game_id: game_id, explosions: explosions}) do
    :erlang.start_timer(@ms_between_frames, self(), [])

    game_state =
      game_id
      |> Game.state()
      |> Map.put(:x, explosions)
      |> convert()

    case Jason.encode(game_state) do
      {:ok, message} -> {:reply, {:text, message}, %{game_id: game_id, explosions: []}}
      {:error, _} -> {:ok, %{game_id: game_id, explosions: []}}
    end
  end

  # Keep a bounded FIFO list of the recent explosion
  def websocket_info({:explosion, x}, state = %{explosions: []}) do
    {:ok, %{state | explosions: [x]}}
  end

  def websocket_info({:explosion, x}, state = %{explosions: explosions}) do
    {:ok, %{state | explosions: Enum.take([x | explosions], @explosions_per_frame)}}
  end

  def websocket_info(_info, state), do: {:ok, state}

  defp convert(game_state) do
    game_state
    |> Map.update(:a, [], &to_json/1)
    |> Map.update(:b, [], &to_json/1)
    |> Map.update(:s, [], &to_json/1)
    |> Map.update(:x, [], &to_json/1)
  end

  defp to_json(xs), do: Enum.map(xs, fn m -> State.WorldJSON.to_json_list(m) end)
end
