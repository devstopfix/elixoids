defmodule Elixoids.World.Velocity do
  @moduledoc """
  Velocity is defined as a struct with two components:
  1) direction in radians anticlockwise from x-axis
  2) a speed in metres/second.
  """

  @type angle :: float()
  @type speed :: float()

  @type t :: %{theta: angle(), speed: speed()}

  defstruct theta: 0.0, speed: 0.0

  alias Elixoids.World.Angle
  alias Elixoids.World.RoundDP
  import Elixoids.World.Angle

  def north(speed \\ 0.0), do: %__MODULE__{theta: :math.pi() / 2, speed: speed}

  def east(speed \\ 0.0), do: %__MODULE__{theta: 0.0, speed: speed}

  def random_velocity(speed), do: %__MODULE__{theta: random_angle(), speed: speed}

  @doc "Double the speed component of Velocity"
  def double(%{speed: speed} = v), do: %{v | speed: speed * 2.0}

  @spec rotate(t(), Angle.t()) :: t()
  def rotate(%{theta: theta} = v, delta_theta),
    do: %{v | theta: normalize_radians(theta + delta_theta)}

  defimpl RoundDP, for: __MODULE__ do
    @doc "Round angle to 3dp"
    def round_dp(%{theta: theta} = v),
      do: %{v | theta: Float.round(theta, 3)}
  end
end
