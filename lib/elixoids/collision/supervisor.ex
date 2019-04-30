defmodule Elixoids.Collision.Supervisor do
  @moduledoc """
  Games are identified by a unique positive integer and have a
  corresponding supervised collision detection process.
  """

  use DynamicSupervisor
  alias Elixoids.Collision.Server, as: CollisionServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_for_game(integer()) :: {:ok, pid()}
  def start_for_game(game_id) when is_integer(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {CollisionServer, game_id})
  end
end
