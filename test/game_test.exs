defmodule Elixoids.Game.ServerTest do
  use ExUnit.Case, async: false

  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.News
  import Elixoids.Const, only: [asteroid_radius_m: 0, world_width_m: 0]

  test "We can retrieve game state of Asteroids" do
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 2)
    # TODO this can be achieved with a pub/sub?
    :timer.sleep(200)
    game_state = Game.state(game_id)
    r = asteroid_radius_m()
    assert %{radius: ^r} = List.first(game_state[:a])
    Process.exit(game, :normal)
  end

  test "We can retrieve game state for UI" do
    tag = "AST"
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: 2)
    Game.spawn_player(game_id, tag)
    :timer.sleep(200)

    game_state = Game.state(game_id)
    assert %{tag: ^tag, radius: 20.0} = List.first(game_state[:s])

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
    assert world_width_m() == List.first(game_state.dim)
    assert 2250.0 == List.last(game_state.dim)
    Process.exit(game, :normal)
  end

  test "We do spawn asteroid" do
    min_asteroid_count = 2
    {:ok, game, game_id} = GameSupervisor.start_game(asteroids: min_asteroid_count)
    {:ok, _} = News.subscribe(game_id)

    Game.check_next_wave(%{
      min_asteroid_count: min_asteroid_count,
      info: %{id: game_id},
      game_id: game_id,
      state: %{asteroids: %{self() => %{}}}
    })

    assert_receive {:news, "ASTEROID spotted"}, 100
    assert Process.exit(game, :normal)
  end
end
