defmodule World.Position do

  @moduledoc """
  The (x,y) position in 2D. Origin is at bottom left.  
  """
    
  defstruct x: 0.0, y: 0.0

  def move(p, dx, dy) do
    %{p | x: p.x + dx, y: p.y + dy}
  end

end