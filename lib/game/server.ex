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

  To start a running Game at 60 fps with 4 random ships:

      {:ok, game} = Game.Server.start_link(60)
      Game.Server.show(game)

  To split an asteroid:

      Game.Server.asteroid_hit(:game, 1)

  To hyperspace a ship:

      Game.Server.hyperspace_ship(game, 10)

  """

  use GenServer

  alias Asteroid.Server, as: Asteroid
  alias Bullet.Server, as: Bullet
  alias Elixoids.Api.SoundEvent
  alias Elixoids.Game.Info
  alias Game.Collision
  alias Ship.Server, as: Ship
  alias World.Clock
  alias World.Velocity
  import Game.Identifiers

  def start_link(args = [game_id: game_id, fps: _, asteroids: _]) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: via(game_id))
  end

  defp via(game_id) when is_integer(game_id),
    do: {:via, Registry, {Registry.Elixoids.Games, {game_id}}}

  def show(pid) do
    GenServer.cast(pid, :show)
  end

  @doc """
  Retrieve the game state as a Map.
  """
  def state(pid) do
    GenServer.call(pid, :state)
  end

  def state_of_ship(game_id, ship_tag) do
    GenServer.call(via(game_id), {:state_of_ship, ship_tag})
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

  def update_bullet(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_bullet, new_state})
  end

  def bullet_missed(game_id, {id, shooter}) do
    GenServer.cast(via(game_id), {:bullet_missed, id, shooter})
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

  def say_player_shot_ship(pid, bullet_id, victim_id) do
    GenServer.cast(pid, {:say_player_shot_ship, bullet_id, victim_id})
  end

  def player_shot_player(game_id, bullet_id, shooter_tag, victim_tag) do
    GenServer.cast(via(game_id), {:player_shot_player, bullet_id, shooter_tag, victim_tag})
  end

  def hyperspace_ship(pid, ship_id) do
    GenServer.cast(pid, {:hyperspace_ship, ship_id})
  end

  def say_ship_hit_by_asteroid(pid, ship_id) do
    GenServer.cast(pid, {:say_ship_hit_by_asteroid, ship_id})
  end

  def broadcast(pid, id, msg) do
    GenServer.cast(pid, {:broadcast, id, msg})
  end

  def spawn_player(pid, player_tag) do
    GenServer.cast(pid, {:spawn_player, player_tag})
  end

  def player_new_heading(game_id, player_tag, theta) do
    GenServer.cast(via(game_id), {:player_new_heading, player_tag, theta})
  end

  def player_pulls_trigger(game_id, player_tag) do
    GenServer.cast(via(game_id), {:player_pulls_trigger, player_tag})
  end

  def remove_player(game_id, player_tag) do
    GenServer.cast(via(game_id), {:remove_player, player_tag})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_asteroids(n) do
    Enum.reduce(1..n, %{}, fn _i, rocks ->
      id = next_id()
      {:ok, pid} = Asteroid.start_link(id, self())
      Map.put(rocks, id, pid)
    end)
  end

  ## Server Callbacks

  def init(game_id: game_id, fps: fps, asteroids: asteroid_count) do
    game_state = initial_game_state(fps, asteroid_count, game_id)

    # TODO remove warning
    if fps > 0 do
      Process.send(self(), :tick, [])
    end

    if game_id == 0 do
      Process.register(self(), :game)
      # TODO remove hardcoded process name
    end

    Process.flag(:trap_exit, true)

    {:ok, game_state}
  end

  defp initial_game_state(fps, asteroid_count, game_id) do
    {:ok, collision_pid} = Collision.start_link(self())

    %{
      :game_id => game_id,
      :info => info(self(), game_id),
      :pids => %{:asteroids => generate_asteroids(asteroid_count), :bullets => %{}, :ships => %{}},
      :state => %{:asteroids => %{}, :bullets => %{}, :ships => %{}},
      :players => %{},
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
    |> IO.puts()

    {:noreply, game}
  end

  def handle_cast({:update_asteroid, asteroid_state}, game) do
    id = elem(asteroid_state, 0)

    if Map.has_key?(game.pids.asteroids, id) do
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
    {id, _, _, _, _, _, _} = ship_state

    if Map.has_key?(game.pids.ships, id) do
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
  TODO this can be achieved with trapped process exit?
  TODO remove shooter
  """
  def handle_cast({:bullet_missed, id, _shooter}, game) do
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
    pid = game.pids.asteroids[id]

    if pid != nil do
      fragments = Asteroid.split(pid)

      new_game =
        Enum.reduce(fragments, game, fn f, game -> new_asteroid_in_game(f, game, self()) end)

      Asteroid.stop(pid)

      {:noreply, remove_asteroid_from_game(new_game, id)}
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
    case game.pids.bullets[bullet_id] do
      nil -> nil
      bullet_pid -> Bullet.hit_asteroid(bullet_pid)
    end

    {:noreply, game}
  end

  def handle_cast({:say_player_shot_ship, bullet_id, victim_id}, game) do
    bullet_pid = game.pids.bullets[bullet_id]
    victim = game.state.ships[victim_id]

    if bullet_pid != nil && victim != nil do
      victim_tag = elem(victim, 1)
      Bullet.hit_ship(bullet_pid, victim_tag, game.game_id)
    end

    {:noreply, game}
  end

  def handle_cast({:player_shot_player, bullet_id, shooter_tag, victim_tag}, game) do
    broadcast(self(), bullet_id, [shooter_tag, "kills", victim_tag])
    {:noreply, put_in(game.kby[victim_tag], shooter_tag)}
  end

  def handle_cast({:hyperspace_ship, ship_id}, game) do
    case game.pids.ships[ship_id] do
      nil ->
        {:noreply, game}

      pid ->
        Ship.hyperspace(pid)
        {:noreply, game}
    end
  end

  def handle_cast({:say_ship_hit_by_asteroid, ship_id}, game) do
    case game.state.ships[ship_id] do
      nil ->
        {:noreply, game}

      {_ship_id, tag, x, y, _, _, _} ->
        broadcast(self(), ship_id, ["ASTEROID", "hit", tag])
        Game.Server.explosion(self(), x, y)
        {:noreply, game}
    end
  end

  def handle_cast({:broadcast, id, msg}, game) do
    txt = Enum.join([id] ++ msg, " ")
    Elixoids.News.publish_news(0, txt)
    {:noreply, game}
  end

  @doc """
  Append an Explosion to the game state at given co-ordinates.
  """
  def handle_cast({:explosion, x, y}, state) do
    # TODO pan
    # TODO not game 0
    pan = Elixoids.Space.frac_x(x)
    Elixoids.News.publish_audio(0, SoundEvent.explosion(pan, state.info.time.()))
    # TODO not game 0
    Elixoids.News.publish_explosion(0, [x, y])
    {:noreply, state}
  end

  @doc """
  Spawn a new ship controlled by player with given tag
  (unless that ship already exists)
  """
  def handle_cast({:spawn_player, player_tag}, game) do
    if ship_id_of_player(game, player_tag) == nil do
      id = next_id()
      {:ok, ship_pid} = Ship.start_link(id, game.info, player_tag)

      new_game =
        game
        |> put_ship_pid(id, ship_pid)
        |> put_player_tag_ship(player_tag, id)

      {:noreply, new_game}
    else
      {:noreply, game}
    end
  end

  def handle_cast({:player_new_heading, player_tag, theta}, game) do
    ship_id = ship_id_of_player(game, player_tag)

    if ship_id != nil && Velocity.valid_theta(theta) do
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
      pid -> Ship.player_pulls_trigger(pid)
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

    case ship_id_of_player(game, player_tag) do
      nil -> {:noreply, game}
      id -> {:noreply, remove_ship_from_game(game, id)}
    end
  end

  @doc """
  Update the game state and check for collisions.
  """
  def handle_cast(:next_frame, game) do
    Collision.collision_tests(game.collision_pid, game)

    next_game_state =
      game
      |> maybe_spawn_asteroid(self())

    {:noreply, next_game_state}
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
      :dim => Elixoids.Space.dimensions(),
      :a => game.state.asteroids |> map_of_tuples_to_list,
      :s => game.state.ships |> map_of_tuples_to_list |> map_rest,
      :b => game.state.bullets |> map_of_tuples_to_list,
      :kby => game.kby
    }

    {:reply, game_state, game}
  end

  def handle_call({:state_of_ship, ship_tag}, _from, game) do
    case only_ship(game.state.ships, ship_tag) do
      nil -> {:reply, %{:error => "ship_not_found"}, game}
      ship -> fetch_ship_state(ship, game)
    end
  end

  defp fetch_ship_state({_, ship_tag, x, y, _, theta, _}, game) do
    asteroids = game.state.asteroids |> Map.values()
    ships = game.state.ships |> Map.values() |> ships_except(ship_tag)

    ship_state = %{
      :tag => ship_tag,
      :theta => theta,
      :ships => ships,
      :rocks => asteroids,
      :origin => {x, y}
    }

    if Map.has_key?(game.kby, ship_tag) do
      {:reply, Map.put(ship_state, :kby, game.kby[ship_tag]), game}
    else
      {:reply, ship_state, game}
    end
  end

  def ships_except(ships, tag) do
    ships
    |> Enum.reject(fn s -> ship_state_has_tag(s, tag) end)
  end

  @doc """
  Convert a list of tuples into a list of lists
  """
  def list_of_tuples_to_list(m) do
    Enum.map(m, fn t -> Tuple.to_list(t) end)
  end

  @doc """
  Convert a map of tuples into a list of lists
  """
  def map_of_tuples_to_list(m) do
    m
    |> Map.values()
    |> Enum.map(fn t -> Tuple.to_list(t) end)
  end

  @doc """
  Drop the head of each list in the given list.
  """
  def map_rest(m) do
    Enum.map(m, fn [_h | t] -> t end)
  end

  # Asteroids

  def new_asteroid_in_game(a, game, game_pid) do
    id = next_id()
    {:ok, pid} = Asteroid.start_link(id, game_pid, a)
    put_in(game.pids.asteroids[id], pid)
  end

  defp maybe_spawn_asteroid(game, game_pid) do
    active_asteroid_count = length(Map.keys(game.pids.asteroids))

    if active_asteroid_count < game.min_asteroid_count do
      new_asteroid_in_game(Asteroid.random_asteroid(), game, game_pid)
    else
      game
    end
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
    candidates =
      ships
      |> Map.values()
      |> Enum.filter(fn s -> ship_state_has_tag(s, tag) end)

    case candidates do
      [] -> nil
      [s] -> s
      [s, _] -> s
    end
  end

  # Game state

  defp remove_bullet_from_game(game, id) do
    game2 = update_in(game.pids.bullets, &Map.delete(&1, id))
    update_in(game2.state.bullets, &Map.delete(&1, id))
  end

  defp remove_asteroid_from_game(game, id) do
    game2 = update_in(game.pids.asteroids, &Map.delete(&1, id))
    update_in(game2.state.asteroids, &Map.delete(&1, id))
  end

  defp remove_ship_from_game(game, id) do
    game2 = update_in(game.pids.ships, &Map.delete(&1, id))
    update_in(game2.state.ships, &Map.delete(&1, id))
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
      id -> get_in(game, [:pids, :ships, id])
    end
  end

  # Partial function that returns number of ms since game began
  @spec game_time() :: (() -> integer())
  defp game_time do
    epoch = Clock.now_ms()
    fn -> Clock.now_ms() - epoch end
  end

  # TODO remove pid
  defp info(pid, game_id), do: Info.new(pid, game_id, game_time())
end
