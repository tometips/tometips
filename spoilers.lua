local re = require("re")

-- T-Engine's C core.  Unimplemented as much as possible.
local surface_metatable = { __index = {} }
local font_metatable = { __index = {} }
__uids = {}
core = {
    display = {
        newSurface = function(x, y)
            local result = {}
            setmetatable(result, surface_metatable)
            return result
        end,
        newFont = function(font, size, no_cache)
            local result = { size = function(s) return 1 end, lineSkip = function() return 1 end }
            setmetatable(result, font_metatable)
            return result
        end,
    },
    fov = {},
    game = {},
    shader = {},
}
fs = {
    exists = function(path)
        --io.stderr:write(string.format("fs.exists(%s)\n", path))
        return false
    end,
    list = function(path)
        --io.stderr:write(string.format("fs.list(%s)\n", path))
        return {}
    end,
}
rng = {
    percent = function(chance) return false end, -- This shouldn't be needed, but data/talents/misc/horrors.lua calls it in its description
}

game = {
    level = {
        entities = {},
    },
    party = {
        hasMember = function(actor) return false end,
    },
}

local old_loadfile = loadfile
loadfile = function(file)
    -- Remove leading '/'
    return old_loadfile(file:sub(2))
end

function loadfile_and_execute(file)
    f = loadfile(file)
    assert(f)
    f()
end
load = loadfile_and_execute

require 'engine.dialogs.Chat'

require 'engine.utils'
require 'lib.json4lua.json.json'
local DamageType = require "engine.DamageType"
local ActorStats = require "engine.interface.ActorStats"
local ActorResource = require "engine.interface.ActorResource"
local ActorTalents = require 'engine.interface.ActorTalents'
local ActorInventory = require "engine.interface.ActorInventory"

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

load("/engine/colors.lua")

-- Body parts - copied from ToME's load.lua
ActorInventory:defineInventory("MAINHAND", "In main hand", true, "Most weapons are wielded in the main hand.", nil, {equipdoll_back="ui/equipdoll/mainhand_inv.png"})
ActorInventory:defineInventory("OFFHAND", "In off hand", true, "You can use shields or a second weapon in your off-hand, if you have the talents for it.", nil, {equipdoll_back="ui/equipdoll/offhand_inv.png"})
ActorInventory:defineInventory("PSIONIC_FOCUS", "Psionic focus", true, "Object held in your telekinetic grasp. It can be a weapon or some other item to provide a benefit to your psionic powers.", nil, {equipdoll_back="ui/equipdoll/psionic_inv.png", etheral=true})
ActorInventory:defineInventory("FINGER", "On fingers", true, "Rings are worn on fingers.", nil, {equipdoll_back="ui/equipdoll/ring_inv.png"})
ActorInventory:defineInventory("NECK", "Around neck", true, "Amulets are worn around the neck.", nil, {equipdoll_back="ui/equipdoll/amulet_inv.png"})
ActorInventory:defineInventory("LITE", "Light source", true, "A light source allows you to see in the dark places of the world.", nil, {equipdoll_back="ui/equipdoll/light_inv.png"})
ActorInventory:defineInventory("BODY", "Main armor", true, "Armor protects you from physical attacks. The heavier the armor the more it hinders the use of talents and spells.", nil, {equipdoll_back="ui/equipdoll/body_inv.png"})
ActorInventory:defineInventory("CLOAK", "Cloak", true, "A cloak can simply keep you warm or grant you wondrous powers should you find a magical one.", nil, {equipdoll_back="ui/equipdoll/cloak_inv.png"})
ActorInventory:defineInventory("HEAD", "On head", true, "You can wear helmets or crowns on your head.", nil, {equipdoll_back="ui/equipdoll/head_inv.png"})
ActorInventory:defineInventory("BELT", "Around waist", true, "Belts are worn around your waist.", nil, {equipdoll_back="ui/equipdoll/belt_inv.png"})
ActorInventory:defineInventory("HANDS", "On hands", true, "Various gloves can be worn on your hands.", nil, {equipdoll_back="ui/equipdoll/hands_inv.png"})
ActorInventory:defineInventory("FEET", "On feet", true, "Sandals or boots can be worn on your feet.", nil, {equipdoll_back="ui/equipdoll/boots_inv.png"})
ActorInventory:defineInventory("TOOL", "Tool", true, "This is your readied tool, always available immediately.", nil, {equipdoll_back="ui/equipdoll/tool_inv.png"})
ActorInventory:defineInventory("QUIVER", "Quiver", true, "Your readied ammo.", nil, {equipdoll_back="ui/equipdoll/ammo_inv.png"})
ActorInventory:defineInventory("GEM", "Socketed Gems", true, "Socketed gems.", nil, {equipdoll_back="ui/equipdoll/gem_inv.png"})
ActorInventory:defineInventory("QS_MAINHAND", "Second weapon set: In main hand", false, "Weapon Set 2: Most weapons are wielded in the main hand. Press 'x' to switch weapon sets.", true)
ActorInventory:defineInventory("QS_OFFHAND", "Second weapon set: In off hand", false, "Weapon Set 2: You can use shields or a second weapon in your off-hand, if you have the talents for it. Press 'x' to switch weapon sets.", true)
ActorInventory:defineInventory("QS_PSIONIC_FOCUS", "Second weapon set: psionic focus", false, "Weapon Set 2: Object held in your telekinetic grasp. It can be a weapon or some other item to provide a benefit to your psionic powers. Press 'x' to switch weapon sets.", true)
ActorInventory:defineInventory("QS_QUIVER", "Second weapon set: Quiver", false, "Weapon Set 2: Your readied ammo.", true)

