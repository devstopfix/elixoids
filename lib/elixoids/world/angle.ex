defmodule Elixoids.World.Angle do
  @moduledoc "Angle in Radians"

  @type t :: number()

  # 360º
  @pi2_radians 2 * :math.pi()

  @doc "Keep angle between 0..2π"
  @spec normalize_radians(number()) :: float()
  def normalize_radians(theta) when theta < 0.0, do: theta + @pi2_radians
  def normalize_radians(theta) when theta > @pi2_radians, do: theta - @pi2_radians
  def normalize_radians(theta), do: theta

  def random_angle, do: :rand.uniform() * @pi2_radians

  def turn_positive?(theta, target_theta) do
    :math.fmod(target_theta - theta + @pi2_radians, @pi2_radians) > :math.pi()
  end

  def valid_theta?(theta) do
    theta >= -@pi2_radians && theta <= @pi2_radians
  end
end
