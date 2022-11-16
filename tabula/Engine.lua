local Class = require("tabula.Class")
local CType = require("tabula.CType")
local Row = require("tabula.Row")
local ffi = require("ffi")
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
  return "/" .. table.concat(archetype, "/")
end

function M:init()
  self.entries = {}
  self.nextEntity = 1

  self.dataTypes = {
    boolean = CType.new("bool"),
    number = CType.new("double"),
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

function M:addRow(values)
  local values = tableMod.copy(values)

  if values.entity then
    assert(not self.entries[entity], "Duplicate entity")
  else
    while self.entries[self.nextEntity] do
      self.nextEntity = self.nextEntity + 1
    end

    values.entity = self.nextEntity
    self.nextEntity = self.nextEntity + 1
  end

  local archetypeSet = keySet(values)
  archetypeSet.entity = nil
  local archetype = sortedKeys(archetypeSet)

  local tablet = self:addTablet(archetype)

  local shard, index = tablet:addRow(values)
  local row = Row.new(shard, index)
  self.entries[values.entity] = row
  return row
end

function M:removeRow(entity)
  local row = assert(self.entries[entity], "No such row")
  row._shard.tablet:removeRow(row._shard, row._index)
  Row.invalidate(row)
  self.entries[entity] = nil
end

function M:addTablet(archetype)
  local parentTablet = self.rootTablet

  for i, component in ipairs(archetype) do
    local childTablet = parentTablet.children[component]

    if not childTablet then
      local childArchetypeSet = tableMod.valueSet(parentTablet.archetype)
      childArchetypeSet[component] = true
      local childArchetype = sortedKeys(childArchetypeSet)

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
