defmodule Elixoids.ExplosionTest do
  use ExUnit.Case, async: true

  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  alias Elixoids.Game.Server, as: Game

  test "Explosion hard left" do
    pos = %{x: 0.0, y: 2.0}
    {:ok, pid, game_id} = GameSupervisor.start_game(asteroids: 2)
    {:ok, _} = News.subscribe(game_id)

    Game.explosion(game_id, pos, 100.0)
    assert_receive {:explosion, %Elixoids.Explosion.Location{x: 0.0, y: 2.0}}, 500
    assert_receive {:audio, %Elixoids.Api.SoundEvent{pan: -1.0, size: 100, snd: "x"}}, 500

    Process.exit(pid, :normal)
  end

  test "Explosion hard right" do
    pos = %{x: 4000.0, y: 2.0}
    {:ok, pid, game_id} = GameSupervisor.start_game(asteroids: 2)
    {:ok, _} = News.subscribe(game_id)

    Game.explosion(game_id, pos, 101.0)
    assert_receive {:explosion, %Elixoids.Explosion.Location{x: 4.0e3, y: 2.0}}, 500
    assert_receive {:audio, %Elixoids.Api.SoundEvent{pan: 1.0, size: 101, snd: "x"}}, 500

    Process.exit(pid, :normal)
  end
end
