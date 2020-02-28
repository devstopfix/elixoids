import Config

config :elixoids,
  asteroid_radius_m: 120.0,
  bullet_range_m: 2000.0,
  cowboy_port: 8065,
  fps: 60,
  initial_asteroids: 2,
  max_inflight_bullets: 4,
  max_shields: 3,
  player_fps: 4,
  saucer_direction_change_interval: 1_000,
  saucer_interval_ms: 15_000,
  saucer_radius_large: 20.0 * (2.0 * 20 / 13.0),
  saucer_radius_small: 20.0 * (10.0 / 13.0),
  saucer_shooting_interval: 500,
  saucer_speed_m_per_s: 240.0,
  saucer_radar_range: 1200.0,
  saucer_rotation_rate_rad_per_sec: :math.pi() * 2,
  ship_radius_m: 20.0,
  ship_rotation_rate_rad_per_sec: :math.pi() * 2 / 3.0

import_config "#{Mix.env()}.exs"
