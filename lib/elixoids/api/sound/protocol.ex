defmodule Elixoids.Api.Sound.Protocol do
  defmodule Sound do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            noise: atom | integer,
            pan: float,
            game_time: non_neg_integer
          }
    defstruct [:noise, :pan, :game_time]

    field(:noise, 1, type: Sound.Noise, enum: true)
    field(:pan, 2, type: :float)
    field(:game_time, 3, type: :uint32)
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

  defp convert(%{snd: "f", pan: pan, gt: gt}), do: Sound.new(kind: 0, pan: pan, game_time: gt)
  defp convert(%{snd: "x", pan: pan, gt: gt}), do: Sound.new(kind: 1, pan: pan, game_time: gt)

  def encode(sound), do: Sound.encode(convert(sound))
end
