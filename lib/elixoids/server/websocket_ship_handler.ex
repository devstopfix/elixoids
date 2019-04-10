defmodule Elixoids.Server.WebsocketShipHandler do
  @moduledoc """
  Websocket Handler. Queries the ship state at 1fps
  and publishes it over the websocket.
  """

  alias Elixoids.Player, as: Player
  alias Elixoids.Server.PlayerInput, as: PlayerInput

  @ms_between_frames 250

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
    IO.puts("Upgrading HTTP connection for player")
    {:cowboy_websocket, req, %{url_tag: tag}}
  end

  # This is the first required callback that's specific to websocket
  # handlers.  Here I'm returning :ok, and no state since we don't
  # plan to track ant state.
  #
  # Useful to know: a new process will be spawned for each connection
  # to the websocket.
  def websocket_init(state = %{url_tag: tag}) do
    IO.puts("Incoming websocket connection...")

    try do
      if Player.valid_player_tag?(tag) do
        Game.Server.spawn_player(:game, tag)
        IO.inspect(welcome: tag)
        :erlang.start_timer(1000, self(), [])
        {:ok, %{tag: tag}}
      else
        IO.inspect(bad_player_tag: tag)
        {:stop, state}
      end
    rescue
      e in RuntimeError ->
        IO.puts(Exception.message(e))
        {:stop, state}
    end
  end

  def websocket_terminate(_reason, _req, tag) do
    Game.Server.remove_player(:game, tag)
    IO.puts(["Farewell", " ", tag])
    :ok
  end

  def player_pulls_trigger(tag) do
    Game.Server.player_pulls_trigger(:game, tag)
    :ok
  end

  def player_turns(tag, theta) do
    Game.Server.player_new_heading(:game, tag, theta)
    :ok
  end

  def handle_input(player_input, tag) do
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
  def websocket_handle(frame = {:text, content}, state) do
    try do
      case Poison.decode(content, as: %PlayerInput{}) do
        {:ok, player_input} -> {handle_input(player_input, state), state}
        {:error, _} -> {:reply, {:text, '{"bad":"json"}'}, state}
      end
    catch
      :exit, _ -> {:reply, {:text, '{"bad":"json!"}'}, state}
    end

    # The reply format here is a 4-tuple starting with :reply followed
    # by the body of the reply, in this case the tuple {:text, reply}
  end

  # Fallback clause for websocket_handle.  If the previous one does not match
  # this one just returns :ok without taking any action.  A proper app should
  # probably intelligently handle unexpected messages.
  def websocket_handle(_data, req, state) do
    {:ok, req, state}
  end

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process.
  def websocket_info({_timeout, _ref, _foo}, req, ship_tag) do
    ship_state = Game.Server.state_of_ship(:game, ship_tag)

    {:ok, message} = Poison.encode(ship_state)

    # set a new timer to send a :timeout message back to this process a second
    # from now.
    :erlang.start_timer(@ms_between_frames, self(), [])

    # send the new message to the client. Note that even though there was no
    # incoming message from the client, we still call the outbound message
    # a 'reply'.  That makes the format for outbound websocket messages
    # exactly the same as websocket_handle()
    {:reply, {:text, message}, req, ship_tag}
  end

  # fallback message handler
  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end
end
