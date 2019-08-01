# Asteroids Graphics for Elixoids

## Development

Start a reactor that serves your files, and a process that compiles the code when the sources change:

    elm reactor && find src | entr -r elm make src/main.elm --output public/elixoids.dev.js

Open the browser:

    http://localhost:8000/public/dev.html

## Production build

```bash
elm make src/Main.elm --optimize --output public/elm.js

closure-compiler --js public/elm.js public/elm-canvas.2.2.js --compilation_level SIMPLE_OPTIMIZATIONS --language_out ECMASCRIPT_2015 --js_output_file public/elixoids.js
```

Compressed with the [Closure Compiler](https://developers.google.com/closure/compiler/).

## Credits

* [JSON parser routine](https://gist.github.com/simonykq/f4623eb5e87ff2834afba1f156e57614) by [Simon Yu](https://github.com/simonykq)
* [Elm Canvas](https://package.elm-lang.org/packages/joakin/elm-canvas/4.0.1/)