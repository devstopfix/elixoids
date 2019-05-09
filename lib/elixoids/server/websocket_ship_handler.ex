defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 8 fps and publishes it over the websocket.
  """

  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Player
  alias Elixoids.Ship.Server, as: Ship
  import Elixir.Translate

  @ms_between_frames div(1000, 4)
  @pause_ms 250

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 1000}

  def init(req = %{bindings: %{game: game, tag: tag}}, _state) do
    {:cowboy_websocket, req, %{url_tag: tag, game_id: game}, @opts}
  end

  def websocket_init(state = %{url_tag: tag, game_id: game}) do
    :erlang.start_timer(@pause_ms, self(), [])

    with {game_id, ""} <- Integer.parse(game),
         Player.valid_player_tag?(tag),
         {:ok, _pid, ship_id} <- Game.spawn_player(game_id, tag) do
      {:ok, %{tag: tag, ship_id: ship_id}}
    else
      :error -> {:stop, state}
      {:error, {:already_started, _}} -> {:stop, state}
    end
  end

  def terminate(_reason, _partial_req, %{ship_id: ship_id}) do
    Ship.stop(ship_id)
    :ok
  end

  def terminate(_reason, _partial_req, _), do: :ok

  @bad_json {:text, '{"bad":"json"}'}

  def websocket_handle({:text, content}, state) do
    case Jason.decode(content) do
      {:ok, player_input} ->
        handle_input(player_input, state)

      {:error, _} ->
        {:reply, @bad_json, state}

      # {:error, :badarg, _} ->
      #   {:reply, @bad_json, state}
    end
  catch
    _, _ -> {:stop, state}
  end

  def websocket_handle(_inframe, state), do: {:ok, state}

  def websocket_info({:timeout, _ref, _}, state = %{ship_id: ship_id}) do
    :erlang.start_timer(@ms_between_frames, self(), [])

    ship_state = Ship.game_state_req(ship_id)
    send_state = convert(ship_state)

    case Jason.encode(send_state) do
      {:ok, message} -> {:reply, {:text, message}, state}
      _ -> {:noreply, state}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end

  # Player

  defp handle_input(player_input, state) when is_list(player_input), do: {:ok, state}

  defp handle_input(player_input, state) when is_map(player_input) do
    for {k, v} <- player_input do
      handle_input(k, v, state)
    end

    {:ok, state}
  end

  defp handle_input(_, state), do: {:ok, state}

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

  defp convert(%{origin: origin, rocks: rocks, ships: ships, theta: theta}) do
    %{
      rocks: asteroids_relative(rocks, origin),
      ships: ships_relative(ships, origin),
      theta: theta
    }
  end
end
