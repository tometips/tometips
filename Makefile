SHELL := /bin/bash

LUA := luajit

TOME_GIT_URL := http://git.net-core.org/tome/t-engine4.git

RELEASE_VERSIONS := 1.1.5 1.2.0 1.2.1 1.2.2 1.2.3 1.2.4 1.2.5 1.3.0 1.3.1 1.3.3 1.4.0 1.4.1 1.4.2 1.4.3
VERSIONS := $(RELEASE_VERSIONS) master

# Enable DLC for these versions
DLC_VERSIONS := 1.3.0 1.3.1 1.3.3 1.4.0 1.4.1 1.4.2 1.4.3

# GitHub Pages output
PAGES_OUTPUT = ../tometips.github.io

all: t-engine4 img html/js/templates.js html/js/partials.js \
	$(patsubst %,html/data/%/tome.json,$(VERSIONS)) \
	$(patsubst %,html/data/%/classes.json,$(VERSIONS)) \
	$(patsubst %,html/data/%/races.json,$(VERSIONS)) \
	$(patsubst %,html/data/%/changes.talents.json,$(VERSIONS)) \
	$(patsubst %,html/data/%/recent-changes.talents.json,$(VERSIONS))

html/data/%/tome.json: % talent_spoilers.lua | dlc
	$(LUA) talent_spoilers.lua $< $(dir $@)

html/data/%/classes.json: % class_spoilers.lua | dlc
	$(LUA) class_spoilers.lua $< $(dir $@)

html/data/%/races.json: % race_spoilers.lua | dlc
	$(LUA) race_spoilers.lua $< $(dir $@)

html/js/partials.js: html/js/partials/*.handlebars
	handlebars --min --partial html/js/partials > $@

html/js/templates.js: html/js/templates/*.handlebars
	handlebars --min html/js/templates > $@

# "make clean" support.  To avoid creating spurious changes, this does not
# delete images.
clean:
	find html/data -mindepth 1 -maxdepth 1 -not -name README.txt | xargs rm -rf
	rm -f html/js/templates.js html/js/partials.js

# Cleaner than clean.  This *does* delete images.
clean-all: clean
	rm -rf html/img/talents/*.png html/img/talents/*/*.png

publish:
	test -d $(PAGES_OUTPUT)
	rsync --recursive --times --exclude=*.handlebars --exclude=*.swp --delete --verbose html/* $(PAGES_OUTPUT)

# Changes from one version to the next
changes.mk: Makefile scripts/make-changes-mk.sh
	scripts/make-changes-mk.sh $(VERSIONS) > $@
-include changes.mk

# Convert and publish images.
img: t-engine4 dlc
	scripts/prepare-img.sh

# Pretty-prints each of the JSON files.
pretty: html/data/$(VERSION)
	for file in $$(find html -name '*.json'); do python -mjson.tool $$file > $$file.tmp && mv $$file.tmp $$file; done

# git shortcuts to automate maintenance of the local source tree
t-engine4:
	git clone $(TOME_GIT_URL)

# git shortcut - git pull
pull:
	cd t-engine4 && \
		git remote set-url origin $(TOME_GIT_URL) && \
		git checkout master && \
		git pull
	@# Mark html/data/master/* as needing updating
	touch master

# Symlinks and working copies
master:
	scripts/link-master-src.sh

$(RELEASE_VERSIONS):
	scripts/copy-tag-src.sh $@

dlc: $(RELEASE_VERSIONS)
	scripts/fetch-dlc.sh $(DLC_VERSIONS)
	touch dlc

.PHONY: clean pretty img pull publish

