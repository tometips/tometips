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
function string.ends(s, ends)
   return ends == '' or string.sub(s, -string.len(ends)) == ends
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
    -- Filename minus leading version subdirectory
    local relative_filename = filename:sub(filename:find('/') + 1)

    if not source_lines[filename] then
        local f = assert(io.open(filename, 'r'))
        source_lines[filename] = f:read("*all"):split('\n')
        f:close()
    end

    for line = dbginfo.linedefined, 1, -1 do
        if source_lines[filename][line]:sub(1, 3) == "new" or source_lines[filename][line]:sub(1, 4) == "uber" then return { relative_filename, line } end
    end
end

function tip.util.logError(s)
    io.stderr:write((spoilers.active.talent_id or "unknown") .. ': ' .. s .. '\n')
end

local font_to_css = {
    italic = 'font-style: italic',
    underline = 'text-decoration: underline',
    bold = 'font-weight: bold',
}

function tip.util.tstringToHtml(tstr)
    local html = { '<p>' }, in_color, in_font

    local function closeColorIfNeeded()
        if in_color then html[#html+1] = '</span></span>' in_color = false end
    end
    local function closeFontIfNeeded()
        if in_font then html[#html+1] = '</span></span>' in_font = false end
    end

    for i, v in ipairs(tstr) do
        if v == true then
            closeColorIfNeeded()
            closeFontIfNeeded()
            html[#html+1] = '</p><p>'
        elseif v[1] == "color" then
            closeColorIfNeeded()
            in_color = true
            if #v == 4 then
                html[#html+1] = ('<span style="color: #%02x%02x%02x"><span class="tstr-color-%02x%02x%02x">'):format(v[2], v[3], v[4], v[2], v[3], v[4])
            else
                local c = colors[v[2]]
                html[#html+1] = ('<span style="color: #%02x%02x%02x"><span class="tstr-color-%s">'):format(c.r, c.g, c.b, v[2])
            end
        elseif v[1] == "font" then
            closeFontIfNeeded()
            if v[2] ~= 'normal' then
                in_font = true
                html[#html+1] = ('<span style="%s"><span class="tstr-font-%s">'):format(font_to_css[v[2]], v[2])
            end
        else
            html[#html+1] = string.escapeHtml(v)
        end
    end

    closeColorIfNeeded()
    closeFontIfNeeded()
    html[#html+1] = '</p>'

    return table.concat(html, '')
end

