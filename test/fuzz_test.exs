defmodule Elixoids.FuzzTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Elixoids.Game.Server, as: Game
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.Server.WebsocketGameHandler
  alias Elixoids.Server.WebsocketNewsHandler
  alias Elixoids.Server.WebsocketShipHandler
  alias Elixoids.Server.WebsocketSoundHandler
  alias Elixoids.News
  import Jason

  @tag fuzz: true, iterations: 100
  property :sound_ws_ignores_input do
    {:ok, _game, game_id} = GameSupervisor.start_game(asteroids: 1)
    News.subscribe(game_id)

    for_all msg in ws_input() do
      assert {:ok, []} == WebsocketSoundHandler.websocket_handle(msg, [])
    end
  end

  @tag fuzz: true, iterations: 100
  property :game_ws_ignores_input do
    {:ok, _game, game_id} = GameSupervisor.start_game(asteroids: 1)
    News.subscribe(game_id)

    for_all msg in ws_input() do
      assert {:ok, []} == WebsocketGameHandler.websocket_handle(msg, [])
    end
  end

  @tag fuzz: true, iterations: 1000
  property :game_ship_ignores_non_json_input do
    Process.flag(:trap_exit, true)
    {:ok, _game_pid, game_id} = GameSupervisor.start_game(asteroids: 0)
    {:ok, ship_pid, ship_id} = Game.spawn_player(game_id, "BIN")
    News.subscribe(game_id)

    ws_state = %{ship_id: ship_id}

    for_all msg in ws_text_input() do
      case WebsocketShipHandler.websocket_handle(msg, ws_state) do
        {:reply, _, _} -> assert Process.alive?(ship_pid)
        {:stop, _} -> assert Process.alive?(ship_pid)
        _other -> assert_receive {:EXIT, :badarg, _}, 100
      end
    end
  end

  @tag fuzz: true, iterations: 1000
  property :game_ship_handles_json_input do
    {:ok, _game_pid, game_id} = GameSupervisor.start_game(asteroids: 0)
    {:ok, ship_pid, ship_id} = Game.spawn_player(game_id, "BIN")
    News.subscribe(game_id)

    ws_state = %{ship_id: ship_id}

    for_all msg in ws_json_input() do
      assert {:ok, ws_state} == WebsocketShipHandler.websocket_handle(msg, ws_state)
      assert Process.alive?(ship_pid)
    end
  end

  @tag fuzz: true, iterations: 1000
  property :game_ship_handles_player_json_input do
    {:ok, _game_pid, game_id} = GameSupervisor.start_game(asteroids: 0)
    {:ok, ship_pid, ship_id} = Game.spawn_player(game_id, "BIN")
    News.subscribe(game_id)

    ws_state = %{ship_id: ship_id}

    for_all msg in ws_player_input() do
      assert {:ok, ws_state} == WebsocketShipHandler.websocket_handle(msg, ws_state)
      assert Process.alive?(ship_pid)
    end
  end

  defp ws_text_input,
    do:
      [unicode_string(), unicode_binary()]
      |> oneof
      |> bind(fn x -> {:text, x} end)

  defp ws_input, do: oneof([ws_text_input(), binary()])

  defp ws_json_input,
    do:
      [
        %{},
        [],
        list(oneof([[], %{}])),
        vector(1, int()),
        vector(1, bool())
      ]
      |> oneof()
      |> bind(&encode!/1)
      |> bind(fn x -> {:text, x} end)

  defp ws_player_input,
    do:
      list(input())
      |> bind(&Map.new/1)
      |> bind(&encode!/1)
      |> bind(fn x -> {:text, x} end)

  defp input, do: [gen_key(), gen_value()] |> bind(fn [k, v] -> {k, v} end)

  defp gen_key, do: [gen_good_key(), gen_other_key()] |> oneof

  defp gen_good_key, do: ["theta", "fire"] |> oneof

  defp gen_other_key,
    do: ~w(foo bar baz qux quux quuz corge grault garply waldo fred plugh xyzzy thud) |> oneof

  defp gen_value,
    do:
      [
        gen_possible_value(),
        gen_other_value()
      ]
      |> oneof()

  defp gen_possible_value,
    do:
      [
        float(),
        bool()
      ]
      |> oneof()

  defp gen_other_value,
    do:
      [
        int(),
        float(),
        bool(),
        short_list(),
        oneof([%{}]),
        unicode_string()
      ]
      |> oneof()

  defp short_list, do: vector(1, oneof([bool(), int(), float()]))
end
