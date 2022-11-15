local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local M = Class.new()

local function formatArchetype(archetype)
  return "{ " .. table.concat(archetype, ", ") .. " }"
end

function M:init(registry, archetype)
  self.registry = assert(registry)
  self.archetype = tableMod.copy(archetype)

  self.columnTypes = {}

  local entityTypeName = assert(self.registry.componentTypes.entity)
  self.columnTypes.entity = assert(self.registry.dataTypes[entityTypeName])

  for _, component in ipairs(self.archetype) do
    local typeName = assert(self.registry.componentTypes[component])
    self.columnTypes[component] = assert(self.registry.dataTypes[typeName])
  end

  self.defaultValues = {}

  for component, columnType in pairs(self.columnTypes) do
    self.defaultValues[component] = columnType.defaultValue
  end

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}
end

function M:addRow(values)
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

    for component, columnType in pairs(self.columnTypes) do
      shard.columns[component] = columnType:allocateArray(self.shardCapacity)
    end

    table.insert(shards, shard)
  end

  local shard = shards[#shards]

  local index = shard.size
  shard.size = shard.size + 1

  for component, column in pairs(shard.columns) do
    column[index] = values[component]
  end

  return shard, index
end

function M:removeRow(shard, index)
  local lastShard = self.shards[#self.shards]
  local lastIndex = lastShard.size - 1
end

return M
