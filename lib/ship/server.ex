defmodule Ship.Server do

  @moduledoc """
  Players ship. Ships have position and size.
  """
  
  use GenServer

  alias World.Point, as: Point
  alias World.Velocity, as: Velocity
  alias Elixoids.Space, as: Space

  @ship_radius_m 20.0
  @nose_radius_m (@ship_radius_m * 1.1)
  @ship_rotation_rad_per_sec (:math.pi * 2 / 10.0)

  def start_link(id) do
    ship = random_ship() 
           |> Map.put(:id, id)
           |> Map.put(:tag, random_tag())

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

  def nose(pid) do
    GenServer.call(pid, :nose)
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

  def handle_call(:position, _from, ship) do
    {:reply, state_tuple(ship), ship}
  end

  @doc """
  The nose of the ship is defined as the centre offset by 
  half of the radius, in the direction the ship is pointing.
  """
  def handle_call(:nose, _from, ship) do
    ship_centre = ship.pos
    v = %Velocity{:theta => ship.theta, :speed => @nose_radius_m}
    p = Point.apply_velocity(ship_centre, v, 1000.0)
    {:reply, {p, ship.theta}, ship}
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
      :theta => Velocity.random_direction}
  end

  def random_ship_point do
    Space.random_point
  end

  def rotate_ship(ship, delta_t_ms) do
    theta = ship.theta
    delta = @ship_rotation_rad_per_sec * delta_t_ms / 1000.0
    %{ship | :theta => Velocity.wrap_angle(theta + delta)} 
  end

  defp random_tag do
    Enum.to_list(?A .. ?Z) |> Enum.take_random(3) |> to_string
  end
 
end