defmodule Elixoids.Game.Zero do
  @moduledoc "Zero game - always running."

  use Supervisor

  @zero 0

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: :game_zero)
  end

  def init(:ok) do
    children = [
      {Elixoids.Game.Server, game_id: @zero, asteroids: 8},
      {Elixoids.Collision.Server, @zero}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
