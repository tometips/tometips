require 'tip.engine'
json = require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local ActorTalents = require 'engine.interface.ActorTalents'

spoilers = {
    -- Currently active parameters.  TODO: Configurable
    active = {
        mastery = 1.3,

        -- To simplify implementation, we use one value for stats (str, dex,
        -- etc.) and powers (physical power, accuracy, mindpower, spellpower).
        stat_power = 100,

        -- According to chronomancer.lua, 300 is "the optimal balance"
        paradox = 300,

        _level = 50,
        _life = 1000,
        _max_life = 1000,

        -- The goal is to display effectiveness at 50% of max psi.
        psi = 50,
        max_psi = 100,
    },

    -- We iterate over these parameters to display the effects of a talent at
    -- different stats and talent levels.
    --
    -- determineDisabled depends on this particular layout (5 varying stats and
    -- 5 varying talent levels).
    all_active = {
        { stat_power=10,  _level=1,  talent_level=1},
        { stat_power=25,  _level=10, talent_level=1},
        { stat_power=50,  _level=25, talent_level=1},
        { stat_power=75,  _level=40, talent_level=1},
        { stat_power=100, _level=50, talent_level=1},
        { stat_power=100, _level=50, talent_level=2},
        { stat_power=100, _level=50, talent_level=3},
        { stat_power=100, _level=50, talent_level=4},
        { stat_power=100, _level=50, talent_level=5},
    },

    -- Merged into active whenever we're not processing per-stat /
    -- per-talent-level values.
    default_active = {
        stat = 100,
        power = 100,
        _level = 50,
        talent_level = 0,
    },

    -- Which parameters have been used for the current tooltip
    used = {
    },

    -- Paradox is a special case.  Unlike most parameter-dependent values, we
    -- only calculate for a single value of paradox.
    usedParadoxOnly = function(self)
        return #table.keys(self.used) == 1 and self.used.paradox
    end,

    -- Determines the HTML tooltip and CSS class to use for the current
    -- talent, by looking at spoilers.used, the results of determineDisabled,
    -- and the results so far of generating the talent message.
    usedMessage = function(self, disable, prev_results)
        disable = disable or {}
        local msg = {}

        local use_talent = self.used.talent and not disable.talent
        if use_talent then
            if self.active.alt_talent then
                msg[#msg+1] = Actor.talents_def[self.active.alt_talent_fake_id or self.active.talent_id].name .. " talent levels 1-5"
            else
                msg[#msg+1] = "talent levels 1-5"
            end

            if self.used.mastery then msg[#msg+1] = ("talent mastery %.2f"):format(self.active.mastery) end
        end

        local stat_power_text
        -- As in determineDisabled, if both stats / powers and talents have an
        -- effect, hide the stats / powers to cut down on space usage.
        if use_talent then
            stat_power_text = tostring(self.active.stat_power)
            level_text = tostring(self.active._level)
        else
            stat_power_text = '10, 25, 50, 75, 100' -- HACK: Duplicated from self.all_active
            level_text = '1, 10, 25, 40, 50'
        end

        local use_stat_power = false
        if not disable.stat_power then
            for k, v in pairs(self.used.stat or {}) do
                if v then msg[#msg+1] = ("%s %s"):format(Actor.stats_def[k].name, stat_power_text) use_stat_power = true end
            end
            if self.used.attack then msg[#msg+1] = ("accuracy %s"):format(stat_power_text) use_stat_power = true end
            if self.used.physicalpower then msg[#msg+1] = ("physical power %s"):format(stat_power_text) use_stat_power = true end
            if self.used.spellpower then msg[#msg+1] = ("spellpower %s"):format(stat_power_text) use_stat_power = true end
            if self.used.mindpower then msg[#msg+1] = ("mindpower %s"):format(stat_power_text) use_stat_power = true end
            if self.used.combat_physresist then msg[#msg+1] = ("physical save %s"):format(stat_power_text) use_stat_power = true end
            if self.used.combat_spellresist then msg[#msg+1] = ("spell save %s"):format(stat_power_text) use_stat_power = true end
            if self.used.combat_mentalresist then msg[#msg+1] = ("mental save %s"):format(stat_power_text) use_stat_power = true end
        end

        if self.used.level and not disable.stat_power then
            msg[#msg+1] = 'character level ' .. level_text
            use_stat_power = true   -- not exactly, but close enough
        end

        -- TODO: Properly determine which talent components depend on max life
        -- See, e.g., Pride of the Orcs for a talent affected by this
        --if self.used.life then msg[#msg+1] = ("life %i"):format(self.active._life) use_stat_power = true end
        --if self.used.max_life then msg[#msg+1] = ("max life %i"):format(self.active._max_life) use_stat_power = true end

        if self.used.paradox then msg[#msg+1] = ("paradox %i"):format(self.active.paradox) use_stat_power = true end

        if self.used.psi and self.used.max_psi then
            -- MAJOR HACK: If it looks like we're in a "(max %d)" block, then
            -- don't include the psi percentage.  Also hard-code the fact that
            -- radius doesn't depend on psi percentage.
            if prev_results[#prev_results-1] ~= 'radius' and not (prev_results[#prev_results-2] == '(' and prev_results[#prev_results-1] == 'max') then
                msg[#msg+1] = ("psi %i%%"):format(self.active.psi / self.active.max_psi * 100)
            end
        elseif self.used.psi or self.used.max_psi then
            -- Abort, since we won't know how to handle.
            -- We can add handling if/when ToME starts using it.
            tip.util.logError("Unexpected use of psi without max_psi or vice versa")
            os.exit(1)
        end

        local css_class
        if use_stat_power and use_talent then
            css_class = 'variable'
        elseif use_stat_power then
            css_class = 'stat-variable'
        else
            css_class = 'talent-variable'
        end

        return (self:usedParadoxOnly() and "Value for\r" or "Values for\r") .. table.concat(msg, ",\r"), css_class
    end,

    -- Looks at the results of getTalentByLevel or multiDiff (a table) to see
    -- which active parameters were actually used for a particular set of
    -- results.
    determineDisabled = function(self, results)
        assert(#results == 9)

        -- All values are the same.  It must be paradox.
        if table.allSame(results) then
            return results[1], {}

        -- Values 5-10 have varying talents.  If they're all the same,
        -- then talents have no effect.
        elseif table.allSame(results, 5, 9) then
            return table.concat(results, ', ', 1, 5), { talent = true }

        -- Values 1-5 have varying stats / powers / levels.  If they're all the
        -- same, then stats / powers / levels have no effect.
        elseif table.allSame(results, 1, 5) then
            return table.concat(results, ', ', 5, 9), { stat_power = true }

        -- Both stats / powers and talents have an effect, but hide the
        -- stats / powers to cut down on space usage.
        else
            return table.concat(results, ', ', 5, 9), {}
        end
    end,

    formatResults = function(self, results, prev_results)
        local new_result, disabled = self:determineDisabled(results)
        local message, css_class = self:usedMessage(disabled, prev_results)
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
    },

    alt_talent = {
        ["cunning/poisons-effects"] = Actor.T_VILE_POISONS,
        ["cunning/traps"] = Actor.T_TRAP_MASTERY,
        ["chronomancy/manifold"] = Actor.T_WEAPON_MANIFOLD,
    },

    -- Indexed by active talent ID; gives the set of additional talent IDs
    -- to pass through (give the loaded talent level instead of forcing to 0)
    talent_passthrough = {
    }
}

-- Add DLC to talent configs if loaded
if Actor.T_VOLCANIC_ROCK then
    spoilers.talent_passthrough[Actor.T_VOLCANIC_ROCK] = { [Actor.T_VOLCANO] = true }
end
if Actor.T_BOULDER_ROCK then
    spoilers.talent_passthrough[Actor.T_BOULDER_ROCK] = { [Actor.T_THROW_BOULDER] = true }
end

local player = game.player
local player_metatable = getmetatable(player)
setmetatable(player, {
    __index = function(t, k)
        if k == 'level' or k == 'max_life' or k == 'life' then
            spoilers.used[k] = true
            return spoilers.active['_' .. k]
        else
            return player_metatable.__index[k]
        end
    end
})
-- Clear values that we need to route through our __index
player.level = nil
player.max_life = nil
player.life = nil

player.getStat = function(self, stat, scale, raw, no_inc)
    spoilers.used.stat = spoilers.used.stat or {}
    spoilers.used.stat[Actor.stats_def[stat].id] = true

    local val = spoilers.active.stat_power
    if no_inc then
        tip.util.logError("Unsupported use of getStat no_inc")
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
        tip.util.logError("Unsupported add to combatPhysicalpower")
    end
    spoilers.used.physicalpower = true
    return spoilers.active.stat_power * mod
end

player.combatSpellpower = function(self, mod, add)
    mod = mod or 1
    if add then
        tip.util.logError("Unsupported add to combatSpellpower")
    end
    spoilers.used.spellpower = true
    return spoilers.active.stat_power * mod
end

player.combatMindpower = function(self, mod, add)
    mod = mod or 1
    if add then
        tip.util.logError("Unsupported add to combatMindpower")
    end
    spoilers.used.mindpower = true
    return spoilers.active.stat_power * mod
end

player.combatPhysicalResist = function(self, fake)
    spoilers.used.combat_physresist = true
    return spoilers.active.stat_power
end

player.combatSpellResist = function(self, fake)
    spoilers.used.combat_spellresist = true
    return spoilers.active.stat_power
end

player.combatMentalResist = function(self, fake)
    spoilers.used.combat_mentalresist = true
    return spoilers.active.stat_power
end

player.getParadox = function(self)
    spoilers.used.paradox = true
    return spoilers.active.paradox
end

player.getPsi = function(self)
    spoilers.used.psi = true
    return spoilers.active.psi
end

player.getMaxPsi = function(self)
    spoilers.used.max_psi = true
    return spoilers.active.max_psi
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
        apply = 0,
        radius = 0,
        what = { ["physical, mental, or magical"] = true }
    }
end
player.getTalentLevel = function(self, id)
    if type(id) == "table" then id = id.id end
    if id == spoilers.active.talent_id then
        spoilers.used.talent = true
        spoilers.used.mastery = true
        return spoilers.active.talent_level * spoilers.active.mastery
    elseif spoilers.talent_passthrough[spoilers.active.talent_id] and spoilers.talent_passthrough[spoilers.active.talent_id][id] then
        return ActorTalents.getTalentLevel(player, id)
    else
        return 0
    end
end
player.getTalentLevelRaw = function(self, id)
    if type(id) == "table" then id = id.id end
    if id == spoilers.active.talent_id then
        spoilers.used.talent = true
        return spoilers.active.talent_level
    elseif spoilers.talent_passthrough[spoilers.active.talent_id] and spoilers.talent_passthrough[spoilers.active.talent_id][id] then
        return ActorTalents.getTalentLevelRaw(player, id)
    else
        return 0
    end
end

-- Overrides data/talents/psionic/psionic.lua.  TODO: Can we incorporate this at all?
function getGemLevel()
    return 0
end

require 'tip.utils'

function getByTalentLevel(actor, f)
    local result = {}

    spoilers.used = {}
    for i, v in ipairs(spoilers.all_active) do
        table.merge(spoilers.active, v)
        local this_result = f()
        if this_result then result[#result+1] = tostring(this_result) end
    end
    table.merge(spoilers.active, spoilers.default_active)

    if next(result) == nil then
        return nil
    elseif table.allSame(result) and not spoilers:usedParadoxOnly() then
        assert(next(spoilers.used) == nil)
        return result[1]
    else
        return spoilers:formatResults(result):gsub('\r', '<br>')
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

function getTalentReqDesc(player, t, tlev)
    -- Based on ActorTalents.getTalentReqDesc
    local new_require = {}
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
    return table.concat(new_require)
end

-- Process each talent, adding text descriptions of the various attributes
local talents_def_out = {}
for tid, orig_t in pairs(Actor.talents_def) do
    t = table.clone(orig_t)
    spoilers.active.talent_id = tid

    -- Special cases: Some talent categories depend on particular talents.
    spoilers.active.alt_talent = false
    spoilers.active.alt_talent_fake_id = nil
    if spoilers.alt_talent[t.type[1]] then
        spoilers.active.talent_id = spoilers.alt_talent[t.type[1]]
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

    t.info_text = tip.util.multiDiff(info_text, function(s, res)
        -- Reduce digits after the decimal.
        for i = 1, #s do
            s[i] = s[i]:gsub("(%d%d+)%.(%d)%d*", function(a, b) return tonumber(b) >= 5 and tostring(tonumber(a) + 1) or a end)
        end

        res:add(spoilers:formatResults(s, res))
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
    t.info_text = t.info_text:gsub('\n[-*][^\n]+', function(s)
        return '<li>' .. s:sub(3) .. '</li>'
    end)

    -- Turn line breaks into <p>
    t.info_text = '<p>' .. t.info_text:gsub("\n", "</p><p>") .. '</p>'

    -- Turn line breaks that we've added into normal line breaks
    t.info_text = t.info_text:gsub("\r", "<br>")

    -- Finish turning ad hoc lists into <ul>
    t.info_text = t.info_text:gsub('([^>])<li>', function(s)
        return s .. '</p><ul><li>'
    end)
    t.info_text = t.info_text:gsub('</li></p>', '</li></ul>')

    -- Add HTML character entities
    t.info_text = t.info_text:gsub('%-%-', '&mdash;')
    t.info_text = t.info_text:gsub('%.%.%.', '&hellip;')

    -- Handle font tags. Duplicated from tip.util.tstringToHtml.
    t.info_text = t.info_text:gsub('#{bold}#', tip.util.fontToSpan('bold'))
    t.info_text = t.info_text:gsub('#{italic}#', tip.util.fontToSpan('italic'))
    t.info_text = t.info_text:gsub('#{underline}#', tip.util.fontToSpan('underline'))
    t.info_text = t.info_text:gsub('#{normal}#', '</span></span>')
    t.info_text = t.info_text:gsub('#LAST#', '</span></span>')
    t.info_text = t.info_text:gsub('#([A-Z0-9_]+)#', tip.util.colorNameToSpan)

    -- Ending of info text.

    t.mode = t.mode or "activated"

    if t.mode ~= "passive" then
        if orig_t.range == Actor.talents_def[Actor.T_SHOOT].range then
            t.range = "archery"
        else
            t.range = getByTalentLevel(player, function() return ("%.1f"):format(player:getTalentRange(t)) end)

            -- Sample error handling:
            --local success, value = pcall(function() getByTalentLevel(player, function() return player:getTalentRange(t) end) end)
            --if not success then
            --    tip.util.logError(string.format("%s: range: %s\n", tid, value))
            --else
            --    t.range = value
            --end
        end
        -- Note: Not the same logic as ToME (which checks <= 1), but seems to work
        if t.range == 1 or t.range == "1" or t.range == "1.0" then t.range = "melee/personal" end

        -- Simple speed logic from 1.2.3 and earlier
        if not player.getTalentSpeed then
            if t.no_energy and type(t.no_energy) == "boolean" and t.no_energy == true then
                t.use_speed = "Instant"
            else
                t.use_speed = "1 turn"
            end
        else
            -- "Usage Speed" logic from Actor:getTalentFullDescription
            local uspeed = "Full Turn"
            local no_energy = util.getval(t.no_energy, player, t)
            local display_speed = util.getval(t.display_speed, player, t)
            if display_speed then
                uspeed = display_speed
            elseif no_energy and type(no_energy) == "boolean" and no_energy == true then
                uspeed = "Instant"
            else
                local speed = player:getTalentSpeed(t)
                local speed_type = player:getTalentSpeedType(t)
                if type(speed_type) == "string" then
                    speed_type = speed_type:capitalize()
                else
                    speed_type = 'Special'
                end
                -- Actual speed value is fairly meaningless for spoilers
                --uspeed = ("%s (#LIGHT_GREEN#%d%%#LAST# of a turn)"):format(speed_type, speed * 100)
                uspeed = speed_type
            end
            t.use_speed = uspeed
        end
    end

    t.cooldown = getvalByTalentLevel(t.cooldown, player, t)

    local cost = {}
    for i, v in ipairs(tip.raw_resources) do
        if t[v] then
            local c = getvalByTalentLevel(t[v], player, t)
            if c then
                cost[#cost+1] = string.format("%s %s", c, tip.resources[v])
            end
        end
    end
    if #cost > 0 then t.cost = table.concat(cost, ", ") end

    if t.image then t.image = t.image:gsub("talents/", "") end

    if t.require then
        local new_require = {}
        for tlev = 1, t.points do
            new_require[#new_require+1] = getTalentReqDesc(player, t, tlev)
        end
        t.require = new_require
        t.multi_require = t.points > 1
    end

    if t._dlc then t._dlc_name = tip.dlc[t._dlc].long_name end

    -- Strip unused elements in order to save space.
    t.display_entity = nil
    t.tactical = nil
    t.allow_random = nil
    t.no_npc_use = nil
    t.__ATOMIC = nil

    -- Find the info function, and use that to find where the talent is defined.
    --
    -- Inscriptions have their own newInscription function that sets an old_info function.
    --
    -- For other talents, engine.interface.ActorTalents:newTalent creates its own
    -- local info function based on the talent's provided info function, so we need to look
    -- for upvalues.
    local d = t.old_info and debug.getinfo(t.old_info) or tip.util.getinfo_upvalue(t.info, 'info')
    if d then
        t.source_code = tip.util.resolveSource(d)
    end

    talents_def_out[tid] = t
end

-- TODO: travel speed
--        local speed = self:getTalentProjectileSpeed(t)
--        if speed then d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, ""..(speed * 100).."% of base", true)
--        else d:add({"color",0x6f,0xff,0x83}, "Travel Speed: ", {"color",0xFF,0xFF,0xFF}, "instantaneous", true)
--        end
--
-- Skip sustain_slots ("Will Deactivate"); it would be nontrivial (ToME's own
-- version just checks currently active sustains), and talent descriptions are
-- hopefully good enough.

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

            local v_out = table.clone(v)
            v_out.talents = {}
            for i = 1, #v.talents do
                if not shouldSkipTalent(v.talents[i]) then
                    table.insert(v_out.talents, talents_def_out[v.talents[i].id])
                end
            end

            local category = k:split('/')[1]
            talents_by_category[category] = talents_by_category[category] or {}
            table.insert(talents_by_category[category], v_out)
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
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'tome.json', 'w')
out:write(json.encode({
    -- Official ToME tag in git.net-core.org to link to.
    tag = tip.git_tag,

    version = tip.version,

    talent_categories = talent_categories,
}, {sort_keys=true}))
out:close()

for k, v in pairs(talents_by_category) do
    local out = io.open(output_dir .. 'talents.'..k:gsub("[']", "_")..'.json', 'w')
    out:write(json.encode(v, {sort_keys=true}))
    out:close()
end

-- Output search indexes
-- Search indexes are sorted by name for more stable diffs
local talents_types_json = {}
local talents_json = {}
for cat_k, cat_v in pairs(talents_by_category) do    -- iterate over "categories" (celestial, cursed, etc.)
    for type_i, type_v in ipairs(cat_v) do           -- iterate over talent types (celestial/chants, celestial/combat, etc.)
        local type_name = cat_k .. '/' .. type_v.name
        talents_types_json[#talents_types_json+1] = { name=type_name, desc=type_v.description, href='talents/'..type_v.type }
        for talent_i, talent_v in ipairs(type_v.talents) do
            talents_json[#talents_json+1] = { name=talent_v.name, desc=("%s %i"):format(talent_v.type[1], talent_v.type[2]), href='talents/'..talent_v.type[1] }
        end
    end
end
table.sort(talents_types_json, function(a, b) return a.name < b.name end)
table.sort(talents_json, function(a, b) return a.name < b.name end)
local talents_types_out = io.open(output_dir .. 'search.talents-types.json', 'w')
local talents_out = io.open(output_dir .. 'search.talents.json', 'w')
talents_types_out:write(json.encode(talents_types_json, {sort_keys=true}))
talents_out:write(json.encode(talents_json, {sort_keys=true}))
talents_types_out:close()
talents_out:close()

