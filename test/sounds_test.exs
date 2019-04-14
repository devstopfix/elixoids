defmodule Elixoids.SoundsTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Game.Server, as: Game
  import World.Clock

  test "When a player shoots we receive a sound event" do
    start_of_game = now_ms()
    tag = "FIR"
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 1)

    # TODO publish events to correct game News.subscribe(game_id)
    News.subscribe(0)

    :ok = Game.spawn_player(game, tag)

    :ok = Game.player_pulls_trigger(game_id, tag)

    assert_receive {:news, fire_msg}, 100
    assert String.contains?(fire_msg, tag)
    assert String.contains?(fire_msg, "fires")
    assert_receive {:audio, %{snd: "f", gt: gt, pan: pan}}, 100

    assert pan >= -1.0
    assert pan <= 1.0
    assert gt >= start_of_game

    Process.exit(game, :normal)
  end
end
