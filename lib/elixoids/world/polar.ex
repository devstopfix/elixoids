defmodule Elixoids.World.Polar do
  @moduledoc "A polar co-ordinate. Angle in radians and distance in meters"

  @type angle :: float()
  @type distance :: float()

  @type t :: %{theta: angle(), distance: distance()}

  defstruct theta: 0.0, distance: 0.0

  alias Elixoids.World.Point
  alias Elixoids.World.RoundDP
  alias World.Velocity

  @spec subtract(Point.t(), Point.t()) :: t()
  def subtract(p1, p0) do
    d = Point.distance_between(p0, p1)
    theta = :math.atan2(p1.y - p0.y, p1.x - p0.x) |> Velocity.wrap_angle()
    %__MODULE__{theta: theta, distance: d}
  end

  defimpl RoundDP, for: __MODULE__ do
    @doc "Round angle to 3dp and distance to centimeters"
    def round_dp(%{theta: theta, distance: distance} = p),
      do: %{p | theta: Float.round(theta, 3), distance: Float.round(distance, 2)}
  end
end
