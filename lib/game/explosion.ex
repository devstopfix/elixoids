defmodule Game.Explosion do

    @fade_out_ms 1 * 1000 # Duration for which explosions are visible

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
    
    defstruct id: -1, x: 0.0, y: 0.0, at: 0 

    @doc """
    Create Explosion at given x,y
    """
    def at_xy(x, y) do
        %Game.Explosion{x: x, y: y, at: World.Clock.now_ms}
    end

    @doc """
    Return true if the explosion should still be animated.
    """
    def active?(ex, t) do
       ex.at >= t
    end

    @doc """
    Filter explosions the occured in the past and have since faded out.
    """
    def filter_expired_explosions(explosions) do
      t = World.Clock.now_ms - @fade_out_ms
      Enum.filter(explosions, &active?(&1, t))
    end

    @doc """
    Convert to list, sent to front end.
    """
    def to_state(ex) do
        [ex.x, ex.y]
    end

end
