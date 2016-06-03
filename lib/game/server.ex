defmodule Game.Server do

  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The game tells the processes to update themselves,
  and they report their new state to the Game.

  To use, start a Game, and periodically send it tick messages:

      {:ok, game} = Game.Server.start_link
      Game.Server.tick(game)
      ...
      Game.Server.tick(game)
      ...

  To retrieve the game state, periodically send a message:

      game_state = Game.Server.state(game)

  The game state is an object containing these properties:

  * `a` - a list of Asteroids

  """

  use GenServer

  alias Asteroid.Server, as: Asteroid
  alias Game.Identifiers, as: Identifiers
  alias World.Clock, as: Clock

  @initial_asteroid_count 16

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

  @doc """
  Retrieve the game state as a Map.
  """
  def state(pid) do
    GenServer.call(pid, :state)
  end  

  def update_asteroid(pid, asteroid_state) do
    GenServer.cast(pid, {:update_asteroid, asteroid_state})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.start_link(id)
      Map.put(rocks, i, pid)
    end)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, ids} = Identifiers.start_link
    rocks = asteroids(ids, @initial_asteroid_count)
    game_state = %{:ids => ids, 
              :pids => %{:asteroids => rocks},
              :state => %{:asteroids => %{}},
              :clock_ms => Clock.now_ms}
    {:ok, game_state}
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

  def handle_cast({:update_asteroid, asteroid_state}, game) do
    id = elem(asteroid_state, 0)
    new_game = put_in(game.state.asteroids[id], asteroid_state)
    {:noreply, new_game}
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
    Enum.each(Map.values(game.pids.asteroids), 
      fn(a) -> Asteroid.move(a, elapsed_ms, self()) end)
    {:reply, {:elapsed_ms, elapsed_ms}, Map.put(game, :clock_ms, Clock.now_ms)}
  end

  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions,
      :a => map_of_tuples_to_list(game.state.asteroids),
      :s => [["AAA", 2000, 1000, 20, 1.0, "FFFFFF"]],
      :x => [],
      :b => []
    }
    {:reply, game_state, game}
  end

  def map_of_tuples_to_list(m) do
    m 
    |> Map.values
    |> Enum.map(fn(t) -> Tuple.to_list(t) end)
  end

end
