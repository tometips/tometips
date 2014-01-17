html/js/spoilers.js: spoilers.lua
	echo "tome = " > $@
	lua spoilers.lua $@

.DELETE_ON_ERROR:

