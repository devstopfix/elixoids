import Config

large_saucer = %{
  direction_change_interval: 1_000,
  radar_range: 1200.0,
  radius: 20.0 * (2.0 * 20 / 13.0),
  rotation_rate_rad_per_sec: :math.pi() * 2,
  saucer_radar_range: 1000.0,
  shooting_interval: 500,
  speed_m_per_s: 240.0
}

small_saucer = %{large_saucer | radius: 20.0 * (10.0 / 13.0)}

config :elixoids,
  asteroid_radius_m: 120.0,
  bullet_range_m: 2000.0,
  cowboy_port: 8065,
  fps: 60,
  initial_asteroids: 8,
  max_inflight_bullets: 4,
  max_shields: 3,
  player_fps: 4,
  saucers: [large_saucer, small_saucer],
  saucer_interval_ms: 15_000,
  ship_radius_m: 20.0,
  ship_rotation_rate_rad_per_sec: :math.pi() * 2 / 3.0

import_config "#{Mix.env()}.exs"
