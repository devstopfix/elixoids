defmodule Elixoids.Api do
  @moduledoc """
  WebSocket API for clients to connect to games.

  Channels available:

  * /news - news feed of the game (shots, misses, hits etc)
  * /ship/AAA - player bots where AAA ~= /[A-Z]{3}/
  * /sound - sound events for the audio client
  * /websocket - UI

  TODO rename /websocket to /999/ui
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
          # Serve a single static file on the route "/".
          {"/", :cowboy_static, {:priv_file, :elixoids, "html/index.html"}},

          # Serve all static files in a directory.
          {"/game/[...]", :cowboy_static, {:dir, "html"}},

          # Serve websocket requests.
          {"/news", Elixoids.Server.WebsocketNewsHandler, []},
          {"/ship/:tag", Elixoids.Server.WebsocketShipHandler, []},
          {"/sound", Elixoids.Api.WebsocketSoundHandler, []},
          {"/websocket", Elixoids.Server.WebsocketGameHandler, []}
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
