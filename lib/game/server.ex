defmodule Game.Server do

  @moduledoc """
  Game process. One process per running Game.
  """

  use GenServer

  alias Game.Identifiers, as: Identifiers

  @initial_asteroid_count 5

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def show(pid) do
    GenServer.cast(pid, :show)
  end

  ## Initial state

  def asteroids(ids, n) do
    Enum.reduce(1..n, %{}, fn(i, rocks) ->
      id = Identifiers.next(ids)
      {:ok, pid} = Asteroid.Server.start_link(id)
      Map.put(rocks, i, pid)
    end)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, ids} = Identifiers.start_link
    rocks = asteroids(ids, @initial_asteroid_count)
    state = %{:ids=> ids, 
              :asteroids=>rocks}
    {:ok, state}
  end

  @doc """
  Echo the state of the game to the console.

      {:ok, game} = Game.Server.start_link
      Game.Server.show(game)
  
  """
  def handle_cast(:show, game) do
    game
    |> Kernel.inspect(pretty: true)
    |> IO.puts
    {:noreply, game}
  end

end
