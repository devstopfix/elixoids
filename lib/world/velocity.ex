defmodule World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  alias World.Velocity, as: Velocity

  @two_pi_radians (2 * :math.pi)

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
    %Velocity{theta: random_direction(), speed: speed}
  end

  def random_direction do
    (:rand.uniform * :math.pi * 2)
  end

  @doc """
  Round angle to 4dp.
  """
  def round_theta(theta) do
    Float.round(theta, 4)
  end

  @doc """
  Keep angle theta between 0..2π
  """
  def wrap_angle(theta) do
    cond do
      (theta < 0.0)              -> (theta + @two_pi_radians)
      (theta >= @two_pi_radians) -> (theta - @two_pi_radians)
      true                       -> theta
    end
  end

end
