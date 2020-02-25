defmodule Elixoids.News do
  @moduledoc """
  Allow games to broadcast game events to subscribers.
  The subscriber may produce score table, statistics etc
  """

  alias Elixoids.Explosion.Location, as: ExplosionLoc

  def subscribe(game_id) when is_integer(game_id) do
    {:ok, _} = Registry.register(Registry.Elixoids.News, key(game_id), true)
  end

  def publish_audio(game_id, audio), do: publish(game_id, {:audio, audio})

  def publish_explosion(game_id, [x, y]),
    do: publish(game_id, {:explosion, %ExplosionLoc{x: x, y: y}})

  def publish_news(game_id, news) when is_binary(news), do: publish(game_id, {:news, news})

  def publish_news(game_id, news) when is_list(news),
    do: publish(game_id, {:news, Enum.join(news, " ")})

  def publish_news_fires(game_id, tag) do
    publish_news(game_id, [tag, "fires"])
  end

  defp publish(game_id, news) when is_integer(game_id) do
    :ok =
      Registry.dispatch(Registry.Elixoids.News, key(game_id), fn pids ->
        for {pid, _} <- pids, do: send(pid, news)
      end)
  end

  defp key(game_id), do: {:game, game_id}
end
