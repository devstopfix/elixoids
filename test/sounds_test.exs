defmodule Elixoids.SoundsTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Elixoids.Api.Sound.Protocol, as: SoundProtocol
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship

  test "When a player shoots we receive a sound event" do
    tag = "FIR"
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 1)

    News.subscribe(game_id)

    {:ok, _, ship_id} = Game.spawn_player(game_id, tag)

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

  test "We can encode sound events as Protobuf" do
    assert <<10, 0, 10, 8, 21, 205, 204, 76, 63, 24, 145, 78>> ==
             SoundProtocol.encode([
               %{snd: "f", pan: 0.0, gt: 0},
               %{snd: "x", pan: 0.8, gt: 10001}
             ])
  end
end
