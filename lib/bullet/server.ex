defmodule Bullet.Server do
  @moduledoc """
  Bullet Process. Bullets have a position and velocity, a TTL,
  and the tag of their firer.
  """

  use GenServer

  alias World.Point, as: Point
  alias Elixoids.Space, as: Space
  alias World.Clock, as: Clock

  @bullet_range_m        2000.0
  @bullet_speed_m_per_s   500.0

  @doc """
  Fire a bullet with:

      {:ok, b} = Bullet.Server.start_link(999, 
        %World.Point{:x=>0.0, :y=>0.0},
        1.0)
      Bullet.Server.move(b, 100, self())
  """
  def start_link(id, pos, theta) do
    b = %{:id=>id,
          :pos=>pos,
          :velocity=>%World.Velocity{:theta=>theta, :speed=>@bullet_speed_m_per_s},
          :expire_at=>calculate_ttl()}
    GenServer.start_link(__MODULE__, b, [])
  end

  @doc """
  Return the state of the process as a tuple
  """
  def position(pid) do
    GenServer.call(pid, :position)
  end

  @doc """
  Move bullet with pid, using time slice, report state back to Game.
  """
  def move(pid, delta_t_ms, game_pid) do
    GenServer.cast(pid, {:move, delta_t_ms, game_pid})
  end

  # GenServer callbacks

  def init(b) do
     {:ok, b}
  end

  def handle_cast({:move, delta_t_ms, game_pid}, b) do
    if (b.expire_at > Clock.now_ms) do
      moved_bullet = move_bullet(b, delta_t_ms)
      Game.Server.update_bullet(game_pid, state_tuple(moved_bullet))
      {:noreply, b}
    else
      Game.Server.delete_bullet(game_pid, b.id)
      GenServer.stop(self())
      {:noreply, b}
    end
  end

  # Functions

  def move_bullet(b, delta_t_ms) do
    p1 = Point.apply_velocity(b.pos, b.velocity, delta_t_ms)
    p2 = Space.wrap(p1)
    %{b | :pos => p2}
  end

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(b) do
    {b.id,
     Point.round(b.pos.x), 
     Point.round(b.pos.y)}
  end

  @doc """
  Calculate the time to live (in ms) of a bullet 
  from the distance it can cover and it's velocity.
  """
  def calculate_ttl do
    fly_time_ms = trunc(@bullet_range_m / (@bullet_speed_m_per_s / 1000.0))
    Clock.now_ms + fly_time_ms
  end

end