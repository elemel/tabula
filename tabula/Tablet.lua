local archetypeMod = require("tabula.archetype")
local Class = require("tabula.Class")
local ffi = require("ffi")
local tableMod = require("tabula.table")

local formatArchetype = assert(archetypeMod.format)
local parseArchetype = assert(archetypeMod.parse)

local M = Class.new()

function M:init(engine, archetype)
  self.engine = assert(engine)
  self.archetype = assert(archetype)

  local componentSet = parseArchetype(self.archetype)
  self.columnTypes = {}

  for component in pairs(componentSet) do
    local typeName = self.engine._columnTypeNames[component]

    if typeName == nil then
      error("No such column: " .. component)
    end

    local columnType = typeName and self.engine._dataTypes[typeName]

    if columnType == nil then
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
    local componentSet = parseArchetype(self.archetype)
    assert(componentSet[component])
    componentSet[component] = nil
    local parentArchetype = formatArchetype(componentSet)
    parent = self.engine:addTablet(parentArchetype)
    self.parents[component] = parent
  end

  return parent
end

function M:addChild(component)
  local child = self.children[component]

  if child == nil then
    local componentSet = parseArchetype(self.archetype)
    assert(not componentSet[component])
    componentSet[component] = true
    local childArchetype = formatArchetype(componentSet)
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
      columnData = {},
      columns = {},
      size = 0,
    }

    for component, columnType in pairs(self.columnTypes) do
      if columnType then
        local size = math.max(1, columnType.size * self.shardCapacity)
        shard.columnData[component] = love.data.newByteData(size)
        shard.columns[component] = ffi.cast(columnType.pointerType, shard.columnData[component]:getFFIPointer())
      else
        shard.columns[component] = {}
      end
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

    if columnType then
      column[index] = columnType.type()
    else
      column[index] = nil
    end
  end

  shard.size = shard.size - 1

  if shard.size == 0 then
    table.remove(self.shards)
  end
end

function M:addRow(values)
  local shard, index = self:pushRow()

  for component, value in pairs(values) do
    local column = shard.columns[component]
    column[index] = value
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
