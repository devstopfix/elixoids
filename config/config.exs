import Config

config :elixoids,
  asteroid_radius_m: 120.0,
  bullet_range_m: 2000.0,
  cowboy_port: 8065,
  fps: 60,
  initial_asteroids: 12,
  max_inflight_bullets: 4,
  max_shields: 3,
  player_fps: 4,
  saucer_direction_change_interval: 1_000,
  saucer_interval_ms: 16_000,
  saucer_shooting_interval: 200,
  saucer_speed_m_per_s: 240.0,
  ship_radius_m: 20.0

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true

#     import_config "#{Mix.env}.exs"
