defmodule Elixoids.Server.PlayerInput do
  @moduledoc """
  Parse player input!

      Poison.decode(~s({"fire": true, "theta": 0}), as: %PlayerInput{})
      {:ok, %PlayerInput{fire: true, theta: 0}}
  """

  @derive [Poison.Encoder]
  defstruct [:theta, :fire]
end
