local Class = require("tabula.Class")
local Entity = require("tabula.Entity")
local PrimitiveType = require("tabula.PrimitiveType")
local StructType = require("tabula.StructType")
local tableMod = require("tabula.table")
local TagType = require("tabula.TagType")
local lton = require("lton")
local ValueType = require("tabula.ValueType")

local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

local function formatArchetype(archetype)
  return "[" .. table.concat(sortedKeys(archetype), ", ") .. "]"
end

function M:init()
  print("Adding tablet #1 for archetype []")

  self.rootTablet = {
    index = 1,
    archetype = {},

    shards = {},
    shardCapacity = 256,

    parents = {},
    children = {},
  }

  self.tablets = { self.rootTablet }
  self.shards = {}

  self.entities = {}
  self.nextKey = 1

  self.dataTypes = {}
  self.componentTypes = {}
  self.names = {}
  self.eventSystems = {}
  self.queries = {}

  self:bootstrap()
end

function M:bootstrap()
  self.dataTypes.key = PrimitiveType.new("double")
  self.dataTypes.tag = TagType.new()
  self.dataTypes.value = ValueType.new()

  self.componentTypes.key = "key"
  self.componentTypes.dataType = "value"
  self.componentTypes.name = "value"
end

function M:addEntity(components)
  components = tableMod.copy(components)
  components.key = self.nextKey
  self.nextKey = self.nextKey + 1

  local archetype = keySet(components)
  archetype.key = nil

  local tablet = self:addTablet(archetype)
  local shard = tablet.shards[#tablet.shards]

  if shard == nil or shard.size == tablet.shardCapacity then
    shard = self:addShard(tablet)
  end

  local row = shard.size
  shard.size = shard.size + 1

  for component, column in pairs(shard.columns) do
    column[row] = components[component]
  end

  local entity = Entity.new(shard, row)
  self.entities[components.key] = entity
  return entity
end

function M:removeEntity(key)
  local entity = self.entities[key]

  if not entity then
    error("No such entity: " .. key)
  end

  entity._shard.columns.key[entity._row] = 0

  if entity._row == entity._shard.size - 1 then
    entity._shard.size = entity._shard.size - 1
  end

  entity._shard = nil
  entity._row = nil

  self.entities[key] = nil
end

function M:addTablet(archetype)
  local parentTablet = self.rootTablet
  local sortedComponents = sortedKeys(archetype)

  for i, component in ipairs(sortedComponents) do
    local childTablet = parentTablet.children[component]

    if not childTablet then
      local childArchetype = tableMod.copy(parentTablet.archetype)
      childArchetype[component] = true

      print(
        "Adding tablet #"
          .. (#self.tablets + 1)
          .. " for archetype "
          .. formatArchetype(childArchetype)
      )

      childTablet = {
        archetype = childArchetype,

        shards = {},
        shardCapacity = 256,

        parents = {},
        children = {},
      }

      parentTablet.children[component] = childTablet
      childTablet.parents[component] = parentTablet

      table.insert(self.tablets, childTablet)
    end

    parentTablet = childTablet
  end

  return parentTablet
end

function M:addShard(tablet)
  print(
    "Adding shard #"
      .. (#tablet.shards + 1)
      .. " for archetype "
      .. formatArchetype(tablet.archetype)
  )

  local shard = {
    tablet = tablet,
    columns = {},
    size = 0,
  }

  shard.columns.key = self.dataTypes.key:allocateArray(tablet.shardCapacity)

  for component in pairs(tablet.archetype) do
    local typeName = self.componentTypes[component]

    if not typeName then
      error("No such component: " .. component)
    end

    local dataType = self.dataTypes[typeName]
    shard.columns[component] = dataType:allocateArray(tablet.shardCapacity)
  end

  table.insert(tablet.shards, shard)
  table.insert(self.shards, shard)
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
