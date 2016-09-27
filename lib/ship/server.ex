defmodule Ship.Server do

  @moduledoc """
  Space ship controlled by a player or bot over a websocker. 
  Ships have position and size.
  """
  
  use GenServer

  alias World.Clock, as: Clock
  alias World.Point, as: Point
  alias World.Velocity, as: Velocity
  alias Elixoids.Player, as: Player
  alias Elixoids.Space, as: Space

  # Ship radius (m)
  @ship_radius_m 20.0

  # The spawn point of a bullet
  @nose_radius_m (@ship_radius_m * 1.1)

  # Rotation rate (radians/sec)
  @ship_rotation_rad_per_sec (:math.pi * 2 / 3.0)

  # Minimum time between shots
  @laser_recharge_ms 500
  @laser_recharge_penalty_ms (@laser_recharge_ms * 2)

  def start_link(id, game_pid, tag \\ Player.random_tag()) do
    ship = Map.merge(random_ship(), %{
           :id=>id,
           :tag=>tag,
           :game_pid=>game_pid,
           :clock_ms=>Clock.now_ms,
           :tick_ms=>Clock.ms_between_frames})

    GenServer.start_link(__MODULE__, ship, [])
  end

  @doc """
  Return position of ship.
  """
  def position(pid) do
    GenServer.call(pid, :position)
  end

  @doc """
  Return a point just ahead of the nose of the ship.
  Bullets are spawned at this point.
  """
  def nose_tag(pid) do
    GenServer.call(pid, :nose_tag)
  end

  @doc """
  Player requests turn to given theta.
  """
  def new_heading(pid, theta) do
    GenServer.cast(pid, {:new_heading, theta})
  end

  @doc """
  Move the ship to a random position on the map
  and prevent it firing.
  """
  def hyperspace(pid) do
    GenServer.cast(pid, :hyperspace)
  end

  @doc """
  Update laser recharge rate
  """
  def fire(pid) do
    GenServer.cast(pid, :fire)
  end

  # GenServer callbacks

  def init(ship) do
    Process.send(self(), :tick, [])
    {:ok, ship}
  end

  @doc """
  Rotate the ship and broadcast new state to the game.
  """
  def handle_cast(:move, ship) do
    delta_t_ms = Clock.since(ship.clock_ms)

    new_ship = ship
    |> rotate_ship(delta_t_ms)
    |> Map.put(:clock_ms, Clock.now_ms)

    Game.Server.update_ship(ship.game_pid, state_tuple(new_ship))
    {:noreply, new_ship}
  end

  def handle_cast(:hyperspace, ship) do
    p = random_ship_point()
    theta = Velocity.random_direction

    new_ship = %{ship | pos: p, theta: theta}
    |> discharge_laser

    {:noreply, new_ship}
  end

  def handle_cast(:fire, ship) do    
    {:noreply, recharge_laser(ship)}
  end

  def handle_cast({:new_heading, theta}, ship) do
    new_ship = %{ship | :target_theta => Velocity.wrap_angle(theta)}
    {:noreply, new_ship}
  end

  @doc """
  Heartbeat. Causes ship to update itself at given interval.
  """
  def handle_info(:tick, a) do
    GenServer.cast(self(), :move)
    Process.send_after(self(), :tick, a.tick_ms)
    {:noreply, a}
  end

  def handle_call(:position, _from, ship) do
    {:reply, state_tuple(ship), ship}
  end

  @doc """
  The nose of the ship is defined as the centre offset by 
  half of the radius, in the direction the ship is pointing.
  """
  def handle_call(:nose_tag, _from, ship) do
    p = calculate_nose(ship)
    can_fire = (Clock.now_ms > ship.laser_charged_at)
    {:reply, {p, ship.theta, ship.tag, can_fire}, ship}
  end

  # Data

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(ship) do
    {ship.id, 
     ship.tag,
     Point.round(ship.pos.x), 
     Point.round(ship.pos.y), 
     Point.round(@ship_radius_m),
     Velocity.round_theta(ship.theta), 
     "FFFFFF"}
  end  

  def random_ship do
    %{:pos => random_ship_point(),
      :theta => 0.0,
      :target_theta => 0.0,
      :laser_charged_at => Clock.now_ms}
  end

  def random_ship_point do
    Space.random_grid_point
  end

  defp clip_delta_theta(delta_theta, delta_t_ms) do
    max_theta = @ship_rotation_rad_per_sec * delta_t_ms / 1000.0
    min_theta = max_theta * -1.0
    cond do
      (delta_theta > max_theta) -> max_theta
      (delta_theta < min_theta) -> min_theta
      true                      -> delta_theta
    end
  end

  defp shortest_angle(delta_theta) do
    other = (:math.pi * 2) - abs(delta_theta)
    Enum.min([delta_theta, other])
  end

  def rotate_ship(ship, delta_t_ms) do
    input_delta_theta = shortest_angle(ship.target_theta - ship.theta)
    delta_theta = clip_delta_theta(input_delta_theta, delta_t_ms)
    theta = Velocity.wrap_angle(ship.theta + delta_theta)
    %{ship | :theta => theta} 
  end

  defp calculate_nose(ship) do
    ship_centre = ship.pos
    v = %Velocity{:theta => ship.theta, :speed => @nose_radius_m}
    Point.apply_velocity(ship_centre, v, 1000.0)
  end

  def recharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_ms)}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_penalty_ms)}
  end

end
