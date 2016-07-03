defmodule Ship.Server do

  @moduledoc """
  Players ship. Ships have position and size.
  """
  
  use GenServer

  alias World.Clock, as: Clock
  alias World.Point, as: Point
  alias World.Velocity, as: Velocity
  alias Elixoids.Space, as: Space

  @ship_radius_m 20.0
  @nose_radius_m (@ship_radius_m * 1.1)
  @ship_rotation_rad_per_sec (:math.pi * 2 / 10.0)

  @laser_recharge_ms 750
  @laser_recharge_penalty_ms 2500

  def start_link(id, tag \\ random_tag()) do
    ship = random_ship() 
           |> Map.put(:id, id)
           |> Map.put(:tag, tag)

    GenServer.start_link(__MODULE__, ship, [])
  end

  @doc """
  Move ship with pid, using time slice, report state back to Game.
  """
  def move(pid, delta_t_ms, game_pid) do
    GenServer.cast(pid, {:move, delta_t_ms, game_pid})
  end

  def position(pid) do
    GenServer.call(pid, :position)
  end

  def nose_tag(pid) do
    GenServer.call(pid, :nose_tag)
  end

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
    {:ok, ship}
  end

  def handle_cast({:move, delta_t_ms, game_pid}, ship) do
    new_ship = rotate_ship(ship, delta_t_ms)
    Game.Server.update_ship(game_pid, state_tuple(new_ship))
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
    max_theta = @ship_rotation_rad_per_sec * delta_t_ms
    min_theta = max_theta * -1.0
    cond do
      (delta_theta > max_theta) -> max_theta
      (delta_theta < min_theta) -> min_theta
      true                      -> delta_theta
    end
  end

  def rotate_ship(ship, delta_t_ms) do
    input_delta_theta = ship.target_theta - ship.theta
    delta_theta = clip_delta_theta(input_delta_theta, delta_t_ms)
    theta = Velocity.wrap_angle(ship.theta + delta_theta)
    %{ship | :theta => theta} 
  end

  defp random_tag do
    ?A..?Z |> Enum.to_list |> Enum.take_random(3) |> to_string
  end
 
  defp calculate_nose(ship) do
    ship_centre = ship.pos
    v = %Velocity{:theta => ship.theta, :speed => @nose_radius_m}
    Point.apply_velocity(ship_centre, v, 1000.0)
  end

  def valid_player_tag?(tag) do
    Regex.match?(~r/^[A-Z]{3}$/, tag)
  end

  def recharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_ms)}
  end

  def discharge_laser(ship) do
    %{ship | :laser_charged_at => (Clock.now_ms + @laser_recharge_penalty_ms)}
  end

end