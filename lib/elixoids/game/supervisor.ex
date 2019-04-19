defmodule Elixoids.Game.Supervisor do
  @moduledoc """
  The dynamic game supervisor is responsible for starting new games
  and restarting them should they crash.

  Games are identified by a unique positive integer, which form part
  of the WebSocket URL used by clients to connect to their game.
  """

  @max_asteroids 64

  use DynamicSupervisor
  alias Elixoids.Collision.Supervisor, as: CollisionSupervisor
  alias Game.Server, as: GameServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new supervised game.

      Elixoids.Game.Supervisor.start_game([fps: 4, asteroids: 4])
  """
  @spec start_game(fps: integer(), asteroids: integer()) :: {:ok, pid(), integer()}
  def start_game(args = [fps: fps, asteroids: asteroid_count])
      when fps >= 0 and fps <= 60 and
             asteroid_count >= 0 and asteroid_count <= @max_asteroids do
    game_id = next_game_id()
    arg = [game_id: game_id]
    child_spec = {GameServer, arg ++ args}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    {:ok, _} = CollisionSupervisor.start_for_game(game_id)
    {:ok, pid, game_id}
  end

  defp next_game_id, do: System.unique_integer([:positive, :monotonic])
end
