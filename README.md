# Elixoids

[Asteroids][1] game engine written in [Elixir][2].

[![Build Status](https://travis-ci.org/devstopfix/elixoids.svg?branch=master)](https://travis-ci.org/devstopfix/elixoids)

The UI is rendered by [asteroids-ui](https://github.com/lachok/asteroids). Audio provided by [SonicAsteroids](https://github.com/jrothwell/sonic-asteroids)

[Asteroids Video](https://www.youtube.com/watch?v=WYSupJ5r2zo)

## Purpose

Game state represented by Actors and Processes. Knows nothing about source of inputs or outputs.

# Testing

Inspect source code:

    mix credo

Run tests whenever source changes:

    mix test.watch

# Build

    mix hex.build

[1]: https://en.wikipedia.org/wiki/Asteroids_(video_game)
[2]: http://elixir-lang.org/
