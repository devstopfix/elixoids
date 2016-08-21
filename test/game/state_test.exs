defmodule Game.StateTest do
  use ExUnit.Case, async: true
  doctest Game.State

  alias Game.State, as: State

  test "Deduplicate lists" do
    current = [[-1], [2], [3]]
    prev = [[-1]]

    assert [[2], [3]] == State.deduplicate_list(current, prev)
  end

end
