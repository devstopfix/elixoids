defmodule Elixoids.PlayerTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Elixoids.Player, as: Player
  alias Elixoids.Ship.Server, as: Ship
  alias Game.Server, as: Game

  test "Valid player tags" do
    assert Player.valid_player_tag?("AAA")
    assert Player.valid_player_tag?("ZZZ")
  end

  test "Invalid player tags" do
    refute Player.valid_player_tag?("AA")
    refute Player.valid_player_tag?("ZZZZ")
    refute Player.valid_player_tag?("A1A")
  end

  test "Two players with can connect" do
    tag1 = "ALC"
    tag2 = "BOB"
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 0)

    News.subscribe(game_id)

    {:ok, pid1, ship1_id} = Game.spawn_player(game_id, tag1)
    {:ok, pid2, ship2_id} = Game.spawn_player(game_id, tag2)

    :ok = Ship.player_pulls_trigger(ship1_id)
    :ok = Ship.player_pulls_trigger(ship2_id)

    assert_receive {:news, "ALC fires"}, 100
    assert_receive {:news, "BOB fires"}, 100

    Process.exit(pid2, :shutdown)
    Process.exit(pid1, :shutdown)
    Process.exit(game, :shutdown)
  end
end
