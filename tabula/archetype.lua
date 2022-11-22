local tableMod = require("tabula.table")

local concat = assert(table.concat)
local copy = assert(tableMod.copy)
local gmatch = assert(string.gmatch)
local insert = assert(table.insert)
local keys = assert(tableMod.keys)
local sort = assert(table.sort)

local M = {}

local cachedComponentSets = {}
cachedComponentSets.__mode = "k"

function M.parse(archetype, result)
  result = result or {}
  local componentSet = cachedComponentSets[archetype]

  if not componentSet then
    componentSet = {}

    for component in gmatch(archetype, "%w+") do
      componentSet[component] = true
    end

    cachedComponentSets[archetype] = componentSet
  end

  return copy(componentSet, result)
end

function M.format(componentSet)
  local components = keys(componentSet)
  sort(components)
  return "/" .. concat(components, "/")
end

return M
