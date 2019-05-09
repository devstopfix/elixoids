defmodule Elixoids.SoundsTest do
  use ExUnit.Case, async: true

  alias Elixoids.Api.Sound, as: SoundProtocol
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Elixoids.Ship.Server, as: Ship
  alias Elixoids.Game.Server, as: Game

  test "When a player shoots we receive a sound event" do
    tag = "FIR"
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 1)

    News.subscribe(game_id)

    {:ok, _, ship_id} = Game.spawn_player(game_id, tag)

    :ok = Ship.player_pulls_trigger(ship_id)

    assert_receive {:news, fire_msg}, 100
    assert String.contains?(fire_msg, tag)
    assert String.contains?(fire_msg, "fires")
    assert_receive {:audio, %{snd: "f", pan: pan}}, 100

    assert pan >= -1.0
    assert pan <= 1.0

    Process.exit(game, :normal)
  end

  test "We can encode short sound events as Protobuf" do
    assert <<21, 205, 204, 204, 61>> ==
             SoundProtocol.encode(%{snd: "f", pan: 0.1, size: 0})
  end

  test "We can encode sound events as Protobuf" do
    assert <<8, 1, 21, 102, 102, 102, 63, 24, 120>> ==
             SoundProtocol.encode(%{snd: "x", pan: 0.9, size: 120})
  end
end
