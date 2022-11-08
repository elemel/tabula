local Class = require("tabula.Class")
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

function M:init()
  print("Adding tablet #1 for archetype {}")

  self.rootTablet = {
    index = 1,
    archetype = {},

    shards = {},
    shardCapacity = 256,

    parents = {},
    children = {},
  }

  self.tablets = {self.rootTablet}
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
  local key = self.nextKey
  self.nextKey = self.nextKey + 1

  local archetype = keySet(components)
  local tablet = self:addTablet(archetype)
  local shard = tablet.shards[#tablet.shards]

  if shard == nil or shard.size == tablet.shardCapacity then
    shard = self:addShard(tablet)
  end

  local row = shard.size
  shard.size = shard.size + 1

  shard.keys[row] = key

  for component in pairs(archetype) do
    local column = shard.columns[component]
    local value = components[component]
    column[row] = value
  end

  self.entities[key] = {
    key = key,
    _shard = shard,
    _row = row,
  }

  return entity
end

function M:removeEntity(key)
  local entity = self.entities[key]

  if not entity then
    error("No such entity: " .. key)
  end

  entity.shard.key[entity.row] = 0

  if entity.row == entity.shard.size - 1 then
    entity.shard.size = entity.shard.size - 1
  end

  entity.shard = nil
  entity.row = nil

  self.entities[key] = nil
end

function M:addTablet(archetype)
  local parentTablet = self.rootTablet
  local sortedComponents = sortedKeys(archetype)

  for i, component in ipairs(sortedComponents) do
    local childTablet = parentTablet.children[component]

    if not childTablet then
      local childArchetype = {}

      for j = 1, i do
        local childComponent = sortedComponents[j]
        childArchetype[childComponent] = true
      end

      print("Adding tablet #" .. (#self.tablets + 1) .. " for archetype {" .. table.concat(sortedKeys(childArchetype), ", ") .. "}")

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
  print("Adding shard #" .. (#tablet.shards + 1) .. " for archetype {" .. table.concat(sortedKeys(tablet.archetype), ", ") .. "}")

  local shard = {
    tablet = tablet,
    keys = {},
    columns = {},
    size = 0,
  }

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
