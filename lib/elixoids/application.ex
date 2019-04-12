defmodule Elixoids.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.Elixoids.News},
      {Registry, keys: :unique, name: Registry.Elixoids.Games},
      Elixoids.Game.Supervisor,
      Elixoids.Server,
      {Game.Server, [game_id: 0, fps: 24, asteroids: 4]} # TODO remove game zero
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
