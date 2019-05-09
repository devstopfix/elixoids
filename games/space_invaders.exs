defmodule Elixoids.Games.SpaceInvaders do
  @moduledoc """
  Starts a game where the Asteroids form a Space Invader formation.

      mix run --no-halt games/space_invaders.exs
  """

  alias Elixoids.Asteroid.Rock
  alias Elixoids.Asteroid.Server, as: Asteroid
  alias Elixoids.Game.Server, as: Game
  alias Elixoids.World.Point
  alias Elixoids.World.Velocity
  import Elixoids.Game.Supervisor, only: [start_game: 1]
  import Elixoids.Space

  def start_link do
    [asteroids: 0]
    |> start_game()
    |> aliens()
    |> barriers()
  end

  defp aliens(game = {_, _, game_id}) do
    [w, h] = dimensions()

    r = h / 11 / 2.0
    v = %Velocity{theta: theta(), speed: 20.0}

    points([w, h], 11, 5, 2, 5, 1)
    |> Enum.map(fn p -> asteroid(game_id, p, r, v) end)

    game
  end

  defp barriers(game = {_, _, game_id}) do
    [w, h] = dimensions()

    radius = 14.0 * :math.pow(2, 4)
    v = %Velocity{theta: theta(), speed: 20.0}

    points([w, h], 4, 1, 1, 1, 3)
    |> Enum.map(fn p -> asteroid(game_id, p, radius, v) end)

    game
  end

  def theta, do: :math.pi() * 2 * 59 / 60.0

  # Create a grid of points sized (x y) with borders (bx bx) and (by1 by2)
  defp points([w, h], x, y, bx, by1, by2) do
    sx = w / (bx + x + bx - 1)
    sy = h / (by1 + y + by2 - 1)
    for x <- bx..(bx + x - 1), y <- by1..(by1 + y - 1), do: %Point{x: x * sx, y: y * sy}
  end

  defp asteroid(game_id, p, r, v) do
    rock = %Rock{pos: p, velocity: v, radius: r}
    {:ok, pid} = Asteroid.start_link(game_id, rock)
    Game.link(game_id, pid)
  end
end

{:ok, _, g} = Elixoids.Games.SpaceInvaders.start_link()
:io.fwrite("localhost:~B/~B/game~n", [Application.get_env(:elixoids, :cowboy_port), g])
