defmodule Asteroid.Server do

   @moduledoc """
   Asteroid process.
   """

   use GenServer

   alias World.Point, as: Point
   alias Elixoids.Space, as: Space

   @asteroid_radius_m 80

   def start_link(id) do
     a = Map.put(random_asteroid(), :id, id)
     GenServer.start_link(__MODULE__, a, [])
   end

   @doc """
   Move asteroid with pid, using time slice, report state back to Game.
   """
   def move(pid, delta_t_ms, game_pid) do
     GenServer.cast(pid, {:move, delta_t_ms, game_pid})
   end

   def position(pid) do
     GenServer.call(pid, :position)
   end

   # GenServer callbacks

   def init(a) do
     {:ok, a}
   end

   def handle_cast({:move, delta_t_ms, game_pid}, a) do
     moved_asteroid = move_asteroid(a, delta_t_ms)
     Game.Server.update_asteroid(game_pid, state_tuple(moved_asteroid))
     {:noreply, moved_asteroid}
   end

   def handle_call(:position, _from, a) do
     {:reply, {a.id, a.pos.x, a.pos.y, a.radius}, a}
   end

   # {:ok, a} = Asteroid.Server.start_link(1)
   # Asteroid.Server.position(a)
   # Asteroid.Server.move(a,1)

   def random_asteroid do
     %{:pos => Elixoids.Space.random_point,
       :velocity => World.Velocity.random_direction_with_speed(10.0),
       :radius => @asteroid_radius_m}
   end

   # Functions

   def move_asteroid(a, delta_t_ms) do
     p1 = Point.apply_velocity(a.pos, a.velocity, delta_t_ms)
     p2 = Space.wrap(p1)
     %{a | :pos => p2}
   end

   @doc """
   The tuple that will be shown to the UI for rendering.
   """
   def state_tuple(a) do
     {a.id, a.pos.x, a.pos.y, a.radius}
   end

end
