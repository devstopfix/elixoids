defmodule Bullet.Server do
  @moduledoc """
  Bullets are spawned by a game. They fly in the direction
  in which the are spawned and then expire. They report their
  position at a given FPS to the game.
  Bullets have a position and velocity, a TTL, and the tag of their firer.
  """

  use GenServer

  alias Elixoids.Space
  alias Game.Server, as: GameServer
  alias World.Point
  import World.Clock
  use Elixoids.Game.Heartbeat

  @bullet_range_m 2000.0
  @bullet_speed_m_per_s 750.0

  @fly_time_ms s_to_ms(@bullet_range_m / @bullet_speed_m_per_s)

  @doc """
  Fire a bullet with:

      {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 1)
      {:ok, b} = Bullet.Server.start_link(999, %World.Point{:x=>0.0, :y=>0.0}, 1.0, "XXX", game_id)
  """
  def start_link(id, pos, theta, shooter, game_id) when is_integer(game_id) do
    v = %World.Velocity{:theta => theta, :speed => @bullet_speed_m_per_s}

    b = %{
      :id => id,
      :pos => pos,
      :velocity => v,
      :shooter => shooter,
      :game_id => game_id,
      :expire_at => calculate_ttl()
    }

    GenServer.start_link(__MODULE__, b)
  end

  @doc """
  The bullet has expired and should be removed from the game.
  """
  def stop(pid) do
    GenServer.cast(pid, :stop)
    # TODO this can be a normal process exit?
  end

  def hit_asteroid(pid) do
    GenServer.cast(pid, :hit_asteroid)
  end

  @doc """
  Stop the bullet, and tell the game who fired the bullet.
  """
  def hit_ship(pid, victim_tag, game_id) do
    GenServer.cast(pid, {:hit_ship, victim_tag, game_id})
  end

  # GenServer callbacks

  def init(state) do
    start_heartbeat()
    {:ok, state}
  end

  @doc """
  Update the position of the bullet and broadcast to the game
  """
  def handle_tick(_pid, delta_t_ms, bullet) do
    if past?(bullet.expire_at) do
      # TODO this should be a stop signal seen by game and collision process
      GameServer.bullet_missed(bullet.game_id, {bullet.id, bullet.shooter})
      {:stop, :normal, bullet}
    else
      moved_bullet = bullet |> move_bullet(delta_t_ms)
      GameServer.update_bullet(bullet.game_id, state_tuple(moved_bullet))
      {:ok, moved_bullet}
    end
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
    msg = Enum.join([b.shooter, "shot", "ASTEROID"], " ")
    Elixoids.News.publish_news(0, msg)
    {:noreply, b}
  end

  def handle_cast({:hit_ship, victim_tag, game_id}, bullet) do
    GameServer.player_shot_player(game_id, bullet.id, bullet.shooter, victim_tag)
    {:stop, :normal, bullet}
  end

  # Functions

  @doc """
  Apply velocity of bullet b to it's position,
  in given time slice.
  """
  def move_bullet(b, delta_t_ms) do
    p2 =
      b.pos
      |> Point.apply_velocity(b.velocity, delta_t_ms)
      |> Space.wrap()

    %{b | :pos => p2}
  end

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(b) do
    {b.id, Point.round(b.pos.x), Point.round(b.pos.y)}
  end

  @doc """
  Calculate the time to live (in ms) of a bullet
  from the distance it can cover and it's velocity.
  """
  def calculate_ttl, do: now_ms() + @fly_time_ms

  @doc """
  Is distance d in metres within the range of a bullet?
  """
  def in_range?(d), do: d < @bullet_range_m
end
