local tableMod = require("tabula.table")

local concat = assert(table.concat)
local copy = assert(tableMod.copy)
local gmatch = assert(string.gmatch)
local insert = assert(table.insert)
local keys = assert(tableMod.keys)
local sort = assert(table.sort)

local M = {}

local cachedColumnSets = {}
cachedColumnSets.__mode = "k"

function M.parse(archetype, result)
  result = result or {}
  local columnSet = cachedColumnSets[archetype]

  if not columnSet then
    columnSet = {}

    for component in gmatch(archetype, "%w+") do
      columnSet[component] = true
    end

    cachedColumnSets[archetype] = columnSet
  end

  return copy(columnSet, result)
end

function M.format(columnSet)
  local components = keys(columnSet)
  sort(components)
  return "/" .. concat(components, "/")
end

return M
