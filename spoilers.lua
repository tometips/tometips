version = arg[1]
package.path = package.path..(';%s/?.lua;./%s/thirdparty/?.lua'):format(version, version)

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

-- Load init.lua and get version number.  Based on Module.lua.
local mod = { config={ settings={} } }
local mod_def = loadfile(version .. '/mod/init.lua')
setfenv(mod_def, mod)
mod_def()

local git_tag = version == 'master' and version or ('tome-%s'):format(version)
if not git_tag then
    io.stderr:write(('Unable to determine Git tag from requested version "%s"\n'):format(version))
    os.exit(1)
end

local old_loadfile = loadfile
loadfile = function(file)
    return old_loadfile(version .. file)
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
ActorStats:defineStat("Strength",     "str", 10, 1, 100, "Strength defines your character's ability to apply physical force. It increases your melee damage, damage done with heavy weapons, your chance to resist physical effects, and carrying capacity.")
ActorStats:defineStat("Dexterity",    "dex", 10, 1, 100, "Dexterity defines your character's ability to be agile and alert. It increases your chance to hit, your ability to avoid attacks, and your damage with light or ranged weapons.")
ActorStats:defineStat("Magic",        "mag", 10, 1, 100, "Magic defines your character's ability to manipulate the magical energy of the world. It increases your spell power, and the effect of spells and other magic items.")
ActorStats:defineStat("Willpower",    "wil", 10, 1, 100, "Willpower defines your character's ability to concentrate. It increases your mana, stamina and PSI capacity, and your chance to resist mental attacks.")
ActorStats:defineStat("Cunning",      "cun", 10, 1, 100, "Cunning defines your character's ability to learn, think, and react. It allows you to learn many worldly abilities, and increases your mental capabilities and chance of critical hits.")
ActorStats:defineStat("Constitution", "con", 10, 1, 100, "Constitution defines your character's ability to withstand and resist damage. It increases your maximum life and physical resistance.")
-- Luck is hidden and starts at half max value (50) which is considered the standard
ActorStats:defineStat("Luck",         "lck", 50, 1, 100, "Luck defines your character's fortune when dealing with unknown events. It increases your critical strike chance, your chance of random encounters, ...")

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

-- Finds the upvalue of f with the given name, and returns debug.getinfo for it
-- See http://www.lua.org/pil/23.1.html, http://www.lua.org/pil/23.1.2.html
function getinfo_upvalue(f, name)
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
function resolveSource(dbginfo)
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
    combat_mindcrit = 0, -- Shouldn't be needed; see http://forums.te4.org/viewtopic.php?f=42&t=39888
    body = { INVEN = 1000, QS_MAINHAND = 1, QS_OFFHAND = 1, MAINHAND = 1, OFFHAND = 1, FINGER = 2, NECK = 1, LITE = 1, BODY = 1, HEAD = 1, CLOAK = 1, HANDS = 1, BELT = 1, FEET = 1, TOOL = 1, QUIVER = 1, QS_QUIVER = 1 },
    wards = {},
    preferred_paradox = 0,
}
game.player = player

