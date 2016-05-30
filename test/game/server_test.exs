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

  test "We can retrieve game state" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    game_state = Game.state(game)
    assert 5 == length(game_state[:a])
    assert [1, _, _, 300] = List.first(game_state[:a])
    assert 4000.0 == List.first(game_state.dim)
  end

  test "We can retrieve viewport dimensions from game state" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    game_state = Game.state(game)
    assert 4000.0 == List.first(game_state.dim)
    assert 2250.0 == List.last(game_state.dim)
  end

end
