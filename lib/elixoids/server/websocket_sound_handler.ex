defmodule Elixoids.Server.WebsocketSoundHandler do

  @moduledoc """
  Websocket Handler. Queries the game state at 12fps
  and publishes it over the websocket.
  """
 
  # 12 FPS
  @ms_between_frames div(1000, 12)

  @behaviour :cowboy_websocket_handler

  def init({_tcp, _http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @doc """
  Client connects here. State is the set of explosions sent to the client recently.
  """
  def websocket_init(_TransportName, req, _opts) do
    IO.puts "Audio client connected as PID #{inspect(self())}"
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:ok, req, MapSet.new}
  end

  def websocket_terminate(_reason, _req, _state) do
    IO.puts "Audio client disconnected from PID #{inspect(self())}"
    :ok
  end

  def websocket_handle({:text, _content}, req, state) do
    {:reply, {:text, "Ignored"}, req, state}
  end
  
  def websocket_handle(_data, req, state) do    
    {:ok, req, state}
  end

  @doc """
  Perodically query the game state, deduplicate explosions,
  and push to the client.
  """
  def websocket_info({_timeout, _ref, _foo}, req, seen) do
    :erlang.start_timer(@ms_between_frames, self(), [])

    game_state = Game.Server.sound_state(:game)
    {explosions, new_seen} = Channels.DeliverOnce.deduplicate(game_state.x, seen)
    new_game_state = %{game_state | :x => explosions}
    {:ok, message} = Poison.encode(new_game_state)
    
    {:reply, {:text, message}, req, new_seen}
  end

  # fallback message handler 
  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end

end
