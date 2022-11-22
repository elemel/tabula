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
local formatArchetype = assert(archetypeMod.format)
local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

function M:init()
  self._rows = {}
  self._nextEntity = 1

  self._dataTypes = {}
  self._columnTypeNames = {}

  self._eventSystems = {}
  self._queries = {}

  self._tablets = {}
  self._tabletVersion = 1
end

function M:addType(name, dataType)
  if self._dataTypes[name] then
    error("Duplicate type: " .. name)
  end

  self._dataTypes[name] = dataType
end

function M:addColumn(component, typeName)
  if self._columnTypeNames[component] then
    error("Duplicate column: " .. component)
  end

  self._columnTypeNames[component] = typeName
end

function M:addRow(values)
  if values.entity then
    if self.rows[entity] then
      error("Duplicate row: " .. entity)
    end
  else
    values = tableMod.copy(values)

    while self._rows[self._nextEntity] do
      self._nextEntity = self._nextEntity + 1
    end

    values.entity = self._nextEntity
    self._nextEntity = self._nextEntity + 1
  end

  local archetype = formatArchetype(values)
  local tablet = self:addTablet(archetype)

  local row = {}
  row._shard, row._index = tablet:addRow(values)
  setmetatable(row, rowMod.mt)
  self._rows[values.entity] = row
  return row
end

function M:findRow(entity)
  return self._rows[entity]
end

function M:removeRow(entity)
  local row = self._rows[entity]

  if not row then
    error("No such row: " .. entity)
  end

  row._shard.tablet:removeRow(row._shard, row._index)

  setmetatable(row, nil)
  clear(row)
  setmetatable(row, rowMod.invalidMt)

  self.rows[entity] = nil
end

function M:addTablet(archetype)
  local tablet = self._tablets[archetype]

  if not tablet then
    print("Adding tablet for archetype: " .. archetype)

    tablet = Tablet.new(self, archetype)
    self._tablets[archetype] = tablet

    self._tabletVersion = self._tabletVersion + 1
  end

  return tablet
end

function M:addEvent(event)
  if self._eventSystems[event] then
    error("Duplicate event: " .. event)
  end

  self._eventSystems[event] = {}
end

function M:addSystem(event, system)
  if not self._eventSystems[event] then
    error("No such event: " .. event)
  end

  assert(type(system) == "function", "Invalid system")
  table.insert(self._eventSystems[event], system)
end

function M:addQuery(name, query)
  if self._queries[name] then
    error("Duplicate query: " .. name)
  end

  for _, component in ipairs(query.includes) do
    if not self._columnTypeNames[component] then
      error("No such column: " .. component)
    end
  end

  for _, component in ipairs(query.excludes) do
    if not self._columnTypeNames[component] then
      error("No such column: " .. component)
    end
  end

  self._queries[name] = query
end

function M:handleEvent(event, ...)
  local systems = self._eventSystems[event]

  if not systems then
    error("No such event: " .. event)
  end

  for _, system in ipairs(systems) do
    system(self, ...)
  end
end

function M:eachShard(queryName, callback)
  local query = self._queries[queryName]

  if not query then
    error("No such query: " .. queryName)
  end

  query:updateTablets(self)
  query:eachShard(callback)
end

function M:eachRow(queryName, callback)
  local query = self._queries[queryName]

  if not query then
    error("No such query: " .. queryName)
  end

  query:updateTablets(self)
  query:eachRow(callback)
end

return M
