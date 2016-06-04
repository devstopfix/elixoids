defmodule Ship.Server do

  @moduledoc """
  Players ship. Ships have position and size.
  """
  
  use GenServer

  alias World.Velocity, as: Velocity
  alias Elixoids.Space, as: Space

  @ship_radius_m 20

  def start_link(id) do
    ship = Map.put(random_ship(), :id, id)
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

  # Data

  @doc """
  The tuple that will be shown to the UI for rendering.
  """
  def state_tuple(ship) do
    {ship.id, ship.pos.x, ship.pos.y, @ship_radius_m, ship.theta, "FFFFFF"}
  end  

  def random_ship do
    %{:pos => random_ship_point(),
      :theta => Velocity.random_direction}
  end

  def random_ship_point do
    Space.random_point
  end

end