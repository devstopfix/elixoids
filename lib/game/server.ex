defmodule Game.Server do

  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The game tells the processes to update themselves,
  and they report their new state to the Game.
  """

  use GenServer

  alias Game.Identifiers, as: Identifiers
  alias World.Clock, as: Clock

  @initial_asteroid_count 5

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def show(pid) do
    GenServer.cast(pid, :show)
  end

  @doc """
  Update the game state. Called by external process running at 
  known FPS (frame-per-second)
  """
  def tick(pid) do
    GenServer.call(pid, :tick)
  end  

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.Server.start_link(id)
      Map.put(rocks, i, {pid})
    end)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, ids} = Identifiers.start_link
    rocks = asteroids(ids, @initial_asteroid_count)
    state = %{:ids => ids, 
              :asteroids => rocks,
              :clock_ms => Clock.now_ms}
    {:ok, state}
  end

  @doc """
  Echo the state of the game to the console.

      {:ok, game} = Game.Server.start_link
      Game.Server.show(game)
  
  """
  def handle_cast(:show, game) do
    game
    |> Kernel.inspect(pretty: true)
    |> IO.puts
    {:noreply, game}
  end

  @doc """
  Update the game state and return the number of ms elpased since last tick.

      {:ok, game} = Game.Server.start_link
      Game.Server.show(game)
      Game.Server.tick(game)
      Game.Server.show(game)
  """
  def handle_call(:tick, _from, game) do
    elapsed_ms = Clock.now_ms - game.clock_ms
    {:reply, {:elapsed_ms, elapsed_ms}, Map.put(game, :clock_ms, Clock.now_ms)}
  end

end
