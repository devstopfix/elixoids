defmodule Elixoids.PlayerTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship

  test "Two players with same name can connect" do
    tag1 = "ACE"
    tag2 = "ACE"
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 0)

    News.subscribe(game_id)

    {:ok, pid1, ship1_id} = Game.spawn_player(game_id, tag1)
    {:ok, pid2, ship2_id} = Game.spawn_player(game_id, tag2)

    :ok = Ship.player_pulls_trigger(ship1_id)
    :ok = Ship.player_pulls_trigger(ship2_id)

    assert_receive {:news, "ACE fires"}, 100
    assert_receive {:news, "ACE fires"}, 100

    Process.exit(pid2, :shutdown)
    Process.exit(pid1, :shutdown)
    Process.exit(game, :shutdown)
  end
end
