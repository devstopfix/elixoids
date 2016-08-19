defmodule Game.Explosion do

    @fade_out_ms 1 * 1000 # Duration for which explosions are visible

    @moduledoc """
    An explosion has a unique identifier and time of detonation,
    and a point in space.
    """
    
    defstruct id: -1, x: 0.0, y: 0.0, at: World.Clock.now_ms 

    @doc """
    Create Explosion at given x,y
    """
    def at_xy(x, y) do
        %Game.Explosion{x: x, y: y}
    end

    @doc """
    Return true if the time of the explosion is before
    the given cut-off time.
    """
    def expired?(ex, t) do
       ex.at < t
    end

    @doc """
    Filter explosions the occured in the past and have since faded out.
    """
    def filter_expired_explosions(explosions) do
      t = World.Clock.now_ms - @fade_out_ms
      Enum.reject(explosions, &expired?(&1, t))
    end

    @doc """
    Convert to list, sent to front end.
    """
    def to_state(ex) do
        [ex.x, ex.y]
    end

end
