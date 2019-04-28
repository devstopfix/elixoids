defmodule Elixoids.Api.SoundEvent do
  @moduledoc """
  JSON map sent to sound clients.

  Each event contains:
  * snd - the sound to play f=fire, x=explosion
  * pan - float -1.0 for hard left, +1.0 for hard right, 0.0 in the centre
  """

  @derive {Jason.Encoder, only: [:snd, :pan]}
  defstruct snd: "", pan: 0.0

  def explosion(pan) when is_float(pan), do: %__MODULE__{snd: "x", pan: pan}

  def fire(pan) when is_float(pan), do: %__MODULE__{snd: "f", pan: pan}
end