-- Copied from ToME's load.lua
DamageType:loadDefinition("/data/damage_types.lua")
ActorTalents:loadDefinition("/data/talents.lua")

-- Actor resources - copied from ToME's load.lua
ActorResource:defineResource("Air", "air", nil, "air_regen", "Air capacity in your lungs. Entities that need not breath are not affected.")
ActorResource:defineResource("Stamina", "stamina", ActorTalents.T_STAMINA_POOL, "stamina_regen", "Stamina represents your physical fatigue. Each physical ability used reduces it.")
ActorResource:defineResource("Mana", "mana", ActorTalents.T_MANA_POOL, "mana_regen", "Mana represents your reserve of magical energies. Each spell cast consumes mana and each sustained spell reduces your maximum mana.")
ActorResource:defineResource("Equilibrium", "equilibrium", ActorTalents.T_EQUILIBRIUM_POOL, "equilibrium_regen", "Equilibrium represents your standing in the grand balance of nature. The closer it is to 0 the more balanced you are. Being out of equilibrium will negatively affect your ability to use Wild Gifts.", 0, false)
ActorResource:defineResource("Vim", "vim", ActorTalents.T_VIM_POOL, "vim_regen", "Vim represents the amount of life energy/souls you have stolen. Each corruption talent requires some.")
ActorResource:defineResource("Positive", "positive", ActorTalents.T_POSITIVE_POOL, "positive_regen", "Positive energy represents your reserve of positive power. It slowly decreases.")
ActorResource:defineResource("Negative", "negative", ActorTalents.T_NEGATIVE_POOL, "negative_regen", "Negative energy represents your reserve of negative power. It slowly decreases.")
ActorResource:defineResource("Hate", "hate", ActorTalents.T_HATE_POOL, "hate_regen", "Hate represents the level of frenzy of a cursed soul.")
ActorResource:defineResource("Paradox", "paradox", ActorTalents.T_PARADOX_POOL, "paradox_regen", "Paradox represents how much damage you've done to the space-time continuum. A high Paradox score makes Chronomancy less reliable and more dangerous to use but also amplifies the effects.", 0, false)
ActorResource:defineResource("Psi", "psi", ActorTalents.T_PSI_POOL, "psi_regen", "Psi represents the power available to your mind.")
ActorResource:defineResource("Soul", "soul", ActorTalents.T_SOUL_POOL, "soul_regen", "Soul fragments you have extracted from your foes.", 0, 10)

