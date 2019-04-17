defmodule Elixoids.SoundsTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship

  test "When a player shoots we receive a sound event" do
    tag = "FIR"
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 1)

    News.subscribe(game_id)

    {:ok, _, ship_id} = Game.spawn_player(game, tag)

    :ok = Ship.player_pulls_trigger(ship_id)

    assert_receive {:news, fire_msg}, 100
    assert String.contains?(fire_msg, tag)
    assert String.contains?(fire_msg, "fires")
    assert_receive {:audio, %{snd: "f", gt: gt, pan: pan}}, 100

    assert pan >= -1.0
    assert pan <= 1.0
    assert gt >= 0

    Process.exit(game, :normal)
  end
end
