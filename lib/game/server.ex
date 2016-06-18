defmodule Game.Server do

  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The game tells the processes to update themselves,
  and they report their new state to the Game.

  To use, start a Game, and periodically send it tick messages:

      {:ok, game} = Game.Server.start_link()
      Game.Server.tick(game)
      ...
      Game.Server.tick(game)
      ...

  To retrieve the game state, periodically send a message:

      game_state = Game.Server.state(game)

  To start a running Game at 60 fps:

      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)

  To split an asteroid:

      Game.Server.asteroid_hit(:game, 1)

  """

  use GenServer

  alias Asteroid.Server, as: Asteroid
  alias Bullet.Server, as: Bullet
  alias Ship.Server, as: Ship
  alias Game.Identifiers, as: Identifiers
  alias World.Clock, as: Clock
  alias Game.Collision, as: Collision

  @initial_asteroid_count   8
  @initial_ship_count       8

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

  def asteroid_hit(pid, id) do
    GenServer.cast(pid, {:asteroid_hit, id})
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

  def stop_bullet(pid, id) do
    GenServer.cast(pid, {:stop_bullet, id})
  end

  def explosion(pid, x, y) do
    GenServer.cast(pid, {:explosion, x, y})
  end

  def say_player_shot_asteroid(pid, bullet_id) do
    GenServer.cast(pid, {:say_player_shot_asteroid, bullet_id})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(_i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.start_link(id)
      Map.put(rocks, id, pid)
    end)
  end

  @doc """
  Generate n new ships and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_ships(ids, n) do
    Enum.reduce(1..n, %{}, fn(_i, ships) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Ship.start_link(id)
      Map.put(ships, id, pid)
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
              :explosions => [],
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
    if (Map.has_key?(game.pids.asteroids, id)) do 
      new_game = put_in(game.state.asteroids[id], asteroid_state)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
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

  """
  def handle_cast({:ship_fires_bullet, ship_id}, game) do
    ship_pid = game.pids.ships[ship_id]
    if ((ship_pid != nil) && Process.alive?(ship_pid)) do
      case Ship.nose_tag(game.pids.ships[ship_id]) do
        {ship_pos, theta, tag} -> fire_bullet_in_game(game, ship_pos, theta, tag)
        _ -> {:noreply, game}
      end
    end
  end

  def handle_cast({:update_bullet, b}, game) do
    id = elem(b, 0)
    if (Map.has_key?(game.pids.bullets, id)) do
      new_game = put_in(game.state.bullets[id], b)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  def handle_cast({:stop_bullet, id}, game) do
    pid = game.pids.bullets[id]
    if pid != nil do
      Bullet.stop(pid)
    end
    new_game = update_in(game.state.bullets, &Map.delete(&1, id))
    new_game2 = update_in(new_game.pids.bullets, &Map.delete(&1, id))
    {:noreply, new_game2}
  end

  @doc """
      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)
      Game.Server.asteroid_hit(game, 1)

  If the game is identified by the atom :game then:

      Game.Server.asteroid_hit(:game, 1)
  """
  def handle_cast({:asteroid_hit, id}, game) do
    pid = game.pids.asteroids[id]
    if pid != nil do
      fragments = Asteroid.split(pid)
      Asteroid.stop(pid)
      new_game = Enum.reduce(fragments, game, fn(f, game) ->
       new_asteroid_in_game(f, game) end)
      new_game2 = update_in(new_game.state.asteroids, &Map.delete(&1, id))
      new_game3 = update_in(new_game2.pids.asteroids, &Map.delete(&1, id))
      {:noreply, new_game3}
    else
      {:noreply, game}
    end
  end

  @doc """
      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)
      Game.Server.say_player_shot_asteroid(game, 55)
  """
  def handle_cast({:say_player_shot_asteroid, bullet_id}, game) do
    bullet_pid = game.pids.bullets[bullet_id]
    if bullet_pid != nil do
      Bullet.hit_asteroid(bullet_pid)
    end
    {:noreply, game}
  end

  def handle_cast({:explosion, x, y}, game) do
    new_game = update_in(game.explosions, &[{x,y} | &1])
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
    check_for_collisions(game)

    new_game = game
    |> maybe_spawn_asteroid
    |> update_game_clock

    {:reply, {:elapsed_ms, elapsed_ms}, new_game}
  end

  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions,
      :a => game.state.asteroids |> map_of_tuples_to_list,
      :s => game.state.ships |> map_of_tuples_to_list |> map_rest,
      :x => game.explosions |> list_of_tuples_to_list,
      :b => game.state.bullets |> map_of_tuples_to_list
    }
    {:reply, game_state, %{game | :explosions => []}}
  end  

  @doc """
  Convert a list of tuples into a list of lists
  """
  def list_of_tuples_to_list(m) do
    m 
    |> Enum.map(fn(t) -> Tuple.to_list(t) end)
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
    |> Enum.map(fn([_h|t]) -> t end)
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
      fn(b) -> Bullet.move(b, elapsed_ms, self()) end)
  end

  # Collisions

  defp check_for_collisions(game) do
    all_asteroids = Map.values(game.state.asteroids)
    all_bullets   = Map.values(game.state.bullets)
    all_ships     = Map.values(game.state.ships)

    bullet_ships = Collision.detect_bullets_hitting_ships(all_bullets, all_ships)
    handle_bullets_hitting_ships(game, bullet_ships)

    bullet_asteroids = Collision.detect_bullets_hitting_asteroids(all_bullets, all_asteroids)
    handle_bullets_hitting_asteroids(game, bullet_asteroids)

    dud_bullets = Enum.uniq(Collision.unique_bullets(bullet_ships) 
              ++ Collision.unique_bullets(bullet_asteroids))
    stop_bullets(dud_bullets)
  end

  defp handle_bullets_hitting_ships(game, bullet_ships) do
    bullet_ships
    |> Collision.unique_bullets
    |> Enum.map(fn(b) -> 
      {_, x, y} = game.state.bullets[b]
      Game.Server.explosion(self(), x, y)
    end)
  end

  defp handle_bullets_hitting_asteroids(game, bullet_asteroids) do
    bullet_asteroids
    |> Collision.unique_targets
    |> Enum.map(fn(a) -> 
      {_, x, y, _r} = game.state.asteroids[a]
      Game.Server.explosion(self(), x, y)
      Game.Server.asteroid_hit(self(), a)
    end)
  end

  defp stop_bullets(bullets) do
    Enum.map(bullets, fn(b) -> 
      Game.Server.stop_bullet(self(), b) end)
  end


  # Asteroids

  defp new_asteroid_in_game(a, game) do
    id = Identifiers.next(game.ids)
    {:ok, pid} = Asteroid.start_link(id, a)
    put_in(game.pids.asteroids[id], pid)
  end

  # Game state

  defp update_game_clock(game) do
    Map.put(game, :clock_ms, Clock.now_ms)
  end

  defp maybe_spawn_asteroid(game) do
    if not_enough_asteroids(game.pids.asteroids) do
      new_asteroid_in_game(Asteroid.random_asteroid, game)
    else
      game
    end
  end

  defp not_enough_asteroids(asteroids) do
    length(Map.keys(asteroids)) < @initial_asteroid_count
  end


  # Development

  defp fire_bullets(game) do
    trigger = rem(World.Clock.now_ms, 200)
    Enum.each(Map.keys(game.pids.ships), 
      fn(ship_id) -> 
        if (ship_id == trigger) do 
          Game.Server.ship_fires_bullet(self(), ship_id) 
        end; 
      end)
  end

  defp fire_bullet_in_game(game, ship_pos, theta, shooter) do
    id = Identifiers.next(game.ids)
    {:ok, b} = Bullet.start_link(id, ship_pos, theta, shooter)
    new_game = put_in(game.pids.bullets[id], b)
    {:noreply, new_game}
  end

end
