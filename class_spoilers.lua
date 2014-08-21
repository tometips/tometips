require 'tip.engine'
require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local Birther = require 'engine.Birther'

local world = Birther.birth_descriptor_def.world["Maj'Eyal"]

class = {}
for i, cls in ipairs(Birther.birth_descriptor_def.class) do
    if world.descriptor_choices.class[cls.name] then
        table.insert(class, {
            name = cls.name,
            display_name = cls.display_name,
            short_name = cls.short_name,
            desc = cls.desc,
            locked_desc = cls.locked_desc,
            subclass = {},
        })

        for j, sub in ipairs(Birther.birth_descriptor_def.subclass) do
            if cls.descriptor_choices.subclass[sub.name] then
                table.insert(class[#class].subclass, {
                    name = sub.name,
                    display_name = sub.display_name,
                    short_name = sub.short_name,
                    desc = sub.desc,
                    locked_desc = sub.locked_desc,
                })
            end
        end
    end
end

-- Output the data
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'classes.json', 'w')
out:write(json.encode({
    class = class
}))
out:close()

