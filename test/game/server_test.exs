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

  test "We can retrieve game state of Asteroids" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)

    game_state = Game.state(game)

    assert [1, _, _, 120.0] = List.first(game_state[:a])
  end

  test "We can retrieve game state of Ships" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)

    game_state = Game.state(game)

    assert [_, _, _, 20.0, _, "FFFFFF"] = List.first(game_state[:s])
  end

  test "We can retrieve game state of eXplosions" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)

    game_state = Game.state(game)

    assert 0 == length(game_state[:x])
    #assert [1, _, _, 40] = List.first(game_state[:a])
  end

  test "We can retrieve viewport dimensions from game state" do
    {:ok, game} = Game.start_link
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)

    game_state = Game.state(game)

    assert 4000.0 == List.first(game_state.dim)
    assert 2250.0 == List.last(game_state.dim)
  end

  test "We record who shot a player" do
    {:ok, game} = Game.start_link
    :timer.sleep(10)

    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)

    Game.ship_fires_bullet(game, 9)
    :timer.sleep(10)

    {:elapsed_ms, _elapsed_ms} = Game.tick(game)
    :timer.sleep(10)
    
    Game.show(game)
    :timer.sleep(10)

    Game.say_player_shot_ship(game, 17, 10)
    :timer.sleep(10)
    {:elapsed_ms, _elapsed_ms} = Game.tick(game)

    Game.show(game)
    :timer.sleep(10)

    state = Game.state(game)

    [player_9_tag,_,_,_,_,_] = hd(state.s)
    [player_10_tag,_,_,_,_,_] = hd(tl(state.s))

    assert player_9_tag == state.kby[player_10_tag]
  end

end
