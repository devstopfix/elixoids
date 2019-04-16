# Elixoids

[Asteroids][1] game engine written in [Elixir][2].

[![Elixoids](docs/elixoids-8fps.gif)][6] [![Elixoids](docs/elixoids.vimeo.JPG)][6]


The UI is rendered by [asteroids-ui][3]. Audio provided by [SonicAsteroids][4].

Watch the [Elixoids movie][6] on [Vimeo](https://vimeo.com) recorded at a Coding Night. Participants were given one hour to write an AI bot that could pilot a ship and play the game! See the original [Arcade Asteroids video](https://www.youtube.com/watch?v=WYSupJ5r2zo).

Master: [![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=master)](https://travis-ci.org/devstopfix/elixoids) Stable v1: [![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=v1)](https://travis-ci.org/devstopfix/elixoids)


# Build

There are two versions of this game, v3 on master, and v1 which was released in 2016.

Check out this repository and run:

    brew install elixir
    mix deps.get

*Master* is currently being refactored and a lot of code being removed and replaced with Elixir 1.4 features such as Registry.

Branch [v1](//github.com/devstopfix/elixoids/tree/v1) contains the version compatible with the UI and original [Sonic][4] repositories.

# Run

This repo contains the game engine, a webserver, and a recent version of the [asteroids-ui][3].

To start a game:

    mix run --no-halt

or a REPL:

    iex -S mix

Open the UI in your browser:

    open http://localhost:8065/game/index.html

The game runs well in full screen, on Chrome this can be enabled with `[cmd]-[↩]`

To hear the sound effects on a Mac, download and run [v3 of the SonicAsteroids.app][7] and set the address to listen to as:

    ws://localhost:8065/sound

See the protocol below.

## Clients

Clients subscribe to an event stream from the game via Websockets.

### Sound Client Protocol

Sound events can be received at `ws://example.com/sound` and are a JSON list of maps:

```json
[
  {"snd": "x", "pan": -0.8, "gt": 83802},
  {"snd": "f", "pan":  0.2, "gt": 84010}
]
...
```

The sound types are:

* `x` : explosion
* `f` : shot fired

The pan is a float from -1 to +1 where -1 is hard left and zero is center. See the [pan property](https://developer.apple.com/documentation/avfoundation/avaudioplayer/1390884-pan)

* `gt` is the game time in milliseconds and can be used for ordering or delaying events

### News Client

There is a sample Python news client at [cat_news.py](client/cat_news.py):

The news stream is a stream of lines of the form:

    PLAYER VERB [SUBJECT]

Examples:

```
PLY fires
PLY hit ASTEROID
PLY hit OTH
```

### Java Ship Client

See [Elixoids Java Client](https://github.com/jrothwell/asteroids-client) by [J Rothwell][5].

### Ruby Clients

There are some sample clients, written in Ruby, in the [clients](clients) folder. They require two libraries (which may require *sudo* depending on your Ruby installation):

    gem install eventmachine
    gem install faye-websocket

    gem list --local

To run a simple client that instructs a ship to [shoot the nearest asteroid](clients/client_shoot_nearest_rock.rb):

    ruby clients/client_shoot_nearest_rock.rb

If you are running the game other than at localhost, specify the websocket in the environment:

    export ELIXOIDS_SERVER=rocks.example.com:8065

NB The websocket library is troublesome. It will often fail to connect after a reboot. Keep trying and it will eventually connect and stay connected! These scripts will be migrated to Python3.

## Refresh UI

In order to get the latest version of the UI:

* checkout [asteroids-ui][3] in a sibling folder to this project
* rebuild:

```
cd asteroids-ui/asteroids-renderer
npm run build
````

Copy the artefacts into the local folder which is served by the game webserver:

    cp asteroids-ui/asteroids-renderer/bin/* elixoids/html/

# Testing

Inspect source code for bad practice:

    mix credo --strict

Run tests whenever source changes:

    mix test.watch

# Deploy

How to install to an Ubuntu 14.04 LTS server:

## Packages

```
sudo apt-get -y update
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get -y update
sudo apt-get -y install esl-erlang
sudo apt-get -y install elixir
sudo apt-get -y install git
sudo apt-get -y install nginx
```

## Reverse proxy websocket

Edit NGINX conf:

    sudo nano /etc/nginx/sites-enabled/default

Before `server`:

```
upstream elixoids {
  server 127.0.0.1:8065 max_fails=5 fail_timeout=6s;
}
```

Server 'location':

```
    location / {

        allow all;

        # Proxy Headers
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Cluster-Client-Ip $remote_addr;

        # The Important Websocket Bits!
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_pass http://elixoids;
    }
```

Restart:

    sudo service nginx restart


Install and build game:

    git clone https://github.com/devstopfix/elixoids.git
    cd elixoids/
    mix deps.get
    mix compile

Run:

    mix run --no-halt


# Licence

This software is published under the [MIT License](LICENSE) and Copyright ©2019 [devstopfix](https://www.devstopfix.com). UI is ©2016 [lachok](https://github.com/lachok). Audio code is ©2016 [jrothwell][5].


[1]: https://en.wikipedia.org/wiki/Asteroids_(video_game)
[2]: http://elixir-lang.org/
[3]: https://github.com/lachok/asteroids
[4]: https://github.com/jrothwell/sonic-asteroids
[5]: https://github.com/jrothwell
[6]: https://vimeo.com/330017229
[7]: https://github.com/devstopfix/sonic-asteroids/releases/tag/v3.19.105