-- Actor stats - copied from ToME's load.lua
ActorStats:defineStat("Strength",	"str", 10, 1, 100, "Strength defines your character's ability to apply physical force. It increases your melee damage, damage done with heavy weapons, your chance to resist physical effects, and carrying capacity.")
ActorStats:defineStat("Dexterity",	"dex", 10, 1, 100, "Dexterity defines your character's ability to be agile and alert. It increases your chance to hit, your ability to avoid attacks, and your damage with light or ranged weapons.")
ActorStats:defineStat("Magic",		"mag", 10, 1, 100, "Magic defines your character's ability to manipulate the magical energy of the world. It increases your spell power, and the effect of spells and other magic items.")
ActorStats:defineStat("Willpower",	"wil", 10, 1, 100, "Willpower defines your character's ability to concentrate. It increases your mana, stamina and PSI capacity, and your chance to resist mental attacks.")
ActorStats:defineStat("Cunning",	"cun", 10, 1, 100, "Cunning defines your character's ability to learn, think, and react. It allows you to learn many worldly abilities, and increases your mental capabilities and chance of critical hits.")
ActorStats:defineStat("Constitution",	"con", 10, 1, 100, "Constitution defines your character's ability to withstand and resist damage. It increases your maximum life and physical resistance.")
-- Luck is hidden and starts at half max value (50) which is considered the standard
ActorStats:defineStat("Luck",		"lck", 50, 1, 100, "Luck defines your character's fortune when dealing with unknown events. It increases your critical strike chance, your chance of random encounters, ...")

function table.allSame(self)
    for i = 2, #self do
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
function multiDiff(str, on_diff)
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

local raw_resources = {'mana', 'soul', 'stamina', 'equilibrium', 'vim', 'positive', 'negative', 'hate', 'paradox', 'psi', 'feedback', 'fortress_energy', 'sustain_mana', 'sustain_equilibrium', 'sustain_vim', 'drain_vim', 'sustain_positive', 'sustain_negative', 'sustain_hate', 'sustain_paradox', 'sustain_psi', 'sustain_feedback' }

local resources = {}
for i, v in ipairs(raw_resources) do
    resources[v] = v
    resources[v] = resources[v]:gsub("sustain_", "")
    resources[v] = resources[v]:gsub("_", " ")
    resources[v] = resources[v]:gsub("positive", "positive energy")
    resources[v] = resources[v]:gsub("negative", "negative energy")
end

local Actor = require 'mod.class.Actor'
local player = Actor.new{
    combat_mindcrit = 0, -- TODO: Configurable(?)
    body = { INVEN = 1000, QS_MAINHAND = 1, QS_OFFHAND = 1, MAINHAND = 1, OFFHAND = 1, FINGER = 2, NECK = 1, LITE = 1, BODY = 1, HEAD = 1, CLOAK = 1, HANDS = 1, BELT = 1, FEET = 1, TOOL = 1, QUIVER = 1, QS_QUIVER = 1 },
    wards = {},
}
game.player = player

