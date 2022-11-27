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

  self.componentSet = parseArchetype(self.archetype)

  for component in pairs(self.componentSet) do
    if not self.engine._componentSet[component] then
      error("No such component: " .. component)
    end
  end

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}
end

function M:addParent(component)
  local parent = self.parents[component]

  if not parent then
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

  if not child then
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

    for component in pairs(self.componentSet) do
      local componentType = self.engine._componentTypes[component]

      if componentType then
        local valueByteSize = ffi.sizeof(componentType.valueType)
        local columnByteSize = math.max(1, valueByteSize * self.shardCapacity)
        local columnData = love.data.newByteData(columnByteSize)
        shard.columnData[component] = columnData
        shard.columns[component] =
          ffi.cast(componentType.pointerType, columnData:getFFIPointer())
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

  for component in pairs(self.componentSet) do
    local column = shard.columns[component]
    local componentType = self.engine._componentTypes[component]

    if componentType then
      column[index] = componentType.valueType()
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
    local sourceColumn = sourceShard.columns[component]

    if sourceColumn then
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
