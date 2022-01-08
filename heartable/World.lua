local Class = require("heartable.Class")
local PrimitiveType = require("heartable.PrimitiveType")
local StructType = require("heartable.StructType")
local tableMod = require("heartable.table")
local TagType = require("heartable.TagType")
local lton = require("lton")
local ValueType = require("heartable.ValueType")

local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

function M:init()
  print("Adding tablet for root archetype {}")

  self.rootTablet = {
    archetype = {},

    shardSize = 256,
    shards = {},

    parents = {},
    children = {},
  }

  self.tablets = {self.rootTablet}

  self.nextEntity = 1
  self.entities = {}

  self.dataTypes = {}
  self.componentTypes = {}
  self.names = {}
  self.eventSystems = {}
  self.queries = {}

  self:bootstrap()
end

function M:bootstrap()
  self.dataTypes.int = PrimitiveType.new("int32_t")
  self.dataTypes.tag = TagType.new()
  self.dataTypes.value = ValueType.new()

  self.componentTypes.dataType = "value"
  self.componentTypes.name = "value"

  self.names.int = self:addEntity({})
  self.names.dataType = self:addEntity({})
  self.names.name = self:addEntity({})
  self.names.tag = self:addEntity({})
  self.names.value = self:addEntity({})
end

function M:addEntity(components)
  local entity = self.nextEntity
  self.nextEntity = entity + 1

  local archetype = keySet(components)
  local tablet = self:addTablet(archetype)
  local shard = tablet.shards[#tablet.shards]

  if shard == nil or shard.rowCount == tablet.shardSize then
    shard = self:addShard(tablet)
  end

  local rowIndex = shard.rowCount
  shard.rowCount = shard.rowCount + 1

  shard.entities[rowIndex] = entity

  for component in pairs(archetype) do
    local column = shard.columns[component]
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

  if lifecycle.rowIndex == shard.rowCount - 1 then
    shard.rowCount = shard.rowCount - 1
  else
    shard.entities[lifecycle.rowIndex] = 0
    shard.tombstoneCount = shard.tombstoneCount + 1
  end

  lifecycle.generation = lifecycle.generation + 1
  lifecycle.shard = nil
end

function M:addTablet(archetype)
  local tablet = self.rootTablet

  local components = keys(archetype)
  table.sort(components)

  for i, component in ipairs(components) do
    local childTablet = tablet.children[component]

    if not childTablet then
      local childArchetype = {}

      for j = 1, i do
        local childComponent = components[j]
        childArchetype[childComponent] = true
      end

      print("Adding tablet for archetype {" .. table.concat(sortedKeys(childArchetype), ", ") .. "}")

      childTablet = {
        archetype = childArchetype,

        shardSize = 256,
        shards = {},

        parents = {},
        children = {},
      }

      tablet.children[component] = childTablet
      childTablet.parents[component] = tablet

      table.insert(self.tablets, childTablet)
    end

    tablet = childTablet
  end

  return tablet
end

function M:addShard(tablet)
  print("Adding shard #" .. (#tablet.shards + 1) .. " for archetype {" .. table.concat(sortedKeys(tablet.archetype), ", ") .. "}")

  local entities = self.dataTypes.int:allocateArray(tablet.shardSize)
  local columns = {}

  for component in pairs(tablet.archetype) do
    local typeName = self.componentTypes[component]

    if not typeName then
      error("No such component: " .. component)
    end

    local dataType = self.dataTypes[typeName]
    columns[component] = dataType:allocateArray(tablet.shardSize)
  end

  shard = {
    tablet = tablet,

    rowCount = 0,
    tombstoneCount = 0,

    entities = entities,
    columns = columns,
  }

  table.insert(tablet.shards, shard)
  return shard
end

function M:addEvent(event)
  if self.eventSystems[event] then
    error("Duplicate event: " .. event)
  end

  self.eventSystems[event] = {}
end

function M:addSystem(event, system)
  if not self.eventSystems[event] then
    error("No such event: " .. event)
  end

  assert(type(system) == "function", "Invalid system")
  table.insert(self.eventSystems[event], system)
end

function M:handleEvent(event, ...)
  local systems = self.eventSystems[event]

  if not systems then
    error("No such event: " .. event)
  end

  for _, system in ipairs(systems) do
    system(self, ...)
  end
end

return M
