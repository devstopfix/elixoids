defmodule Game.StateTest do
  use ExUnit.Case, async: true
  doctest Game.State

  alias Game.State, as: State

  test "Deduplicate empty lists" do
    current = []
    prev = []

    assert [] == State.deduplicate_list(current, prev)
  end

  test "Do not deduplicate new items" do
    current = [1, 2, 3]
    prev = []

    assert [1, 2, 3] == State.deduplicate_list(current, prev)
  end

  test "Deduplicate lists" do
    current = [[-1], [2], [3]]
    prev = [[-1]]

    assert [[2], [3]] == State.deduplicate_list(current, prev)
  end

  test "Deduplicate explosions" do
    current = %{x: [1, 2], dim: [4000, 2000], b: []}
    prev = %{x: [1], dim: [4000, 2000]}
    assert %{x: [2], dim: [4000, 2000], b: []} == State.deduplicate(current, prev)
  end

  test "Initial game state has empty explosion list" do
    state = State.initial()
    assert Map.has_key?(state, :x)
    assert [] == state.x
  end
end
