defmodule Elixoids.Asteroid.Server do
  @moduledoc """
  Asteroid process. Asteroids have position, size and velocity,
  and wander the game area.
  """

  use GenServer

  alias Elixoids.Asteroid.Location, as: AsteroidLoc
  alias Elixoids.Asteroid.Rock
  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Space
  alias Elixoids.World.Velocity
  import Elixoids.Const
  import Elixoids.Game.Identifiers
  use Elixoids.Game.Heartbeat

  def start_link(game_id, rock \\ %{}) when is_integer(game_id) do
    a = %{
      :id => next_id(),
      :game_id => game_id,
      :rock => Map.merge(random_asteroid(), rock)
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

  def handle_tick(_pid, delta_t_ms, asteroid = %{game_id: game_id}) do
    moved_asteroid = asteroid |> move(delta_t_ms)
    GameServer.update_asteroid(game_id, state_tuple(moved_asteroid))
    {:ok, moved_asteroid}
  end

  def handle_cast(:destroyed, asteroid = %{rock: rock, game_id: game_id}) do
    if rock.radius >= splittable_radius_m() do
      rocks = Rock.cleave(rock)
      GameServer.spawn_asteroids(game_id, rocks)
    end

    {:stop, {:shutdown, :destroyed}, asteroid}
  end

  def random_asteroid do
    %Rock{
      :pos => Elixoids.Space.random_point_on_border(),
      :velocity => asteroid_velocity(),
      :radius => asteroid_radius_m()
    }
  end

  defp asteroid_velocity, do: asteroid_speed_m_per_s() |> Velocity.random_velocity()

  defp move(a = %{rock: %{velocity: v}}, delta_t_ms) do
    update_in(a, [:rock, Access.key(:pos)], fn pos ->
      pos |> Velocity.apply_velocity(v, delta_t_ms) |> Space.wrap()
    end)
  end

  defp state_tuple(a = %{rock: rock}) do
    %AsteroidLoc{pid: self(), id: a.id, pos: rock.pos, radius: rock.radius}
  end
end
