local Class = require("tabula.Class")
local CType = require("tabula.CType")
local ffi = require("ffi")
local rowMod = require("tabula.row")
local tableMod = require("tabula.table")
local Tablet = require("tabula.Tablet")
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

  self.rows = {}
  self.nextEntity = 1

  self.dataTypes = {
    boolean = CType.new(ffi.typeof("bool[?]")),
    number = CType.new(ffi.typeof("double[?]")),
    tag = TagType.new(),
    value = ValueType.new(),
  }

  self.componentTypes = { entity = "number" }
  self.names = {}
  self.eventSystems = {}
  self.queries = {}

  self.rootTablet = Tablet.new(self, {})
  self.tablets = { self.rootTablet }
end

function M:addEntity(components)
  local components = tableMod.copy(components)

  components.entity = self.nextEntity
  self.nextEntity = self.nextEntity + 1

  local archetype = keySet(components)
  archetype.entity = nil

  local tablet = self:addTablet(archetype)

  local shard, index = tablet:insertRow(components)
  local row = rowMod.newRow(shard, index)
  self.rows[components.entity] = row
  return row
end

function M:removeEntity(entity)
  local row = self.rows[entity]

  if not row then
    error("No such entity: " .. entity)
  end

  local shard = row._shard
  shard.columns.entity[row._index] = 0

  while shard.size > 0 and shard.columns.entity[shard.size - 1] == 0 do
    shard.size = shard.size - 1
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

      childTablet = Tablet.new(self, childArchetype)

      parentTablet.children[component] = childTablet
      childTablet.parents[component] = parentTablet

      table.insert(self.tablets, childTablet)
    end

    parentTablet = childTablet
  end

  return parentTablet
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
