defmodule Elixoids.Saucer.Supervisor do
  @moduledoc """
  Supervises saucer NPCs.
  """

  use DynamicSupervisor

  alias Elixoids.Saucer.Server, as: Saucer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_saucer(game_id) when is_integer(game_id) do
    child_spec = {Saucer, game_id}
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
