defmodule Game.Asteroid do
  
   @moduledoc """
   Asteroid process.
   """

   use GenServer

   def start_link do
     a = %{:pos => %World.Point{}, 
           :velocity => %World.Velocity{},
           :radius => 10.0}
     GenServer.start_link(__MODULE__, a, [])
   end

   def init(a) do
     {:ok, a}
   end

   def move(asteroid, delta_t_ms) do
     GenServer.cast(asteroid, {:move, delta_t_ms})
   end

   def handle_cast({:move, delta_t_ms}, asteroid) do
     {:noreply, asteroid}
   end

   # {:ok, a} = Game.Asteroid.start_link
   # Game.Asteroid.move(a,1)

end