defmodule Elixoids.FuzzTest do
  use ExUnit.Case, async: true
  use ExCheck

  alias Asteroid.Server, as: Asteroid
  alias Elixoids.Game.Supervisor, as: GameSupervisor
  alias Elixoids.World.Point
  alias Game.Server, as: Game
  alias Ship.Server, as: Ship

  @tag: fuzz
  property :news_ws_ignores_input do

    # TODO use real client and hit real server

    for_all msg in binary() do

    end
  end

end
