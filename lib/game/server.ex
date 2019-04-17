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
  use Elixoids.Game.Heartbeat

  alias Asteroid.Server, as: Asteroid
  alias Bullet.Server, as: Bullet
  alias Elixoids.Api.SoundEvent
  alias Elixoids.Game.Info
  alias Game.Collision
  alias Ship.Server, as: Ship
  alias World.Clock
  alias World.Velocity
  import Game.Identifiers
  import Logger

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

  def update_asteroid(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_asteroid, new_state})
  end

  def asteroid_hit(pid, id) do
    GenServer.cast(pid, {:asteroid_hit, id})
  end

  def update_ship(pid, new_state) do
    GenServer.cast(pid, {:update_ship, new_state})
  end

  def bullet_fired(game_id, bullet_pid) do
    GenServer.cast(via(game_id), {:bullet_fired, bullet_pid})
  end

  def update_bullet(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_bullet, new_state})
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

  # TODO remove from game
  def hyperspace_ship(pid, ship_id) when is_integer(ship_id) do
    GenServer.cast(pid, {:hyperspace_ship, ship_id})
  end

  def say_ship_hit_by_asteroid(pid, ship_id) do
    GenServer.cast(pid, {:say_ship_hit_by_asteroid, ship_id})
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
  def generate_asteroids(n, game_info) do
    Enum.reduce(1..n, %{}, fn _i, rocks ->
      id = next_id()
      {:ok, pid} = Asteroid.start_link(id, game_info)
      Map.put(rocks, id, pid)
    end)
  end

  ## Server Callbacks

  def init(game_id: game_id, fps: _fps, asteroids: asteroid_count) do
    game_state = initial_game_state(asteroid_count, game_id)

    if game_id == 0 do
      Process.register(self(), :game)
      # TODO remove hardcoded process name
    end

    Process.flag(:trap_exit, true)

    start_heartbeat()

    {:ok, game_state}
  end

  defp initial_game_state(asteroid_count, game_id) do
    {:ok, collision_pid} = Collision.start_link(self())

    info = game_info(self(), game_id)
    asteroids = generate_asteroids(asteroid_count, info)

    %{
      :game_id => game_id,
      :info => info,
      :pids => %{:asteroids => asteroids, :bullets => %{}, :ships => %{}},
      :state => %{:asteroids => %{}, :bullets => %{}, :ships => %{}},
      :players => %{},
      # TODO link with Registry
      :collision_pid => collision_pid,
      :min_asteroid_count => asteroid_count
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
  Put a marker for the spawned bullet into the game
  """
  def handle_cast({:bullet_fired, bullet_pid}, game) do
    Process.link(bullet_pid)
    {:noreply, put_in(game.state.bullets[bullet_pid], :spawn)}
  end

  @doc """
  Update the game state with the position of a bullet.
  The bullet broadcasts its state at a given fps.
  """
  def handle_cast({:update_bullet, b}, game) do
    if Map.has_key?(game.state.bullets, b.pid) do
      new_game = put_in(game.state.bullets[b.pid], b)
      {:noreply, new_game}
    else
      {:noreply, game}
    end
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

      new_game = Enum.reduce(fragments, game, fn f, game -> new_asteroid_in_game(f, game) end)

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
    # TODO change from bullet_id to pid
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
        Elixoids.News.publish_news(game.game_id, ["ASTEROID", "hit", tag])
        Game.Server.explosion(self(), x, y)
        {:noreply, game}
    end
  end

  @doc """
  Append an Explosion to the game state at given co-ordinates.
  """
  def handle_cast({:explosion, x, y}, game) do
    pan = Elixoids.Space.frac_x(x)
    Elixoids.News.publish_audio(game.game_id, SoundEvent.explosion(pan, game.info.time.()))
    Elixoids.News.publish_explosion(game.game_id, [x, y])
    {:noreply, game}
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
  def handle_tick(_pid, _delta_t_ms, game) do
    Collision.collision_tests(game.collision_pid, game)
    next_game_state = maybe_spawn_asteroid(game)
    {:ok, next_game_state}
  end

  @doc """
  Remove processes that exit from the game state
  """
  def handle_info(msg, state) do
    case msg do
      {:EXIT, pid, :normal} ->
        {:noreply, remove_pid_from_game_state(pid, state)}

      {:EXIT, pid, :shutdown} ->
        {:noreply, remove_pid_from_game_state(pid, state)}

      _ ->
        [:EXIT, msg, state] |> inspect |> error()
        {:noreply, state}
    end
  end

  defp remove_pid_from_game_state(pid, game) do
    remove_bullet_from_game(game, pid)
  end

  @doc """
  Return the current state of the game to the UI websocket.
  """
  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions(),
      :a => game.state.asteroids |> map_of_tuples_to_list,
      :s => game.state.ships |> map_of_tuples_to_list |> map_rest,
      :b => game.state.bullets |> map_of_tuples_to_list
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

    {:reply, ship_state, game}
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
    |> Enum.map(fn t -> Elixoids.Api.State.JSON.to_json_list(t) end)
  end

  @doc """
  Drop the head of each list in the given list.
  """
  def map_rest(m) do
    Enum.map(m, fn [_h | t] -> t end)
  end

  # Asteroids

  def new_asteroid_in_game(a, game) do
    id = next_id()
    {:ok, pid} = Asteroid.start_link(id, game.info, a)
    put_in(game.pids.asteroids[id], pid)
  end

  defp maybe_spawn_asteroid(game) do
    active_asteroid_count = length(Map.keys(game.pids.asteroids))

    if active_asteroid_count < game.min_asteroid_count do
      new_asteroid_in_game(Asteroid.random_asteroid(), game)
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

  defp remove_bullet_from_game(game, bullet_pid) do
    case pop_in(game, [:state, :bullets, bullet_pid]) do
      {nil, _} -> game
      {_, new_state} -> new_state
    end
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
  defp game_info(pid, game_id), do: Info.new(pid, game_id, game_time())
end
