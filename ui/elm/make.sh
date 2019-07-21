#!/bin/bash

elm make src/main.elm --output public/elixoids.dev.js && elm reactor
