defmodule Space do

  @moduledoc """
  Define the play area (world) in which the Game is played.
  All units are in metres.
  """

  # The ratio of the play area
  @ratio 16.0 / 9.0

  @width 4000.0 # 4km
  @height @width / @ratio

end