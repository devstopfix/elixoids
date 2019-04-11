defmodule Game.ExplosionTest do
  use ExUnit.Case, async: true

  alias Elixoids.News
  alias Game.Server, as: Game

  # TODO refactor with game number, not atom :game

  # test "Convert struct to state sent to client" do
  #   {:ok, game} = Game.start_link({2, 1})
  #   News.subscribe(0)
  #   Game.explosion(game, 1.0, 2.0)
  #   assert_receive {:explosion, [1.0, 2.0]}, 500
  #   Process.exit(game, :normal)
  # end
end
