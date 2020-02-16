import Config

config :elixoids,
  cowboy_port: 8065,
  asteroid_radius_m: 120.0,
  bullet_range_m: 2000.0,
  ship_radius_m: 20.0,
  initial_asteroids: 8

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true

#     import_config "#{Mix.env}.exs"
