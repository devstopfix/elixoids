defmodule Elixoids.ResilianceTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Asteroid.Server, as: Asteroid
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.World.Point
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship

  test "When asteroid exits the game continues" do
    Process.flag(:trap_exit, true)
    {:ok, game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)
    {:ok, asteroid_pid} = Asteroid.start_link(%{id: game_id})
    Process.sleep(10)
    assert Process.alive?(asteroid_pid)
    Process.exit(asteroid_pid, :kill)

    assert_receive {:EXIT, asteroid_pid, :killed}, 500
    refute Process.alive?(asteroid_pid)
    assert Process.alive?(game_pid)
  end

  test "When bullet exits the game continues" do
    tag = "FIR"
    Process.flag(:trap_exit, true)
    {:ok, game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)
    {:ok, ship_pid, ship_id} = Game.spawn_player(game_id, tag)
    {:ok, bullet_pid} = Bullet.Server.start_link(0, tag, %Point{}, 1.0)

    assert Process.alive?(bullet_pid)
    Process.exit(bullet_pid, :kill)

    assert_receive {:EXIT, bullet_pid, :killed}, 100
    refute Process.alive?(bullet_pid)
    assert Process.alive?(ship_pid)
    assert Process.alive?(game_pid)
  end

  test "When ship exits the bullet and game continues" do
    tag = "FIR"
    Process.flag(:trap_exit, true)
    {:ok, game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)
    {:ok, ship_pid, ship_id} = Game.spawn_player(game_id, tag)
    {:ok, bullet_pid} = Bullet.Server.start_link(0, tag, %Point{}, 1.0)

    assert Process.alive?(bullet_pid)
    Process.exit(ship_pid, :kill)

    refute Process.alive?(ship_pid)
    assert Process.alive?(bullet_pid)
    assert Process.alive?(game_pid)
  end

  test "When Collision process exits the game continues" do
    {:ok, game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)

    [{collision_pid, _}] = Registry.lookup(Registry.Elixoids.Collisions, {game_id})
    Process.exit(collision_pid, :kill)

    assert Process.alive?(game_pid)
    refute Process.alive?(collision_pid)
    Process.sleep(100)

    [{collision2_pid, _}] = Registry.lookup(Registry.Elixoids.Collisions, {game_id})
    assert collision2_pid != collision_pid
    Process.exit(game_pid, :shutdown)
    Process.sleep(100)
    # TODO link collision and game process refute Process.alive?(collision2_pid)
  end

  # TODO test "When game ends, collision process ends" do
  #   {:ok, game_pid, game_id} = GameSupervisor.start_game(asteroids: 1)

  #   Process.sleep(100)
  #   assert Process.alive?(game_pid)

  #   [{collision_pid, _}] = Registry.lookup(Registry.Elixoids.Collisions, {game_id})
  #   Process.exit(game_pid, :kill)
  #   Process.sleep(100)
  #   refute Process.alive?(game_pid)
  #   refute Process.alive?(collision_pid)
  # end
end
