defmodule Elixoids.Ship.Rotate do
  @moduledoc "Rotate a ship towards a target angle"

  import Elixoids.World.Angle, only: [normalize_radians: 1, turn_positive?: 2]

  @doc """
  Rotate the ship from it's current theta towards it's
  intended delta_theta - but clip the rate of rotation
  by the time elapsed since the last frame.
  """
  def rotate_ship(ship, delta_t_ms) do
    case ship do
      %{target_theta: target_theta, theta: theta, rotation_rate: rotation_rate_per_sec} ->
        new_theta = calculate_theta(theta, target_theta, rotation_rate_per_sec, delta_t_ms)
        %{ship | :theta => new_theta}

      %{
        target_theta: target_theta,
        velocity: %{theta: theta} = v,
        rotation_rate: rotation_rate_per_sec
      } ->
        new_theta = calculate_theta(theta, target_theta, rotation_rate_per_sec, delta_t_ms)
        new_v = %{v | theta: new_theta}
        %{ship | velocity: new_v}
    end
  end

  defp calculate_theta(theta, target_theta, rotation_rate_per_sec, delta_t_ms) do
    delta_theta = clip_delta_theta(abs(target_theta - theta), delta_t_ms, rotation_rate_per_sec)

    if turn_positive?(target_theta, theta),
      do: normalize_radians(theta + delta_theta),
      else: normalize_radians(theta - delta_theta)
  end

  defp clip_delta_theta(delta_theta, delta_t_ms, rotation_rate_per_sec) do
    max_theta = rotation_rate_per_sec * delta_t_ms / 1000.0

    if delta_theta > max_theta do
      max_theta
    else
      delta_theta
    end
  end
end
