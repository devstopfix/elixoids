# Sound Effects for Elixoids

Part of the the Coding Night challenge will be to implement a stereo sound effect module that listens to the game event feed and plays the appropriate sound effects. Listen to the [Asteroids arcade game video](https://www.youtube.com/watch?v=WYSupJ5r2zo).

## Sounds

Sound assets can be found at [classicgaming.cc](http://www.classicgaming.cc/classics/asteroids/sounds)

# Protocol

The URL of the web socket TBC. For development:

    ws://localhost:8065/websocket

The websocket will emmit a stream of JSON records at a given FPS. Each record will be a JSON object. The interesting attributes are:

```json
{"a":[],
 "b":[[47,941.3,2032.8],[49,919.1,1037.0]],
 "dim":[4.0e3,2250.0],
 "s":[],
 "x":[ [2000.0, 500.0]]}
```

The dimension of the play area is given by `dim` in meters. The default is 4000m on the x-axis and 2250m on the y-axis. `0,0` is bottom left.

## Bullets

Bullets `b` are a list of lists, where each sub-list is:

* bullet id - unique integer
* x - bullet x
* y - bullet y

Bullets travel for about 2 seconds and will be sent multiple times before they expire. It is therefore necessary to keep a set of bullet ids previously seen and only play sounds for new bullets.

## Explosions

Explosions `x` are a list of lists, where each sub-list is:

* x - explosion at x
* y - explosion at y

Explosions appear once in a record (at detonation) and are never resent.

## Stereo

The x ordinate of an explosion can be used to place the sound in the speakers:

* 0.0 - hard left
* 2000.0 - middle (both channels)
* 4000.0 - hard right

The dimensions of the play area are not expected to change but you should use the `dim` property rather than hard code.

# Sample code

This code can be used to connect to the web socket and listen to the event stream:

```ruby
require 'faye/websocket'
require 'eventmachine'
require 'json'


EM.run {
  ws = Faye::WebSocket::Client.new('ws://localhost:8065/websocket')

  ws.on :open do |event|
    p [:open]
  end

  ws.on :message do |event|
    frame = JSON.parse(event.data)
    unless frame['x'].empty?
      frame['x'].each do |xplosion|
        x,y = xplosion
        p "Explosion at #{x.to_s}, #{y.to_s}"
      end
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}

```

## Prerequisites

A web socket library such as [Faye Websocket](https://github.com/faye/faye-websocket-ruby)

    gem install faye-websocket
    gem install eventmachine


# Runing a real game.

See the [Asteroids Server README](https://github.com/devstopfix/asteroids-server) for build and running instructions. Elixir required!
