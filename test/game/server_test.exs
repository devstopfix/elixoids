defmodule Game.ServerTest do
  use ExUnit.Case, async: false
  doctest Game.Server

  alias Game.Server, as: Game

  test "Can start a game" do
    {:ok, game} = Game.start_link
    Game.show(game)
  end

end
