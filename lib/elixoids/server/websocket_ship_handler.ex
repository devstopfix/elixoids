defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 4fps
  and publishes it over the websocket.
  """

  alias Elixoids.Player, as: Player
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship
  import Elixir.Translate
  import Logger

  @ms_between_frames div(1000, 8)
  @pause_ms 250

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 1000}

  def init(req = %{bindings: %{tag: tag}}, _state) do
    [:http_connection, :ship] |> inspect |> info()
    {:cowboy_websocket, req, %{url_tag: tag, game_id: 0}, @opts}
  end

  def websocket_init(state = %{url_tag: tag, game_id: game_id}) do
    if Player.valid_player_tag?(tag) do
      {:ok, _pid, ship_id} = Game.spawn_player(game_id, tag)
      :erlang.start_timer(@pause_ms, self(), [])
      {:ok, %{tag: tag, ship_id: ship_id}}
    else
      {:stop, state}
    end
  end

  def terminate(_reason, _partial_req, %{ship_id: ship_id, tag: tag}) do
    Ship.stop(ship_id)
    [:ws_disconnect, tag] |> inspect |> info()
    :ok
  end

  def websocket_handle({:text, content}, state = %{tag: tag}) do
    case Jason.decode(content) do
      {:ok, player_input} ->
        handle_input(player_input, state)

      {:error, e} ->
        [:badjson, tag, content, e] |> inspect |> Logger.info()
        {:reply, {:text, '{"bad":"json"}'}, state}
    end
  end

  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  def websocket_info({:timeout, _ref, _}, state = %{ship_id: ship_id}) do
    ship_state = Ship.game_state(ship_id)
    send_state = convert(ship_state)

    :erlang.start_timer(@ms_between_frames, self(), [])

    case Jason.encode(send_state) do
      {:ok, message} -> {:reply, {:text, message}, state}
      _ -> {:noreply, state}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  # Player

  @spec handle_input(map(), map()) :: boolean()
  defp handle_input(player_input, state) do
    for {k, v} <- player_input do
      handle_input(k, v, state)
    end

    {:ok, state}
  end

  defp handle_input("fire", true, state), do: player_pulls_trigger(state)
  defp handle_input("theta", theta, state) when is_float(theta), do: player_turns(theta, state)

  defp handle_input("theta", theta, state) when is_integer(theta),
    do: player_turns(theta * 1.0, state)

  defp handle_input(_k, _v, _state), do: false

  defp player_pulls_trigger(%{ship_id: ship_id}) do
    Ship.player_pulls_trigger(ship_id)
    true
  end

  defp player_turns(theta, %{ship_id: ship_id}) do
    Ship.new_heading(ship_id, theta)
    true
  end

  defp convert(%{origin: %{x: x, y: y}, rocks: rocks, ships: ships, theta: theta}) do
    %{
      rocks: asteroids_relative(rocks, x, y),
      ships: ships_relative(ships, x, y),
      theta: theta
    }
  end
end
