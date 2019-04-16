defmodule Asteroid.Server do
  @moduledoc """
  Asteroid process. Asteroids have position, size and velocity,
  and wander the game area.
  """

  use GenServer
  use Elixoids.Game.Heartbeat

  alias Elixoids.Space
  alias Game.Server, as: GameServer
  alias World.Point
  alias World.Velocity

  # Radius of random asteroid
  @asteroid_radius_m 120.0

  # Smallest asteroid that can survive being hit
  @splittable_radius_m 20.0

  # 45º
  @quarter_pi_radians :math.pi() / 4.0

  # Initial speed of asteroid
  @asteroid_speed_m_per_s 20.0

  def start_link(id, game_info, asteroid \\ random_asteroid()) do
    a =
      Map.merge(asteroid, %{
        :id => id,
        :game => game_info
      })

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
  def handle_call(:split, _game_pid, a) do
    if a.radius >= @splittable_radius_m do
      directions = [@quarter_pi_radians, -1 * @quarter_pi_radians]

      fragments =
        Enum.map(
          directions,
          fn delta_theta ->
            delta_theta
            |> Velocity.perturb()
            |> cleave(a)
            |> anonymous()
          end
        )

      {:reply, fragments, a}
    else
      {:reply, [], a}
    end
  end

  def random_asteroid do
    p = Elixoids.Space.random_point_on_border()
    v = Velocity.random_direction_with_speed(@asteroid_speed_m_per_s)
    %{:pos => p, :velocity => v, :radius => @asteroid_radius_m}
  end

  # Functions

  def move_asteroid(a, delta_t_ms) do
    p2 =
      a.pos
      |> Point.apply_velocity(a.velocity, delta_t_ms)
      |> Space.wrap()

    %{a | :pos => p2}
  end

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(a) do
    {a.id, Point.round(a.pos.x), Point.round(a.pos.y), Point.round(a.radius)}
  end

  @doc """
  Remove the id of the asteroid
  """
  def anonymous(a) do
    Map.delete(a, :id)
  end

  @doc """
  Halve the radius of the asteroid.
  """
  def halve(a) do
    r = a.radius / 2.0
    %{a | radius: r}
  end

  @doc """
  Change the direction of the asteroid by given angle
  """
  def redirect(a, delta_theta) do
    update_in(a.velocity, &Velocity.fork(&1, delta_theta))
  end

  @doc """
  Double the speed of the asteroid.
  """
  def speedup(a) do
    update_in(a.velocity, &Velocity.double(&1))
  end

  @doc """
  Bump the asteroid in the direction it is facing,
  by half its radius
  """
  def bump(a) do
    t_ms = a.radius / a.velocity.speed * 1000 / 2
    update_in(a.pos, &Point.apply_velocity(&1, a.velocity, t_ms))
  end

  def cleave(delta_theta, a) do
    a
    |> halve
    |> redirect(delta_theta)
    |> speedup
    |> bump
  end
end
