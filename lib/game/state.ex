defmodule Game.State do

  @moduledoc """
  Functions that operate on game state.
  """

  @doc """
  Deduplicate events in current state that were
  transmitted in previous state.

  e.g. explosions only need to be sent once

  Returns 'current' state with events removed
  """
  def deduplicate(current, prev) do
    %{}
  end

  @doc """
  Remove items found in prev from current
  """
  def deduplicate_list(current, prev) do
    current
  end

end