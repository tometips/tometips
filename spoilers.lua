-- This is the main script that generates the spoilers data.

local lua = arg[1]

-- List of versions and DLCs
require 'versions'

for version,dlcs in pairs(versions) do
  os.execute(lua..' class_spoilers.lua '..version)
  os.execute(lua..' race_spoilers.lua '..version)
  os.execute(lua..' talent_spoilers.lua '..version)
end

