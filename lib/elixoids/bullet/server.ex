defmodule Elixoids.Bullet.Server do
  @moduledoc """
  Bullets are spawned by a game. They fly in the direction
  in which the are spawned and then expire. They report their
  position at a given FPS to the game.
  Bullets have a position and velocity, a TTL, and the tag of their firer.
  """

  use GenServer

  alias Elixoids.Bullet.Location, as: BulletLoc
  alias Elixoids.Game.Server, as: GameServer
  alias Elixoids.Space
  alias Elixoids.World.Velocity
  import Elixoids.Const
  import Elixoids.World.Clock
  use Elixoids.Game.Heartbeat

  @doc """
  Fire with:

      {:ok, b} = Elixoids.Bullet.Server.start_link(0, "XXX", %{:x=>0.0, :y=>0.0}, 1.0)
  """
  def start_link(game_id, shooter, pos, theta)
      when is_integer(game_id) and
             is_map(pos) and
             is_number(theta) and
             is_binary(shooter) do
    b = %{
      :id => System.unique_integer([:positive, :monotonic]),
      :pos => [pos],
      :velocity => bullet_velocity(theta),
      :shooter => shooter,
      :game_id => game_id,
      :expire_at => calculate_ttl()
    }

    GenServer.start_link(__MODULE__, b)
  end

  # GenServer callbacks

  @impl true
  def init(state) do
    start_heartbeat()
    {:ok, state}
  end

  @doc """
  Update the position of the bullet and broadcast to the game
  """
  @impl Elixoids.Game.Tick
  def handle_tick(_pid, delta_t_ms, bullet = %{game_id: game_id}) do
    if past?(bullet.expire_at) do
      {:stop, {:shutdown, :detonate}, bullet}
    else
      moved_bullet = bullet |> move(delta_t_ms)
      GameServer.update_bullet(game_id, state_tuple(moved_bullet))
      {:ok, moved_bullet}
    end
  end

  defp move(b = %{velocity: v, pos: [pos | _]}, delta_t_ms) do
    new_pos = pos |> Velocity.apply_velocity(v, delta_t_ms) |> Space.wrap()
    %{b | pos: [new_pos, pos]}
  end

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(b), do: %BulletLoc{pid: self(), id: b.id, shooter: b.shooter, pos: b.pos}

  @doc """
  Calculate the time to live (in ms) of a bullet
  from the distance it can cover and it's velocity.
  """
  def calculate_ttl, do: now_ms() + fly_time_ms()

  @doc """
  Is distance d in metres within the range of a bullet?
  """
  def in_range?(d), do: d < bullet_range_m()

  defp bullet_velocity(theta), do: %Velocity{:theta => theta, :speed => bullet_speed_m_per_s()}
end
