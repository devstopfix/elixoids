defmodule Elixoids.Game.Zero do
  @moduledoc "Temporary zero game - used for default WS endpoints."

  use Supervisor

  @zero 0

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {Game.Server, game_id: @zero, asteroids: 8},
      {Elixoids.Collision.Server, @zero}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
