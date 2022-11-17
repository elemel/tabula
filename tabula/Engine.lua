local archetypeMod = require("tabula.archetype")
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

function M:init()
  self.rows = {}
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

  self.tablets = {}
  self.tabletVersion = 1
end

function M:addRow(values)
  local values = tableMod.copy(values)

  if values.entity then
    assert(not self.rows[entity], "Duplicate entity")
  else
    while self.rows[self.nextEntity] do
      self.nextEntity = self.nextEntity + 1
    end

    values.entity = self.nextEntity
    self.nextEntity = self.nextEntity + 1
  end

  local archetype = archetypeMod.fromComponentSet(values)
  local tablet = self:addTablet(archetype)

  local shard, index = tablet:addRow(values)
  local row = Row.new(shard, index)
  self.rows[values.entity] = row
  return row
end

function M:removeRow(entity)
  local row = assert(self.rows[entity], "No such row")
  row._shard.tablet:removeRow(row._shard, row._index)
  Row.invalidate(row)
  self.rows[entity] = nil
end

function M:addTablet(archetype)
  local tablet = self.tablets[archetype]

  if not tablet then
    print("Adding tablet for archetype " .. archetype)

    tablet = Tablet.new(self, archetype)
    self.tablets[archetype] = tablet

    self.tabletVersion = self.tabletVersion + 1
  end

  return tablet
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
