html/data/tome.json: spoilers.lua
	lua spoilers.lua $(dir $@)

clean:
	rm -f html/data/*.json

# Pretty-prints each of the JSON files.
pretty: html/data/tome.json
	for file in html/data/*.json; do python -mjson.tool $$file > $$file.tmp && mv $$file.tmp $$file; done

.DELETE_ON_ERROR:

.PHONY: clean pretty
