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
  alias Elixoids.Game.Server, as: GameServer
  import Game.Identifiers

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new supervised game.

      Elixoids.Game.Supervisor.start_game([fasteroids: 4])
  """
  @spec start_game(asteroids: integer()) :: {:ok, pid(), integer()}
  def start_game(args = [asteroids: asteroid_count])
      when asteroid_count >= 0 and asteroid_count <= @max_asteroids do
    game_id = next_game_id()
    arg = [game_id: game_id]
    child_spec = {GameServer, arg ++ args}
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    {:ok, _} = CollisionSupervisor.start_for_game(game_id)
    {:ok, pid, game_id}
  end
end
