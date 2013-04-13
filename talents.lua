require 'engine.utils'

-- FIXME: Figure out where these should go and what they should do
colors = {}
DamageType = {}
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
    assert(loadfile(file:sub(2)))()
end
load = loadfile_and_execute

function newDamageType(args)
    DamageType[args.type] = args
end

function newTalentType(args)
    print(args.name)
    print(args.description)
end

function newTalent(args)
    print(args.name)
end

load("/data/damage_types.lua")

-- Copied (at least for now) from data/talents.lua
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

