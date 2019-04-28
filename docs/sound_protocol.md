# Elixir Sound Protocol

Sound events can be received at `ws://example.com/0/sound` where `0` is the game number you want to connect to. There will always be a game zero running.

Each game sound produces an event:

| Field | Type           | Content                          |
| ----- | -------------- | -------------------------------- |
| snd   | x|f            | eXplosion or shot Fired          |
| pan   | float -1..1    | Stero pan                        |
| size  | int            | Size of entity that caused sound |

The pan is a float from -1 to +1 where -1 is hard left and zero is center. See the [pan property](https://developer.apple.com/documentation/avfoundation/avaudioplayer/1390884-pan)

Sizes:

| Size (m) | Entity            |
| -------: | ----------------- |
|     120  | largest asteroid  |
|      60  | asteroid          |
|      30  | asteroid          |
|      15  | smallest asteroid |
|      20  | ship              |
|       0  | bullet            |

## Protobuf

Reduce network bandwidth by subscribing using the [sound protocol buffer](priv/proto/sound.proto). Your client will need to initiate the web socket connection with the HTTP header:

    Accept: application/octet-stream

For example:

```python
ws = websocket.WebSocketApp(ws_url, header = {"Accept": "application/octet-stream"}, ...
```

Generate your Python client:

    protoc --python_out /tmp priv/proto/sound.proto

## JSON Protocol

The websocket will receive a JSON message which is a list of a single sound event. Each event is a map:

```json
[ {"snd": "x", "pan": -0.8, "size": 120} ]
...
[ {"snd": "f", "pan":  0.2, "size": 0} ]
```

This is the default protocol - you can request it with the HTTP header:

    Accept: application/json

Each JSON event is around 36 bytes, compared to 5-7 bytes for the protobuf.
