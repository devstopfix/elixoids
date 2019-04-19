defmodule Asteroid.Server do
  @moduledoc """
  Asteroid process. Asteroids have position, size and velocity,
  and wander the game area.
  """

  use GenServer
  use Elixoids.Game.Heartbeat

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Asteroid.Rock
  alias Elixoids.Space
  alias Game.Server, as: GameServer
  alias World.Point
  alias World.Velocity
  import Game.Identifiers

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

     {:ok, a} = Asteroid.Server.start_link(9999)
     Process.alive?(a)
     Asteroid.Server.stop(a)
     Process.alive?(a)
  """
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  @doc """
  Return a list of zero or two new asteroid states.

  Returns empty list if the asteroid is too small to be split.
  Otherwise returns a list of two new states of smaller rocks
  flying in opposite directions.

  {:ok, game} = Game.Server.start_link(60)
  Game.Server.show(game)

  rock = IEx.Helpers.pid(0,140,0)
  Asteroid.Server.split(rock)
  """
  def split(pid) do
    GenServer.call(pid, :split)
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

  def handle_cast(:stop, b) do
    {:stop, :normal, b}
  end

  @doc """
  Split a single asteroid into two smaller asteroids heading
  in different directions and return a list of the new rocks,
  or return an empty list if the rock is too small to split.
  """
  def handle_call(:split, _game_pid, a = %{rock: rock}) do
    if rock.radius >= @splittable_radius_m do
      rocks = Rock.cleave(rock, 4)
      {:reply, rocks, a}
    else
      {:reply, [], a}
    end
  end

  def random_asteroid do
    p = Elixoids.Space.random_point_on_border()
    v = Velocity.random_direction_with_speed(@asteroid_speed_m_per_s)
    %Rock{:pos => p, :velocity => v, :radius => @asteroid_radius_m}
  end

  # Functions

  defp move_asteroid(a = %{rock: rock}, delta_t_ms) do
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
