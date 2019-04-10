defmodule Game.Explosion do
  import Game.Identifiers

  # Duration for which explosions are visible
  @fade_out_ms 1 * 1000

  @moduledoc """
  An explosion has a unique identifier and time of detonation,
  and a point in space.

  Explosions remain in state for 1s:

      {:ok, game} = Game.Server.start_link()
      Game.Server.tick(game)
      Game.Server.show(game)
      Game.Server.sound_state(game)

      Game.Server.explosion(game, 1.0, 1.0)

      Game.Server.tick(game)
      Game.Server.show(game)
      Game.Server.sound_state(game)

  """

  @derive {Jason.Encoder, only: [:x, :y, :explosion]}
  defstruct id: -1, x: 0.0, y: 0.0, explosion: 0

  @doc """
  Create Explosion at given x,y
  """
  def at_xy(x, y) do
    %Game.Explosion{x: x, y: y, explosion: World.Clock.now_ms(), id: next_id()}
  end

  @doc """
  Return true if the explosion should still be animated.
  """
  def active?(ex, t) do
    ex.at >= t
  end

  @doc """
  Convert to list, sent to front end.
  """
  def to_state(ex) do
    [ex.x, ex.y]
  end
end
