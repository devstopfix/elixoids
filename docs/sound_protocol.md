# Elixir Sound Protocol

Sound events can be received at `ws://example.com/0/sound` where `0` is the integer game number you want to connect to.

## JSON Protocol

The websocket will receive a JSON message at around 12fps, each message is a list of sound events. Each event is a map:

```json
[
  {"snd": "x", "pan": -0.8, "gt": 83802},
  {"snd": "f", "pan":  0.2, "gt": 83840},
  ...
]
...
```

| Field | Type           | Content                  |
| ----- | -------------- | -------------------------|
| snd   | x|f            | eXplosion or shot Fired  |
| pan   | float -1..1    | Stero pan                |
| gt    | integer        | ms since start of game   |

The pan is a float from -1 to +1 where -1 is hard left and zero is center. See the [pan property](https://developer.apple.com/documentation/avfoundation/avaudioplayer/1390884-pan)

## Protobuf

Reduce network bandwidth by subscribing using the [sound protocol buffer](priv/proto/sound.proto).

Generate your client:

    protoc --python_out /tmp priv/proto/sound.proto

