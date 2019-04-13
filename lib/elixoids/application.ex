defmodule Elixoids.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.Elixoids.News},
      {Registry, keys: :unique, name: Registry.Elixoids.Games},
      Elixoids.Api,
      Elixoids.Game.Supervisor,
      # TODO remove game zero #32
      {Game.Server, [game_id: 0, fps: 12, asteroids: 4]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
