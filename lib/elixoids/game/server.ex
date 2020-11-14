defmodule Elixoids.Game.Server do
  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The processes update themselves and they report their new state to the Game.

  Players are identified by a name (AAA..ZZZ) and control a Ship process.
  """

  use GenServer

  alias Elixoids.Api.SoundEvent
  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Bullet.Server, as: Bullet
  alias Elixoids.Collision.Server, as: CollisionServer
  alias Elixoids.Game.Snapshot
  alias Elixoids.News
  alias Elixoids.Saucer.Supervisor, as: Saucer
  alias Elixoids.Ship.Server, as: Ship
  alias Elixoids.Ship.Targets
  import Elixoids.Const, only: [saucer_interval_ms: 0, saucers: 0]
  import Logger

  use Elixoids.Game.Heartbeat

  def start_link(args = [game_id: game_id, asteroids: _]) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, args, name: via(game_id))
  end

  defp via(game_id) when is_integer(game_id),
    do: {:via, Registry, {Registry.Elixoids.Games, {game_id}}}

  def show(pid) do
    GenServer.cast(pid, :show)
  end

  def state(game_id) do
    GenServer.call(via(game_id), :state)
  end

  def bullet_fired(game_id, shooter_tag, pos, theta) do
    GenServer.call(via(game_id), {:bullet_fired, shooter_tag, pos, theta})
  end

  def explosion(game_id, pos, radius) do
    GenServer.cast(via(game_id), {:explosion, pos, radius})
  end

  def update_asteroid(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :asteroids, new_state})
  end

  def update_bullet(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :bullets, new_state})
  end

  def update_ship(game_id, new_state) do
    GenServer.cast(via(game_id), {:update_entity, :ships, new_state})
  end

  def spawn_asteroids(game_id, rocks) do
    GenServer.cast(via(game_id), {:spawn_asteroids, rocks})
  end

  def link(game_id, pid) do
    GenServer.cast(via(game_id), {:link, pid})
  end

  @spec spawn_player(integer(), String.t()) ::
          {:ok, pid(), term()} | {:error, {:already_started, pid()}}
  def spawn_player(game_id, player_tag) do
    GenServer.call(via(game_id), {:spawn_player, player_tag})
  end

  def state_of_ship(game_id, ship_pid, from) do
    GenServer.cast(via(game_id), {:state_of_ship, ship_pid, from})
  end

  ## Initial state

  def generate_asteroids(0, _), do: []

  def generate_asteroids(n, game_id) do
    Enum.map(1..n, fn _ -> {:ok, _pid} = Asteroid.start_link(game_id) end)
  end

  ## Server Callbacks

  @impl true
  def init(game_id: game_id, asteroids: asteroid_count) do
    game_state = initial_game_state(asteroid_count, game_id)
    Process.flag(:trap_exit, true)
    start_heartbeat()
    maybe_spawn_saucer()
    {:ok, game_state}
  end

  defp initial_game_state(asteroid_count, game_id) do
    generate_asteroids(asteroid_count, game_id)

    %{
      :game_id => game_id,
      :state => %{:asteroids => %{}, :bullets => %{}, :ships => %{}},
      :min_asteroid_count => asteroid_count,
      :saucers => saucers()
    }
  end

  @doc """
  Echo the state of the game to the console.

      {:ok, game} = Elixoids.Game.Server.start_link
      Elixoids.Game.Server.show(game)

  """
  @impl true
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

  def handle_cast({:spawn_asteroids, rocks}, game = %{game_id: game_id}) do
    Enum.each(rocks, fn rock -> new_asteroid_in_game(rock, game_id) end)
    {:noreply, game}
  end

  def handle_cast({:link, pid}, game) do
    Process.link(pid)
    {:noreply, game}
  end

  def handle_cast({:explosion, %{x: x, y: y}, radius}, game) do
    pan = Elixoids.Space.frac_x(x)
    News.publish_audio(game.game_id, SoundEvent.explosion(pan, radius))
    News.publish_explosion(game.game_id, [x, y])
    {:noreply, game}
  end

  def handle_cast({:state_of_ship, ship_pid, from}, game) do
    case game.state.ships[ship_pid] do
      nil ->
        {:noreply, game}

      ship ->
        GenServer.reply(from, fetch_ship_state(ship, game))
        {:noreply, game}
    end
  end

  @doc """
  Update the game state and check for collisions.
  """
  @impl Elixoids.Game.Tick
  def handle_tick(_pid, _delta_t_ms, game = %{game_id: game_id}) do
    snap = snapshot(game)
    CollisionServer.collision_tests(game_id, snap)
    {:ok, game}
  end

  def handle_info({:EXIT, pid, :normal}, state) do
    {:noreply, remove_pid_from_game_state(pid, state, [:ships])}
  end

  def handle_info({:EXIT, pid, {:shutdown, :destroyed}}, state) do
    next_state = remove_pid_from_game_state(pid, state, [:asteroids]) |> check_next_wave()
    {:noreply, next_state}
  end

  def handle_info({:EXIT, pid, {:shutdown, :detonate}}, state) do
    {:noreply, remove_pid_from_game_state(pid, state, [:bullets])}
  end

  def handle_info({:EXIT, pid, :shutdown}, state) do
    {:noreply, remove_pid_from_game_state(pid, state, [:ships])}
  end

  # Saucer exits
  def handle_info({:EXIT, pid, {:shutdown, :crashed}}, state) do
    {:noreply, remove_pid_from_game_state(pid, state, [:ships])}
  end

  def handle_info(msg = {:EXIT, pid, _}, state) do
    [:EXIT, msg, state] |> inspect |> warn()
    {:noreply, remove_pid_from_game_state(pid, state)}
  end

  def handle_info(:spawn_saucer, %{:state => %{:ships => ships}} = game) when ships == %{} do
    Process.send_after(self(), :spawn_saucer, saucer_interval_ms())
    {:noreply, game}
  end

  def handle_info(:spawn_saucer, %{:saucers => []} = game) do
    {:noreply, game}
  end

  def handle_info(:spawn_saucer, %{:saucers => [saucer | xs]} = game) do
    Process.send_after(self(), :spawn_saucer, saucer_interval_ms())
    {:ok, _pid} = Saucer.start_saucer(game.game_id, saucer)
    {:noreply, %{game | saucers: xs ++ [saucer]}}
  end

  @impl true
  def handle_call({:bullet_fired, shooter_tag, pos, theta}, _from, game) do
    {:ok, bullet_pid} = Bullet.start_link(game.game_id, shooter_tag, pos, theta)
    {:reply, {:ok, bullet_pid}, game}
  end

  # Spawn a new ship controlled by player with given tag (unless that ship already exists)
  def handle_call({:spawn_player, player_tag}, _from, game = %{game_id: game_id}) do
    case Ship.start_link(game_id, player_tag) do
      {:ok, ship_pid, ship_id} -> {:reply, {:ok, ship_pid, ship_id}, game}
      e -> {:reply, e, game}
    end
  end

  # Return the current state of the game to the UI websocket.
  def handle_call(:state, _from, game) do
    game_state = %{
      :dim => Elixoids.Space.dimensions(),
      :a => game.state.asteroids |> Map.values(),
      :s => game.state.ships |> Map.values(),
      :b => game.state.bullets |> Map.values()
    }

    {:reply, game_state, game}
  end

  defp fetch_ship_state(shiploc, game) do
    asteroids = game.state.asteroids |> Map.values()
    ships = game.state.ships |> Map.values() |> ships_except(shiploc.tag)

    %Targets{
      :theta => shiploc.theta,
      :ships => ships,
      :rocks => asteroids,
      :origin => shiploc.pos
    }
  end

  def ships_except(ships, tag) do
    ships
    |> Enum.reject(fn s -> ship_state_has_tag(s, tag) end)
  end

  def ship_state_has_tag(%{tag: expected_tag}, expected_tag), do: true
  def ship_state_has_tag(%{tag: _}, _), do: false

  # Asteroids

  def new_asteroid_in_game(a, game_id) do
    {:ok, _pid} = Asteroid.start_link(game_id, a)
  end

  def check_next_wave(game = %{game_id: game_id}) do
    if few_asteroids?(game) do
      News.publish_news(game_id, ["ASTEROID", "spotted"])
      new_asteroid_in_game(Asteroid.random_asteroid(), game_id)
    end

    game
  end

  defp few_asteroids?(%{min_asteroid_count: min_asteroid_count, state: %{asteroids: asteroids}}) do
    length(Map.keys(asteroids)) < min_asteroid_count
  end

  # Game state

  defp remove_pid_from_game_state(pid, game, keys \\ [:asteroids, :bullets, :ships]) do
    Enum.reduce(keys, game, fn thng, game ->
      case pop_in(game, [:state, thng, pid]) do
        {nil, _} -> game
        {_, new_game} -> new_game
      end
    end)
  end

  # @spec snapshot(map()) :: Snapshot.t()
  defp snapshot(game_state) do
    %Snapshot{
      asteroids: Map.values(game_state.state.asteroids),
      bullets: Map.values(game_state.state.bullets),
      ships: Map.values(game_state.state.ships)
    }
  end

  defp maybe_spawn_saucer do
    time = saucer_interval_ms()
    if time > 0, do: Process.send_after(self(), :spawn_saucer, time)
  end
end
