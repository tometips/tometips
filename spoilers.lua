require 'engine.utils'
require 'lib.json4lua.json.json'

Actor = {}

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
Actor.talents_types_def = {}
function newTalentType(t)
    t.description = t.description or ""
    t.points = t.points or 1
    t.talents = {}
    -- Omit for cleaner JSON
    -- table.insert(self.talents_types_def, t)
    Actor.talents_types_def[t.type] = t
end

-- from engine.interface.ActorTalents
Actor.talents_def = {}
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
    Actor.talents_def[t.id] = t
    Actor[t.id] = t.id

    -- Register in the type
    table.insert(Actor.talents_types_def[t.type[1]].talents, t)
end

-- from talents.lua
damDesc = function(self, type, dam)
    -- Increases damage
    if self.inc_damage then
        local inc = self:combatGetDamageIncrease(type)
        dam = dam + (dam * inc / 100)
    end
    return dam
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
local player = Actor

player.getTalentRange = function(self, t)
    if not t.range then return 1 end
    if type(t.range) == "function" then return t.range(self, t) end
    return t.range
end

player.getTalentRadius = function(self, t)
    if not t.radius then return 0 end
    if type(t.radius) == "function" then return t.radius(self, t) end
    return t.radius
end

--- Trigger a talent method
player.callTalent = function(self, tid, name, ...)
    local t = Actor.talents_def[tid]
    name = name or "trigger"
    if t[name] then return t[name](self, t, ...) end
end

player.rescaleDamage = function(self, dam)
    if dam <= 0 then return dam end
--	return dam * (1 - math.log10(dam * 2) / 7) --this is the old version, pre-combat-stat-rescale
    return dam ^ 1.04
end

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

-- Compute a diminishing returns value based on a stat value that scales with a power
-- stat == "str", "con",.... or a numeric value
-- low = value to match when stat = 10
-- high = value to match when stat = 100
-- power = scaling factor (default 0.5) or "log" for log10
-- add = amount to add the result (default 0)
-- shift = amount to add to the stat value before computation (default 0)
player.combatStatScale = function(self, stat, low, high, power, add, shift)
	stat = type(stat) == "string" and self:getStat(stat,nil,true) or stat
	power, add, shift = power or 0.5, add or 0, shift or 0
	local x_low, x_high = 10, 100 -- Implied stat values to match
	local x_low_adj, x_high_adj
	if power == "log" then
		x_low_adj, x_high_adj = math.log10(x_low+shift), math.log10(x_high+shift)
		stat = math.max(1, stat)
	else
		x_low_adj, x_high_adj = (x_low+shift)^power, (x_high+shift)^power
	end
	local m = (high - low)/(x_high_adj - x_low_adj)
	local b = low -m*x_low_adj
	if power == "log" then -- always >= 0
		return math.max(0, m * math.log10(stat + shift) + b + add)
--		return math.max(0, m * math.log10(stat + shift) + b + add), m, b
	else 
		return math.max(0, m * (stat + shift)^power + b + add)
--		return math.max(0, m * (stat + shift)^power + b + add), m, b
	end
end

-- Compute a diminishing returns value based on talent level that cannot go beyond a limit
-- t = talent def table or a numeric value
-- limit = value approached as talent levels increase
-- high = value at talent level 5
-- low = value at talent level 1 (optional)
-- raw if true specifies use of raw talent level
--    returns (limit - add)*TL/(TL + halfpoint) + add == add when TL = 0 and limit when TL = infinity
-- TL = talent level, halfpoint and add are internally computed to match the desired high/low values
-- note that the progression low->high->limit must be monotone, consistently increasing or decreasing
player.combatTalentLimit = function(self, t, limit, low, high, raw)
    local x_low, x_high = 1,5 -- Implied talent levels for low and high values respectively
    local tl = type(t) == "table" and (raw and self:getTalentLevelRaw(t) or self:getTalentLevel(t)) or t
    if low then
        local p = limit*(x_high-x_low)
        local m = x_high*high - x_low*low
        local halfpoint = (p-m)/(high - low)
        local add = (limit*(x_high*low-x_low*high) + high*low*(x_low-x_high))/(p-m)
        return (limit-add)*tl/(tl + halfpoint) + add
