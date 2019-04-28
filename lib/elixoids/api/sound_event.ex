defmodule Elixoids.Api.SoundEvent do
  @moduledoc """
  JSON map sent to sound clients.

  Each event contains:
  * snd - the sound to play f=fire, x=explosion
  * pan - float -1.0 for hard left, +1.0 for hard right, 0.0 in the centre
  """

  @derive {Jason.Encoder, only: [:snd, :pan, :size]}
  defstruct snd: "", pan: 0.0, size: 0

  def explosion(pan, radius) when is_float(pan),
    do: %__MODULE__{snd: "x", pan: pan, size: trunc(radius)}

  def fire(pan) when is_float(pan), do: %__MODULE__{snd: "f", pan: pan, size: 0}
end
