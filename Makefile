SHELL := /bin/bash

VERSIONS := 1.1.5 master

# GitHub Pages output
PAGES_OUTPUT = ../tometips.github.io

all: t-engine4 $(patsubst %,html/data/%/tome.json,$(VERSIONS)) img html/data/master/changes.talents.json

html/data/%/tome.json: % spoilers.lua
	lua spoilers.lua $< $(dir $@)

clean:
	rm -rf html/data/* html/img/talents/*.png html/img/talents/*/*.png

publish:
	test -d $(PAGES_OUTPUT)
	rm -rf $(PAGES_OUTPUT)/*
	cp -a html/* $(PAGES_OUTPUT)

# Changes from one version to the next
# HACK: Hard-code version numbers for now
html/data/master/changes.talents.json: html/data/1.1.5/tome.json html/data/master/tome.json makechangelist.lua
	lua makechangelist.lua html/data/ 1.1.5 master

# Convert and publish images.
img: t-engine4
	scripts/prepare-img.sh

# Pretty-prints each of the JSON files.
pretty: html/data/$(VERSION)
	for file in $$(find html -name '*.json'); do python -mjson.tool $$file > $$file.tmp && mv $$file.tmp $$file; done

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

# Symlinks and working copies
master:
	scripts/link-master-src.sh

$(filter-out master,$(VERSIONS)):
	scripts/copy-tag-src.sh

.PHONY: clean pretty img switch-dev switch-release pull publish

