defmodule Game.Events do
  
  @moduledoc """
  Receives game events.
  """

  use GenServer

  @doc """
  {:ok, e} = Game.Events.start_link
  """
  def start_link do
    GenServer.start(__MODULE__, MapSet.new, [])
  end

  def flush(pid) do
    GenServer.call(pid, :flush)
  end

  def broadcast(pid, msg) do
    GenServer.cast(pid, {:broadcast, msg})
  end

  def handle_cast({:broadcast, msg}, messages) do
    {:noreply, MapSet.put(messages, msg)}
  end

  def handle_call(:flush, _from, messages) do 
    {:reply, MapSet.to_list(messages), MapSet.new}
  end

end
