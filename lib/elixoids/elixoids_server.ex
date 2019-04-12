defmodule Elixoids.Server do

  @moduledoc """
  Asteroids Server. Starts a game and opens websocket.
  Registers the game process as :game.
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
          # PathMatch is "/"
          # Handler is :cowboy_static -- one of cowboy's built-in handlers.  See :
          #   http://ninenines.eu/docs/en/cowboy/HEAD/manual/cowboy_static/
          # Options is a tuple of { type, atom, string }.  In this case:
          #   :priv_file             -- serve a single file
          #   :asteroids_server -- application name.  This is used to search for
          #                             the path that priv/ exists in.
          #   "index.html            -- filename to serve
          {"/", :cowboy_static, {:priv_file, :elixoids, "html/index.html"}},

          # Serve all static files in a directory.
          # PathMatch is "/static/[...]" -- string at [...] will be used to look up the file
          # Handler is :cowboy_static -- one of cowboy's built-in handlers.  See :
          #   http://ninenines.eu/docs/en/cowboy/HEAD/manual/cowboy_static/
          # Options is a tuple of { type, atom, string }.  In this case:
          #   :priv_dir              -- serve files from a directory
          #   :asteroids_server -- application name.  This is used to search for
          #                             the path that priv/ exists in.
          #   "static_files"         -- directory to look for files in
          # {"/static/[...]", :cowboy_static, {:priv_dir,  :asteroids_server, "html"}},
          {"/game/[...]", :cowboy_static, {:dir, "html"}},

          # Serve a dynamic page with a custom handler
          # When a request is sent to "/dynamic", pass the request to the custom handler
          # defined in module DynamicPageHandler.
          # {"/dynamic", DynamicPageHandler, []},

          # Serve websocket requests.
          {"/websocket", Elixoids.Server.WebsocketGameHandler, []},
          {"/ship/:tag", Elixoids.Server.WebsocketShipHandler, []},
          {"/sound", Elixoids.Server.WebsocketSoundHandler, []},
          {"/news", Elixoids.Server.WebsocketNewsHandler, []}
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
