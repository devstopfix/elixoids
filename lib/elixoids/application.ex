defmodule Elixoids.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = [
      {Registry, keys: :duplicate, name: Registry.Elixoids.News}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
