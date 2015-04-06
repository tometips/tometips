-- Creates a list of content in a particular DLC
-- Experimental; not yet used in HTML/JS

require 'tip.engine'
json = require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local Birther = require 'engine.Birther'

local dlc = table.clone(tip.dlc)
if next(dlc) then
    dlc.talents_types = {}
    for k, t in pairs(Actor.talents_types_def) do
        if type(k) == 'string' and t._dlc then
            dlc[t._dlc].talents_types = dlc[t._dlc].talents_types or {}
            table.insert(dlc[t._dlc].talents_types, k)
        end
    end

    dlc.subclasses = {}
    for i, sub in ipairs(Birther.birth_descriptor_def.subclass) do
        if sub._dlc then
            dlc[sub._dlc].subclass = dlc[sub._dlc].subclass or {}
            table.insert(dlc[sub._dlc].subclass, sub.short_name)
        end
    end

    dlc.subraces = {}
    for i, sub in ipairs(Birther.birth_descriptor_def.subrace) do
        if sub._dlc then
            dlc[sub._dlc].subrace = dlc[sub._dlc].subraces or {}
            table.insert(dlc[sub._dlc].subrace, sub.short_name)
        end
    end
end

-- Output the data
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'dlc.json', 'w')
out:write(json.encode(tip.dlc, {sort_keys=true}))
out:close()

