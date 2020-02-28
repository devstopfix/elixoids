defmodule Elixoids.World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  @type angle :: number()
  @type speed :: number()

  @type t :: %{theta: angle(), speed: speed()}

  defstruct theta: 0.0, speed: 0.0

  alias Elixoids.World.Angle
  alias Elixoids.World.Point
  import Elixoids.World.Angle

  def north(speed \\ 0.0), do: %__MODULE__{theta: :math.pi() / 2, speed: speed}

  def east(speed \\ 0.0), do: %__MODULE__{theta: 0.0, speed: speed}

  def west(speed \\ 0.0), do: %__MODULE__{theta: :math.pi(), speed: speed}

  def random_velocity(speed), do: %__MODULE__{theta: random_angle(), speed: speed}

  def double_speed(%{speed: speed} = v), do: %{v | speed: speed * 2.0}

  @spec rotate(t(), Angle.t()) :: __MODULE__.t()
  def rotate(%{theta: theta} = v, delta_theta),
    do: %{v | theta: normalize_radians(theta + delta_theta)}

  @ms_in_s 1000.0

  @spec apply_velocity(Point.t(), __MODULE__.t(), number()) :: Point.t()
  def apply_velocity(p, %{theta: theta, speed: speed}, delta_t_ms) do
    dx = :math.cos(theta) * speed * delta_t_ms / @ms_in_s
    dy = :math.sin(theta) * speed * delta_t_ms / @ms_in_s
    Point.translate(p, dx, dy)
  end
end
