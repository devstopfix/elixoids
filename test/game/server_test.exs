defmodule Game.ServerTest do
  use ExUnit.Case, async: false
  doctest Game.Server

  alias Game.Server, as: Game

  test "Can start a game" do
    {:ok, game} = Game.start_link
    Game.show(game)
  end

  test "The clock can update a game" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, elapsed_ms} = Game.tick(game)
    assert elapsed_ms >= 0
  end

end
