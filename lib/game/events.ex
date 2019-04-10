defmodule Game.Events do
  @moduledoc """
  Receives game events.
  """

  use GenServer

  @doc """
  {:ok, e} = Game.Events.start_link
  """
  def start_link do
    GenServer.start(__MODULE__, MapSet.new(), [])
  end

  def flush(pid) do
    GenServer.call(pid, :flush)
  end

  def broadcast(pid, msg) do
    GenServer.cast(pid, {:broadcast, msg})
  end

  def player_shot_asteroid(pid, player_tag) do
    msg = Enum.join([player_tag, "shot", "ASTEROID"], " ")
    GenServer.cast(pid, {:broadcast, msg})
  end

  def player_kills(pid, shooter, victim_tag) do
    msg = Enum.join([shooter, "killed", victim_tag], " ")

    GenServer.cast(pid, {:broadcast, msg})
  end

  def handle_cast({:broadcast, msg}, messages) do
    {:noreply, MapSet.put(messages, msg)}
  end

  def handle_call(:flush, _from, messages) do
    {:reply, MapSet.to_list(messages), MapSet.new()}
  end
end
