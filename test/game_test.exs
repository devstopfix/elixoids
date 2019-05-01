defmodule Elixoids.Game.ServerTest do
  use ExUnit.Case, async: false

  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Game.Supervisor, as: GameSupervisor

  test "We can retrieve game state of Asteroids" do
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 2)
    :timer.sleep(200)
    game_state = Game.state(game_id)
    assert %{radius: 120.0} = List.first(game_state[:a])
    Process.exit(game, :normal)
  end

  test "We can retrieve game state for UI" do
    tag = "AST"
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 2)
    Game.spawn_player(game_id, tag)
    :timer.sleep(200)

    game_state = Game.state(game_id)
    assert %{tag: tag, radius: 20.0} = List.first(game_state[:s])

    Process.exit(game, :normal)
  end

  test "Games get different ids and pids" do
    {:ok, game1, game1_id} = GameSupervisor.start_game(asteroids: 1)
    {:ok, game2, game2_id} = GameSupervisor.start_game(asteroids: 2)
    assert game2_id != game1_id
    assert game1 != game2
  end

  test "We can retrieve viewport dimensions from game state" do
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 1)
    :timer.sleep(10)
    game_state = Game.state(game_id)
    assert 4000.0 == List.first(game_state.dim)
    assert 2250.0 == List.last(game_state.dim)
    Process.exit(game, :normal)
  end

  test "We do not spawn asteroid" do
    {:ok, game, _game_id} = GameSupervisor.start_game(asteroids: 1)

    next_state = Game.check_next_wave(%{min_asteroid_count: 1, state: %{asteroids: %{1 => %{}}}})

    assert 1 == next_state.min_asteroid_count
    assert [1] == Map.keys(next_state.state.asteroids)
    assert Process.exit(game, :normal)
  end

  test "We do spawn asteroid" do
    min_asteroid_count = 2
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: min_asteroid_count)

    info = %{id: game_id}

    # next_state =
    Game.check_next_wave(%{
      min_asteroid_count: min_asteroid_count,
      info: info,
      state: %{asteroids: %{1 => %{}}}
    })

    # Process.sleep(100)

    # TODO how to test this as it is async: assert 2 == next_state.state.asteroids |> Map.keys() |> length
    # TODO add a news event "ASTEROID spotted"
    # TODO fix wave assert min_asteroid_count + 1 == next_state.min_asteroid_count
    assert Process.exit(game, :normal)
  end
end