spoilers = {
    -- Currently active parameters.  TODO: Configurable
    active = {
        mastery = 1.3,
        stat = 100,
        spellpower = 100,
        mindpower = 100,
        -- According to chronomancer.lua, 300 is "the optimal balance"
        paradox = 300,
    },

    -- Which parameters have been used for the current tooltip
    used = {
    },

    usedMessage = function(self)
        local tip = {}
        if self.used.talent then
            if self.active.alt_talent then
                tip[#tip+1] = Actor.talents_def[self.active.alt_talent_fake_id or self.active.talent_id].name .. " levels 1-5"
            else
                tip[#tip+1] = "levels 1-5"
            end
        end
        if self.used.mastery then tip[#tip+1] = ("talent mastery %.2f"):format(self.active.mastery) end
        for k, v in pairs(self.used.stat or {}) do
            if v then tip[#tip+1] = ("%s %i"):format(Actor.stats_def[k].name, self.active.stat) end
        end
        if self.used.spellpower then tip[#tip+1] = ("spellpower %i"):format(self.active.spellpower) end
        if self.used.mindpower then tip[#tip+1] = ("mindpower %i"):format(self.active.mindpower) end
        if self.used.paradox then tip[#tip+1] = ("paradox %i"):format(self.active.paradox) end
        return "Values for " .. table.concat(tip, ", ")
    end,

}

player.getStat = function(self, stat, scale, raw, no_inc)
    spoilers.used.stat = spoilers.used.stat or {}
    spoilers.used.stat[stat] = true

    local val = spoilers.active.stat
    if no_inc then
        io.stderr:write("Unsupported use of getStat no_inc")
    end

    -- Based on interface.ActorStats.getStat
    if scale then
        if not raw then
            val = math.floor(val * scale / self.stats_def[stat].max)
        else
            val = val * scale / self.stats_def[stat].max
        end
    end
    return val
end

player.combatSpellpower = function(self, mod, add)
    mod = mod or 1
    if add then
        io.stderr:write("Unsupported add to combatSpellpower")
    end
    spoilers.used.spellpower = true
    return spoilers.active.spellpower * mod
end

player.combatMindpower = function(self, mod, add)
    mod = mod or 1
    if add then
        io.stderr:write("Unsupported add to combatMindpower")
    end
    spoilers.used.mindpower = true
    return spoilers.active.mindpower * mod
end

player.getParadox = function(self)
    spoilers.used.paradox = true
    return spoilers.active.paradox
end

player.isTalentActive = function() return false end  -- TODO: Doesn't handle spiked auras
player.hasEffect = function() return false end
player.getSoul = function() return math.huge end
player.knowTalent = function() return false end
player.getInscriptionData = function()
    return {
        inc_stat = 0,

        -- TODO: Can we use any better values for the following?
        range = 0,
        power = 0,
        dur = 0,
        heal = 0,
        effects = 0,
        speed = 0,
        heal_factor = 0,
        turns = 0,
        die_at = 0,
        mana = 0,
        what = { ["physical, mental, or magical"] = true }
    }
end
player.getTalentLevel = function(self, id)
    if type(id) == "table" then id = id.id end
    if id == spoilers.active.talent_id then
        spoilers.used.talent = true
        spoilers.used.mastery = true
        return spoilers.active.talent_level * spoilers.active.mastery
    else
        return 0
    end
end
player.getTalentLevelRaw = function(self, id)
    if type(id) == "table" then id = id.id end
    if id == spoilers.active.talent_id then
        spoilers.used.talent = true
        return spoilers.active.talent_level
    else
        return 0
    end
end

-- Overrides data/talents/psionic/psionic.lua.  TODO: Can we incorporate this at all?
function getGemLevel()
    return 0
end

function getByTalentLevel(actor, f)
    local result = {}

    spoilers.used = {}
    for i = 1, 5 do
        spoilers.active.talent_level = i
        result[#result+1] = tostring(f())
    end
    spoilers.active.talent_level = nil

    if table.allSame(result) then
        result = result[1]
    else
        result = table.concat(result, ", ")
    end

    if next(spoilers.used) ~= nil then
        return '<acronym class="variable" title="' .. spoilers:usedMessage() .. '">' .. result .. '</acronym>'
    else
        return result
    end
end

function getvalByTalentLevel(val, actor, t)
    if type(val) == "function" then
        return getByTalentLevel(actor, function() return val(actor, t) end)
    -- ToME supports random values, but we shouldn't need that.
    --elseif type(val) == "table" then
    --    return val[rng.range(1, #val)]
    else
        return val
    end
end

-- Process each talent, adding text descriptions of the various attributes
for tid, t in pairs(Actor.talents_def) do
    spoilers.active.talent_id = tid

    -- Special cases: Poison effects depend on the Vile Poisons talent.  Traps depend on Trap Mastery.
    spoilers.active.alt_talent = false
    spoilers.active.alt_talent_fake_id = nil
    if t.type[1] == "cunning/poisons-effects" then
        spoilers.active.talent_id = Actor.T_VILE_POISONS
        spoilers.active.alt_talent = true
    end
    if t.type[1] == "cunning/traps" then
        spoilers.active.talent_id = Actor.T_TRAP_MASTERY
        spoilers.active.alt_talent = true
    end
    -- Special case: Jumpgate's talent is tied to Jumpgate: Teleport.
    -- TODO: This is arguably a bug, since ToME can't properly report talent increases' effects either.
    if t.name:starts('Jumpgate') then
        spoilers.active.talent_id = Actor.T_JUMPGATE_TELEPORT
        spoilers.active.alt_talent = true
        spoilers.active.alt_talent_fake_id = Actor.T_JUMPGATE
    end

    -- Beginning of info text.  This is a bit complicated.
    -- TODO: Any way to get better tooltips for when one part depends on a stat but the rest doesn't?
    local info_text = {}
    spoilers.used = {}
    for i = 1, 5 do
        spoilers.active.talent_level = i
        info_text[i] = t.info(player, t):escapeHtml():toTString():tokenize(" ()[]")
    end
    spoilers.active.talent_level = nil

    t.info_text = multiDiff(info_text, function(s, res)
        -- Reduce digits after the decimal.
        for i = 1, #s do
            s[i] = s[i]:gsub("(%d%d+)%.(%d)%d*", function(a, b) return tonumber(b) >= 5 and tostring(tonumber(a) + 1) or a end)
        end

        res:add('<acronym class="variable" title="', spoilers:usedMessage(), '">', table.concat(s, ", "), '</acronym>')
    end):toString()

	-- Special case: Extract Gems is too hard to format
	if t.id == Actor.T_EXTRACT_GEMS then
		spoilers.active.talent_level = 5
		t.info_text = t.info(player, t):escapeHtml()
		spoilers.active.talent_level = nil
	end

    -- Hack: Fix text like "increases foo by 1., 2., 3., 4., 5."
    t.info_text = t.info_text:gsub('%., ', ", ")
    t.info_text = t.info_text:gsub(',, ', ", ")

    -- Turn ad hoc lists into <ul>
    t.info_text = t.info_text:gsub('\n[lL]evel %d+ *[-:][^\n]+', function(s)
        return '<li>' .. s:sub(2) .. '</li>'
    end)
    t.info_text = t.info_text:gsub('\nAt level %d+:[^\n]+', function(s)
        return '<li>' .. s:sub(2) .. '</li>'
    end)
    t.info_text = t.info_text:gsub('\n%-[^\n]+', function(s)
        return '<li>' .. s:sub(3) .. '</li>'
    end)

    -- Turn line breaks into <p>
    t.info_text = '<p>' .. t.info_text:gsub("\n", "</p><p>") .. '</p>'

    -- Finish turning ad hoc lists into <ul>
    t.info_text = t.info_text:gsub('([^>])<li>', function(s)
        return s .. '</p><ul><li>'
    end)
    t.info_text = t.info_text:gsub('</li></p>', '</li></ul>')

    -- Add HTML character entities
    t.info_text = t.info_text:gsub('%-%-', '&mdash;')

    -- Ending of info text.

    t.mode = t.mode or "activated"

    if t.mode ~= "passive" then
        if t.range == Actor.talents_def[Actor.T_SHOOT].range then
            t.range = "archery"
        else
            t.range = getByTalentLevel(player, function() return player:getTalentRange(t) end)

            -- Sample error handling:
            --local success, value = pcall(function() getByTalentLevel(player, function() return player:getTalentRange(t) end) end)
            --if not success then
            --    io.stderr:write(string.format("%s: range: %s\n", tid, value))
            --else
            --    t.range = value
            --end
        end
        -- Note: Not the same logic as ToME (which checks <= 1), but seems to work
        if t.range == 1 or t.range == "1" then t.range = "melee/personal" end

        if t.no_energy and type(t.no_energy) == "boolean" and t.no_energy == true then
            t.use_speed = "instant"
        else
            t.use_speed = "1 turn"
        end
    end

    t.cooldown = getvalByTalentLevel(t.cooldown, player, t)

    for i, v in ipairs(raw_resources) do
        cost = {}
        if t[v] then
            cost[#cost+1] = string.format("%s %s", getvalByTalentLevel(t[v], player, t), resources[v])
        end
        if #cost > 0 then t.cost = table.concat(cost, ", ") end
    end

    if t.image then t.image = t.image:gsub("talents/", "") end
end

local talents_types_def_dict = {}
for k, v in pairs(Actor.talents_types_def) do
    if type(k) ~= 'number' then
        talents_types_def_dict[k] = v
    end
end

-- TODO: travel speed, requirements, description
--        local speed = self:getTalentProjectileSpeed(t)
--        if speed then d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, ""..(speed * 100).."% of base", true)
--        else d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, "instantaneous", true)
--        end
-- TODO: Hide 'hide = "always"'?

-- TODO: Special cases:
-- Golem's armor reconfiguration depends on armor mastery
-- Values that depend only on a stat - Wave of Power's range, prodigies - can these be improved?

out = arg[1] and io.open(arg[1], 'w') or io.stdout
out:write("tome = ")
out:write(json.encode({
    colors = colors,
    -- FIXME: Strip death_message
    --DamageType = DamageType,
    talents_types_def = talents_types_def_dict,
    talents_def = Actor.talents_def
}))

