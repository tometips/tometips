require 'tip.engine'
json = require 'lib.json4lua.json.json'

local Actor = require 'mod.class.Actor'
local Birther = require 'engine.Birther'

local world = Birther.birth_descriptor_def.world["Maj'Eyal"]

local blacklist_subclasses = { Psion = true }

function img(file, w, h)
    return { file = 'npc/' .. file .. '.png', width = w, height = h }
end

-- Manually configured images for each subclass. ToME itself instead uses
-- (I think) its paper dolls and particle system, but that would be too hard
-- to reproduce.
--
-- A few of these images aren't a great match; oh well.
local subclass_images = {
    ALCHEMIST = { 'humanoid_human_master_alchemist', 'alchemist_golem' },
    ADVENTURER = { 'hostile_humanoid_adventurers_party' },
    ANORITHIL = { 'patrol_sunwall_anorithil_patrol' },
    ARCANE_BLADE = { 'humanoid_human_arcane_blade' },
    ARCHER = { 'humanoid_thalore_thalore_hunter', 'humanoid_halfling_halfling_slinger' },
    ARCHMAGE = { { 'humanoid_shalore_elven_tempest-resized', 64, 80 }, { 'humanoid_human_pyromancer-cropped', 64, 80 } },
    BERSERKER = { 'humanoid_dwarf_norgan' },
    BRAWLER = { 'humanoid_human_slave_combatant' },
    BULWARK = { 'humanoid_human_last_hope_guard' },
    CORRUPTOR = { 'humanoid_shalore_elven_corruptor', 'humanoid_shalore_elven_blood_mage' },
    CURSED = { 'humanoid_human_ben_cruthdar__the_cursed' },
    DEMONOLOGIST = { 'humanoid_shalore_elven_warrior', 'demon_minor_fire_imp' },
    DOOMBRINGER = { { 'demon_major_champion_of_urh_rok-cropped', 64, 106 } },
    DOOMED = { 'shadow-caster' },
    MARAUDER = { { 'humanoid_human_rej_arkatis-cropped', 64, 78 } },
    MINDSLAYER = { { 'humanoid_yeek_yeek_mindslayer-cropped', 64, 85 } },
    NECROMANCER = { 'humanoid_human_necromancer', 'undead_lich_lich-cropped' },
    OOZEMANCER = { 'vermin_oozes_bloated_ooze', 'humanoid_dwarf_dwarven_summoner' },
    PARADOX_MAGE = { 'humanoid_elf_high_chronomancer_zemekkys' },
    REAVER = { 'humanoid_human_reaver' },
    ROGUE = { 'humanoid_human_rogue' },
    SHADOWBLADE = { 'humanoid_human_shadowblade' },
    SKIRMISHER = { 'humanoid_human_high_slinger' },
    SOLIPSIST = { 'humanoid_yeek_yeek_psionic' },
    SUMMONER = { 'humanoid_thalore_ziguranth_summoner', 'summoner_ritch' },
    SUN_PALADIN = { 'humanoid_human_sun_paladin_guren' },
    TEMPORAL_WARDEN = { 'humanoid_elf_star_crusader', 'humanoid_elf_elven_archer' },
    WYRMIC = { 'humanoid_human_fire_wyrmic', 'humanoid_human_multihued_wyrmic' },
}

function birtherDescToHtml(desc)
    -- Replace the "Stat modifiers:" and "Life per level:" block,
    -- since we'll display those more neatly in HTML.
    desc = desc:gsub("\n#GOLD#Stat.*", "")

    return tip.util.tstringToHtml(string.toTString(desc))
end

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
local subclass_short_desc = {}
for i, sub in ipairs(Birther.birth_descriptor_def.subclass) do
    if not blacklist_subclasses[sub.name] then
        -- Process talent types for HTML, and split them into class and generic
        local talents_types_class = {}
        local talents_types_generic = {}

        local check_talents_types = function(talents_types, unlockable)
            if type(talents_types) == 'table' then
                for k, v in pairs(talents_types) do
                    -- This "if" is necessary to handle unimplemented or nonexistent talents (!?)
                    if Actor.talents_types_def[k] then
                        -- Our output is the same as the array used by ToME, with
                        -- the following modifications:
                        --
                        -- Make masteries 1-based
                        v[2] = v[2] + 1.0
                        -- Add talent type name
                        v[3] = k:split('/')[1] .. ' / ' .. Actor.talents_types_def[k].name
                        -- Add whether or not it's unlockable
                        v[4] = unlockable

                        if Actor.talents_types_def[k].generic then
                            talents_types_generic[k] = v
                        else
                            talents_types_class[k] = v
                        end
                    end
                end
            end
        end

        check_talents_types(sub.talents_types)
        check_talents_types(sub.unlockable_talents_types, true)

        subclasses[sub.short_name] = {
            name = sub.name,
            display_name = sub.display_name,
            short_name = sub.short_name,
            desc = birtherDescToHtml(sub.desc),
            locked_desc = sub.locked_desc,
            stats = sub.stats,
            talents_types_class = talents_types_class,
            talents_types_generic = talents_types_generic,
            talents = sub.talents,
            copy_add = sub.copy_add,
            _dlc = sub._dlc,
            _dlc_name = sub._dlc and tip.dlc[sub._dlc].long_name or nil,
            images = table.mapv(function(v) return type(v) == 'table' and img(unpack(v)) or img(v) end, subclass_images[sub.short_name] or {}),
        }
        subclass_short_desc[sub.short_name] = sub.desc:split('\n')[1]
    end
end

-- Output the data
local output_dir = tip.outputDir()

local out = io.open(output_dir .. 'classes.json', 'w')
out:write(json.encode({
    classes = classes,
    class_list = class_list,
    subclasses = subclasses,
}, {sort_keys=true}))
out:close()

-- Output the search indexes
local classes_json = {}
for class_k, class_v in pairs(classes) do
    for subclass_i, subclass_v in ipairs(class_v.subclass_list) do
        local subclass = subclasses[subclass_v]
        classes_json[#classes_json+1] = { name=subclass.display_name, desc=subclass_short_desc[subclass_v], href='classes/'..class_v.short_name:lower()..'/'..subclass.short_name:lower() }
    end
end
local classes_out = io.open(output_dir .. 'search.classes.json', 'w')
classes_out:write(json.encode(classes_json, {sort_keys=true}))
classes_out:close()
