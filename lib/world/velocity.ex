defmodule World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  defstruct theta: 0.0, speed: 0.0

end