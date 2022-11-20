local archetypeMod = require("tabula.archetype")
local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local M = Class.new()

function M:init(engine, archetype)
  self.engine = assert(engine)
  self.archetype = assert(archetype)

  local components = archetypeMod.toComponents(self.archetype)
  self.columnTypes = {}

  for _, component in ipairs(components) do
    local typeName = self.engine._columnTypeNames[component]

    if not typeName then
      error("No such column: " .. component)
    end

    local columnType = self.engine._dataTypes[typeName]

    if not columnType then
      error("No such type: " .. typeName)
    end

    self.columnTypes[component] = columnType
  end

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}
end

function M:addParent(component)
  local parent = self.parents[component]

  if parent == nil then
    local components = archetypeMod.toComponents(self.archetype)
    local componentSet = tableMod.valueSet(components)
    assert(componentSet[component])
    componentSet[component] = nil
    local parentArchetype = archetypeMod.fromComponentSet(componentSet)
    parent = self.engine:addTablet(parentArchetype)
    self.parents[component] = parent
  end

  return parent
end

function M:addChild(component)
  local child = self.children[component]

  if child == nil then
    local components = archetypeMod.toComponents(self.archetype)
    local componentSet = tableMod.valueSet(components)
    assert(not componentSet[component])
    componentSet[component] = true
    local childArchetype = archetypeMod.fromComponentSet(componentSet)
    child = self.engine:addTablet(childArchetype)
    self.children[component] = child
  end

  return child
end

function M:pushRow()
  local shards = self.shards

  if #shards == 0 or shards[#shards].size == self.shardCapacity then
    print(
      "Adding shard #" .. (#shards + 1) .. " for archetype: " .. self.archetype
    )

    local shard = {
      tablet = self,
      columns = {},
      size = 0,
    }

    for component, columnType in pairs(self.columnTypes) do
      shard.columns[component] = columnType:allocateColumn(self.shardCapacity)
    end

    table.insert(shards, shard)
  end

  local shard = shards[#shards]

  local index = shard.size
  shard.size = shard.size + 1

  return shard, index
end

function M:popRow()
  local shard = self.shards[#self.shards]
  local index = shard.size - 1

  for component, columnType in pairs(self.columnTypes) do
    local column = shard.columns[component]
    column[index] = columnType.defaultValue
  end

  shard.size = shard.size - 1

  if shard.size == 0 then
    table.remove(self.shards)
  end
end

function M:addRow(values)
  local shard, index = self:pushRow()

  for component, columnType in pairs(self.columnTypes) do
    local column = shard.columns[component]
    column[index] = tableMod.get(values, component, columnType.defaultValue)
  end

  return shard, index
end

function M:copyRow(targetShard, targetIndex, sourceShard, sourceIndex)
  assert(targetShard.tablet == self)

  for component, targetColumn in pairs(targetShard.columns) do
    local sourceColumn = sourceShard[component]

    if sourceColumn ~= nil then
      targetColumn[targetIndex] = sourceColumn[sourceIndex]
    end
  end
end

function M:removeRow(shard, index)
  local lastShard = self.shards[#self.shards]
  local lastIndex = lastShard.size - 1

  self:copyRow(shard, index, lastShard, lastIndex)
  self:popRow()
end

return M
