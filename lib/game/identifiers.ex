defmodule Game.Identifiers do

  def next_id() do
    System.unique_integer([:positive])
  end

end
