defmodule Elixoids.Server.WebsocketHandler do

  @moduledoc """
  Websocket Handler. Queries the game state at 24fps
  and publishes it over the websocket.
  """
 
  # 24 FPS
  @ms_between_frames div(1000, 24)

  @behaviour :cowboy_websocket_handler

  # We are using the websocket handler.  See the documentation here:
  #     http://ninenines.eu/docs/en/cowboy/HEAD/manual/websocket_handler/
  #
  # All cowboy HTTP handlers require an init() function, identifies which
  # type of handler this is and returns an initial state (if the handler
  # maintains state).  In a websocket handler, you return a 
  # 3-tuple with :upgrade as shown below.  This is essentially following
  # the specification of websocket, in which a plain HTTP request is made
  # first, which requests an upgrade to the websocket protocol.
  def init({_tcp, _http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  # This is the first required callback that's specific to websocket
  # handlers.  Here I'm returning :ok, and no state since we don't 
  # plan to track ant state.
  #
  # Useful to know: a new process will be spawned for each connection
  # to the websocket.
  def websocket_init(_TransportName, req, _opts) do
    IO.puts "Starting game with PID is #{inspect(self())}"

    # Here I'm starting a standard erlang timer that will send
    # an empty message [] to this process in one second. If your handler
    # can handle more that one kind of message that wouldn't be empty.
    :erlang.start_timer(1000, self(), [])
    {:ok, req, :undefined_state}
  end

  # Required callback.  Put any essential clean-up here.
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  # websocket_handle deals with messages coming in over the websocket.
  # it should return a 4-tuple starting with either :ok (to do nothing)
  # or :reply (to send a message back).  
  def websocket_handle({:text, content}, req, state) do

    # Use JSEX to decode the JSON message and extract the word entered
    # by the user into the variable 'message'.
    {:ok, %{"message" => message}} = JSEX.decode(content)

    # Reverse the message and use JSEX to re-encode a reply contatining
    # the reversed message.
    rev = String.reverse(message)
    {:ok, reply} = JSEX.encode(%{reply: rev})

    #IO.puts("Message: #{message}")
    
    # The reply format here is a 4-tuple starting with :reply followed 
    # by the body of the reply, in this case the tuple {:text, reply} 
    {:reply, {:text, reply}, req, state}
  end
  
  # Fallback clause for websocket_handle.  If the previous one does not match
  # this one just returns :ok without taking any action.  A proper app should
  # probably intelligently handle unexpected messages.
  def websocket_handle(_data, req, state) do    
    {:ok, req, state}
  end

  # websocket_info is the required callback that gets called when erlang/elixir
  # messages are sent to the handler process.  In this example, the only erlang 
  # messages we are passing are the :timeout messages from the timing loop. 
  #
  # In a larger app various clauses of websocket_info might handle all kinds
  # of messages and pass information out the websocket to the client.
  def websocket_info({_timeout, _ref, _foo}, req, state) do

    game_state = Game.Server.state(:game)

    {:ok, message} = JSEX.encode(game_state)

    
    # set a new timer to send a :timeout message back to this process a second
    # from now.
    :erlang.start_timer(@ms_between_frames, self(), [])

    # send the new message to the client. Note that even though there was no
    # incoming message from the client, we still call the outbound message 
    # a 'reply'.  That makes the format for outbound websocket messages 
    # exactly the same as websocket_handle()
    {:reply, {:text, message}, req, state}
  end

  # fallback message handler 
  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end

end
