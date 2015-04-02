json = require 'lib.json4lua.json.json'

if #arg < 3 or #arg > 4 then
    print(("Usage: %s json_dir from_version to_version [prefix]"):format(arg[0]))
    os.exit(2)
end
local json_dir, from_version, to_version, prefix = unpack(arg)
json_dir = json_dir .. '/'
prefix = prefix or ''
print(("Processing changes from %s to %s..."):format(from_version, to_version))

function loadJson(filename)
    print(("Loading %s..."):format(filename))
    local f = io.open(filename, 'r')
    if not f then
        print(("Failed to load %s"):format(filename))
        os.exit(1)
    end
    local result = json.decode(f:read("*all"))
    f:close()
    return result
end

-- Load JSON files into a variable layout similar to the JS frontend.
tome = {}
for i, ver in ipairs({from_version, to_version}) do
    tome[ver] = loadJson(json_dir .. ver .. '/tome.json')
    tome[ver].talents = {}
    for j, cat in ipairs(tome[ver].talent_categories) do
        tome[ver].talents[cat] = loadJson(json_dir .. ver .. '/talents.' .. cat .. '.json')
    end
end

-- General diff algorithm, based on Heckel
-- (http://dl.acm.org/citation.cfm?doid=359460.359467), via Resig
-- (http://ejohn.org/projects/javascript-diff-algorithm/).
function diff(o, n)
    local os = {}
    local ns = {}

    for i = 1, #n do
        if not ns[n[i]] then
            ns[n[i]] = { rows = {}, o = nil }
        end
        table.insert(ns[n[i]].rows, i)
    end

    for i = 1, #o do
        if not os[o[i]] then
            os[o[i]] = { rows = {}, n = nil }
        end
        table.insert(os[o[i]].rows, i)
    end

    for k, v in pairs(ns) do
        if #ns[k].rows == 1 and os[k] and #os[k].rows == 1 then
            n[ns[k].rows[1]] = { text = n[ns[k].rows[1]], row = os[k].rows[1] }
            o[os[k].rows[1]] = { text = o[os[k].rows[1]], row = ns[k].rows[1] }
        end
    end

    for i = 1, #n - 1 do
        if n[i].text and not n[i+1].text and n[i].row + 1 < #o and not o[n[i].row + 1].text and n[i+1] == o[n[i].row + 1] then
            n[i+1] = { text = n[i+1], row = n[i].row + 1 }
            o[n[i].row+1] = { text = o[n[i].row+1], row = i + 1 }
        end
    end

    for i = #n - 1, 2, -1 do
        if n[i].text and not n[i-1].text and n[i].row > 1 and not o[n[i].row - 1].text and n[i-1] == o[n[i].row - 1] then
            n[i-1] = { text = n[i-1], row = n[i].row - 1 }
            o[n[i].row-1] = { text = o[n[i].row - 1], row = i - 1 }
        end
    end

    return o, n
end

-- Iterates over two tables, using the diff algorithm to find matching elements.
--
-- For each element, if a matching pair can be found (determined by keyFunction),
-- execute processFunction on the matching pair.
--
-- Otherwise, execute processFunction on whichever element is by itself.
--
-- Also based on Resig (http://ejohn.org/projects/javascript-diff-algorithm/).
--
-- NOTE: As currently used, this doesn't pick up on reordering.  Should it?
function processDiffTable(a, b, keyFunction, processFunction)
    local a_keys = {}
    local b_keys = {}
    for i = 1, #a do
        table.insert(a_keys, keyFunction(a[i]))
    end
    for i = 1, #b do
        table.insert(b_keys, keyFunction(b[i]))
    end

    local o, n = diff(a_keys, b_keys)

    if #n == 0 then
        for i = 1, #o do
            processFunction(a[i], nil)
        end
    else
        if type(n[1]) == 'string' then
            for j = 1, #o do
                if type(o[j]) ~= 'string' then break end
                processFunction(a[j], nil)
            end
        end

        for i = 1, #n do
            if type(n[i]) == 'string' then
                processFunction(nil, b[i])
            else
                for j = n[i].row + 1, #o do
                    if type(o[j]) ~= 'string' then break end
                    processFunction(a[j], nil)
                end
                processFunction(a[n[i].row], b[i])
            end
        end
    end
end

changes = { talents = {} }

local talent_keys = { 'info_text', 'cooldown', 'mode', 'cost', 'range', 'use_speed', 'require' }

-- 1.3 changes how use speed is displayed (from "1 turn" to "Weapon", "Spell", etc.)
local ignore_talent_keys = {}
if from_version == '1.2.5' and to_version == '1.3.0' then
    print("Ignoring use_speed")
    ignore_talent_keys.use_speed = true
end

function talentsMatch(from, to)
    for i = 1, #talent_keys do
        if not ignore_talent_keys[talent_keys[i]] then
            local lhs, rhs = from[talent_keys[i]], to[talent_keys[i]]
            -- Minimal table support.  For now, we only need arrays.
            if type(lhs) == 'table' and type(rhs) == 'table' then
                for j, v in ipairs(lhs) do
                    if lhs[j] ~= rhs[j] then return false end
                end
            elseif lhs ~= rhs then return false end
        end
    end
    return true
end

function recordChange(changelist, key, change_type, from, to)
    if #changelist == 0 or changelist[#changelist].name ~= key then
        table.insert(changelist, { name = key, values = {} })
    end

    -- To simplify usage within JavaScript:
    -- * If an entry is added or removed, then record the new / old entry
    --   under "value".
    -- * If an entry is changed, then record the new entry as "value" and the
    --   old entry as "value2".
    -- The result is that "value" is always the most relevant item to use.
    if from and to then
        table.insert(changelist[#changelist].values, { type=change_type, value=to, value2=from })
    else
        table.insert(changelist[#changelist].values, { type=change_type, value=to or from })
    end
end

processDiffTable(tome[from_version].talent_categories, tome[to_version].talent_categories,
    function(supercategory_name) return supercategory_name end,

    -- Iterate over talent "supercategory" names (spells, techniques, etc.)
    function(from, to)
        processDiffTable(tome[from_version].talents[from] or {}, tome[to_version].talents[to] or {},
            function(category_list) return category_list.type end,

            -- Iterate over talent categories ("spells/fire", etc.)
            function(from, to)
                -- Hack: Reconstruct the full user-visible name from the
                -- "supercategory" (before the slash) and the user-visible name
                -- after the slash.
                local category_type = from and from.type or to.type
                local category_name = category_type:gsub('/.*', '') .. ' / ' .. (from and from.name or to.name)

                processDiffTable(from and from.talents or {}, to and to.talents or {},
                    function(talent) return talent.name end,

                    -- Iterate over individual talents
                    function(from, to)
                        if not from then
                            recordChange(changes.talents, category_name, "added", from, to)
                        elseif not to then
                            recordChange(changes.talents, category_name, "removed", from, to)
                        elseif not talentsMatch(from, to) then
                            recordChange(changes.talents, category_name, "changed", from, to)
                        end
                    end)
            end)
    end)

local out = io.open(json_dir .. to_version .. '/' .. prefix .. 'changes.talents.json', 'w')
out:write(json.encode(changes.talents, {sort_keys=true}))
out:close()

