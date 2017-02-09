defmodule Game.Server do

  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The processes update themselves and they report their new state to the Game.

  Players are identified by a name (AAA..ZZZ) and control a Ship process.

  To use, start a Game, and periodically send it tick messages:

      {:ok, game} = Game.Server.start_link()
      Game.Server.tick(game)
      ...
      Game.Server.tick(game)
      ...

  To retrieve the game state, periodically send a message:

      game_state = Game.Server.state(game)

  To start a running Game at 20 fps with a player:

      {:ok, game} = Game.Server.start_link(20)
      Game.Server.show(game)
      Game.Server.spawn_player(game, Elixoids.Player.random_tag)

  To split an asteroid:

      Game.Server.asteroid_hit(:game, 1)

  To hyperspace a ship:

      Game.Server.hyperspace_ship(game, 10)

  """

  use GenServer

  alias Asteroid.Server, as: Asteroid
  alias Bullet.Server, as: Bullet
  alias Ship.Server, as: Ship
  alias Game.Identifiers, as: Identifiers
  alias World.Clock, as: Clock
  alias Game.Collision, as: Collision
  alias Game.Explosion, as: Explosion

  @initial_asteroid_count   4

  def start_link(fps \\ 0, 
                 asteroid_count \\ @initial_asteroid_count) do
    case Process.whereis(:news) do
      nil -> 
        {:ok, e} = Game.Events.start_link
        Process.register(e, :news)
      _ -> true
    end
    GenServer.start_link(__MODULE__, {:ok, fps, asteroid_count}, [])
  end

  def show(pid) do
    GenServer.cast(pid, :show)
  end

  @doc """
  Retrieve the game state as a Map.
  """
  def state(pid) do
    GenServer.call(pid, :state)
  end  

  def sound_state(pid) do
    GenServer.call(pid, :sound_state)
  end

  def state_of_ship(pid, ship_tag) do
    GenServer.call(pid, {:state_of_ship, ship_tag})
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

  def bullet_fired(pid, bullet_id, bullet_pid) do
    GenServer.cast(pid, {:bullet_fired, bullet_id, bullet_pid})
  end

  def update_bullet(pid, new_state) do
    GenServer.cast(pid, {:update_bullet, new_state})
  end

  def bullet_missed(pid, {id, shooter}) do
    GenServer.cast(pid, {:bullet_missed, id, shooter})
  end

  def stop_bullet(pid, id) do
    GenServer.cast(pid, {:stop_bullet, id})
  end

  def explosion(pid, x, y) do
    GenServer.cast(pid, {:explosion, x, y})
  end

  def detonate_asteroid(pid, id) do
    GenServer.cast(pid, {:detonate_asteroid, id})
  end

  def detonate_ship(pid, id) do
    GenServer.cast(pid, {:detonate_ship, id})
  end

  def say_player_shot_asteroid(pid, bullet_id) do
    GenServer.cast(pid, {:say_player_shot_asteroid, bullet_id})
  end

  def say_player_shot_ship(pid, bullet_id, victim_id) do
    GenServer.cast(pid, {:say_player_shot_ship, bullet_id, victim_id})
  end

  def player_shot_player(pid, bullet_id, shooter_tag, victim_tag) do
    GenServer.cast(pid, {:player_shot_player, bullet_id, shooter_tag, victim_tag})
  end

  def hyperspace_ship(pid, ship_id) do
    GenServer.cast(pid, {:hyperspace_ship, ship_id})
  end

  def ships_collide(pid, ship1_id, ship2_id) do
    GenServer.cast(pid, {:ships_collide, ship1_id, ship2_id})
  end

  def say_ship_hit_by_asteroid(pid, ship_id) do
    GenServer.cast(pid, {:say_ship_hit_by_asteroid, ship_id})
  end

  def asteroid_hit_ship(pid, asteroid_id, ship_id) do
    GenServer.cast(pid, {:asteroid_hit_ship, asteroid_id, ship_id})
  end

  def broadcast(pid, id, msg) do
    GenServer.cast(pid, {:broadcast, id, msg})
  end

  @doc """
  Spawn a player with a random tag:
      Game.Server.spawn_player(:game, Elixoids.Player.random_tag)
  """

  def spawn_player(pid, player_tag) do
    GenServer.cast(pid, {:spawn_player, player_tag})
  end

  def player_new_heading(pid, player_tag, theta) do
    GenServer.cast(pid, {:player_new_heading, player_tag, theta})
  end

  def player_pulls_trigger(pid, player_tag) do
    GenServer.cast(pid, {:player_pulls_trigger, player_tag})
  end

  def remove_player(pid, player_tag) do
    GenServer.cast(pid, {:remove_player, player_tag})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(_i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.start_link(id, self())
      Map.put(rocks, id, pid)
    end)
  end

  ## Server Callbacks

  def init({:ok, fps, asteroid_count}) do
    Process.flag(:trap_exit, true)
    Process.flag(:priority, :high)
    game_state = initial_game_state(fps, asteroid_count)
    if fps > 0 do Process.send(self(), :tick, []) end
    {:ok, game_state}
  end

  defp initial_game_state(fps, asteroid_count) do
    {:ok, ids} = Identifiers.start_link
    {:ok, collision_pid} = Game.Collision.start_link(self(), Elixoids.Space.dimensions)
    %{
        :ids => ids, 
        :pids =>  %{:asteroids => generate_asteroids(ids, asteroid_count),
                    :bullets => %{}, 
                    :ships => %{}},
        :state => %{:asteroids => %{},
                    :bullets => %{},
                    :ships => %{}},
        :players => %{},
        :explosions => [],
        :collision_pid => collision_pid,
        :min_asteroid_count => asteroid_count,
        :tick_ms => Clock.ms_between_frames(fps),
        :kby => %{}
      }
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
    if Map.has_key?(game.pids.asteroids,id) do 
      new_game = put_in(game.state.asteroids[id], asteroid_state)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  @doc """
  Update game state with ship state.
  """
  def handle_cast({:update_ship, ship_state}, game) do
    {id,_,_ ,_ ,_ ,_ ,_} = ship_state
    if Map.has_key?(game.pids.ships,id) do
      new_game = put_in(game.state.ships[id], ship_state)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  @doc """
  Put the bullet into the game.
  """
  def handle_cast({:bullet_fired, bullet_id, bullet_pid}, game) do
    {:noreply, put_in(game.pids.bullets[bullet_id], bullet_pid)}
  end

  @doc """
  Update the game state with the position of a bullet.
  The bullet broadcasts its state at a given fps.
  """
  def handle_cast({:update_bullet, b}, game) do
    {id, _, _} = b
    if Map.has_key?(game.pids.bullets, id) do
      new_game = put_in(game.state.bullets[id], b)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  @doc """
  Remove bullet from Game.
  """
  def handle_cast({:bullet_missed, id, shooter}, game) do
    broadcast(self(), id, [shooter, "misses"])
    {:noreply, remove_bullet_from_game(game, id)}
  end

  def handle_cast({:stop_bullet, id}, game) do
    pid = game.pids.bullets[id]
    if pid != nil do
      Bullet.stop(pid)
    end
    {:noreply, remove_bullet_from_game(game, id)}
  end

  @doc """
      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)
      Game.Server.asteroid_hit(game, 1)

  If the game is identified by the atom :game then:

      Game.Server.asteroid_hit(:game, 1)
  """
  def handle_cast({:asteroid_hit, id}, game) do
    case game.pids.asteroids[id] do
      nil -> {:noreply, game}
      pid -> detonate_asteroid(self(), id)
             fragments = Asteroid.split(pid)
             new_game = Enum.reduce(fragments, game, fn(f, game) -> new_asteroid_in_game(f, game, self()) end)
             Asteroid.stop(pid)
             {:noreply, remove_asteroid_from_game(new_game, id)}
    end
  end

  def handle_cast({:detonate_asteroid, id}, game) do
    case game.state.asteroids[id] do
      nil -> false
      {_, x, y, _} -> explosion(self(), x, y)
    end
    {:noreply, game}
  end

  def handle_cast({:detonate_ship, id}, game) do
    case game.state.ships[id] do
      nil -> false
      {_, _, x, y, _, _, _} -> explosion(self(), x, y)
    end
    {:noreply, game}
  end


  @doc """
      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)
      Game.Server.say_player_shot_asteroid(game, 55)
  """
  def handle_cast({:say_player_shot_asteroid, bullet_id}, game) do
    case game.pids.bullets[bullet_id] do
      nil -> nil
      bullet_pid -> Bullet.hit_asteroid(bullet_pid)
    end
    {:noreply, game}
  end

  def handle_cast({:say_player_shot_ship, bullet_id, victim_id}, game) do
    bullet_pid = game.pids.bullets[bullet_id]
    victim = game.state.ships[victim_id]
    if (bullet_pid != nil) && (victim != nil) do
      victim_tag = elem(victim, 1)
      Bullet.hit_ship(bullet_pid, victim_tag, self())
    end
    {:noreply, game}
  end

  def handle_cast({:player_shot_player, bullet_id, shooter_tag, victim_tag}, game) do
    broadcast(self(), bullet_id, [shooter_tag, "kills", victim_tag])
    {:noreply, put_in(game.kby[victim_tag], shooter_tag)}
  end

  def handle_cast({:hyperspace_ship, ship_id}, game) do
    GenServer.cast(self(), :ships_moved)
    case game.pids.ships[ship_id] do
      nil -> {:noreply, game}
      pid -> Ship.hyperspace(pid)
             {:noreply, game} 
    end
  end


  @doc """
  When two ships collide hyperspace the newest ship.
  """
  def handle_cast({:ships_collide, ship1_id, ship2_id}, game) do
    broadcast(self(), ship2_id, ["COLLISION!"])
    hyperspace_ship(self(), max(ship1_id, ship2_id))
    {:noreply, game}
  end

  def handle_cast({:say_ship_hit_by_asteroid, ship_id}, game) do
    case game.state.ships[ship_id] do
      nil -> {:noreply, game}
      {_ship_id, tag, x, y, _, _, _,} ->
        broadcast(self(), ship_id, ["ASTEROID", "hit", tag])
        Game.Server.explosion(self(), x, y)
        {:noreply, game}
    end
  end

  def handle_cast({:asteroid_hit_ship, asteroid_id, ship_id}, game) do
    hyperspace_ship(self(), ship_id)
    asteroid_hit(self(), asteroid_id)    
    say_ship_hit_by_asteroid(self(), ship_id)
    {:noreply, game}
  end

  def handle_cast({:broadcast, id, msg}, game) do
    txt = Enum.join([id] ++ msg, " ")
    Game.Events.broadcast(:news, txt)
    {:noreply, game}
  end

  @doc """
  Append an Explosion to the game state at given co-ordinates.
  """
  def handle_cast({:explosion, x, y}, game) do
    e = Explosion.at_xy(x, y)
    next_game_state = update_in(game.explosions, &[e | &1])
    {:noreply, next_game_state}
  end

  @doc """
  Spawn a new ship controlled by player with given tag
  (unless that ship already exists)
  """
  def handle_cast({:spawn_player, player_tag}, game) do
    if ship_id_of_player(game, player_tag) == nil do
      id = Identifiers.next(game.ids)
      {:ok, ship_pid} = Ship.start_link(id, self(), player_tag)

      new_game = game
      |> put_ship_pid(id, ship_pid)
      |> put_player_tag_ship(player_tag, id)

      GenServer.cast(self(), :ships_moved)

      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  def handle_cast({:player_new_heading, player_tag, theta}, game) do
    ship_id = ship_id_of_player(game, player_tag)
    if ship_id != nil && World.Velocity.valid_theta(theta) do
      case Map.get(game.pids.ships, ship_id) do
        nil -> nil
        pid -> Ship.new_heading(pid, theta)  
      end           
    end
    {:noreply, game}
  end

  def handle_cast({:player_pulls_trigger, player_tag}, game) do
    case ship_pid_of_player(game, player_tag) do
      nil -> nil
      pid -> Ship.player_pulls_trigger(pid, game.ids)
    end
    {:noreply, game}
  end

  @doc """
  Stop the ship process and remove it from the game state.
  """
  def handle_cast({:remove_player, player_tag}, game) do
    case ship_pid_of_player(game, player_tag) do
      nil -> nil
      pid -> Ship.stop(pid)
    end
    GenServer.cast(self(), :ships_moved)
    case ship_id_of_player(game, player_tag) do
      nil -> {:noreply, game}
      id  -> {:noreply, remove_ship_from_game(game, id)}
    end
  end

  @doc """
  Update the game state and check for collisions.
  """
  def handle_cast(:next_frame, game) do

    Collision.collision_tests(game.collision_pid, game) 

    next_game_state = game
    |> maybe_spawn_asteroid(self())
    |> filter_explosions

    {:noreply, next_game_state}
  end

  @doc """
  Any time ships are added, moved or destroyed,
  send their postitions to the collission process.
  """
  def handle_cast(:ships_moved, game) do
    ships = game.state.ships
    |> Map.values
    |> Enum.map(fn {id, _, x, y, r, _, _} -> {:ship, id, x, y, r} end)
    Collision.ships(game.collision_pid, ships, Elixoids.Space.dimensions)
    {:noreply, game}
  end

  # Information

  def handle_info(:tick, state) do
    GenServer.cast(self(), :next_frame)
    Process.send_after(self(), :tick, state.tick_ms)
    {:noreply, state}
  end

  @doc """
  Echo any unsual messages to the console. 
  Ignore processes that stop normally.
  """
  def handle_info(msg, state) do
    case msg do
      {:EXIT, _pid, :normal} -> nil
      _ -> IO.puts(inspect(msg))
    end
    {:noreply, state}
  end

  @doc """
  Return the current state of the game to the UI websocket.
  """
  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions,
      :a => game.state.asteroids |> map_of_tuples_to_list,
      :s => game.state.ships |> map_of_tuples_to_list |> map_rest,
      :x => game.explosions |> explosions_to_list,
      :b => game.state.bullets |> map_of_tuples_to_list,
      :kby => game.kby
    }
    {:reply, game_state, game}
  end  

  def handle_call(:sound_state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions,
      :x => game.explosions    |> explosions_to_list,
      :b => game.state.bullets |> map_of_tuples_to_list
    }
    {:reply, game_state, game}    
  end

  def handle_call({:state_of_ship, ship_tag}, _from, game) do
    ship = only_ship(game.state.ships, ship_tag)
    if ship != nil do
      {_, ship_tag, x, y, _, theta, _} = ship
      ship_state = %{
        :status => 200,
        :tag => ship_tag,
        :theta => theta,
        :ships => ships_relative(game.state.ships, ship_tag, x, y),
        :rocks => asteroids_relative(game.state.asteroids, x, y)
      }
      if Map.has_key?(game.kby, ship_tag) do
        {:reply, Map.put(ship_state, :kby, game.kby[ship_tag]) , game}
      else
        {:reply, ship_state, game}
      end
    else
      {:reply, %{:status => 404}, game}
    end
  end

  @doc """
  Convert a list of tuples into a list of lists

  TODO move out of this class
  """
  def list_of_tuples_to_list(m) do
    Enum.map(m, fn(t) -> Tuple.to_list(t) end)
  end

  @doc """
  Convert a map of tuples into a list of lists

  TODO move out of this class
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
    Enum.map(m, fn([_h|t]) -> t end)
  end

  # Asteroids

  def new_asteroid_in_game(a, game, game_pid) do
    id = Identifiers.next(game.ids)
    {:ok, pid} = Asteroid.start_link(id, game_pid, a)
    put_in(game.pids.asteroids[id], pid)
  end

  defp maybe_spawn_asteroid(game, game_pid) do
    active_asteroid_count = length(Map.keys(game.pids.asteroids))
    if active_asteroid_count < game.min_asteroid_count do
      new_asteroid_in_game(Asteroid.random_asteroid, game, game_pid)
    else
      game
    end
  end

  # Game state

  def filter_explosions(game) do
    update_in(game.explosions, &Explosion.filter_expired_explosions(&1))
  end

  # Ships

  def ship_state_has_tag(ship, expected_tag) do
    {_, tag, _, _, _, _, _} = ship
    tag == expected_tag
    # case ship do
    #   {_, expected_tag, _, _, _, _, _} -> true
    #   _ -> false
    # end 
  end

  def only_ship(ships, tag) do
    # TO DO must be better way to get head of list or nil
    candidates = ships
    |> Map.values
    |> Enum.filter(fn(s) -> ship_state_has_tag(s, tag) end) 
    case candidates do
      [] -> nil
      [s] -> s
      [s,_] -> s
    end
  end

  def ships_except(ships, tag) do
    ships
    |> Map.values
    |> Enum.reject(fn(s) -> ship_state_has_tag(s, tag) end) 
  end

  def ship_relative(ship, ox, oy) do
    {_, tag, sx, sy, _, _, _} = ship

    d = World.Point.distance(ox, oy, sx, sy)

    theta = :math.atan2(sy - oy, sx - ox)

    theta
    |> World.Velocity.wrap_angle()
    |> World.Velocity.round_theta()

    [tag, theta, World.Point.round(d)]
  end

  @doc """
      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)
      Game.Server.spawn_player(game, "OUR")
      Game.Server.state_of_ship(game, "OUR")
  """
  def ships_relative(ships, ship_tag, ship_x, ship_y) do
    ships
    |> ships_except(ship_tag)
    |> Enum.map(fn(s) -> ship_relative(s, ship_x, ship_y) end)
    |> Enum.filter(fn(s) -> Bullet.in_range?(List.last(s)) end)
  end

  def asteroid_relative(asteroid, ox, oy) do
    {id, ax, ay, r} = asteroid

    d = World.Point.distance(ox, oy, ax, ay)

    theta = :math.atan2(ay - oy, ax - ox)

    theta
    |> World.Velocity.wrap_angle()
    |> World.Velocity.round_theta()

    [id, theta, r, World.Point.round(d)]
  end

  @doc """
      {:ok, game} = Game.Server.start_link(60, 4, 4)
      Game.Server.show(game)
      Game.Server.spawn_player(game, "OUR")
      Game.Server.state_of_ship(game, "OUR")
  """
  def asteroids_relative(rocks, ship_x, ship_y) do
    rocks
    |> Map.values
    |> Enum.map(fn(a) -> asteroid_relative(a, ship_x, ship_y) end)
    |> Enum.filter(fn(s) -> Bullet.in_range?(List.last(s)) end)
  end

  @doc """
  Convert our game state containing a list of explosion structs,
  to a list of lists
  """
  def explosions_to_list(explosions) do
    Enum.map(explosions, &Explosion.to_state(&1))
  end

  # Game state

  defp remove_bullet_from_game(game, id) do
    game2 = update_in(game.pids.bullets, &Map.delete(&1, id))
    update_in(game2.state.bullets,       &Map.delete(&1, id))
  end

  defp remove_asteroid_from_game(game, id) do
    game2 = update_in(game.pids.asteroids, &Map.delete(&1, id))
    update_in(game2.state.asteroids,       &Map.delete(&1, id))
  end

  defp remove_ship_from_game(game, id) do
    game2 = update_in(game.pids.ships, &Map.delete(&1, id))
    update_in(game2.state.ships,       &Map.delete(&1, id))
  end

  # Update game pids with new new ship
  defp put_ship_pid(game, id, pid) do
    put_in(game.pids.ships[id], pid)
  end

  # Update player tag to ship id mapping
  defp put_player_tag_ship(game, player_tag, id) do
    put_in(game.players[player_tag], id)
  end

  @doc """
  Return the id of the Ship contolled by Player with given tag, or nil.
  """
  def ship_id_of_player(game, tag) do
    get_in(game, [:players, tag])
  end

  @doc """
  Get the PID of the Ship controlled by the Player with given tag,
  or nil.
  """
  def ship_pid_of_player(game, tag) do
    case ship_id_of_player(game, tag) do
      nil -> nil
      id  -> get_in(game, [:pids, :ships, id])
    end
  end

end
