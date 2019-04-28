defmodule Elixoids.Api.Sound.Protocol do
  defmodule Sound do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            noise: atom | integer,
            pan: float
          }
    defstruct [:noise, :pan]

    field(:noise, 1, type: Sound.Noise, enum: true)
    field(:pan, 2, type: :float)
  end

  defmodule Sound.Noise do
    @moduledoc false
    use Protobuf, enum: true, syntax: :proto3

    field(:FIRE, 0)
    field(:EXPLOSION, 1)
    field(:HYPERSPACE, 2)
    field(:RUMBLE, 3)
    field(:SAUCER, 4)
  end

  defp convert(%{snd: "f", pan: pan}), do: Sound.new(kind: 0, pan: pan)
  defp convert(%{snd: "x", pan: pan}), do: Sound.new(kind: 1, pan: pan)

  def encode(sound), do: Sound.encode(convert(sound))
end
