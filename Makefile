html/data/tome.json: spoilers.lua
	lua spoilers.lua $(dir $@)

clean:
	rm -f html/data/*.json

.DELETE_ON_ERROR:

.PHONY: clean
