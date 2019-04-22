defmodule Elixoids.Game.Info do
  @moduledoc """
  Information and functions about a game that can be
  used in dependent processes.
  """

  defstruct id: 0, time: nil

  def new(game_id, game_time) do
    %__MODULE__{id: game_id, time: game_time}
  end
end
