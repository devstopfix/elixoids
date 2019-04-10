defmodule Elixoids.News do
  @moduledoc """
  Allow games to broadcast game events to subscribers.

  The subscriber may produce score table, statistics etc
  """

  def subscribe(game_id) when is_integer(game_id) do
    {:ok, _} = Registry.register(Registry.Elixoids.News, key(game_id), true)
  end

  def publish(game_id, news) when is_integer(game_id) do
    :ok =
      Registry.dispatch(Registry.Elixoids.News, key(game_id), fn pids ->
        for {pid, _} <- pids, do: send(pid, {:news, news})
      end)
  end

  defp key(game_id), do: {:game, game_id}
end
