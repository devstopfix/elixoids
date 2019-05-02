defmodule Elixoids.BulletTest do
  use ExUnit.Case, async: false

  alias Elixoids.Bullet.Server, as: Bullet
  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.World.Point
  import Elixoids.World.Clock

  @max_bullet_flight_time 2999

  @tag :slow
  test "Bullet lives 2.6 seconds" do
    Process.flag(:trap_exit, true)
    tag = "FIR"
    {:ok, _game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)
    {:ok, _ship_pid, _ship_id} = Game.spawn_player(game_id, tag)

    start_t = now_ms()
    {:ok, bullet_pid} = Bullet.start_link(0, tag, %Point{}, 1.0)

    assert_receive {:EXIT, pid, :normal}, @max_bullet_flight_time

    elapsed_ms = now_ms() - start_t
    assert elapsed_ms >= 2500
    assert elapsed_ms <= @max_bullet_flight_time
    assert pid == bullet_pid
  end
end
