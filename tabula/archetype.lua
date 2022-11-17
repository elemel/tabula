local tableMod = require("tabula.table")

local concat = assert(table.concat)
local copy = assert(tableMod.copy)
local gmatch = assert(string.gmatch)
local keys = assert(tableMod.keys)
local sort = assert(table.sort)

local M = {}

local cachedComponentArrays = {}
cachedComponentArrays.__mode = "k"

function M.toComponents(archetype, result)
  result = result or {}
  local cachedComponents = cachedComponentArrays[archetype]

  if not cachedComponents then
    local componentSet = { entity = true }

    for component in gmatch(archetype, "%w+") do
      componentSet[component] = true
    end

    cachedComponents = keys(componentSet)
    sort(cachedComponents)

    cachedComponentArrays[archetype] = cachedComponents
  end

  return copy(cachedComponents, result)
end

function M.fromComponentSet(componentSet)
  componentSet = copy(componentSet)
  componentSet.entity = nil

  local components = keys(componentSet)
  sort(components)

  return "/" .. concat(components, "/")
end

return M
