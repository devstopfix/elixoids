defmodule Elixoids.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = [
      {Registry, name: Registry.Elixoids.Collisions, keys: :unique},
      {Registry, name: Registry.Elixoids.Games, keys: :unique},
      {Registry, name: Registry.Elixoids.News, keys: :duplicate},
      {Registry, name: Registry.Elixoids.Ships, keys: :unique},
      Elixoids.Api,
      Elixoids.Collision.Supervisor,
      Elixoids.Game.Supervisor,
      # TODO remove game zero #32
      {Game.Server, [game_id: 0, fps: 24, asteroids: 4]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
