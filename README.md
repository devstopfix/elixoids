# Elixoids

[Asteroids][1] game engine written in [Elixir][2].

[![Elixoids](docs/elixoids-8fps.gif)][6] [![Elixoids](docs/elixoids.vimeo.JPG)][6]


The UI is rendered by [JavaScript asteroids-ui][3]. Audio provided by [SonicAsteroids][4].

Watch the [Elixoids movie][6] on [Vimeo](https://vimeo.com) recorded at a Coding Night. Participants were given one hour to write an AI bot that could pilot a ship and play the game! See the original [Arcade Asteroids video](https://www.youtube.com/watch?v=WYSupJ5r2zo).

Master: [![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=master)](https://travis-ci.org/devstopfix/elixoids)


# Build

To run the game [on Ubuntu](docs/ubuntu.md) or on OSX:

    brew install elixir
    git clone https://github.com/devstopfix/elixoids.git
    cd elixoids
    mix deps.get

# Run

This repo contains the game engine, a webserver, and a recent version of the [asteroids-ui][3].

To start a game:

    mix run --no-halt

Open the UI in your browser:

    open http://localhost:8065/0/game

The game runs well in full screen, on Chrome this can be enabled with `[cmd]-[↩]`

To hear the sound effects on a Mac, download and run [v3 of the SonicAsteroids.app][4] and set the address to listen to as:

    ws://localhost:8065/0/sound

In the REPL you can start multiple games on the same server:

```elixir
iex -S mix

{:ok, pid, id} = Elixoids.Game.Supervisor.start_game([asteroids: 16])
{:ok, #PID<0.538.0>, 2}
```

```bash
open http://localhost:8065/2/game
python3 clients/miner.py --name TWO --game 2
```

## Clients

Clients subscribe to an event stream from the game via Websockets. The resources available are:

| Path               | Accept                   | Content                   |
| ------------------ | ------------------------ | ------------------------- |
| `/0/graphics`      | application/json         | Graphics stream           |
| `/0/news`          | text/plain               | News stream               |
| `/0/ship/PLY`      | application/json         | Game state for player PLY |
| `/0/sound`         | application/json         | Sound stream              |
| `/0/sound`         | application/octet-stream | Binary sound stream       |


### Sound Client Protocol

Sound events can be received at `ws://example.com/0/sound` and here is the [sound format](docs/sound_protocol.md). There is a Unicode visualizer using Protocol Buffers in [listen.py](clients/listen.py).

### News Client

There is a sample Python news client at [cat_news.py](clients/cat_news.py). The news stream at `ws://example.com/0/news` is a stream of text lines of the form:

    [PLY|ASTEROID] VERB [PLY|ASTEROID]

Example dialogue:

```
PLY fires
PLY shot ASTEROID
PLY kills OTH
ASTEROID hit PLY
ASTEROID spotted
```

### Java Ship Client

See [Elixoids Java Client](https://github.com/jrothwell/asteroids-client) by [J Rothwell][5].

### Python Asteroid Miner Client

The [CBDR](https://en.wikipedia.org/wiki/Constant_bearing,_decreasing_range) Python client at [miner.py](clients/miner.py) will try and shoot the asteroid which is on the most constant bearing with it:

    pip3 install websocket-client
    python3 clients/miner.py --host localhost:8065 --name MCB

### Ruby Client

There is a simple Ruby client that [shoots the nearest ship](clients/shoot_nearest_ship.rb):

    gem install eventmachine
    gem install faye-websocket

    export ELIXOIDS_SERVER=rocks.example.com:8065 ruby clients/shoot_nearest_ship.rb

NB The websocket connection can be *troublesome* on OSX. It will often fail to connect after a reboot. Keep trying and it will eventually connect and stay connected! These scripts will be migrated to Python3.

### Graphics Client

Graphics stream can be received at `ws://example.com/0/graphics` - to be documented - see [asteroids-ui][3] for reference implementation or the [Elm conversion][7].

In order to get the latest version of the UI:

* checkout [asteroids-ui][3] in a sibling folder to this project
* rebuild:

While developing the UI you can start a test card game that allows you to prove your rendering:

```base
mix run --no-halt -e "Elixoids.World.Testcard.start_testcard"
```

Then connect to `ws://localhost:8065/1/game`.

```bash
cd asteroids-ui/asteroids-renderer
npm run buildmin
````
Copy the artefacts into the local folder which is served by the game webserver:

```bash
cp asteroids-ui/asteroids-renderer/bin/* elixoids/priv/html/
```

## Deploy

See the [Ubuntu deployment guide](docs/ubuntu.md) to run the game engine on a server.

## Licence

This software is published under the [MIT License](LICENSE) and Copyright ©2019 [devstopfix](https://www.devstopfix.com). UI is ©2016 [lachok](https://github.com/lachok). Audio code is ©2016 [jrothwell][5].


[1]: https://en.wikipedia.org/wiki/Asteroids_(video_game)
[2]: http://elixir-lang.org/
[3]: https://github.com/lachok/asteroids
[4]: https://github.com/jrothwell/sonic-asteroids
[5]: https://github.com/jrothwell
[6]: https://vimeo.com/330017229
[7]: https://github.com/devstopfix/asteroids-graphics/tree/elm