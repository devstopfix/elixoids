defmodule Elixoids.Audio do
  @moduledoc """
  Allow games to broadcast audio events to subscribers.
  """

  def subscribe(game_id) when is_integer(game_id) do
    {:ok, _} = Registry.register(Registry.Elixoids.Audio, key(game_id), true)
  end

  def publish(game_id, sound) when is_integer(game_id) do
    :ok =
      Registry.dispatch(Registry.Elixoids.Audio, key(game_id), fn pids ->
        for {pid, _} <- pids, do: send(pid, {:audio, sound})
      end)
  end

  defp key(game_id), do: {:game, game_id}
end
