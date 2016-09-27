defmodule Elixoids.PlayerTest do
  use ExUnit.Case, async: true
  doctest Elixoids.Player

  alias Elixoids.Player, as: Player

  test "Valid player tags" do
    assert Player.valid_player_tag?("AAA")
    assert Player.valid_player_tag?("ZZZ")
  end

  test "Invalid player tags" do
    refute Player.valid_player_tag?("AA")
    refute Player.valid_player_tag?("ZZZZ")
    refute Player.valid_player_tag?("A1A")
  end

end
