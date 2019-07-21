#!/bin/bash

if ! which closure-compiler ; then
  echo "Missing Closure Compiler"
  exit 1
fi

input=src/main.elm
canvas=public/lib/elm-canvas.2.2.js
resources=public/lib/resources.js

target1=public/elixoids.dev.js
target2=public/elixoids.opt.js
target3=public/elixoids.dev.simple.js
target4=public/elixoids.opt.simple.js
target5=public/elixoids_canvas.dev.simple.js
target6=public/elixoids_canvas.opt.simple.js

target=public/elixoids.js
prod_target=../../priv/html/elixoids.js

time elm make $input            --output $target1
time elm make $input --optimize --output $target2

time closure-compiler --js $target1 --compilation_level SIMPLE_OPTIMIZATIONS --js_output_file $target3
time closure-compiler --js $target2 --compilation_level SIMPLE_OPTIMIZATIONS --js_output_file $target4

# PROD

time closure-compiler --js $target1 $canvas $resources --compilation_level SIMPLE_OPTIMIZATIONS --language_out ECMASCRIPT_2015 --js_output_file $target5
if closure-compiler --js $target2 $canvas $resources --compilation_level SIMPLE_OPTIMIZATIONS --language_out ECMASCRIPT_2015 --js_output_file $target6; then
    rm $target
    cp $target6 $target

    md5 $prod_target
    cp $target $prod_target
    md5 $prod_target

    echo "OK!"
fi

# EXPERIMENETS

# target7=public/elixoids_canvas.opt.advanced.js
# time closure-compiler --js $target2 $canvas --compilation_level ADVANCED_OPTIMIZATIONS --language_out ECMASCRIPT_2015 --js_output_file $target7
