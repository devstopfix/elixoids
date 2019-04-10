defmodule Game.Identifiers do
  @moduledoc false

  def next_id() do
    System.unique_integer([:positive])
  end
end
