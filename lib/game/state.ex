defmodule Game.State do
  @moduledoc """
  Functions that operate on game state.
  """

  @doc """
  Empty initial state for processes that track differences
  between frames
  """
  def initial do
    %{x: []}
  end

  @doc """
  Deduplicate events in current state that were
  transmitted in previous state.

  e.g. explosions only need to be sent once

  Returns 'current' state with events removed
  """
  def deduplicate(current, prev) do
    current
    |> Map.update!(:x, &deduplicate_list(&1, prev.x))
  end

  @doc """
  Remove items found in prev from current
  """
  def deduplicate_list(current, prev) do
    current
    |> MapSet.new()
    |> MapSet.difference(MapSet.new(prev))
    |> MapSet.to_list()
  end
end
