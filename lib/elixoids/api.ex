defmodule Elixoids.Api do
  @moduledoc """
  WebSocket API for clients to connect to games.

  Channels available:

  * /news - news feed of the game (shots, misses, hits etc)
  * /ship/AAA - player bots where AAA ~= /[A-Z]{3}/
  * /0/sound - sound events for the audio client
  * /0/graphics - UI stream

  TODO add game ids to all paths

  """

  @port 8065

  defp dispatch do
    :cowboy_router.compile([
      # :_ match on all hostnames -> localhost:8065.
      {
        :_,

        # Routes: { PathMatch, Handler, Options}
        [
          {"/icon.png", :cowboy_static, {:priv_file, :elixoids, "html/icon.png"}},

          # Serve a single static file on the route "/".
          {"/", :cowboy_static, {:priv_file, :elixoids, "priv/html/index.html"}},

          # Serve all static files in a directory.
          {"/game/[...]", :cowboy_static, {:dir, "priv/html"}},

          # Serve websocket requests.
          {"/:game/news", Elixoids.Server.WebsocketNewsHandler, []},
          {"/ship/:tag", Elixoids.Server.WebsocketShipHandler, []},
          {"/:game/sound", Elixoids.Server.WebsocketSoundHandler, []},
          {"/:game/graphics", Elixoids.Server.WebsocketGameHandler, []}
        ]
      }
    ])
  end

  def start_link(_opts) do
    {:ok, _} =
      :cowboy.start_clear(
        :elixoids_http,
        [{:port, @port}],
        %{env: %{dispatch: dispatch()}}
      )
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
