defmodule Elixoids.ExplosionTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Elixoids.Game.Server, as: Game

  test "Convert struct to state sent to client" do
    {:ok, pid, game_id} = GameSupervisor.start_game(asteroids: 2)
    pos = %{x: 1.0, y: 2.0}
    News.subscribe(game_id)
    Game.explosion(game_id, pos, 100.0)
    assert_receive {:explosion, pos}, 500
    Process.exit(pid, :normal)
  end
end
