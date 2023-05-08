import Config

# The accuracy is a random normal value applied to the true bearing from saucer to target.
#   0.0  -> 1.000  Precise
#   0.0125         Leathal
#   0.25
#   0.05 -> 0.700
#   0.1  -> 0.400  Scatter gun

large_saucer = %{
  accuracy: 0.025,
  direction_change_interval: 1_000,
  radius: 20.0 * (2.0 * 20 / 13.0),
  rotation_rate_rad_per_sec: :math.pi() * 2,
  saucer_radar_range: 1500.0,
  shields: 3,
  shooting_interval: 500,
  speed_m_per_s: 240.0
}

small_saucer = %{
  large_saucer
  | accuracy: 0.0125,
    radius: 18.0,
    speed_m_per_s: 300.0,
    saucer_radar_range: 1000.0
}

warthog = %{large_saucer | shooting_interval: 125, radius: 30.0}

config :elixoids,
  asteroid_radius_m: 120.0,
  bullet_range_m: 2000.0,
  bullet_speed_m_per_s: 1250.0,
  cowboy_port: 8065,
  fps: 60,
  initial_asteroids: 8,
  max_inflight_bullets: 4,
  max_shields: 3,
  player_fps: 4,
  saucers: [large_saucer, large_saucer, small_saucer, large_saucer, warthog],
  saucer_interval_ms: 15_000,
  ship_laser_recharge_ms: 200,
  ship_radius_m: 20.0,
  ship_rotation_rate_rad_per_sec: :math.pi() * 2 / 3.0

import_config "#{Mix.env()}.exs"
