-- Lua utility functions, copied from te4's engine/utils.lua

--- Returns a clone of a table
-- @param tbl The original table to be cloned
-- @param deep Boolean to determine if recursive cloning occurs
-- @param k_skip A table containing key values set to true if you want to skip them.
-- @return The cloned table.
function table.clone(tbl, deep, k_skip)
	local n = {}
	k_skip = k_skip or {}
	for k, e in pairs(tbl) do
		if not k_skip[k] then
			-- Deep copy subtables, but not objects!
			if deep and type(e) == "table" and not e.__CLASSNAME then
				n[k] = table.clone(e, true, k_skip)
			else
				n[k] = e
			end
		end
	end
	return n
end

util = {}

function util.getval(val, ...)
	if type(val) == "function" then return val(...)
	elseif type(val) == "table" then return val[rng.range(1, #val)]
	else return val
	end
end

