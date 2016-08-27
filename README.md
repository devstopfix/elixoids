# Elixoids

[Asteroids][1] game engine written in [Elixir][2].

Master: [![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=master)](https://travis-ci.org/devstopfix/elixoids)

Stable v1: [![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=v1)](https://travis-ci.org/devstopfix/elixoids)

The UI is rendered by [asteroids-ui][3]. Audio provided by [SonicAsteroids][4]

[Asteroids Video](https://www.youtube.com/watch?v=WYSupJ5r2zo)

# Build

There are two versions of this game. Branch *v1* contains the version compatible with the UI and Sonic repositories. Switch to that branch until they are modified to be compatible with master.

Check out this repository and run:

    git checkout v1
    mix deps.get

You may need to install Elixir and Erlang v18, on a Mac you can use homebrew:

    brew install homebrew/versions/erlang-r18
    brew install elixir

The software will not compile on Erlang v19 at present due to a dependency that [ExCheck has on triq](https://github.com/devstopfix/elixoids/issues/35).

# Run

This repo contains the game engine, a webserver, and a recent version of the [asteroids-ui][3].

To start a game:

    iex -S mix

Open the UI in your browser:

    open http://localhost:8065/game/index.html

The game runs well in full screen, on Chrome this can be enabled with `[cmd]-[↩]`

To hear the sound effects on a Mac, download and run [SonicAsteroids.app](https://github.com/jrothwell/sonic-asteroids/releases) and set the address to listen to as:

    ws://localhost:8065/sound

## Clients

There are some sample clients, written in Ruby, in the [clients](clients) folder. They require two libraries (which may require *sudo* depending on your Ruby installation):

    gem install eventmachine
    gem install faye-websocket

    gem list --local

To run a simple client that instructs a ship to [shoot the nearest asteroid](clients/client_shoot_nearest_rock.rb):

    ruby clients/client_shoot_nearest_rock.rb

If you are running the game other than at localhost, specify the websocket in the environment:

    export ELIXOIDS_SERVER=rocks.example.com:8065

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

    mix credo

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

This software is published under the [MIT License](LICENSE) and copyright [devstopfix](https://github.com/devstopfix). UI is copyright [lachok](https://github.com/lachok). Audio code is copyright [jrothwell](https://github.com/jrothwell).


[1]: https://en.wikipedia.org/wiki/Asteroids_(video_game)
[2]: http://elixir-lang.org/
[3]: https://github.com/lachok/asteroids
[4]: https://github.com/jrothwell/sonic-asteroids
