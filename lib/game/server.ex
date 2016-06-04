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
  alias Bullet.Server, as: Bullet
  alias Ship.Server, as: Ship
  alias Game.Identifiers, as: Identifiers
  alias World.Clock, as: Clock

  @initial_asteroid_count 8
  @initial_ship_count     6

  def start_link(fps \\ 0) do
    GenServer.start_link(__MODULE__, {:ok, fps}, [])
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

  def update_asteroid(pid, new_state) do
    GenServer.cast(pid, {:update_asteroid, new_state})
  end

  def update_ship(pid, new_state) do
    GenServer.cast(pid, {:update_ship, new_state})
  end

  def ship_fires_bullet(pid, ship_id) do
    GenServer.cast(pid, {:ship_fires_bullet, ship_id})
  end

  def update_bullet(pid, new_state) do
    GenServer.cast(pid, {:update_bullet, new_state})
  end

  def delete_bullet(pid, id) do
    GenServer.cast(pid, {:delete_bullet, id})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.start_link(id)
      Map.put(rocks, i, pid)
    end)
  end

  @doc """
  Generate n new ships and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_ships(ids, n) do
    Enum.reduce(1..n, %{}, fn(i, ships) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Ship.start_link(id)
      Map.put(ships, i, pid)
    end)
  end

  ## Server Callbacks

  def init({:ok, fps}) do
    {:ok, ids} = Identifiers.start_link
    rocks = generate_asteroids(ids, @initial_asteroid_count)
    ships = generate_ships(ids, @initial_ship_count)
    game_state = %{:ids => ids, 
              :pids =>  %{:asteroids => rocks, 
                          :bullets => %{},
                          :ships => ships},
              :state => %{:asteroids => %{},
                          :bullets => %{},
                          :ships => %{}},
              :clock_ms => Clock.now_ms}
    start_ticker(self(), fps)
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

  def handle_cast({:update_ship, ship_state}, game) do
    id = elem(ship_state, 0)
    new_game = put_in(game.state.ships[id], ship_state)
    {:noreply, new_game}
  end


  @doc """
  Ship fires a bullet in the direction it is facing.

      {:ok, game} = Game.Server.start_link(4)
      Game.Server.tick(game)
      Game.Server.show(game)
      Game.Server.ship_fires_bullet(game, 1)
      Game.Server.show(game)
      Game.Server.ship_fires_bullet(game, 2)
      Game.Server.show(game)
      Game.Server.ship_fires_bullet(game, 3)
      Game.Server.show(game)

  """
  def handle_cast({:ship_fires_bullet, ship_id}, game) do
    ship_pid = game.pids.ships[ship_id]
    if (ship_pid != nil) do
      case Ship.nose(game.pids.ships[ship_id]) do
        {ship_pos, theta} -> fire_bullet_in_game(game, ship_pos, theta)
        _ -> {:noreply, game}
      end
    end
  end

  def handle_cast({:update_bullet, b}, game) do
    id = elem(b, 0)
    new_game = put_in(game.state.bullets[id], b)
    {:noreply, new_game}
  end

  def handle_cast({:delete_bullet, id}, game) do
    new_game = update_in(game.state.bullets, &Map.delete(&1, id))
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

    move_asteroids(game, elapsed_ms)
    move_ships(game, elapsed_ms)
    move_bullets(game, elapsed_ms)
    fire_bullets(game)

    {:reply, {:elapsed_ms, elapsed_ms}, Map.put(game, :clock_ms, Clock.now_ms)}
  end

  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions,
      :a => game.state.asteroids |> map_of_tuples_to_list,
      :s => game.state.ships |> map_of_tuples_to_list |> map_rest,
      :x => [],
      :b => game.state.bullets |> map_of_tuples_to_list
    }
    {:reply, game_state, game}
  end  

  @doc """
  Convert a map of tuples into a list of lists
  """
  def map_of_tuples_to_list(m) do
    m 
    |> Map.values
    |> Enum.map(fn(t) -> Tuple.to_list(t) end)
  end

  @doc """
  Drop the head of each list in the given list.
  """
  def map_rest(m) do
    m
    |> Enum.map(fn([_h|t]) -> t end )
  end

  defp start_ticker(pid, fps) do
    if ((fps > 0) && (fps <= 60)) do
      Game.Ticker.start_link(pid, fps)
    end
  end

  defp move_asteroids(game, elapsed_ms) do
    Enum.each(Map.values(game.pids.asteroids), 
      fn(a) -> Asteroid.move(a, elapsed_ms, self()) end)
  end

  defp move_ships(game, elapsed_ms) do
    Enum.each(Map.values(game.pids.ships), 
      fn(s) -> Ship.move(s, elapsed_ms, self()) end)
  end

  defp move_bullets(game, elapsed_ms) do
    Enum.each(Map.values(game.pids.bullets), 
      fn(s) -> Bullet.move(s, elapsed_ms, self()) end)
  end

  defp fire_bullets(game) do
    trigger = rem(World.Clock.now_ms, 100)
    Enum.each(Map.keys(game.pids.ships), 
      fn(ship_id) -> if (ship_id == trigger) do Game.Server.ship_fires_bullet(self(), ship_id) end; end)
  end

  defp fire_bullet_in_game(game, ship_pos, theta) do
    id = Identifiers.next(game.ids)
    {:ok, b} = Bullet.start_link(id, ship_pos, theta)
    new_game = put_in(game.pids.bullets[id], b)
    {:noreply, new_game}
  end

end
