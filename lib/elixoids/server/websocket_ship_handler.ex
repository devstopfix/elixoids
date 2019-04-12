defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 4fps
  and publishes it over the websocket.
  """

  alias Elixoids.Player, as: Player
  alias Game.Server, as: Game
  import Elixir.Translate
  import Logger

  @ms_between_frames div(1000, 4)
  @pause_ms 1000

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 1000}

  def init(req = %{bindings: %{tag: tag}}, _state) do
    [:http_connection, :ship] |> inspect |> info()
    {:cowboy_websocket, req, %{url_tag: tag, game_id: 0}, @opts}
  end

  def websocket_init(state = %{url_tag: tag, game_id: game_id}) do
    if Player.valid_player_tag?(tag) do
      Game.spawn_player(:game, tag)
      [:ws_connection, :ship, tag] |> inspect |> info()
      :erlang.start_timer(@pause_ms, self(), [])
      {:ok, %{tag: tag, game_id: game_id}}
    else
      [:bad_player_tag, tag] |> inspect |> warn()
      {:stop, state}
    end
  rescue
    e in RuntimeError ->
      [:ws_connection, e] |> inspect |> error()
      {:stop, state}
  end

  def terminate(_reason, _partial_req, %{tag: tag, game_id: game_id}) do
    Game.remove_player(game_id, tag)
    [:ws_disconnect, tag] |> inspect |> info()
    :ok
  end

  def websocket_handle({:text, content}, state = %{tag: tag}) do
    case Jason.decode(content) do
      {:ok, player_input} ->
        handle_input(player_input, state)
        {:ok, state}

      {:error, e} ->
        [:badjson, tag, content, e] |> inspect |> Logger.info()
        {:reply, {:text, '{"bad":"json"}'}, state}
    end
  end

  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  def websocket_info({:timeout, _ref, _}, state = %{tag: ship_tag, game_id: game_id}) do
    ship_state = Game.state_of_ship(game_id, ship_tag)

    {x, y} = ship_state.origin

    send_state =
      ship_state
      |> Map.update(:rocks, %{}, &asteroids_relative(&1, x, y))
      |> Map.update(:ships, %{}, &ships_relative(&1, x, y))
      |> Map.delete(:origin)

    :erlang.start_timer(@ms_between_frames, self(), [])

    case Jason.encode(send_state) do
      {:ok, message} -> {:reply, {:text, message}, state}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  # Player

  @spec handle_input(map(), String.t()) :: boolean()
  defp handle_input(player_input, state) do
    for {k, v} <- player_input do
      handle_input(k, v, state)
    end
    |> Enum.any?()
  end

  defp handle_input("fire", true, state), do: player_pulls_trigger(state)
  defp handle_input("theta", theta, state) when is_float(theta), do: player_turns(theta, state)

  defp handle_input("theta", theta, state) when is_integer(theta),
    do: player_turns(theta * 1.0, state)

  defp handle_input(_k, _v, _state), do: false

  defp player_pulls_trigger(%{tag: tag, game_id: game_id}) do
    Game.player_pulls_trigger(game_id, tag)
    true
  end

  defp player_turns(theta, %{tag: tag, game_id: game_id}) do
    Game.player_new_heading(game_id, tag, theta)
    true
  end
end
