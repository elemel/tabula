local archetypeMod = require("tabula.archetype")
local Class = require("tabula.Class")
local CType = require("tabula.CType")
local rowMod = require("tabula.row")
local ffi = require("ffi")
local tableMod = require("tabula.table")
local Tablet = require("tabula.Tablet")
local lton = require("lton")
local ValueType = require("tabula.ValueType")

local clear = assert(tableMod.clear)
local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

function M:init()
  self.rows = {}
  self.nextEntity = 1

  self.dataTypes = {}
  self.columnTypeNames = {}

  self.eventSystems = {}
  self.queries = {}

  self.tablets = {}
  self.tabletVersion = 1

  self:addType("double", CType.new("double"))
  self:addType("value", ValueType.new())

  self:addColumn("entity", "double")
end

function M:addType(name, dataType)
  assert(not self.dataTypes[name], "Duplicate type")
  self.dataTypes[name] = dataType
end

function M:addColumn(component, typeName)
  assert(not self.columnTypeNames[component], "Duplicate column")
  self.columnTypeNames[component] = typeName
end

function M:addRow(values)
  if values.entity then
    assert(not self.rows[entity], "Duplicate entity")
  else
    values = tableMod.copy(values)

    while self.rows[self.nextEntity] do
      self.nextEntity = self.nextEntity + 1
    end

    values.entity = self.nextEntity
    self.nextEntity = self.nextEntity + 1
  end

  local row = {}
  local columnValues = {}

  for component, value in pairs(values) do
    if self.columnTypeNames[component] then
      columnValues[component] = value
    else
      row[component] = value
    end
  end

  local archetype = archetypeMod.fromComponentSet(columnValues)
  local tablet = self:addTablet(archetype)

  row._shard, row._index = tablet:addRow(columnValues)
  setmetatable(row, rowMod.mt)
  self.rows[values.entity] = row
  return row
end

function M:findRow(entity)
  return self.rows[entity]
end

function M:removeRow(entity)
  local row = assert(self.rows[entity], "No such row")
  row._shard.tablet:removeRow(row._shard, row._index)

  setmetatable(row, nil)
  clear(row)
  setmetatable(row, rowMod.invalidMt)

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

function M:addQuery(name, query)
  assert(not self.queries[name], "Duplicate query")
  self.queries[name] = query
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

function M:eachRow(queryName, callback)
  local query = assert(self.queries[queryName], "No such query")
  query:eachRow(callback)
end

return M
