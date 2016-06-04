defmodule Ship.Server do

  @moduledoc """
  Players ship. Ships have position and size.
  """
  
  use GenServer

  alias World.Point, as: Point
  alias World.Velocity, as: Velocity
  alias Elixoids.Space, as: Space

  @ship_radius_m 20.0

  def start_link(id) do
    ship = random_ship() 
           |> Map.put(:id, id)
           |> Map.put(:tag, "AAA")

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

  def handle_cast({:move, _delta_t_ms, game_pid}, ship) do
    Game.Server.update_ship(game_pid, state_tuple(ship))
    {:noreply, ship}
  end

  def handle_call(:position, _from, ship) do
    {:reply, state_tuple(ship), ship}
  end

  def handle_call(:nose, _from, ship) do
    {:reply, {ship.pos, ship.theta}, ship}
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

end