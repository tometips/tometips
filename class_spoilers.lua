require 'tip.engine'
require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local Birther = require 'engine.Birther'

local world = Birther.birth_descriptor_def.world["Maj'Eyal"]

function birtherDescToHtml(desc)
    return tip.util.tstringToHtml(string.toTString(desc))
end

local blacklist_subclasses = { Psion = true }

local classes = {}
local class_list = {}
for i, cls in ipairs(Birther.birth_descriptor_def.class) do
    if world.descriptor_choices.class[cls.name] then
        class_list[#class_list+1] = cls.short_name
        classes[cls.short_name] = {
            name = cls.name,
            display_name = cls.display_name,
            short_name = cls.short_name,
            desc = birtherDescToHtml(cls.desc),
            locked_desc = cls.locked_desc,
            subclass_list = {},
        }

        for j, sub in ipairs(Birther.birth_descriptor_def.subclass) do
            if cls.descriptor_choices.subclass[sub.name] and not blacklist_subclasses[sub.name] then
                table.insert(classes[cls.short_name].subclass_list, sub.short_name)
            end
        end
    end
end

local subclasses = {}
for i, sub in ipairs(Birther.birth_descriptor_def.subclass) do
    subclasses[sub.short_name] = {
        name = sub.name,
        display_name = sub.display_name,
        short_name = sub.short_name,
        desc = birtherDescToHtml(sub.desc),
        locked_desc = sub.locked_desc,
    }
end

-- Output the data
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'classes.json', 'w')
out:write(json.encode({
    classes = classes,
    class_list = class_list,
    subclasses = subclasses,
}))
out:close()

