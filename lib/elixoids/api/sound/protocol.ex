defmodule Elixoids.Api.Sound.Protocol do
  defmodule Sound do
    @moduledoc false
    use Protobuf, syntax: :proto3

    #  protoc --elixir_out /tmp priv/proto/sound.proto

    @type t :: %__MODULE__{
            noise: atom | integer,
            pan: float,
            size: integer
          }
    defstruct [:noise, :pan, :size]

    field(:noise, 1, type: Sound.Noise, enum: true)
    field(:pan, 2, type: :float)
    field(:size, 3, type: :int32)
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

  defp convert(%{snd: "f", pan: pan, size: size}), do: Sound.new(noise: :FIRE, pan: pan, size: size)

  defp convert(%{snd: "x", pan: pan, size: size}),
    do: Sound.new(noise: :EXPLOSION, pan: pan, size: size)

  def encode(sound), do: Sound.encode(convert(sound))
end
