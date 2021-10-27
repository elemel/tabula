local Class = require("heartable.Class")
local PrimitiveType = require("heartable.PrimitiveType")
local StringType = require("heartable.StringType")
local StructType = require("heartable.StructType")
local tableMod = require("heartable.table")
local TagType = require("heartable.TagType")
local lton = require("lton")

local keys = assert(tableMod.keys)

local M = Class.new()

function M:init()
  self.nextEntity = 1
  self.entities = {}

  self.names = {}
  self.dataTypes = {}
  self.componentTypes = {}

  self.tablets = {}
  self.tabletRoot = {}

  self.doubleType = PrimitiveType.new("double")

  self:bootstrap()
end

function M:bootstrap()
  self.names.name = self:addEntity({})
  self.names.string = self:addEntity({})
  self.names.tag = self:addEntity({})

  self.dataTypes.string = StringType.new()
  self.dataTypes.tag = TagType.new()

  self.componentTypes.name = "string"
end

function M:addEntity(components)
  local entity = self.nextEntity
  self.nextEntity = entity + 1

  local archetype = keys(components)
  table.sort(archetype)

  local tablet = self:addTablet(archetype)
  local shard = tablet.shards[#tablet.shards]

  if shard == nil or shard.size == shard.capacity then
    local entities = self.doubleType:allocateArray(tablet.shardCapacity)
    local columns = {}

    for _, columnType in ipairs(tablet.columnTypes) do
      local column = columnType:allocateArray(tablet.shardCapacity)
      table.insert(columns, column)
    end

    shard = {
      capacity = tablet.shardCapacity,
      size = 0,
      garbage = 0,

      entities = entities,
      columns = columns,
    }

    table.insert(tablet.shards, shard)
  end

  local rowIndex = shard.size
  shard.size = shard.size + 1

  shard.entities[rowIndex] = entity

  local row = {}

  for i, component in ipairs(archetype) do
    local column = shard.columns[i]
    local value = components[component]
    column[rowIndex] = value
  end

  self.entities[entity] = {
    generation = 0,
    shard = shard,
    rowIndex = rowIndex,
  }

  return entity
end

function M:addComponent(entity, component, value)
end

function M:removeEntity(entity)
  local lifecycle = self.entities[entity]
  local shard = lifecycle.shard

  if not shard then
    error("No such entity: " .. entity)
  end

  if lifecycle.rowIndex == shard.size - 1 then
    shard.size = shard.size - 1
  else
    shard.entities[lifecycle.rowIndex] = 0
    shard.garbage = shard.garbage + 1
  end
end

function M:addTablet(archetype)
  local previousComponent = ""
  local node = self.tabletRoot

  for _, component in ipairs(archetype) do
    if component <= previousComponent then
      error("Invalid archetype")
    end

    local nextNode = node[component]

    if nextNode == nil then
      nextNode = {}
      node[component] = nextNode
    end

    node = nextNode
    previousComponent = component
  end

  local tablet = node[0]

  if not tablet then
    print("Adding tablet: " .. table.concat(archetype, ", "))

    local columnTypes = {}

    for _, component in ipairs(archetype) do
      local componentType = assert(self.componentTypes[component])
      local dataType = assert(self.dataTypes[componentType])
      table.insert(columnTypes, dataType)
    end

    tablet = {
      archetype = archetype,
      columnTypes = columnTypes,
      shardCapacity = 256,
      shards = {},
    }

    table.insert(self.tablets, tablet)
    node[0] = tablet
  end

  return tablet
end

function M:handleEvent(event, ...)
end

return M
