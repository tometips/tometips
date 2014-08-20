tip = tip or {}
tip.util = {}

function table.allSame(self, from, to)
    from = from or 1
    to = to or #self
    for i = from + 1, to do
        if self[i] ~= self[i-1] then return false end
    end
    return true
end

-- From http://lua-users.org/wiki/StringRecipes
function string.starts(s, start)
   return string.sub(s, 1, string.len(start)) == start
end

function string.escapeHtml(self)
    return self:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

-- Based on T-Engine's tstring:diffWith
function tip.util.multiDiff(str, on_diff)
    local res = tstring{}
    for i = 1, #str[1] do
        local s = {}
        for j = 1, #str do s[j] = str[j][i] end
        if type(str[1][i]) == "string" and not table.allSame(s) then
            on_diff(s, res)
        else
            res:add(str[1][i])
        end
    end
    return res
end

-- Finds the upvalue of f with the given name, and returns debug.getinfo for it
-- See http://www.lua.org/pil/23.1.html, http://www.lua.org/pil/23.1.2.html
function tip.util.getinfo_upvalue(f, name)
    local i = 1
    while true do
        local n, v = debug.getupvalue(f, i)
        if not n then return nil end
        if n == name then return debug.getinfo(v, 'S') end
        i = i + 1
    end
end

-- Support for loading source files and using debug.getinfo to find where
-- entities are defined.
local source_lines = {}
function tip.util.resolveSource(dbginfo)
    local filename = dbginfo.source:sub(2)

    if not source_lines[filename] then
        local f = assert(io.open(filename, 'r'))
        source_lines[filename] = f:read("*all"):split('\n')
        f:close()
    end

    for line = dbginfo.linedefined, 1, -1 do
        if source_lines[filename][line]:sub(1, 3) == "new" or source_lines[filename][line]:sub(1, 4) == "uber" then return { filename, line } end
    end
end

function tip.util.logError(s)
    io.stderr:write((spoilers.active.talent_id or "unknown") .. ': ' .. s .. '\n')
end

