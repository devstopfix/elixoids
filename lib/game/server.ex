defmodule Game.Server do
  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The processes update themselves and they report their new state to the Game.

  Players are identified by a name (AAA..ZZZ) and control a Ship process.
  """

  use GenServer
  use Elixoids.Game.Heartbeat

  alias Asteroid.Server, as: Asteroid
  alias Bullet.Server, as: Bullet
  alias Elixoids.Api.SoundEvent
  alias Elixoids.Collision.Server, as: CollisionServer
  alias Elixoids.Game.Info
  alias Elixoids.Game.Snapshot
  alias Elixoids.Ship.Targets
  alias Ship.Server, as: Ship
  import Logger

  def start_link(args = [game_id: game_id, asteroids: _]) do
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
  def state(game_id) do
    GenServer.call(via(game_id), :state)
  end

  @spec state_of_ship(integer(), pid()) :: map()
  def state_of_ship(game_id, ship_pid) do
    GenServer.call(via(game_id), {:state_of_ship, ship_pid})
  end

  def update_asteroid(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :asteroids, new_state})
  end

  def spawn_asteroids(game_id, rocks) do
    GenServer.cast(via(game_id), {:spawn_asteroids, rocks})
  end

  def update_ship(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :ships, new_state})
  end

  def bullet_fired(game_id, shooter_tag, pos, theta) do
    GenServer.call(via(game_id), {:bullet_fired, shooter_tag, pos, theta})
  end

  def update_bullet(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :bullets, new_state})
  end

  def explosion(game_id, pos, radius) do
    GenServer.cast(via(game_id), {:explosion, pos, radius})
  end

  @spec spawn_player(integer(), String.t()) :: {:ok, pid(), term()} | {:error, :tag_in_use}
  def spawn_player(game_id, player_tag) do
    GenServer.call(via(game_id), {:spawn_player, player_tag})
  end

  ## Initial state

  @doc """
  Generate n new asteroids and store as a map of their
  identifier to a tuple of their {pid, state}.
  """
  def generate_asteroids(n, game_info) do
    Enum.reduce(1..n, %{}, fn _i, rocks ->
      {:ok, pid} = Asteroid.start_link(game_info)
      Map.put(rocks, pid, :spawn)
    end)
  end

  ## Server Callbacks

  def init(game_id: game_id, asteroids: asteroid_count) do
    game_state = initial_game_state(asteroid_count, game_id)
    Process.flag(:trap_exit, true)
    start_heartbeat()
    {:ok, game_state}
  end

  defp initial_game_state(asteroid_count, game_id) do
    info = game_info(game_id)
    asteroids = generate_asteroids(asteroid_count, info)

    %{
      :game_id => game_id,
      :info => info,
      :state => %{:asteroids => asteroids, :bullets => %{}, :ships => %{}},
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

  def handle_cast({:update_entity, entity, state = %{pid: pid}}, game) do
    {_, new_game} = get_and_update_in(game, [:state, entity, pid], fn old -> {old, state} end)

    {:noreply, new_game}
  end

  def handle_cast({:spawn_asteroids, rocks}, game) do
    new_game = Enum.reduce(rocks, game, fn f, game -> new_asteroid_in_game(f, game) end)
    {:noreply, new_game}
  end

  @doc """
  Append an Explosion to the game state at given co-ordinates.
  """
  def handle_cast({:explosion, %{x: x, y: y}, radius}, game) do
    pan = Elixoids.Space.frac_x(x)
    Elixoids.News.publish_audio(game.game_id, SoundEvent.explosion(pan, radius))
    Elixoids.News.publish_explosion(game.game_id, [x, y])
    {:noreply, game}
  end

  @doc """
  Update the game state and check for collisions.
  """
  def handle_tick(_pid, _delta_t_ms, game = %{game_id: game_id}) do
    snap = snapshot(game)
    CollisionServer.collision_tests(game_id, snap)
    next_game_state = check_next_wave(game)
    {:ok, next_game_state}
  end

  @doc """
  Remove processes that exit from the game state
  """
  def handle_info(msg, state) do
    case msg do
      {:EXIT, pid, :shutdown} ->
        {:noreply, remove_pid_from_game_state(pid, state)}

      {:EXIT, pid, :normal} ->
        {:noreply, remove_pid_from_game_state(pid, state)}

      {:EXIT, pid, msg} ->
        [:EXIT, msg, state] |> inspect |> warn()
        {:noreply, remove_pid_from_game_state(pid, state)}
    end
  end

  def handle_call({:state_of_ship, ship_pid}, _from, game) do
    case game.state.ships[ship_pid] do
      nil -> {:reply, %Targets{}, game}
      ship -> fetch_ship_state(ship, game)
    end
  end

  @doc """
  Put a marker for the spawned bullet into the game
  """
  def handle_call({:bullet_fired, shooter_tag, pos, theta}, _from, game) do
    {:ok, bullet_pid} = Bullet.start_link(game.game_id, shooter_tag, pos, theta)
    {:reply, {:ok, bullet_pid}, put_in(game.state.bullets[bullet_pid], :spawn)}
  end

  @doc """
  Spawn a new ship controlled by player with given tag
  (unless that ship already exists)
  """
  def handle_call({:spawn_player, player_tag}, _from, game) do
    case Ship.start_link(game.info, player_tag) do
      {:ok, ship_pid, ship_id} -> {:reply, {:ok, ship_pid, ship_id}, game}
      e -> {:reply, e, game}
    end
  end

  @doc """
  Return the current state of the game to the UI websocket.
  """
  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions(),
      :a => game.state.asteroids |> filter_active(),
      :s => game.state.ships |> Map.values(),
      :b => game.state.bullets |> filter_active()
    }

    {:reply, game_state, game}
  end

  defp fetch_ship_state(shiploc, game) do
    asteroids = game.state.asteroids |> filter_active()
    ships = game.state.ships |> Map.values() |> ships_except(shiploc.tag)

    ship_state = %Targets{
      :theta => shiploc.theta,
      :ships => ships,
      :rocks => asteroids,
      :origin => shiploc.pos
    }

    {:reply, ship_state, game}
  end

  def ships_except(ships, tag) do
    ships
    |> Enum.reject(fn s -> ship_state_has_tag(s, tag) end)
  end

  def ship_state_has_tag(%{tag: expected_tag}, expected_tag), do: true
  def ship_state_has_tag(%{tag: _}, _), do: false

  # Asteroids

  def new_asteroid_in_game(a, game) do
    {:ok, pid} = Asteroid.start_link(game.info, a)
    put_in(game.state.asteroids[pid], :spawn)
  end

  def check_next_wave(game = %{min_asteroid_count: min_asteroid_count}) do
    active_asteroid_count = length(Map.keys(game.state.asteroids))

    if active_asteroid_count < min_asteroid_count do
      new_asteroid_in_game(Asteroid.random_asteroid(), game)
    else
      game
    end
  end

  # TODO next_wave
  # defp next_wave(game_state) do
  #   game_state
  #   |> Map.update!(:min_asteroid_count, &min(&1 + 1, @max_asteroids))
  # end

  # Game state

  defp remove_pid_from_game_state(pid, game) do
    Enum.reduce([:asteroids, :bullets, :ships], game, fn thng, game ->
      case pop_in(game, [:state, thng, pid]) do
        {nil, _} -> game
        {_, new_game} -> new_game
      end
    end)
  end

  defp game_info(game_id), do: %Info{id: game_id}

  # @spec snapshot(map()) :: Snapshot.t()
  defp snapshot(game_state) do
    %Snapshot{
      asteroids: filter_active(game_state.state.asteroids),
      bullets: filter_active(game_state.state.bullets),
      ships: filter_active(game_state.state.ships)
    }
  end

  # Remove actors that have a placeholder state of :spawn
  defp filter_active(m), do: m |> Map.values() |> Enum.filter(&Kernel.is_map/1)
end
