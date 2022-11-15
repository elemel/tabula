local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local M = Class.new()

local function formatArchetype(archetype)
  return "{ " .. table.concat(tableMod.sortedKeys(archetype), ", ") .. " }"
end

function M:init(registry, archetype)
  self.registry = assert(registry)
  self.archetype = tableMod.copy(archetype)

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}
end

function M:insertRow(components)
  local shards = self.shards

  if #shards == 0 or shards[#shards].size == self.shardCapacity then
    print(
      "Adding shard #"
      .. (#shards + 1)
      .. " for archetype "
      .. formatArchetype(self.archetype)
      )

    local shard = {
      tablet = self,
      columns = {},
      size = 0,
    }

    shard.columns.entity = self:allocateColumn("entity")

    for component in pairs(self.archetype) do
      shard.columns[component] = self:allocateColumn(component)
    end

    table.insert(shards, shard)
  end

  local shard = shards[#shards]

  local index = shard.size
  shard.size = shard.size + 1

  for component, column in pairs(shard.columns) do
    column[index] = components[component]
  end

  return shard, index
end

function M:allocateColumn(component)
  local componentType = assert(self.registry.componentTypes[component])
  local dataType = assert(self.registry.dataTypes[componentType])
  return dataType:allocateArray(self.shardCapacity)
end

return M
