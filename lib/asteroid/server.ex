defmodule Asteroid.Server do
  @moduledoc """
  Asteroid process. Asteroids have position, size and velocity,
  and wander the game area.
  """

  use GenServer

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Asteroid.Rock
  alias Elixoids.Space
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity
  alias Game.Server, as: GameServer
  import Game.Identifiers
  use Elixoids.Game.Heartbeat

  # Radius of random asteroid
  @asteroid_radius_m 120.0

  # Smallest asteroid that can survive being hit
  @splittable_radius_m 20.0

  # Initial speed of asteroid
  @asteroid_speed_m_per_s 20.0

  def start_link(game_info, rock \\ random_asteroid()) do
    a = %{
      :id => next_id(),
      :game => game_info,
      :rock => rock
    }

    GenServer.start_link(__MODULE__, a)
  end

  @doc """
  The asteroid has been destroyed.
  """
  def destroyed(pid) do
    GenServer.cast(pid, :destroyed)
  end

  # GenServer callbacks

  def init(a) do
    start_heartbeat()
    {:ok, a}
  end

  def handle_tick(_pid, delta_t_ms, asteroid) do
    moved_asteroid = asteroid |> move_asteroid(delta_t_ms)
    GameServer.update_asteroid(asteroid.game.id, state_tuple(moved_asteroid))
    {:ok, moved_asteroid}
  end

  def handle_cast(:destroyed, asteroid = %{rock: rock}) do
    if rock.radius >= @splittable_radius_m do
      rocks = Rock.cleave(rock, 2)
      GameServer.spawn_asteroids(asteroid.game.id, rocks)
      {:stop, :normal, asteroid}
    end

    {:stop, :normal, asteroid}
  end

  def random_asteroid do
    p = Elixoids.Space.random_point_on_border()
    v = asteroid_velocity()
    %Rock{:pos => p, :velocity => v, :radius => @asteroid_radius_m}
  end

  defp asteroid_velocity, do: Velocity.random_velocity(@asteroid_speed_m_per_s)

  # Functions

  defp move_asteroid(a = %{rock: rock}, delta_t_ms) do
    # TODO refactor
    p2 =
      rock.pos
      |> Point.apply_velocity(a.rock.velocity, delta_t_ms)
      |> Space.wrap()

    Map.put(a, :rock, Map.put(rock, :pos, p2))
  end

  defp state_tuple(a = %{rock: rock}) do
    %AsteroidLoc{pid: self(), id: a.id, pos: rock.pos, radius: rock.radius}
  end
end
