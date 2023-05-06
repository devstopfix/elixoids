# Sources

src_js := ui/elm/public/elixoids.js

# Targets

target_js := priv/html/elixoids.js

# Main

build: build_elm $(target_js)

$(target_js): $(src_js) 
	cp -v $(src_js) $(target_js)

build_elm:
	make -C `pwd`/ui/elm build

.PHONY: clean
clean:
	rm -f $(target_js)