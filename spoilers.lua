require 'engine.utils'
require 'lib.json4lua.json.json'

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

local raw_resources = {'mana', 'soul', 'stamina', 'equilibrium', 'vim', 'positive', 'negative', 'hate', 'paradox', 'psi', 'feedback', 'fortress_energy', 'sustain_mana', 'sustain_equilibrium', 'sustain_vim', 'drain_vim', 'sustain_positive', 'sustain_negative', 'sustain_hate', 'sustain_paradox', 'sustain_psi', 'sustain_feedback' }

local resources = {}
for i, v in ipairs(raw_resources) do
    resources[v] = v
    resources[v] = resources[v]:gsub("sustain_", "")
    resources[v] = resources[v]:gsub("_", " ")
    resources[v] = resources[v]:gsub("positive", "positive energy")
    resources[v] = resources[v]:gsub("negative", "negative energy")
end

game = {}
local player = {}

-- Compute a diminishing returns value based on talent level that scales with a power
-- t = talent def table or a numeric value
-- low = value to match at talent level 1
-- high = value to match at talent level 5
-- power = scaling factor (default 0.5) or "log" for log10
-- add = amount to add the result (default 0)
-- shift = amount to add to the talent level before computation (default 0)
-- raw if true specifies use of raw talent level
player.combatTalentScale = function(self, t, low, high, power, add, shift, raw)
    local tl = type(t) == "table" and (raw and self:getTalentLevelRaw(t) or self:getTalentLevel(t)) or t
    power, add, shift = power or 0.5, add or 0, shift or 0
    local x_low, x_high = 1, 5 -- Implied talent levels to fit
    local x_low_adj, x_high_adj
    if power == "log" then
        x_low_adj, x_high_adj = math.log10(x_low+shift), math.log10(x_high+shift)
        tl = math.max(1, tl)
    else
        x_low_adj, x_high_adj = (x_low+shift)^power, (x_high+shift)^power
    end
    local m = (high - low)/(x_high_adj - x_low_adj)
    local b = low - m*x_low_adj
    if power == "log" then -- always >= 0
        return math.max(0, m * math.log10(tl + shift) + b + add)
--        return math.max(0, m * math.log10(tl + shift) + b + add), m, b
    else 
        return math.max(0, m * (tl + shift)^power + b + add)
--        return math.max(0, m * (tl + shift)^power + b + add), m, b
    end
end

player.hasEffect = function() return false end
player.getSoul = function() return math.huge end
player.knowTalent = function() return false end

function get_talent_level_val(val, actor, t)
    if type(val) == "function" then
        local result = {}
        for i = 1, 5 do
            actor.getTalentLevel = function() return i end
            result[#result+1] = tostring(val(actor, t))
            if result[#result] == result[#result-1] then result[#result] = nil end
        end
        actor.getTalentLevel = nil
        return table.concat(result, ", ")
    elseif type(val) == "table" then
        return val[rng.range(1, #val)]
    else
        return val
    end
end

for tid, t in pairs(talents_def) do
    t.mode = t.mode or "activated"

    if t.mode ~= "passive" then
        if t.no_energy and type(t.no_energy) == "boolean" and t.no_energy == true then
            t.use_speed = "instant"
        else
            t.use_speed = "1 turn"
        end
    end

    for i, v in ipairs(raw_resources) do
        cost = {}
        if t[v] then
            cost[#cost+1] = string.format("%s %s", get_talent_level_val(t[v], player, t), resources[v])
        end
        if #cost > 0 then t.cost = table.concat(cost, ", ") end
    end
end

-- TODO: travel speed, range, requirements, description
--         if self:getTalentRange(t) > 1 then d:add({"color",0x6f,0xff,0x83}, "Range: ", {"color",0xFF,0xFF,0xFF}, ("%0.1f"):format(self:getTalentRange(t)), true)
--        else d:add({"color",0x6f,0xff,0x83}, "Range: ", {"color",0xFF,0xFF,0xFF}, "melee/personal", true)
--        end
--        local speed = self:getTalentProjectileSpeed(t)
--        if speed then d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, ""..(speed * 100).."% of base", true)
--        else d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, "instantaneous", true)
--        end
-- TODO: cooldown for Rush and similar

if true then
    print(json.encode({
        colors = colors,
        -- FIXME: Strip death_message
        DamageType = DamageType,
        talents_types_def = talents_types_def,
        talents_def = talents_def
    }))
end

