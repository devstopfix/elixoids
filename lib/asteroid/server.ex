defmodule Asteroid.Server do
  @moduledoc """
  Asteroid process. Asteroids have position, size and velocity,
  and wander the game area.
  """

  use GenServer

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Asteroid.Rock
  alias Elixoids.Space
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

  def destroyed(pid) do
    GenServer.cast(pid, :destroyed)
  end

  # GenServer callbacks

  def init(a) do
    start_heartbeat()
    {:ok, a}
  end

  def handle_tick(_pid, delta_t_ms, asteroid = %{game: %{id: game_id}}) do
    moved_asteroid = asteroid |> move(delta_t_ms)
    GameServer.update_asteroid(game_id, state_tuple(moved_asteroid))
    {:ok, moved_asteroid}
  end

  def handle_cast(:destroyed, asteroid = %{rock: rock}) do
    if rock.radius >= @splittable_radius_m do
      rocks = Rock.cleave(rock, 2)
      GameServer.spawn_asteroids(asteroid.game.id, rocks)
    end

    {:stop, :normal, asteroid}
  end

  def random_asteroid do
    %Rock{
      :pos => Elixoids.Space.random_point_on_border(),
      :velocity => asteroid_velocity(),
      :radius => @asteroid_radius_m
    }
  end

  defp asteroid_velocity, do: Velocity.random_velocity(@asteroid_speed_m_per_s)

  defp move(a = %{rock: %{velocity: v}}, delta_t_ms) do
    update_in(a, [:rock, Access.key(:pos)], fn pos ->
      pos |> Velocity.apply_velocity(v, delta_t_ms) |> Space.wrap()
    end)
  end

  defp state_tuple(a = %{rock: rock}) do
    %AsteroidLoc{pid: self(), id: a.id, pos: rock.pos, radius: rock.radius}
  end
end
