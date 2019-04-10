defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 4fps
  and publishes it over the websocket.
  """

  alias Elixoids.Player, as: Player
  import Logger

  @ms_between_frames div(1000, 4)
  @pause_ms 1000

  @behaviour :cowboy_handler

  @opts %{idle_timeout: 60 * 1000}

  def init(req = %{bindings: %{tag: tag}}, _state) do
    [:http_connection, :ship] |> inspect |> Logger.info()
    {:cowboy_websocket, req, %{url_tag: tag}, @opts}
  end

  def websocket_init(state = %{url_tag: tag}) do
    if Player.valid_player_tag?(tag) do
      Game.Server.spawn_player(:game, tag)
      [:ws_connection, :ship, tag] |> inspect |> Logger.info()
      :erlang.start_timer(@pause_ms, self(), [])
      {:ok, %{tag: tag}}
    else
      [:bad_player_tag, tag] |> inspect |> Logger.warn()
      {:stop, state}
    end
  rescue
    e in RuntimeError ->
      [:ws_connection, e] |> inspect |> Logger.error()
      {:stop, state}
  end

  def terminate(_reason, _partial_req, %{tag: tag}) do
    Game.Server.remove_player(:game, tag)
    [:ws_disconnect, tag] |> inspect |> Logger.info()
    :ok
  end

  defp player_pulls_trigger(tag) do
    Game.Server.player_pulls_trigger(:game, tag)
    true
  end

  defp player_turns(tag, theta) do
    Game.Server.player_new_heading(:game, tag, theta)
    true
  end

  @spec handle_input(map(), String.t()) :: boolean()
  defp handle_input(player_input, tag) do
    for {k, v} <- player_input do
      handle_input(k, v, tag)
    end |> Enum.any?
  end

  defp handle_input("fire", true, tag), do: player_pulls_trigger(tag)
  defp handle_input("theta", theta, tag) when is_float(theta), do: player_turns(tag, theta)

  defp handle_input("theta", theta, tag) when is_integer(theta),
    do: player_turns(tag, theta * 1.0)

  defp handle_input(_k, _v, _tag), do: false

  def websocket_handle({:text, content}, state = %{tag: tag}) do
    case Jason.decode(content) do
      {:ok, player_input} ->
        handle_input(player_input, tag)
        {:ok, state}

      {:error, e} ->
        [:badjson, tag, content, e] |> inspect |> Logger.info()
        {:reply, {:text, '{"bad":"json"}'}, state}
    end
  end

  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  def websocket_info({:timeout, _ref, _}, state = %{tag: ship_tag}) do
    ship_state = Game.Server.state_of_ship(:game, ship_tag)
    :erlang.start_timer(@ms_between_frames, self(), [])

    case Jason.encode(ship_state) do
      {:ok, message} -> {:reply, {:text, message}, state}
    end
  end

  def websocket_info(_info, state) do
    {:ok, state}
  end
end
