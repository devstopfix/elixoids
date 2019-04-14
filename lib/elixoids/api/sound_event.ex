defmodule Elixoids.Api.SoundEvent do

  import World.Clock

  @derive {Jason.Encoder, only: [:snd, :pan, :gt]}
  defstruct snd: "", pan: 0.0, gt: now_ms()

  def explosion(pan) when is_float(pan), do: %__MODULE__{snd: "x", pan: pan}

  def fire(pan) when is_float(pan), do: %__MODULE__{snd: "f", pan: pan}

end
