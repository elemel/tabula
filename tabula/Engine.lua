local Class = require("tabula.Class")
local CType = require("tabula.CType")
local ffi = require("ffi")
local rowMod = require("tabula.row")
local tableMod = require("tabula.table")
local TagType = require("tabula.TagType")
local lton = require("lton")
local ValueType = require("tabula.ValueType")

local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

local function formatArchetype(archetype)
  return "{ " .. table.concat(sortedKeys(archetype), ", ") .. " }"
end

function M:init()
  print("Adding tablet #1 for archetype { }")

  self.rootTablet = {
    archetype = {},

    shards = {},
    shardCapacity = 256,

    parents = {},
    children = {},
  }

  self.tablets = { self.rootTablet }
  self.shards = {}

  self.rows = {}
  self.nextEntity = 1

  self.dataTypes = {
    boolean = CType.new(ffi.typeof("bool[?]")),
    number = CType.new(ffi.typeof("double[?]")),
    tag = TagType.new(),
    value = ValueType.new(),
  }

  self.componentTypes = {}
  self.names = {}
  self.eventSystems = {}
  self.queries = {}
end

function M:addEntity(components)
  local entity = self.nextEntity
  self.nextEntity = self.nextEntity + 1

  local archetype = keySet(components)

  local tablet = self:addTablet(archetype)
  local shard

  if #tablet.shards == 0 then
    shard = self:addShard(tablet)
  else
    shard = tablet.shards[#tablet.shards]

    while shard._size > 0 and shard.entity[shard._size - 1] == 0 do
      shard._size = shard._size - 1
    end

    if shard._size == tablet.shardCapacity then
      shard = self:addShard(tablet)
    end
  end

  local index = shard._size
  shard._size = shard._size + 1

  shard.entity[index] = entity

  for component, value in pairs(components) do
    column = shard[component]
    column[index] = components[component]
  end

  self.rows[entity] = rowMod.newRow(shard, index)
  return entity
end

function M:removeEntity(entity)
  local row = self.rows[entity]

  if not row then
    error("No such entity: " .. entity)
  end

  local shard = row._shard
  shard.entity[row._index] = 0

  while shard._size > 0 and shard.entity[shard._size - 1] == 0 do
    shard._size = shard._size - 1
  end

  row._shard = nil
  row._index = nil

  self.rows[entity] = nil
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
    _tablet = tablet,
    _size = 0,
  }

  shard.entity = self.dataTypes.number:allocateArray(tablet.shardCapacity)

  for component in pairs(tablet.archetype) do
    local typeName = self.componentTypes[component]

    if not typeName then
      error("No such component: " .. component)
    end

    local dataType = self.dataTypes[typeName]
    shard[component] = dataType:allocateArray(tablet.shardCapacity)
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
