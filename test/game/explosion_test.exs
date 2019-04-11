defmodule Game.ExplosionTest do
  use ExUnit.Case, async: true

  alias Elixoids.News
  alias Game.Server, as: Game

  test "Convert struct to state sent to client" do
    {:ok, pid} = Game.start_link(2, 1)
    News.subscribe(0)
    Game.explosion(pid, 1.0, 2.0)
    assert_receive {:explosion, [1.0, 2.0]}, 500
  end
end
