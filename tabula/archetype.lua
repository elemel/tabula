local tableMod = require("tabula.table")

local concat = assert(table.concat)
local copy = assert(tableMod.copy)
local gmatch = assert(string.gmatch)
local insert = assert(table.insert)
local keys = assert(tableMod.keys)
local sort = assert(table.sort)

local M = {}

local cachedComponentArrays = {}
cachedComponentArrays.__mode = "k"

function M.toComponents(archetype, result)
  result = result or {}
  local cachedComponents = cachedComponentArrays[archetype]

  if not cachedComponents then
    cachedComponents = {}

    for component in gmatch(archetype, "%w+") do
      insert(cachedComponents, component)
    end

    sort(cachedComponents)
    cachedComponentArrays[archetype] = cachedComponents
  end

  return copy(cachedComponents, result)
end

function M.fromComponentSet(componentSet)
  local components = keys(componentSet)
  sort(components)
  return "/" .. concat(components, "/")
end

return M
