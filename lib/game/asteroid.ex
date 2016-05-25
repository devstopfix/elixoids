defmodule Game.Asteroid do
  
   @moduledoc """
   Asteroid process.
   """

   use GenServer

   def start_link do
     GenServer.start_link(__MODULE__, :ok, [])
   end

   def init(:ok) do
     {:ok, %{}}
   end

   def handle_cast({:move, delta_t_ms}, asteroid) do
     {:noreply, asteroid}
   end

end