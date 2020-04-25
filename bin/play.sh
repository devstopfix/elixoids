#!/bin/bash

PORT=8065
HOST="`hostname`:$PORT"
PID="/tmp/elixoids_game"
SONIC=~/Applications/SonicAsteroids.app/Contents/MacOS/SonicAsteroids

# If we are running a game, stop it
if [ -f "$PID" ]; then
  kill -9 `cat $PID` 2>/dev/null
fi

# Start the game and save it's PID
nice -n 10 mix run --no-halt &
echo $! > $PID

# UI
sleep 4.0
open "http://$HOST/0/game"

# Audio
if [ -x "$(command -v $SONIC)" ]; then
  $SONIC "ws://$HOST/0/sound" &
fi

# Clients that shoot rocks
if [ -x "$(command -v python3)" ]; then
    sleep 4.0
    nice -n 19 python3 clients/miner.py --host "$HOST" --game 0 --name MIN &

    sleep 4.0
    nice -n 19 python3 clients/miner.py --host "$HOST" --game 0 &
fi

# Hunter that shoots ships
if [ -x "$(command -v ruby)" ]; then
    sleep 8.0
    ELIXOIDS_SERVER="$HOST" ruby clients/shoot_nearest_ship.rb KIL &
fi
