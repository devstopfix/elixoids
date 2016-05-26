defmodule World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  alias World.Velocity, as: Velocity

  defstruct theta: 0.0, speed: 0.0

  def north do
    %Velocity{theta: (:math.pi / 2)}
  end

  def west do
    %Velocity{theta: :math.pi}
  end

  def south do
    %Velocity{theta: (3 * :math.pi / 2)}
  end

  def east do
    %Velocity{theta: 0.0}
  end

  def random_direction_with_speed(speed) do
    %Velocity{theta: (:rand.uniform * :math.pi * 2), speed: speed}
  end

end