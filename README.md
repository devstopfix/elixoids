# Elixoids

[Asteroids 1979 arcade game][1] engine written in [Elixir][2]. Watch the [Elixoids movie][6] on [Vimeo](https://vimeo.com) recorded at a Coding Night. Participants were given one hour to write an AI bot that could pilot a ship and play the game! See the original [Arcade Asteroids video](https://www.youtube.com/watch?v=WYSupJ5r2zo).

[![Elixoids](docs/elixoids-8fps.gif)][6] [![Elixoids](docs/elixoids.vimeo.JPG)][6]

The original UI was rendered by [JavaScript asteroids-ui][3] and has had a recent [Elm conversion](ui/elm/README.md). Audio originall provided by [SonicAsteroids][4] before conversion to [Web Audio][8].

[![Build Status](https://github.com/devstopfix/elixoids/workflows/ci/badge.svg)](https://github.com/devstopfix/elixoids/actions)


## Build

To run the game [on Ubuntu](docs/ubuntu.md), or on OSX:

    brew install elixir
    git clone https://github.com/devstopfix/elixoids.git
    cd elixoids
    mix deps.get

## Run

This repo contains the game engine, a webserver, and a recent version of the [asteroids-ui](ui/elm/README.md).

To start a game use the [play script](bin/play.sh) or:

    mix run --no-halt

Open the UI in your browser:

    open http://localhost:8065/0/game

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

The parameters of the game can be alterted in the [config](config/config.exs).

## Clients

Clients subscribe to an event stream from the game via Websockets. The resources available are:

| Path               | Accept                   | Content                   |
| ------------------ | ------------------------ | ------------------------- |
| `/0/graphics`      | application/json         | Graphics stream           |
| `/0/news`          | text/event-stream        | News stream               |
| `/0/ship/PLY`      | application/json         | Game state for player PLY |

### News Client

The news stream at `http://example.com/0/news` is a stream of text lines of the form:

    [PLY|ASTEROID] VERB [PLY|ASTEROID]

Example dialogue:

```bash
$ curl -H 'Accept: text/event-stream' http://localhost:8065/0/news 2>&1

PLY fires
PLY shot ASTEROID
PLY fires
PLY shot OTH
PLY kills OTH
ASTEROID hit PLY
ASTEROID spotted
```

This can be used to generate a hi-score table:

    elixir --no-halt clients/hiscore.exs http://localhost:8065/0/news

### Java Ship Client

See [Elixoids Java Client](https://github.com/jrothwell/asteroids-client) by [J Rothwell][5].

### Python Asteroid Miner Client

The [CBDR](https://en.wikipedia.org/wiki/Constant_bearing,_decreasing_range) Python client at [miner.py](clients/miner.py) will try and shoot the asteroid which is on the most constant bearing with it:

    pip3 install websocket-client --user
    python3 clients/miner.py --host localhost:8065 --name MCB

### Ruby Client

There is a simple Ruby client that [shoots the nearest ship](clients/shoot_nearest_ship.rb):

    gem install eventmachine
    gem install faye-websocket

    export ELIXOIDS_SERVER=rocks.example.com:8065 ruby clients/shoot_nearest_ship.rb

NB The websocket connection can be *troublesome* on OSX. It will often fail to connect after a reboot. Keep trying and it will eventually connect and stay connected! These scripts will be migrated to Python3.

### Graphics Client

Graphics stream can be received at `ws://example.com/0/graphics` - to be documented - see [GraphicsDecoder.elm](ui/elm/src/GraphicsDecoder.elm) and [asteroids-ui][3] for reference implementations.

While developing the UI you can start a [test card](docs/testcard-classic.jpg) game that allows you to prove your rendering:

    mix run --no-halt games/testcard.exs

Then connect to `ws://localhost:8065/1/game`.

## Deploy

See the [Ubuntu deployment guide](docs/ubuntu.md) to run the game engine on a server.

## Licence

This software is published under the [MIT License](LICENSE) and Copyright ©2019 [devstopfix](https://www.devstopfix.com). UI is ©2016 [lachok](https://github.com/lachok). Audio code is ©2016 [jrothwell][5]. Button CSS by [ozer][7].

[1]: https://en.wikipedia.org/wiki/Asteroids_(video_game)
[2]: http://elixir-lang.org/
[3]: https://github.com/lachok/asteroids
[4]: https://github.com/jrothwell/sonic-asteroids
[5]: https://github.com/jrothwell
[6]: https://vimeo.com/330017229
[7]: https://codepen.io/ozer/pen/KwvKoR
[8]: https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API