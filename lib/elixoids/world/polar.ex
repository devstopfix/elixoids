defmodule Elixoids.World.Polar do
  @moduledoc "A polar co-ordinate. Angle in radians and distance in meters"

  @type angle :: float()
  @type distance :: float()

  @type t :: %{theta: angle(), distance: distance()}

  defstruct theta: 0.0, distance: 0.0

  alias Elixoids.World.Point
  import Elixoids.World.Angle

  def subtract(p1, p0) do
    d = Point.distance_between(p0, p1)
    theta = :math.atan2(p1.y - p0.y, p1.x - p0.x) |> normalize_radians()
    %__MODULE__{theta: theta, distance: d}
  end
end