spoilers = {
    -- Currently active parameters.  TODO: Configurable
    active = {
        mastery = 1.3,
        -- To simplify implementation, we use one value for stats (str, dex,
        -- etc.) and powers (physical power, accuracy, mindpower, spellpower).
        stat_power = 100,
        -- According to chronomancer.lua, 300 is "the optimal balance"
        paradox = 300,
    },

    -- We iterate over these parameters to display the effects of a talent at
    -- different stats and talent levels.
    --
    -- determineDisabled depends on this particular layout (5 varying stats and
    -- 5 varying talent levels).
    all_active = {
        { stat_power=10,  talent_level=1},
        { stat_power=25,  talent_level=1},
        { stat_power=50,  talent_level=1},
        { stat_power=75,  talent_level=1},
        { stat_power=100, talent_level=1},
        { stat_power=100, talent_level=2}, 
        { stat_power=100, talent_level=3}, 
        { stat_power=100, talent_level=4}, 
        { stat_power=100, talent_level=5}, 
    },

    -- Merged into active whenever we're not processing per-stat /
    -- per-talent-level values.
    default_active = {
        stat = 100,
        power = 100,
        talent_level = 0,
    },

    -- Which parameters have been used for the current tooltip
    used = {
    },

    -- Determines the HTML tooltip and CSS class to use for the current
    -- talent, by looking at spoilers.used and the results of
    -- determineDisabled.
    usedMessage = function(self, disable)
        disable = disable or {}
        local tip = {}

        local use_talent = self.used.talent and not disable.talent
        if use_talent then
            if self.active.alt_talent then
                tip[#tip+1] = Actor.talents_def[self.active.alt_talent_fake_id or self.active.talent_id].name .. " talent levels 1-5"
            else
                tip[#tip+1] = "talent levels 1-5"
            end

            if self.used.mastery then tip[#tip+1] = ("talent mastery %.2f"):format(self.active.mastery) end
        end

        local stat_power_text
        -- As in determineDisabled, if both stats / powers and talents have an
        -- effect, hide the stats / powers to cut down on space usage.
        if use_talent then
            stat_power_text = tostring(self.active.stat_power)
        else
            stat_power_text = '10, 25, 50, 75, 100' -- HACK/TODO: Remove duplication with self.all_active
        end

        local use_stat_power = false
        if not disable.stat_power then
            for k, v in pairs(self.used.stat or {}) do
                if v then tip[#tip+1] = ("%s %s"):format(Actor.stats_def[k].name, stat_power_text) use_stat_power = true end
            end
            if self.used.attack then tip[#tip+1] = ("accuracy %s"):format(stat_power_text) use_stat_power = true end
            if self.used.physicalpower then tip[#tip+1] = ("physical power %s"):format(stat_power_text) use_stat_power = true end
            if self.used.spellpower then tip[#tip+1] = ("spellpower %s"):format(stat_power_text) use_stat_power = true end
            if self.used.mindpower then tip[#tip+1] = ("mindpower %s"):format(stat_power_text) use_stat_power = true end
        end

        if self.used.paradox then tip[#tip+1] = ("paradox %i"):format(self.active.paradox) use_stat_power = true end

        local css_class
        if use_stat_power and use_talent then
            css_class = 'variable'
        elseif use_stat_power then
            css_class = 'stat-variable'
        else
            css_class = 'talent-variable'
        end

        return "Values for " .. table.concat(tip, ", "), css_class
    end,

    -- Looks at the results of getTalentByLevel or multiDiff (a table) to see
    -- which active parameters were actually used for a particular set of
    -- results.
    determineDisabled = function(self, results)
        assert(#results == 9)

        -- Values 5-10 have varying talents.  If they're all the same,
        -- then talents have no effect.
        if table.allSame(results, 5, 9) then
            return table.concat(results, ', ', 1, 5), { talent = true }

        -- Values 1-5 have varying stats / powers.  If they're all the
        -- same, then stats / powers have no effect.
        elseif table.allSame(results, 1, 5) then
            return table.concat(results, ', ', 5, 9), { stat_power = true }

        -- Both stats / powers and talents have an effect, but hide the
        -- stats / powers to cut down on space usage.
        else
            return table.concat(results, ', ', 5, 9), {}
        end
    end,

    formatResults = function(self, results)
        local new_result, disabled = self:determineDisabled(results)
        local message, css_class = self:usedMessage(disabled)
        return '<acronym class="' .. css_class .. '" title="' .. message .. '">' .. new_result .. '</acronym>'
    end,

    blacklist_talent_type = {
        ["chronomancy/temporal-archery"] = true, -- unavailable in this ToME version
        ["psionic/possession"] = true,           -- unavailable in this ToME version
        ["psionic/psi-archery"] = true,          -- unavailable in this ToME version
        ["sher'tul/fortress"] = true,            -- unavailable in this ToME version
        ["tutorial"] = true,                     -- Do these even still exist?
        ["wild-gift/malleable-body"] = true,     -- unavailable in this ToME version (and not even intelligible)
        ["spell/war-alchemy"] = true,            -- Added in 1.2.0, but it only has the old fire alchemy "Heat" talent
    },

    blacklist_talent = {
        ["T_SHERTUL_FORTRESS_GETOUT"] = true,
        ["T_SHERTUL_FORTRESS_BEAM"] = true,
        ["T_SHERTUL_FORTRESS_ORBIT"] = true,
        ["T_GLOBAL_CD"] = true,                  -- aka "charms"
    }
}

function logError(s)
    io.stderr:write((spoilers.active.talent_id or "unknown") .. ': ' .. s .. '\n')
end

player.getStat = function(self, stat, scale, raw, no_inc)
    spoilers.used.stat = spoilers.used.stat or {}
    spoilers.used.stat[stat] = true

    local val = spoilers.active.stat_power
    if no_inc then
        logError("Unsupported use of getStat no_inc")
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

player.combatAttack = function(self, weapon, ammo)
    spoilers.used.attack = true
    return spoilers.active.stat_power
end

player.combatPhysicalpower = function(self, mod, weapon, add)
    mod = mod or 1
    if add then
        logError("Unsupported add to combatPhysicalpower")
    end
    spoilers.used.physicalpower = true
    return spoilers.active.stat_power * mod
end

player.combatSpellpower = function(self, mod, add)
    mod = mod or 1
    if add then
        logError("Unsupported add to combatSpellpower")
    end
    spoilers.used.spellpower = true
    return spoilers.active.stat_power * mod
end

player.combatMindpower = function(self, mod, add)
    mod = mod or 1
    if add then
        logError("Unsupported add to combatMindpower")
    end
    spoilers.used.mindpower = true
    return spoilers.active.stat_power * mod
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
    for i, v in ipairs(spoilers.all_active) do
        table.merge(spoilers.active, v)
        result[#result+1] = tostring(f())
    end
    table.merge(spoilers.active, spoilers.default_active)

    if table.allSame(result) then
        assert(next(spoilers.used) == nil)
        return result[1]
    else
        return spoilers:formatResults(result)
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
    -- Special case: Armour Training isn't very useful unless you're wearing armor.
    if tid == 'T_ARMOUR_TRAINING' then
        player.inven[player.INVEN_BODY][1] = { subtype = "heavy" }
    end

    -- Beginning of info text.  This is a bit complicated.
    local info_text = {}
    spoilers.used = {}
    for i, v in ipairs(spoilers.all_active) do
        table.merge(spoilers.active, v)
        info_text[i] = t.info(player, t):escapeHtml():toTString():tokenize(" ()[]")
    end
    table.merge(spoilers.active, spoilers.default_active)

    t.info_text = multiDiff(info_text, function(s, res)
        -- Reduce digits after the decimal.
        for i = 1, #s do
            s[i] = s[i]:gsub("(%d%d+)%.(%d)%d*", function(a, b) return tonumber(b) >= 5 and tostring(tonumber(a) + 1) or a end)
        end

        res:add(spoilers:formatResults(s))
    end):toString()

    -- Special case: Extract Gems is too hard to format
    if t.id == Actor.T_EXTRACT_GEMS then
        spoilers.active.talent_level = 5
        t.info_text = t.info(player, t):escapeHtml()
        spoilers.active.talent_level = nil
    end
    -- Special case: Finish Armour Training.
    if tid == 'T_ARMOUR_TRAINING' then
        player.inven[player.INVEN_BODY][1] = nil
        t.info_text = t.info_text:gsub(' with your current body armour', ', assuming heavy mail armour')
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
    t.info_text = t.info_text:gsub('%.%.%.', '&hellip;')

    -- Ending of info text.

    t.mode = t.mode or "activated"

    if t.mode ~= "passive" then
        if t.range == Actor.talents_def[Actor.T_SHOOT].range then
            t.range = "archery"
        else
            t.range = getByTalentLevel(player, function() return ("%.1f"):format(player:getTalentRange(t)) end)

            -- Sample error handling:
            --local success, value = pcall(function() getByTalentLevel(player, function() return player:getTalentRange(t) end) end)
            --if not success then
            --    logError(string.format("%s: range: %s\n", tid, value))
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

    local cost = {}
    for i, v in ipairs(raw_resources) do
        if t[v] then
            cost[#cost+1] = string.format("%s %s", getvalByTalentLevel(t[v], player, t), resources[v])
        end
    end
    if #cost > 0 then t.cost = table.concat(cost, ", ") end

    if t.image then t.image = t.image:gsub("talents/", "") end

    if t.require then
        -- Based on ActorTalents.getTalentReqDesc
        local new_require = {}
        local tlev = 1
        local req = t.require
        spoilers.used = {}
        if type(req) == "function" then req = req(player, t) end
        if req.level then
            local v = util.getval(req.level, tlev)
            if #new_require > 0 then new_require[#new_require+1] = ', ' end
            new_require[#new_require+1] = ("Level %d"):format(v)
        end
        if req.stat then
            for s, v in pairs(req.stat) do
                v = util.getval(v, tlev)
                if spoilers.used.stat then
                    local stat = {}
                    for k, s in pairs(spoilers.used.stat or {}) do
                        stat[#stat+1] = Actor.stats_def[k].short_name:capitalize()
                    end
                    if #new_require > 0 then new_require[#new_require+1] = ', ' end
                    new_require[#new_require+1] = ("%s %d"):format(table.concat(stat, " or "), v)
                else
                    if #new_require > 0 then new_require[#new_require+1] = ', ' end
                    new_require[#new_require+1] = ("%s %d"):format(player.stats_def[s].short_name:capitalize(), v)
                end
            end
        end
        if req.special then
            if #new_require > 0 then new_require[#new_require+1] = '; ' end
            new_require[#new_require+1] = req.special.desc
        end
        if req.talent then
            -- Currently unimplemented (not because it's hard, but because ToME doesn't use it)
            assert(false)
        end
        t.require = table.concat(new_require)
    end

    -- Strip unused elements in order to save space.
    t.display_entity = nil
    t.tactical = nil
    t.allow_random = nil
    t.no_npc_use = nil

    -- Find the info function, and use that to find where the talent is defined.
    --
    -- Inscriptions have their own newInscription function that sets an old_info function.
    --
    -- For other talents, engine.interface.ActorTalents:newTalent creates its own
    -- local info function based on the talent's provided info function, so we need to look
    -- for upvalues.
    local d = t.old_info and debug.getinfo(t.old_info) or getinfo_upvalue(t.info, 'info')
    if d then
        t.source_code = resolveSource(d)
    end
end

-- TODO: travel speed, requirements
--        local speed = self:getTalentProjectileSpeed(t)
--        if speed then d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, ""..(speed * 100).."% of base", true)
--        else d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, "instantaneous", true)
--        end

-- TODO: Special cases:
-- Golem's armor reconfiguration depends on armor mastery
-- Values that depend only on a stat - Wave of Power's range, prodigies - can these be improved?

-- Helper functions for organizing ToME's data for output
function shouldSkipTalent(t)
    -- Remove blacklisted and hide = "always" talents and five of the six copies of inscriptions.
    return spoilers.blacklist_talent[t.id] or
        (t.hide == 'always' and t.id ~= 'T_ATTACK') or
        (t.is_inscription and t.id:match('.+_[2-9]')) or
        shouldSkipPsiTalent(t)
end

-- Implementation for shouldSkipTalent: skip psionic talents that were hidden
-- and replaced but not actually removed in 1.2.0.
function shouldSkipPsiTalent(t)
    return t.hide == true and t.type[1]:starts("psionic/") and t.autolearn_mindslayer
end

-- Reorganize ToME's data for output
local talents_by_category = {}
local talent_categories = {}
for k, v in pairs(Actor.talents_types_def) do
    -- talent_types_def is indexed by both number and name.
    -- We only want to print by name.
    -- Also support blacklisting unavailable talent types.
    if type(k) ~= 'number' and not spoilers.blacklist_talent_type[k] then
        if next(v.talents) ~= nil then   -- skip talent categories with no talents

            -- This modifies the real in-memory talents table, but we shouldn't need the original version...
            for i = #v.talents, 1, -1 do
                if shouldSkipTalent(v.talents[i]) then
                    table.remove(v.talents, i)
                end
            end

            local category = k:split('/')[1]
            talents_by_category[category] = talents_by_category[category] or {}
            table.insert(talents_by_category[category], v)
            talent_categories[category] = true
        end
    end
end
talent_categories = table.keys(talent_categories)
table.sort(talent_categories)

for k, v in pairs(talents_by_category) do
    table.sort(v, function(a, b) return a.name:upper() < b.name:upper() end)
end

-- Output the data
local output_dir = (arg[2] or '.') .. '/'
print("OUTPUT DIRECTORY: " .. output_dir)
os.execute('mkdir -p ' .. output_dir)

local out = io.open(output_dir .. 'tome.json', 'w')
out:write(json.encode({
    -- Official ToME tag in git.net-core.org to link to.
    tag = git_tag,

    version = version,

    has_changes = version ~= '1.1.5', -- HACK: Hard-code for now

    talent_categories = talent_categories,
}))
out:close()

for k, v in pairs(talents_by_category) do
    local out = io.open(output_dir .. 'talents.'..k:gsub("[']", "_")..'.json', 'w')
    out:write(json.encode(v))
    out:close()
end

