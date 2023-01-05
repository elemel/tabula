local archetypeMod = require("tabula.archetype")
local Class = require("tabula.Class")
local dataMod = require("tabula.data")
local ffi = require("ffi")
local queryMod = require("tabula.query")
local rowMod = require("tabula.row")
local tableMod = require("tabula.table")
local Tablet = require("tabula.Tablet")

local clear = assert(tableMod.clear)
local formatArchetype = assert(archetypeMod.format)
local keys = assert(tableMod.keys)
local keySet = assert(tableMod.keySet)
local sortedKeys = assert(tableMod.sortedKeys)

local M = Class.new()

function M:init()
  self._properties = {}

  self._dataTypes = {}
  self._columnSet = {}
  self._columnTypes = {}

  self._tablets = {}
  self._tabletVersion = 1

  self._rows = {}
  self._nextEntity = 1

  self._queries = {}
  self._eventSystems = {}
end

function M:setProperty(name, value)
  self._properties[name] = value
end

function M:getProperty(name)
  return self._properties[name]
end

function M:addDataType(name)
  if self._dataTypes[name] then
    error("Duplicate data type: " .. name)
  end

  self._dataTypes[name] = dataMod.newDataType(name)
end

function M:addColumn(component, typeName)
  if self._columnSet[component] then
    error("Duplicate column: " .. component)
  end

  if typeName then
    local columnType = self._dataTypes[typeName]

    if not columnType then
      error("No such data type: " .. typeName)
    end

    self._columnTypes[component] = columnType
  end

  self._columnSet[component] = true
end

function M:addRow(cells)
  if cells.entity then
    if self.rows[entity] then
      error("Duplicate row: " .. entity)
    end
  else
    cells = tableMod.copy(cells)

    while self._rows[self._nextEntity] do
      self._nextEntity = self._nextEntity + 1
    end

    cells.entity = self._nextEntity
    self._nextEntity = self._nextEntity + 1
  end

  local archetype = formatArchetype(cells)
  local tablet = self:addTablet(archetype)

  local row = {}
  row._shard, row._index = tablet:addRow(cells)
  setmetatable(row, rowMod.mt)
  self._rows[cells.entity] = row
  return row
end

function M:getRow(entity)
  return self._rows[entity]
end

function M:removeRow(entity)
  local row = self._rows[entity]

  if not row then
    error("No such row: " .. entity)
  end

  row._shard._tablet:removeRow(row._shard, row._index)

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

function M:addQuery(name, allOf, noneOf)
  if self._queries[name] then
    error("Duplicate query: " .. name)
  end

  allOf = allOf or {}
  noneOf = noneOf or {}

  for _, component in ipairs(allOf) do
    if not self._columnSet[component] then
      error("No such column: " .. component)
    end
  end

  for _, component in ipairs(noneOf) do
    if not self._columnSet[component] then
      error("No such column: " .. component)
    end
  end

  self._queries[name] = queryMod.newQuery(allOf, noneOf)
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

function M:eachRow(queryName, callback)
  local query = self._queries[queryName]

  if not query then
    error("No such query: " .. queryName)
  end

  queryMod.updateTablets(query, self)

  local arity = #query.allOf
  local func = queryMod.eachRowFuncs[arity]
  func(query.tablets, query.allOf, callback)
end

return M
