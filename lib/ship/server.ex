defmodule Ship.Server do

  @moduledoc """
  Space ship controlled by a player or bot over a websocker. 
  Ships have position and size.
  Ships are identified by a unique integer.
  Players are identified by a 3-char string (AAA..ZZZ)
  Players control ships - the game maintains a map of Player to Ship
  """
  
  use GenServer

  alias Bullet.Server, as: Bullet
  alias Elixoids.Player, as: Player
  alias Elixoids.Space, as: Space
  alias Game.Identifiers, as: Identifiers
  alias Game.Server, as: Game
  alias World.Clock, as: Clock
  alias World.Point, as: Point
  alias World.Velocity, as: Velocity

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

    name = String.to_atom(tag <> Integer.to_string(id))

    GenServer.start_link(__MODULE__, ship, [name: name])
  end

  @doc """
  Return position of ship.
  """
  def position(pid) do
    GenServer.call(pid, :position)
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

  @doc """
  Stop the process.
  """
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  @doc """
  Player pulls trigger, which may fire a bullet
  if the ship is recharged.
  """
  def player_pulls_trigger(pid, ids) do
    GenServer.cast(pid, {:player_pulls_trigger, ids})
  end

  # GenServer callbacks

  def init(ship) do
    Process.send(self(), :tick, [])
    {:ok, ship}
  end

  def handle_cast(:stop, ship) do
    {:stop, :normal, ship}
  end

  @doc """
  Rotate the ship and broadcast new state to the game.
  """
  def handle_cast(:move, ship) do
    delta_t_ms = Clock.since(ship.clock_ms)

    new_ship = ship
    |> rotate_ship(delta_t_ms)
    |> Map.put(:clock_ms, Clock.now_ms)

    Game.update_ship(ship.game_pid, state_tuple(new_ship))
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

  def handle_cast({:player_pulls_trigger, ids}, ship) do
    if Clock.past?(ship.laser_charged_at) do
      id = Identifiers.next(ids) 
      pos = calculate_nose(ship)
      {:ok, bullet_pid} = Bullet.start_link(id, pos, ship.theta, ship.tag, ship.game_pid)
      Game.bullet_fired(ship.game_pid, id, bullet_pid)
      Game.broadcast(ship.game_pid, id, [ship.tag, "fires"])
      {:noreply, recharge_laser(ship)}
    else
      {:noreply, ship}
    end
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
    Point.apply_velocity(ship_centre, v, 500.0)
  end

  @doc """
  Update game state with time at which they can fire again
  """
  def recharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_ms)}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_penalty_ms)}
  end

end
