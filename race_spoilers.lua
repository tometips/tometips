require 'tip.engine'
json = require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local Birther = require 'engine.Birther'

-- "Arena" and the Infinite Dungeon contain all available races from all normal (full) campaigns.
-- Normal campaigns like "Maj'Eyal" may have only a subset.
local world = Birther.birth_descriptor_def.world["Arena"]

local blacklist_races = { ['Tutorial Human'] = true, Construct = true }
local blacklist_subraces = { ['Tutorial Basic'] = true, ['Tutorial Stats'] = true, ['Runic Golem'] = true }

function img(file, w, h)
    return { file = 'npc/' .. file .. '.png', width = w, height = h }
end

-- Manually configured images for each subrace.  See class_spoilers.lua.
local subrace_images = {
    OGRE = { { 'giant_ogre_ogre_guard-cropped', 64, 112 } },
    DOOMELF = { { 'demon_statue_uruivellas-cropped', 61, 106 } },
}

function birtherRaceDescToHtml(desc)
    -- Replace the "Stat modifiers:" and "Life per level:" block,
    -- since we'll display those more neatly in HTML.
    desc = desc:gsub("\n#GOLD#Stat.*", "")

    -- Racial talents mistakenly use #WHITE# instead of #LAST#.
    desc = desc:gsub("#GOLD#([a-zA-Z ]+)#WHITE#", function(t) return '#GOLD#' .. t .. '#LAST#' end)

    return tip.util.tstringToHtml(string.toTString(desc))
end

local races = {}
local race_list = {}
for i, r in ipairs(Birther.birth_descriptor_def.race) do
    if world.descriptor_choices.race[r.name] and not blacklist_races[r.name] then
        race_list[#race_list+1] = r.short_name
        races[r.short_name] = {
            name = r.name,
            display_name = r.display_name,
            short_name = r.short_name,
            desc = birtherRaceDescToHtml(r.desc),
            locked_desc = r.locked_desc,
            subrace_list = {},
        }

        for j, sub in ipairs(Birther.birth_descriptor_def.subrace) do
            if r.descriptor_choices.subrace[sub.name] and not blacklist_subraces[sub.name] then
                -- Hack: Apply race's copy to subrace.  This modifies ToME's
                -- data structures, but we don't reuse them, so it's harmless.
                sub.full_copy = table.clone(r.copy)
                table.merge(sub.full_copy, sub.copy)
                table.insert(races[r.short_name].subrace_list, sub.short_name)
            end
        end
    end
end

local subraces = {}
local subrace_short_desc = {}
for i, sub in ipairs(Birther.birth_descriptor_def.subrace) do
    if not blacklist_subraces[sub.name] then
        subraces[sub.short_name] = {
            name = sub.name,
            display_name = sub.display_name,
            short_name = sub.short_name,
            desc = birtherRaceDescToHtml(sub.desc),
            locked_desc = sub.locked_desc,
            stats = sub.inc_stats,
            copy = sub.full_copy,
            experience = sub.experience,
            _dlc = sub._dlc,
            _dlc_name = sub._dlc and tip.dlc[sub._dlc].long_name or nil,
            images = table.mapv(function(v) return type(v) == 'table' and img(unpack(v)) or img(v) end, subrace_images[sub.short_name] or {}),
        }

        -- Hack: Look up size category text without an Actor object
        if sub.full_copy and sub.full_copy.size_category then subraces[sub.short_name].size = Actor.TextSizeCategory(sub.full_copy) end

        subrace_short_desc[sub.short_name] = sub.desc:split('\n')[1]
    end
end

-- Output the data
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'races.json', 'w')
out:write(json.encode({
    races = races,
    race_list = race_list,
    subraces = subraces,
}, {sort_keys=true}))
out:close()

-- Output the search indexes
-- Search indexes are sorted by name for more stable diffs
local races_json = {}
for race_k, race_v in pairs(races) do
    for subrace_i, subrace_v in ipairs(race_v.subrace_list) do
        local subrace = subraces[subrace_v]
        races_json[#races_json+1] = { name=subrace.display_name, desc=subrace_short_desc[subrace_v], href='races/'..race_v.short_name:lower()..'/'..subrace.short_name:lower() }
    end
end
table.sort(races_json, function(a, b) return a.name < b.name end)
local races_out = io.open(output_dir .. 'search.races.json', 'w')
races_out:write(json.encode(races_json, {sort_keys=true}))
races_out:close()
