defmodule Elixoids.Game.Tick do
  @moduledoc false
  @callback handle_tick(pid(), integer(), term()) :: {:ok, term()} | {:stop, :normal, term()}
end
