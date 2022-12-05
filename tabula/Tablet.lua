local archetypeMod = require("tabula.archetype")
local Class = require("tabula.Class")
local shardMod = require("tabula.shard")
local tableMod = require("tabula.table")

local formatArchetype = assert(archetypeMod.format)
local parseArchetype = assert(archetypeMod.parse)

local M = Class.new()

function M:init(engine, archetype)
  self.engine = assert(engine)
  self.archetype = assert(archetype)

  self.columnSet = parseArchetype(self.archetype)

  for component in pairs(self.columnSet) do
    if not self.engine._columnSet[component] then
      error("No such column: " .. component)
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
    local columnSet = parseArchetype(self.archetype)
    assert(columnSet[component])
    columnSet[component] = nil
    local parentArchetype = formatArchetype(columnSet)
    parent = self.engine:addTablet(parentArchetype)
    self.parents[component] = parent
  end

  return parent
end

function M:addChild(component)
  local child = self.children[component]

  if not child then
    local columnSet = parseArchetype(self.archetype)
    assert(not columnSet[component])
    columnSet[component] = true
    local childArchetype = formatArchetype(columnSet)
    child = self.engine:addTablet(childArchetype)
    self.children[component] = child
  end

  return child
end

function M:pushRow()
  local shards = self.shards

  if #shards == 0 or shards[#shards]._size == self.shardCapacity then
    print(
      "Adding shard #" .. (#shards + 1) .. " for archetype: " .. self.archetype
    )

    local shard = shardMod.newShard(self)
    table.insert(shards, shard)
  end

  local shard = shards[#shards]

  local index = shard._size
  shard._size = shard._size + 1

  return shard, index
end

function M:popRow()
  local shard = self.shards[#self.shards]
  local index = shard._size - 1

  for component in pairs(self.columnSet) do
    local column = shard[component]
    local columnType = self.engine._columnTypes[component]

    if columnType then
      column[index] = columnType.valueType()
    else
      column[index] = nil
    end
  end

  shard._size = shard._size - 1

  if shard._size == 0 then
    table.remove(self.shards)
  end
end

function M:addRow(cells)
  local shard, index = self:pushRow()

  for component, value in pairs(cells) do
    local column = shard[component]
    column[index] = value
  end

  return shard, index
end

function M:removeRow(shard, index)
  local lastShard = self.shards[#self.shards]
  local lastIndex = lastShard._size - 1

  shardMod.copyRow(self.columnSet, lastShard, lastIndex, shard, index)
  self:popRow()
end

return M
