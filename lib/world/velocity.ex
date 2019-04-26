defmodule World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  alias World.Velocity, as: Velocity

  @type t :: %{theta: float(), speed: float()}

  defstruct theta: 0.0, speed: 0.0

  def north(speed \\ 0.0) do
    %Velocity{theta: :math.pi() / 2, speed: speed}
  end

  def east(speed \\ 0.0), do: %Velocity{theta: 0.0, speed: speed}

  def random_direction_with_speed(speed) do
    %Velocity{theta: random_direction(), speed: speed}
  end

  # 360º
  @two_pi_radians 2 * :math.pi()

  def random_direction, do: :rand.uniform() * :math.pi() * 2

  @doc """
  Double the speed component of Velocity
  """
  def double(v) do
    %{v | speed: v.speed * 2}
  end

  @doc """
  Change the direction by delta_thetaº clockwise
  """
  def fork(v, delta_theta) do
    theta = wrap_angle(v.theta + delta_theta)
    %{v | theta: theta}
  end

  @doc """
  Modify the angle by a small amount
  """
  def perturb(theta) do
    delta_theta = :rand.uniform() * :math.pi() / 24.0
    wrap_angle(theta + delta_theta)
  end

  @doc """
  Round angle to 3dp.
  TODO move to Angle
  """
  def round_theta(theta), do: Float.round(theta, 3)

  @doc """
  Keep angle theta between 0..2π
  """
  def wrap_angle(theta) do
    cond do
      theta < 0.0 -> theta + @two_pi_radians
      theta >= @two_pi_radians -> theta - @two_pi_radians
      true -> theta
    end
  end

  def valid_theta(theta) do
    theta >= -@two_pi_radians && theta <= @two_pi_radians
  end

  @doc """
  fmod returns the floating-point remainder of a / b
  # TODO call to Erlang fmod
  """
  def fmod(a, b) do
    a - Float.floor(a / b) * b
  end
end
