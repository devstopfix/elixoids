defmodule Elixoids.Server.RedirectHandler do
  @moduledoc "Redirect old v1 URLs"

  @behaviour :cowboy_handler

  def init(req, any) do
    new_req =
      :cowboy_req.reply(
        303,
        %{"location" => "/0/game"},
        "",
        req
      )

    {:ok, new_req, any}
  end
end
