defmodule Game.Server do

   @moduledoc """
   Game process. One process per running Game.
   """

   use GenServer

   alias World.Point, as: Point
   alias Elixoids.Space, as: Space

end
