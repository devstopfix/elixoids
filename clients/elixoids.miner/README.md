# elixoids.miner

[Elixoids client](https://github.com/devstopfix/elixoids) that only targets asteroids.

## Usage

To run, supply the URL of the websocket where the game server is running:

    java -jar target/elixoids.miner-0.1.0-standalone.jar ws://example.com/ship/ROK

Beware! This client does not (yet) check to see if there are any ships between it and the asteroid it is targeting.

# Build

    lein uberjar

## Repl

```clojure
(use 'elixoids.ship)
(for [a (range 71 73)] (echo-state-fire (apply str ["R" "K" (char a)])))
```

# License

Copyright © 2016 devstopfix

Distributed under the Eclipse Public License either version 1.0 or (at
your option) any later version.
