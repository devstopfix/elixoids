defmodule Elixoids.Player do
  
  @moduledoc """
  Functions specific to a player.
  """

  @doc """
  Random 3-char player name (AAA..ZZZ)
  """
  def random_tag do
    ?A..?Z |> Enum.to_list |> Enum.take_random(3) |> to_string
  end
 
  @doc """
  Is given tag a valid player name?
  """
  def valid_player_tag?(tag) do
    Regex.match?(~r/^[A-Z]{3}$/, tag)
  end

end