--        return (limit-add)*tl/(tl + halfpoint) + add, halfpoint, add
    else
        local add = 0
        local halfpoint = limit*x_high/(high-add)-x_high
        return (limit-add)*tl/(tl + halfpoint) + add
--        return (limit-add)*tl/(tl + halfpoint) + add, halfpoint, add
    end
end

--- Gets damage based on talent
player.combatTalentSpellDamage = function(self, t, base, max, spellpower_override)
    -- Compute at "max"
    local mod = max / ((base + 100) * ((math.sqrt(5) - 1) * 0.8 + 1))
    -- Compute real
    return self:rescaleDamage((base + (spellpower_override or self:combatSpellpower())) * ((math.sqrt(self:getTalentLevel(t)) - 1) * 0.8 + 1) * mod)
end

--- Gets damage based on talent
player.combatTalentStatDamage = function(self, t, stat, base, max)
    -- Compute at "max"
    local mod = max / ((base + 100) * ((math.sqrt(5) - 1) * 0.8 + 1))
    -- Compute real
    local dam = (base + (self:getStat(stat))) * ((math.sqrt(self:getTalentLevel(t)) - 1) * 0.8 + 1) * mod
    dam =  dam * (1 - math.log10(dam * 2) / 7)
    dam = dam ^ (1 / 1.04)
    return self:rescaleDamage(dam)
end

player.getStat = function(self, stat)
    return 100 -- TODO: Configurable
end

player.combatSpellpower = function(self, mod, add)
    mod = mod or 1
    if add then
        io.stderr:write("Unsupported add to combatSpellpower")
    end
    return 100 * mod   -- TODO: Configurable
end

player.getParadox = function(self)
    -- According to chronomancer.lua, 300 is "the optimal balance"
    return 300 -- TODO: Configurable, or at least report it
end

player.isTalentActive = function() return false end  -- TODO: Doesn't handle spiked auras
player.hasEffect = function() return false end
player.getSoul = function() return math.huge end
player.knowTalent = function() return false end
player.getInscriptionData = function()
    return {
        range = "varies"
    }
end

-- Overrides data/talents/psionic/psionic.lua.  TODO: Can we incorporate this at all?
function getGemLevel()
    return 0
end

function getByTalentLevel(actor, f)
    local result = {}
    for i = 1, 5 do
        actor.getTalentLevel = function() return i end
        actor.getTalentLevelRaw = function() return i end
        result[#result+1] = tostring(f())
        if result[#result] == result[#result-1] then result[#result] = nil end
    end
    actor.getTalentLevel = nil
    actor.getTalentLevelRaw = nil
    return #result > 0 and table.concat(result, ", ") or nil
end

function getvalByTalentLevel(val, actor, t)
    if type(val) == "function" then
        return getByTalentLevel(actor, function() return val(actor, t) end)
    elseif type(val) == "table" then
        return val[rng.range(1, #val)]
    else
        return val
    end
end

-- Process each talent, adding text descriptions of the various attributes
for tid, t in pairs(Actor.talents_def) do
    t.mode = t.mode or "activated"

    if t.mode ~= "passive" then
        if t.range == archery_range then
            t.range = "archery"
        else
            local success, value = pcall(function() getByTalentLevel(player, function() return player:getTalentRange(t) end) end)
            if not success then
                io.stderr:write(string.format("%s: range: %s\n", tid, value))
            else
                t.range = value
            end
        end
        if t.range == 1 then t.range = "melee/personal" end

        if t.no_energy and type(t.no_energy) == "boolean" and t.no_energy == true then
            t.use_speed = "instant"
        else
            t.use_speed = "1 turn"
        end
    end

    for i, v in ipairs(raw_resources) do
        cost = {}
        if t[v] then
            cost[#cost+1] = string.format("%s %s", getvalByTalentLevel(t[v], player, t), resources[v])
        end
        if #cost > 0 then t.cost = table.concat(cost, ", ") end
    end

    player.getTalentLevel = function() return 5 end
    player.getTalentLevelRaw = function() return 5 end
    t.info_text = t.info(player, t)
    player.getTalentLevel = nil
    player.getTalentLevelRaw = nil
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
        talents_types_def = Actor.talents_types_def,
        talents_def = Actor.talents_def
    }))
end

