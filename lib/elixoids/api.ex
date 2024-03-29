defmodule Elixoids.Api do
  @moduledoc "HTTP server to serve game HTML and WS channels available"

  import Elixoids.Const, only: [ws_idle_timeout: 0]

  defp dispatch do
    :cowboy_router.compile([
      {
        :_,
        [
          {"/", Elixoids.Server.RedirectHandler, []},
          {"/game/index.html", Elixoids.Server.RedirectHandler, []},
          {"/:game/game", :cowboy_static, {:priv_file, :elixoids, "html/game_elm.html"}},
          {"/:game/graphics", Elixoids.Server.WebsocketGameHandler, []},
          {"/:game/news", Elixoids.Server.WebsocketNewsHandler, []},
          {"/:game/ship/:tag", Elixoids.Server.WebsocketShipHandler, []},
          {"/[...]", :cowboy_static, {:priv_dir, :elixoids, "html"}}
        ]
      }
    ])
  end

  def start_link(opts) do
    {:ok, _} =
      :cowboy.start_clear(
        :elixoids_http,
        opts,
        %{env: %{dispatch: dispatch()}, idle_timeout: ws_idle_timeout()}
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
