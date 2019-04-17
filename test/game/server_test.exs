defmodule Game.ServerTest do
  use ExUnit.Case, async: false
  doctest Game.Server

  alias Bullet.Server, as: Bullet
  alias Game.Server, as: Game
  alias Elixoids.Game.Supervisor, as: GameSupervisor

  test "When we stop a bullet it is removed from game" do
    tag = "DUD"
    {:ok, game, game_id} = GameSupervisor.start_game(fps: 8, asteroids: 1)
    {:ok, _game_pid, _ship_id} = Game.spawn_player(game, tag)

    {:ok, bullet_pid} = Bullet.start_link(game_id, tag, %{x: 0, y: 0}, 0.0)
    Game.bullet_fired(game_id, bullet_pid)

    :timer.sleep(100)

    state = Game.state(game)

    assert 1 == Enum.count(state.b)

    Process.exit(bullet_pid, :normal)

    # TODO
    # :timer.sleep(1000)

    # state2 = Game.state(game)

    # Game.show(game)
    # assert Enum.empty?(state2.b)

    Process.exit(game, :normal)
  end

  test "We can retrieve game state of Asteroids" do
    {:ok, game, _game_id} = GameSupervisor.start_game(fps: 2, asteroids: 2)
    :timer.sleep(200)
    game_state = Game.state(game)
    assert [_, _, _, 120.0] = List.first(game_state[:a])
    Process.exit(game, :normal)
  end

  test "We can retrieve game state of Ships" do
    {:ok, game, _game_id} = GameSupervisor.start_game(fps: 2, asteroids: 2)
    Game.spawn_player(game, "AST")
    :timer.sleep(200)

    Game.show(game)
    game_state = Game.state(game)
    assert [_, _, _, 20.0, _, "FFFFFF"] = List.first(game_state[:s])

    Process.exit(game, :normal)
  end

  test "Games get different ids and pids" do
    {:ok, game1, game1_id} = GameSupervisor.start_game(fps: 1, asteroids: 1)
    {:ok, game2, game2_id} = GameSupervisor.start_game(fps: 2, asteroids: 2)
    assert game2_id != game1_id
    assert game1 != game2
  end

  test "We can retrieve viewport dimensions from game state" do
    {:ok, game, _game_id} = GameSupervisor.start_game(fps: 60, asteroids: 1)
    :timer.sleep(10)
    game_state = Game.state(game)
    assert 4000.0 == List.first(game_state.dim)
    assert 2250.0 == List.last(game_state.dim)
    Process.exit(game, :normal)
  end

  # test "We record who shot a player" do
  #   {:ok, game, _game_id} = GameSupervisor.start_game(fps: 60, asteroids: 1)
  #   :timer.sleep(10)

  #   # {:elapsed_ms, _elapsed_ms} = Game.tick(game)
  #   :timer.sleep(10)

  #   Game.ship_fires_bullet(game, 9)
  #   :timer.sleep(10)

  #   {:elapsed_ms, _elapsed_ms} = Game.tick(game)
  #   :timer.sleep(10)

  #   :timer.sleep(10)

  #   Game.say_player_shot_ship(game, 17, 10)
  #   :timer.sleep(10)
  #   {:elapsed_ms, _elapsed_ms} = Game.tick(game)

  #   :timer.sleep(10)

  #   state = Game.state(game)

  #   [player_9_tag,_,_,_,_,_] = hd(state.s)
  #   [player_10_tag,_,_,_,_,_] = hd(tl(state.s))

  #   assert player_9_tag == state.kby[player_10_tag]

  #   ship_state = Game.state_of_ship(game, player_10_tag)
  #   assert player_9_tag == ship_state.kby
  # end

  # test "We can filter on ship id" do
  #   ships = %{
  #     9 => {9, "VOI", 1464.0, 416.0, 20.0, 1.5612, "FFFFFF"},
  #     10 => {10, "CXN", 1704.0, 1555.0, 20.0, 1.3603, "FFFFFF"},
  #     15 => {15, "SYX", 2612.0, 933.0, 20.0, 0.7888, "FFFFFF"},
  #     16 => {16, "IGA", 2065.0, 1446.0, 20.0, 2.7704, "FFFFFF"}
  #   }

  #   assert {15, "SYX", 2612.0, 933.0, 20.0, 0.7888, "FFFFFF"} == Game.only_ship(ships, "SYX")
  # end

  # test "We get nil for missing ship" do
  #   ships = %{
  #     9 => {9, "VOI", 1464.0, 416.0, 20.0, 1.5612, "FFFFFF"},
  #     10 => {10, "CXN", 1704.0, 1555.0, 20.0, 1.3603, "FFFFFF"},
  #     15 => {15, "SYX", 2612.0, 933.0, 20.0, 0.7888, "FFFFFF"},
  #     16 => {16, "IGA", 2065.0, 1446.0, 20.0, 2.7704, "FFFFFF"}
  #   }

  #   assert nil == Game.only_ship(ships, "UKN")
  # end

  # test "We can filter out ship id" do
  #   ships = [
  #     {9, "VOI", 1464.0, 416.0, 20.0, 1.5612, "FFFFFF"},
  #     {14, "LPE", 1797.0, 1067.0, 20.0, 2.0466, "FFFFFF"},
  #     {15, "SYX", 2612.0, 933.0, 20.0, 0.7888, "FFFFFF"},
  #     {16, "IGA", 2065.0, 1446.0, 20.0, 2.7704, "FFFFFF"}
  #   ]

  #   assert [
  #            {9, "VOI", 1464.0, 416.0, 20.0, 1.5612, "FFFFFF"},
  #            {14, "LPE", 1797.0, 1067.0, 20.0, 2.0466, "FFFFFF"},
  #            {16, "IGA", 2065.0, 1446.0, 20.0, 2.7704, "FFFFFF"}
  #          ] == Game.ships_except(ships, "SYX")
  # end

  # test "We can find ship state by tag" do
  #   assert Game.ship_state_has_tag({15, "SYX", 2612.0, 933.0, 20.0, 0.7888, "FFFFFF"}, "SYX")
  # end

  # test "We do not find missing ship state by tag" do
  #   refute Game.ship_state_has_tag({9, "VOI", 1464.0, 416.0, 20.0, 1.5612, "FFFFFF"}, "XXX")
  # end
end
