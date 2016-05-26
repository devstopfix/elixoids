defmodule Game.Asteroid do
  
   @moduledoc """
   Asteroid process.
   """

   use GenServer

   alias World.Point, as: Point
   alias Elixoids.Space, as: Space

   def start_link do
     GenServer.start_link(__MODULE__, random_asteroid, [])
   end

   def move(pid, delta_t_ms) do
     GenServer.cast(pid, {:move, delta_t_ms})
   end

   def position(pid) do
     GenServer.call(pid, :position)
   end

   # GenServer callbacks

   def init(a) do
     {:ok, a}
   end

   def handle_cast({:move, delta_t_ms}, a) do
     p1 = Point.apply_velocity(a.pos, a.velocity, delta_t_ms)
     p2 = Space.wrap(p1)
     {:noreply, %{a | :pos => p2}}
   end

   def handle_call(:position, _from, a) do
     {:reply, {a.pos.x, a.pos.y, a.radius}, a}
   end

   # {:ok, a} = Game.Asteroid.start_link
   # Game.Asteroid.position(a)
   # Game.Asteroid.move(a,1)

   def random_asteroid do
     %{:pos => Elixoids.Space.random_point,
       :velocity => World.Velocity.random_direction_with_speed(10.0),
       :radius => 40.0}
   end

end