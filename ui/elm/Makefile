# Source code
canvas := public/lib/elm-canvas.2.2.js
resources := public/lib/resources.js
src := $(wildcard src/*.elm)
main := src/Main.elm

# Targets
dev_js := public/elixoids.dev.js
dev_simple_js := public/elixoids.dev.simple.js
opt_js := public/elixoids.opt.js
opt_simple_js := public/elixoids.opt.simple.js
opt_adv_js := public/elixoids.opt.adv.js
target := public/elixoids.js

# Config
level := SIMPLE_OPTIMIZATIONS

# Main
build: compile optimize $(target)
compile: $(dev_js) $(opt_js)
optimize: $(dev_simple_js) $(opt_simple_js)

# Binaries available
closure_compiler:
	which closure-compiler

elm:
	which elm

$(dev_js): src elm
	elm make $(main) --output $(dev_js)

$(opt_js): src elm
	elm make $(main) --optimize --output $(opt_js)

$(dev_simple_js): $(dev_js) closure_compiler
	closure-compiler --js $(dev_js) --compilation_level $(level) --js_output_file $(dev_simple_js)

$(opt_simple_js): $(opt_js) closure_compiler
	closure-compiler --js $(opt_js) --compilation_level $(level) --js_output_file $(opt_simple_js)

$(target): $(opt_js) closure_compiler
	closure-compiler --js $(opt_js) $(canvas) $(resources) --compilation_level $(level) --language_out ECMASCRIPT_2015 --js_output_file $(target)

.PHONY: clean
clean:
	rm -f $(dev_js) $(dev_simple_js) $(opt_js) $(opt_simple_js) $(target)

# # Advanced (experiment)
# advanced: $(opt_adv_js)
# $(opt_adv_js) : $(opt_js) closure_compiler
# 	time closure-compiler --js $(opt_js) $(canvas) $(resources) --compilation_level ADVANCED_OPTIMIZATIONS --language_out ECMASCRIPT_2015 --js_output_file $(opt_adv_js)
