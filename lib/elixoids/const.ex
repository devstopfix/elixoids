defmodule Elixoids.Const do
  @moduledoc """
  Game constants.
  """

  @app :elixoids

  # 4km
  def world_width_m, do: 4000.0

  def world_ratio, do: 16.0 / 9.0

  def initial_asteroids, do: Application.get_env(@app, :initial_asteroids, 8)

  # Largest initial asteroid
  @asteroid_radius_m Application.compile_env!(@app, :asteroid_radius_m)
  def asteroid_radius_m, do: @asteroid_radius_m

  # Initial speed of asteroid
  def asteroid_speed_m_per_s, do: 20.0

  # Smallest asteroid that can survive being hit
  def splittable_radius_m, do: 20.0

  @bullet_range_m Application.compile_env!(@app, :bullet_range_m)
  @bullet_speed_m_per_s Application.compile_env!(@app, :bullet_speed_m_per_s)
  def bullet_range_m, do: @bullet_range_m
  def bullet_speed_m_per_s, do: @bullet_speed_m_per_s

  @ms_in_s 1_000
  def fly_time_ms, do: trunc(bullet_range_m() / bullet_speed_m_per_s() * @ms_in_s)

  # Ship radius (m)
  @ship_radius_m Application.compile_env!(@app, :ship_radius_m)
  def ship_radius_m, do: @ship_radius_m

  # Minimum time between shots
  @laser_recharge_ms Application.compile_env!(@app, :ship_laser_recharge_ms)
  def laser_recharge_ms, do: @laser_recharge_ms
  def laser_recharge_penalty_ms, do: laser_recharge_ms() * 2

  def max_inflight_bullets, do: Application.get_env(@app, :max_inflight_bullets)
  def max_shields, do: Application.get_env(@app, :max_shields)

  # The spawn point of a bullet
  def nose_radius_m, do: ship_radius_m() * 1.05

  @spec ws_idle_timeout :: 3_600_000
  def ws_idle_timeout, do: 1 * 60 * 60 * 1000

  def saucers, do: Application.get_env(@app, :saucers, [])

  def saucer_interval_ms, do: Application.get_env(@app, :saucer_interval_ms)

  def saucer_tag, do: "SČR"

  @ship_rotation_rate_rad_per_sec Application.compile_env!(@app, :ship_rotation_rate_rad_per_sec)
  def ship_rotation_rate_rad_per_sec, do: @ship_rotation_rate_rad_per_sec
end
