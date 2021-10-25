local Class = require("heartable.Class")
local ffi = require("ffi")
local tableMod = require("heartable.table")

local copyArray = assert(tableMod.copyArray)
local doubleArrayType = ffi.typeof("double[?]")

local M = Class.new()

function M:init(entityType, columnTypes)
  self.entityType = assert(entityType)
  self.columnTypes = assert(columnTypes)

  self.size = 0
  self.capacity = 1

  self.entities = doubleArrayType(self.capacity)
  self.columns = {}

  for _, columnType in ipairs(self.columnTypes) do
    local column = assert(columnType:allocateArray(self.capacity))
    table.insert(self.columns, column)
  end
end

function M:addRow(entity, row)
  self:reserve(self.size + 1)

  local rowIndex = self.size
  self.size = rowIndex + 1
  self.entities[rowIndex] = entity

  for columnIndex, column in ipairs(self.columns) do
    column[rowIndex] = row[columnIndex]
  end

  return rowIndex
end

function M:reserve(capacity)
  if self.capacity < capacity then
    repeat
      self.capacity = self.capacity * 2
    until self.capacity >= capacity

    local entities = doubleArrayType(self.capacity)
    copyArray(self.entities, 0, self.size, entities, 0)
    self.entities = entities

    for columnIndex, column in ipairs(self.columns) do
      local columnType = self.columnTypes[columnIndex]
      local newColumn = assert(columnType:allocateArray(self.capacity))
      copyArray(column, 0, self.size, newColumn, 0)
      self.columns[columnIndex] = newColumn
    end
  end
end

function M:removeRow(rowIndex)
  assert(0 <= rowIndex and rowIndex < self.size)
  local movedEntity = 0

  if rowIndex < self.size - 1 then
    movedEntity = self.entities[self.size - 1]
    self.entities[rowIndex] = movedEntity

    for _, column in pairs(self.columns) do
      column[rowIndex] = column[self.size - 1]
    end
  end

  self.size = self.size - 1
  return movedEntity
end

return M
