defmodule Bullet.Server do
  @moduledoc """
  Bullets are spawned by a game. They fly in the direction
  in which the are spawned and then expire. They report their
  position at a given FPS to the game.
  Bullets have a position and velocity, a TTL,
  and the tag of their firer.
  """

  use GenServer

  alias World.Point, as: Point
  alias Elixoids.Space, as: Space
  alias World.Clock, as: Clock

  @bullet_range_m        2000.0
  @bullet_speed_m_per_s   750.0

  @doc """
  Fire a bullet with:

      {:ok, game} = Game.Server.start_link()
      {:ok, b} = Bullet.Server.start_link(999, %World.Point{:x=>0.0, :y=>0.0}, 1.0, "XXX", game
      Process.alive?(b)
      GenServer.call(b, :position)

      receive do {:update_bullet, b} -> b after 500 -> nil end
  """
  def start_link(id, pos, theta, shooter, game_pid) do
    v = %World.Velocity{:theta=>theta, :speed=>@bullet_speed_m_per_s}
    b = %{:id=>id,
          :pos=>pos,
          :velocity=>v,
          :shooter=>shooter,
          :game_pid => game_pid,
          :expire_at=>calculate_ttl(),
          :clock_ms => Clock.now_ms,
          :tick_ms=>16}
    GenServer.start_link(__MODULE__, b, [])
  end

  @doc """
  Return the state of the process as a tuple
  """
  def position(pid) do
    GenServer.call(pid, :position)
  end

  @doc """
  The bullet has expired and should be removed from the game.

      {:ok, b} = Bullet.Server.start_link(999, 
        %World.Point{:x=>0.0, :y=>0.0},
        1.0)
      Process.alive?(b)
      Bullet.Server.stop(b)
      Process.alive?(b)
  """
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def hit_asteroid(pid) do
    GenServer.cast(pid, :hit_asteroid)
  end

  def hit_ship(pid, victim_tag) do
    GenServer.call(pid, {:hit_ship, victim_tag})
  end

  # GenServer callbacks

  def init(state) do
    Process.send(self(), :tick, [])
    {:ok, state}
  end

  @doc """
  Update the position of the bullet and broadcast to the game
  """
  def handle_cast(:move, bullet) do
    delta_t_ms = Clock.since(bullet.clock_ms)

    moved_bullet = bullet
    |> move_bullet(delta_t_ms)
    |> Map.put(:clock_ms, Clock.now_ms)

    Game.Server.update_bullet(bullet.game_pid, state_tuple(moved_bullet))
    {:noreply, moved_bullet}
  end

  @doc """
  Game tells the bullet to stop. Maybe it hit something.
  The game will receive the exit message and remove the bullet
  from it's list of active bullets.
  """
  def handle_cast(:stop, b) do
    {:stop, :normal, b}
  end

  @doc """
  Test
      {:ok, game} = Game.Server.start_link()
      Game.Server.tick(game)
      Game.Server.show(game)
      Game.Server.ship_fires_bullet(game, 12)
      Game.Server.show(game)
      Bullet.Server.hit_asteroid(:c.pid(0,19,0))
  """
  def handle_cast(:hit_asteroid, b) do
    Game.Events.player_shot_asteroid(:news, b.shooter)
    
    {:noreply, b}
  end

  @doc """
  Broadcast game event that player kills player
  """
  def handle_call({:hit_ship, victim_tag}, _from, b) do
    Game.Events.player_kills(:news, b.shooter, victim_tag)
    
    {:reply, {b.shooter, victim_tag}, b}
  end

  @doc """
  Tick event occurs at approximately 60fps until the bullet expires.
  If the bullet is still travelling, tell it to move, and enque the next tick. 
  Otherwise stop.
  """
  def handle_info(:tick, bullet) do
    if Clock.past?(bullet.expire_at) do
      Game.Server.bullet_missed(bullet.game_pid, {bullet.id, bullet.shooter})
      {:stop, :normal, bullet}
    else
      GenServer.cast(self(), :move)  
      Process.send_after(self(), :tick, bullet.tick_ms)
      {:noreply, bullet}
    end
  end

  # Functions

  @doc """
  Apply velocity of bullet b to it's position,
  in given time slice.
  """
  def move_bullet(b, delta_t_ms) do
    p2 = b.pos
    |> Point.apply_velocity(b.velocity, delta_t_ms)
    |> Space.wrap()

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
    bullet_speed_m_per_ms = (@bullet_speed_m_per_s / 1000.0)
    fly_time_ms = trunc(@bullet_range_m / bullet_speed_m_per_ms)
    Clock.now_ms + fly_time_ms
  end

  @doc """
  Is distance d in metres within the range of a bullet?
  """
  def in_range?(d) do
    d < @bullet_range_m
  end

end
