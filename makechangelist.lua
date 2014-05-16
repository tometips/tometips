require 'lib.json4lua.json.json'

if #arg ~= 3 then
    print(("Usage: %s json_dir from_version to_version"):format(arg[0]))
    os.exit(2)
end
local json_dir, from_version, to_version = unpack(arg)
json_dir = json_dir .. '/'
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

-- Iterates over two tables, whose members are in order.
--
-- For each element, if a matching pair can be found (determined by keyFunction),
-- execute processFunction on the matching pair.
--
-- Otherwise, execute processFunction on whichever element is by itself.
function processSortedTable(a, b, keyFunction, processFunction)
    local i, j = 1, 1
    while i <= #a or j <= #b do
        -- Assume string keys.  Do a case-insensitive comparison to match
        -- spoilers.lua's sort order.
        local key_a = i <= #a and keyFunction(a[i]):upper()
        local key_b = j <= #b and keyFunction(b[j]):upper()

        if key_a == key_b then
            processFunction(a[i], b[j])
            i = i + 1
            j = j + 1
        elseif key_a and (not key_b or key_a < key_b) then
            processFunction(a[i], nil)
            i = i + 1
        else
            processFunction(nil, b[j])
            j = j + 1
        end
    end
end

changes = { talents = {} }

function talentsMatch(from, to)
    -- FIXME: Check additional parameters
    return from.info_text == to.info_text
end

function recordChange(key, subkey, change_type, from, to)
    if #changes[key] == 0 or changes[key][#changes[key]].name ~= subkey then
        table.insert(changes[key], { name = subkey, values = {} })
    end

    -- To simplify usage within JavaScript:
    -- * If an entry is added or removed, then record the new / old entry
    --   under "value".
    -- * If an entry is changed, then record the new entry as "value" and the
    --   old entry as "value2".
    -- The result is that "value" is always the most relevant item to use.
    if from and to then
        table.insert(changes[key][#changes[key]].values, { type=change_type, value=to, value2=from })
    else
        table.insert(changes[key][#changes[key]].values, { type=change_type, value=to or from })
    end
end

processSortedTable(tome[from_version].talent_categories, tome[to_version].talent_categories,
    function(supercategory_name) return supercategory_name end,

    -- Iterate over talent "supercategory" names (spells, techniques, etc.)
    function(from, to)
        processSortedTable(tome[from_version].talents[from] or {}, tome[to_version].talents[to] or {},
            function(category_list) return category_list.name end,

            -- Iterate over talent categories ("spells/fire", etc.)
            function(from, to)
                local category_type = from and from.type or to.type
                processSortedTable(from and from.talents or {}, to and to.talents or {},
                    function(talent) return talent.name end,

                    -- Iterate over individual talents
                    function(from, to)
                        if not from then
                            recordChange("talents", category_type, "added", from, to)
                        elseif not to then
                            recordChange("talents", category_type, "removed", from, to)
                        elseif not talentsMatch(from, to) then
                            recordChange("talents", category_type, "changed", from, to)
                        end
                    end)
            end)
    end)

local out = io.open(json_dir .. to_version .. '/changes.talents.json', 'w')
out:write(json.encode(changes.talents))
out:close()

