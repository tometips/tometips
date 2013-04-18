require 'engine.utils'
require('lib.json4lua.json.json')

-- FIXME: Figure out where these should go and what they should do
resolvers = {
    equip = function() end,
    inscriptions = function() end,
    levelup = function() end,
    mbonus = function() end,
    nice_tile = function() end,
    racial = function() end,
    rngavg = function() end,
    sustains_at_birth = function() end,
    tactic = function() end,
    talents = function() end,
    tmasteries = function() end
}

function setDefaultProjector()
end

function loadfile_and_execute(file)
    -- Remove leading '/'
    -- Idiomatic version:
    -- assert(loadfile(file:sub(2)))()
    -- lua2js-compatible version:
    f = loadfile(file:sub(2))
    assert(f)
    f()
end
load = loadfile_and_execute

DamageType = {}
function newDamageType(t)
    DamageType[t.type] = t
end

-- from engine.interface.ActorTalents
talents_types_def = {}
function newTalentType(t)
	t.description = t.description or ""
	t.points = t.points or 1
	t.talents = {}
    -- Omit for cleaner JSON
	-- table.insert(self.talents_types_def, t)
	talents_types_def[t.type] = t
end

-- from engine.interface.ActorTalents
talents_def = {}
function newTalent(t)
	if type(t.type) == "string" then t.type = {t.type, 1} end
	if not t.type[2] then t.type[2] = 1 end
	t.short_name = t.short_name or t.name
	t.short_name = t.short_name:upper():gsub("[ ']", "_")
	t.mode = t.mode or "activated"
	t.points = t.points or 1

	-- Can pass a string, make it into a function
	if type(t.info) == "string" then
		local infostr = t.info
		t.info = function() return infostr end
	end

	-- Remove line stat with tabs to be cleaner ..
	local info = t.info
	t.info = function(self, t) return info(self, t):gsub("\n\t+", "\n") end

	t.id = "T_"..t.short_name
	talents_def[t.id] = t

	-- Register in the type
	table.insert(talents_types_def[t.type[1]].talents, t)
end

load("/engine/colors.lua")
load("/data/damage_types.lua")

-- This list is copied (at least for now) from data/talents.lua.
load("/data/talents/misc/misc.lua")
load("/data/talents/techniques/techniques.lua")
load("/data/talents/cunning/cunning.lua")
load("/data/talents/spells/spells.lua")
load("/data/talents/gifts/gifts.lua")
load("/data/talents/celestial/celestial.lua")
load("/data/talents/corruptions/corruptions.lua")
load("/data/talents/undeads/undeads.lua")
load("/data/talents/cursed/cursed.lua")
load("/data/talents/chronomancy/chronomancer.lua")
load("/data/talents/psionic/psionic.lua")
load("/data/talents/uber/uber.lua")

print(json.encode({
    colors = colors,
    -- FIXME: Strip death_message
    DamageType = DamageType,
    talents_types_def = talents_types_def
}))

