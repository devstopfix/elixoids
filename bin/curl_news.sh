#!/bin/bash

GAME=${1:-0}

curl -H 'Accept: text/event-stream' "http://localhost:8065/$GAME/news" 2>&1