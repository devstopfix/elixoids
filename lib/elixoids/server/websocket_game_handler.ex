defmodule Elixoids.Server.WebsocketGameHandler do
  @moduledoc """
  Websocket Handler. Queries the game state at 24fps
  and publishes it over the websocket.
  """

  import Logger

  # 24 FPS
  @ms_between_frames div(1000, 24)
  @pause_ms 1000

  @behaviour :cowboy_handler

  def init(req, _state) do
    [:http_connection, :game] |> inspect |> Logger.info()
    {:cowboy_websocket, req, %{}}
  end

  # This is the first required callback that's specific to websocket
  # handlers.  Here I'm returning :ok, and no state since we don't
  # plan to track ant state.
  #
  # Useful to know: a new process will be spawned for each connection
  # to the websocket.
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

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process.  In this example, the only erlang
  # messages we are passing are the :timeout messages from the timing loop.
  #
  # In a larger app various clauses of websocket_info might handle all kinds
  # of messages and pass information out the websocket to the client.
  def websocket_info({_timeout, _ref, _}, prev_state) do
    # set a new timer to send a :timeout message back to this process
    :erlang.start_timer(@ms_between_frames, self(), [])

    game_state = Game.Server.state(:game)
    transmit = Game.State.deduplicate(game_state, prev_state)
    {:ok, message} = Poison.encode(transmit)

    {:reply, {:text, message}, game_state}
  end

  # fallback message handler
  def websocket_info(_info, state) do
    {:ok, state}
  end
end
