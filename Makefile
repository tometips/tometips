SHELL := /bin/bash

all: t-engine4 links html/data/tome.json img

html/data/tome.json: spoilers.lua
	lua spoilers.lua $(dir $@)

clean:
	rm -rf html/data/* html/img/talents/*.png html/img/talents/*/*.png

# Convert and publish images.
img: t-engine4 switch-dev
	mkdir -p html/img/talents/{64,48,32}
	cp --update t-engine4/game/modules/tome/data/gfx/talents/*.png html/img/talents/64/
	for size in 32 48; do \
		for img in html/img/talents/64/*.png; do \
			newimg=$${img/64/$$size}; \
			if [ ! -f $$newimg -o $$img -nt $$newimg ]; then \
				echo Converting $$newimg...; \
				convert -resize $${size}x$${size} $$img $$newimg; \
			fi; \
		done; \
	done

# Pretty-prints each of the JSON files.
pretty: html/data/tome.json
	for file in html/data/*.json; do python -mjson.tool $$file > $$file.tmp && mv $$file.tmp $$file; done

# git shortcuts to automate maintenance of the local source tree
t-engine4:
	git clone http://git.net-core.org/darkgod/t-engine4.git
	$(MAKE) switch-release

# git shortcut - switch to development / master / trunk code
switch-dev:
	cd t-engine4 && git checkout master

# git shortcut - switch to release code.  We assume the last tag is the current
# release.
switch-release:
	cd t-engine4 && git checkout $$(git tag | tail -n 1)

# git shortcut - git pull
pull:
	$(MAKE) switch-dev
	cd t-engine4 && git pull

# Symlinks
links: data engine mod thirdparty
data:
	ln -s t-engine4/game/modules/tome/data
engine:
	ln -s t-engine4/game/engines/default/engine
mod:
	ln -s t-engine4/game/modules/tome mod
thirdparty:
	ln -s t-engine4/game/thirdparty

.DELETE_ON_ERROR:

.PHONY: clean pretty links img switch-dev switch-release pull

