defmodule Elixoids.Api.SoundEvent do
  @moduledoc """
  JSON map sent to sound clients.

  Each event contains:
  * snd - the sound to play f=fire, x=explosion
  * pan - float -1.0 for hard left, +1.0 for hard right, 0.0 in the centre
  * gt  - game time milliseconds - used for ordering events
  """

  import World.Clock

  @derive {Jason.Encoder, only: [:snd, :pan, :gt]}
  defstruct snd: "", pan: 0.0, gt: now_ms()

  def explosion(pan) when is_float(pan), do: %__MODULE__{snd: "x", pan: pan}

  def fire(pan, t) when is_float(pan), do: %__MODULE__{snd: "f", pan: pan, gt: t}
end
