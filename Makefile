html/js/spoilers.js: spoilers.lua
	echo "spoilers = " > $@
	lua spoilers.lua >> $@
