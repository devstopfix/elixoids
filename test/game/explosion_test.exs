defmodule Game.ExplosionTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Game.Server, as: Game

  test "Convert struct to state sent to client" do
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 2, asteroids: 2)
    News.subscribe(game_id)
    Game.explosion(game, 1.0, 2.0)
    assert_receive {:explosion, [1.0, 2.0]}, 500
    Process.exit(game, :normal)
  end
end
