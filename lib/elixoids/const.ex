defmodule Elixoids.Const do
  @moduledoc """
  Game constants.
  """

  @app :elixoids

  # 4km
  def world_width_m, do: 4000.0

  def world_ratio, do: 16.0 / 9.0

  def initial_asteroids, do: Application.get_env(@app, :initial_asteroids)

  # Largest initial asteroid
  @asteroid_radius_m Application.get_env(@app, :asteroid_radius_m)
  def asteroid_radius_m, do: @asteroid_radius_m

  # Initial speed of asteroid
  def asteroid_speed_m_per_s, do: 20.0

  # Smallest asteroid that can survive being hit
  def splittable_radius_m, do: 20.0

  @bullet_range_m Application.get_env(@app, :bullet_range_m)
  def bullet_range_m, do: @bullet_range_m
  def bullet_speed_m_per_s, do: 1250.0

  @ms_in_s 1_000
  def fly_time_ms, do: trunc(bullet_range_m() / bullet_speed_m_per_s() * @ms_in_s)

  # Ship radius (m)
  @ship_radius_m Application.get_env(@app, :ship_radius_m)
  def ship_radius_m, do: @ship_radius_m

  # Minimum time between shots
  def laser_recharge_ms, do: 200
  def laser_recharge_penalty_ms, do: laser_recharge_ms() * 2

  def max_inflight_bullets, do: Application.get_env(@app, :max_inflight_bullets)
  def max_shields, do: Application.get_env(@app, :max_shields)

  # The spawn point of a bullet
  def nose_radius_m, do: ship_radius_m() * 1.05

  def ws_idle_timeout, do: 1 * 60 * 60 * 1000

  def saucer_speed_m_per_s, do: Application.get_env(@app, :saucer_speed_m_per_s)

  def saucer_direction_change_interval,
    do: Application.get_env(@app, :saucer_direction_change_interval)

  def saucer_radius_large, do: Application.get_env(@app, :saucer_radius_large)

  def saucer_interval_ms, do: Application.get_env(@app, :saucer_interval_ms)

  @saucer_shooting_interval Application.get_env(@app, :saucer_shooting_interval)
  def saucer_shooting_interval, do: @saucer_shooting_interval

  @saucer_radar_range Application.get_env(@app, :saucer_radar_range)
  def saucer_radar_range, do: @saucer_radar_range

  def saucer_tag, do: "SČR"

  @ship_rotation_rate_rad_per_sec Application.get_env(@app, :ship_rotation_rate_rad_per_sec)
  def ship_rotation_rate_rad_per_sec, do: @ship_rotation_rate_rad_per_sec

  @saucer_rotation_rate_rad_per_sec Application.get_env(@app, :saucer_rotation_rate_rad_per_sec)
  def saucer_rotation_rate_rad_per_sec, do: @saucer_rotation_rate_rad_per_sec
end
