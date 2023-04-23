defmodule Elixoids.Application do
  @moduledoc false

  use Application
  @port Application.compile_env!(:elixoids, :cowboy_port)

  def start(_start_type, _start_args) do
    children = [
      {Registry, name: Registry.Elixoids.Collisions, keys: :unique},
      {Registry, name: Registry.Elixoids.Games, keys: :unique},
      {Registry, name: Registry.Elixoids.News, keys: :duplicate},
      {Registry, name: Registry.Elixoids.Ships, keys: :unique},
      {Elixoids.Api, [port: @port]},
      Elixoids.Collision.Supervisor,
      Elixoids.Game.Supervisor,
      Elixoids.Game.Zero,
      Elixoids.Saucer.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
