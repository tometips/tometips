SHELL := /bin/bash

V11 := 1.1.5
V12 := 1.2.2
VERSIONS := $(V11) $(V12)
#VERSIONS := $(V11) $(V12) master

# GitHub Pages output
PAGES_OUTPUT = ../tometips.github.io

all: t-engine4 $(patsubst %,html/data/%/tome.json,$(VERSIONS)) img html/data/$(V12)/changes.talents.json

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
html/data/$(V12)/changes.talents.json: html/data/$(V11)/tome.json html/data/$(V12)/tome.json makechangelist.lua
	lua makechangelist.lua html/data/ $(V11) $(V12)

# Convert and publish images.
img: t-engine4
	scripts/prepare-img.sh

# Pretty-prints each of the JSON files.
pretty: html/data/$(VERSION)
	for file in $$(find html -name '*.json'); do python -mjson.tool $$file > $$file.tmp && mv $$file.tmp $$file; done

# git shortcuts to automate maintenance of the local source tree
t-engine4:
	git clone http://git.net-core.org/darkgod/t-engine4.git

# git shortcut - git pull
pull:
	cd t-engine4 && git checkout master
	cd t-engine4 && git pull

# Symlinks and working copies
master:
	scripts/link-master-src.sh

$(filter-out master,$(VERSIONS)):
	scripts/copy-tag-src.sh $@

.PHONY: clean pretty img pull publish

