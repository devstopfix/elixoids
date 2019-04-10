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
    {:ok, _pid} = Elixoids.Audio.subscribe(0)
    [:ws_connection, :audio] |> inspect |> Logger.info()
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, MapSet.new()}
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
  def websocket_info({:timeout, _ref, _}, seen) do
    :erlang.start_timer(@ms_between_frames, self(), [])

    case Enum.empty?(state) do
      true -> {:ok, state}
      false -> {:reply, {:text, format(state)}, MapSet.new()
    end

    game_state = Game.Server.sound_state(:game)
    {explosions, new_seen} = Channels.DeliverOnce.deduplicate(game_state.x, seen)
    new_game_state = %{game_state | :x => explosions}
    case  Jason.encode(new_game_state) do
      {:ok, message} -> {:reply, {:text, message}, req, new_seen}
    end
  end

  defp format(state) do

  end

  def websocket_info(_, state) do
    {:ok, state}
  end
end
