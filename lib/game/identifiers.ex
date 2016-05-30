defmodule Game.Identifiers do
  @moduledoc """
  Generate unique, sequential, integer identifiers.
  """
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, 1, [])
  end

  def next(pid) do
    GenServer.call(pid, {:next})
  end

  def handle_call({:next}, _from, n) do
    {:reply, n, n + 1}
  end

end
