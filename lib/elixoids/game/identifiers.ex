defmodule Elixoids.Game.Identifiers do
  @moduledoc false

  def next_id, do: System.unique_integer([:positive])

  def next_game_id, do: System.unique_integer([:positive, :monotonic])
end
