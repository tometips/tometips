html/js/spoilers.js: spoilers.lua
	echo "tome = " > $@
	lua spoilers.lua >> $@
