defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 1fps
  and publishes it over the websocket.
  """

  alias Elixoids.Player, as: Player
  alias Elixoids.Server.PlayerInput, as: PlayerInput
  import Logger

  @ms_between_frames 250
  @pause_ms 1000

  @behaviour :cowboy_handler

  # We are using the websocket handler.  See the documentation here:
  #     http://ninenines.eu/docs/en/cowboy/HEAD/manual/websocket_handler/
  #
  # All cowboy HTTP handlers require an init() function, identifies which
  # type of handler this is and returns an initial state (if the handler
  # maintains state).  In a websocket handler, you return a
  # 3-tuple with :upgrade as shown below.  This is essentially following
  # the specification of websocket, in which a plain HTTP request is made
  # first, which requests an upgrade to the websocket protocol.

  def init(req = %{bindings: %{tag: tag}}, _state) do
    [:http_connection, :ship] |> inspect |> Logger.info()
    {:cowboy_websocket, req, %{url_tag: tag}}
  end

  # This is the first required callback that's specific to websocket
  # handlers.  Here I'm returning :ok, and no state since we don't
  # plan to track ant state.
  #
  # Useful to know: a new process will be spawned for each connection
  # to the websocket.
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
    :ok
  end

  defp player_turns(tag, theta) do
    Game.Server.player_new_heading(:game, tag, theta)
    :ok
  end

  defp handle_input(player_input, tag) do
    cond do
      player_input.fire == true -> player_pulls_trigger(tag)
      is_float(player_input.theta) -> player_turns(tag, player_input.theta)
      is_integer(player_input.theta) -> player_turns(tag, player_input.theta * 1.0)
      true -> :ok
    end
  end

  # websocket_handle deals with messages coming in over the websocket.
  # it should return a 4-tuple starting with either :ok (to do nothing)
  # or :reply (to send a message back).
  def websocket_handle({:text, content}, state) do
    case Poison.decode(content, as: %PlayerInput{}) do
      {:ok, player_input} -> {handle_input(player_input, state), state}
      {:error, _} -> {:reply, {:text, '{"bad":"json"}'}, state}
    end
  rescue
    _ -> {:reply, {:text, '{"bad":"json!"}'}, state}
  end

  # Fallback clause for websocket_handle.  If the previous one does not match
  # this one just returns :ok without taking any action.  A proper app should
  # probably intelligently handle unexpected messages.
  def websocket_handle(_inframe, state) do
    {:ok, state}
  end

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process.
  def websocket_info({:timeout, _ref, _}, state = %{tag: ship_tag}) do
    ship_state = Game.Server.state_of_ship(:game, ship_tag)
    {:ok, message} = Poison.encode(ship_state)
    :erlang.start_timer(@ms_between_frames, self(), [])
    {:reply, {:text, message}, state}
  end

  # fallback message handler
  def websocket_info(_info, state) do
    {:ok, state}
  end
end
