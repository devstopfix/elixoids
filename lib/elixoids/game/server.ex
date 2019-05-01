defmodule Elixoids.Game.Server do
  @moduledoc """
  Game process. One process per running Game.
  Each object in the game is represented by a Process.
  The processes update themselves and they report their new state to the Game.

  Players are identified by a name (AAA..ZZZ) and control a Ship process.
  """

  use GenServer
  use Elixoids.Game.Heartbeat

  alias Elixoids.Api.SoundEvent
  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Bullet.Server, as: Bullet
  alias Elixoids.Collision.Server, as: CollisionServer
  alias Elixoids.Game.Info
  alias Elixoids.Game.Snapshot
  alias Elixoids.News
  alias Elixoids.Ship.Server, as: Ship
  alias Elixoids.Ship.Targets
  import Logger

  @max_asteroids 32

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

  @spec spawn_player(integer(), String.t()) ::
          {:ok, pid(), term()} | {:error, {:already_started, pid()}}
  def spawn_player(game_id, player_tag) do
    GenServer.call(via(game_id), {:spawn_player, player_tag})
  end

  def state_of_ship(game_id, ship_pid) do
    GenServer.call(via(game_id), {:state_of_ship, ship_pid})
  end

  ## Initial state

  def generate_asteroids(n, game_info) do
    Enum.map(1..n, fn _ -> {:ok, _pid} = Asteroid.start_link(game_info) end)
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
    generate_asteroids(asteroid_count, info)

    %{
      :game_id => game_id,
      :info => info,
      :state => %{:asteroids => %{}, :bullets => %{}, :ships => %{}},
      :min_asteroid_count => asteroid_count
    }
  end

  @doc """
  Echo the state of the game to the console.

      {:ok, game} = Elixoids.Game.Server.start_link
      Elixoids.Game.Server.show(game)

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
    Enum.each(rocks, fn rock -> new_asteroid_in_game(rock, game) end)
    {:noreply, game}
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
  def handle_info(msg = {:EXIT, _, _}, state) do
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

  # Ceiling on maximum asteroids in a wave
  def handle_info({:next_wave, inc_asteroid_count}, game)
      when inc_asteroid_count > @max_asteroids,
      do: {:noreply, game}

  def handle_info(
        {:next_wave, inc_asteroid_count},
        game = %{min_asteroid_count: min_asteroid_count}
      )
      when inc_asteroid_count <= min_asteroid_count,
      do: {:noreply, game}

  def handle_info({:next_wave, inc_asteroid_count}, game) do
    {:noreply, %{game | min_asteroid_count: inc_asteroid_count}}
  end

  def handle_call({:state_of_ship, ship_pid}, _from, game) do
    case game.state.ships[ship_pid] do
      nil -> {:reply, %Targets{}, game}
      ship -> fetch_ship_state(ship, game)
    end
  end

  def handle_call({:bullet_fired, shooter_tag, pos, theta}, _from, game) do
    {:ok, bullet_pid} = Bullet.start_link(game.game_id, shooter_tag, pos, theta)
    {:reply, {:ok, bullet_pid}, game}
  end

  @doc """
  Spawn a new ship controlled by player with given tag (unless that ship already exists)
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
      :a => game.state.asteroids |> Map.values(),
      :s => game.state.ships |> Map.values(),
      :b => game.state.bullets |> Map.values()
    }

    {:reply, game_state, game}
  end

  defp fetch_ship_state(shiploc, game) do
    asteroids = game.state.asteroids |> Map.values()
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
    {:ok, _pid} = Asteroid.start_link(game.info, a)
  end

  def check_next_wave(game = %{min_asteroid_count: min_asteroid_count, game_id: game_id}) do
    if few_asteroids?(game) do
      News.publish_news(game_id, ["ASTEROID", "spotted"])
      new_asteroid_in_game(Asteroid.random_asteroid(), game)

      if !Enum.empty?(game.state.asteroids) && min_asteroid_count < @max_asteroids,
        do: Process.send_after(self(), {:next_wave, min_asteroid_count + 1}, 8000)
    end

    game
  end

  defp few_asteroids?(%{min_asteroid_count: min_asteroid_count, state: %{asteroids: asteroids}}) do
    length(Map.keys(asteroids)) < min_asteroid_count
  end

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
      asteroids: Map.values(game_state.state.asteroids),
      bullets: Map.values(game_state.state.bullets),
      ships: Map.values(game_state.state.ships)
    }
  end
end
