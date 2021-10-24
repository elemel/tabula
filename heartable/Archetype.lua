local Class = require("heartable.Class")
local ffi = require("ffi")
local tableMod = require("heartable.table")

local copyArray = assert(tableMod.copyArray)
local doubleArrayType = ffi.typeof("double[?]")

local M = Class.new()

function M:init(componentTypes, components)
  self.componentTypes = assert(componentTypes)
  self.size = 0
  self.capacity = 1
  self.entities = doubleArrayType(self.capacity)
  self.columns = {}

  for _, component in ipairs(components) do
    local componentType = assert(self.componentTypes[component])
    self.columns[component] = componentType:allocateArray(self.capacity)
  end
end

function M:addEntity(entity, components)
  self:reserve(self.size + 1)

  local row = self.size
  self.size = row + 1
  self.entities[row] = entity

  for component, column in pairs(self.columns) do
    local value = components[component] or 0
    column[row] = value
  end

  return row
end

function M:reserve(capacity)
  if self.capacity < capacity then
    repeat
      self.capacity = self.capacity * 2
    until self.capacity >= capacity

    local entities = doubleArrayType(self.capacity)
    copyArray(self.entities, 0, self.size, entities, 0)
    self.entities = entities

    for component, column in pairs(self.columns) do
      local componentType = assert(self.componentTypes[component])
      local newColumn = componentType:allocateArray(self.capacity)
      copyArray(column, 0, self.size, newColumn, 0)
      self.columns[component] = newColumn
    end
  end
end

function M:removeEntity(row)
  assert(0 <= row and row < self.size)
  local movedEntity = 0

  if row < self.size - 1 then
    movedEntity = self.entities[self.size - 1]
    self.entities[row] = movedEntity

    for _, column in pairs(self.columns) do
      column[row] = column[self.size - 1]
    end
  end

  self.size = self.size - 1
  return movedEntity
end

return M
