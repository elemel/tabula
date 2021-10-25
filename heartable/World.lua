local Class = require("heartable.Class")
local EntityTable = require("heartable.EntityTable")
local PrimitiveType = require("heartable.PrimitiveType")
local StringType = require("heartable.StringType")
local StructType = require("heartable.StructType")
local tableMod = require("heartable.table")
local TagType = require("heartable.TagType")

local keys = assert(tableMod.keys)

local M = Class.new()

function M:init()
  self.nextEntity = 1
  self.entities = {}

  self.names = {}
  self.dataTypes = {}
  self.componentTypes = {}

  self.entityTables = {}
  self.entityTableRoot = {}
  self:bootstrap()
end

function M:bootstrap()
  self.names.isComponent = self:addEntity({})
  self.names.isDataType = self:addEntity({})
  self.names.name = self:addEntity({})
  self.names.string = self:addEntity({})
  self.names.tag = self:addEntity({})

  self.dataTypes[self.names.string] = StringType.new()
  self.dataTypes[self.names.tag] = TagType.new()

  self.componentTypes[self.names.isComponent] = self.names.tag
  self.componentTypes[self.names.isDataType] = self.names.tag
  self.componentTypes[self.names.name] = self.names.string
end

function M:addEntity(components)
  for k, v in pairs(components) do
    print(k, v)
  end

  local entity = self.nextEntity
  self.nextEntity = entity + 1

  local entityType = keys(components)
  table.sort(entityType)

  local row = {}

  for i, component in ipairs(entityType) do
    local value = components[component]
    table.insert(row, value)
  end

  local entityTable = self:addEntityTable(entityType)
  local rowIndex = entityTable:addRow(entity, row)
  self.entities[entity] = {entityTable = entityTable, rowIndex = rowIndex}

  return entity
end

function M:addComponent(entity, component, value)
end

function M:removeEntity(entity)
  local entityTable, rowIndex = unpack(self.entities[entity])
  local movedEntity = entityTable:removeRow(rowIndex)

  if movedEntity ~= 0 then
    self.entities[movedEntity].rowIndex = rowIndex
  end

  self.entities[entity] = nil
end

function M:addEntityTable(entityType)
  local previousComponent = 0
  local node = self.entityTableRoot

  for _, component in ipairs(entityType) do
    if component <= previousComponent then
      error("Invalid entity type")
    end

    local nextNode = node[component]

    if nextNode == nil then
      nextNode = {}
      node[component] = nextNode
    end

    node = nextNode
    previousComponent = component
  end

  local entityTable = node[0]

  if not entityTable then
    local columnTypes = {}

    for _, component in ipairs(entityType) do
      local componentType = assert(self.componentTypes[component])
      local dataType = assert(self.dataTypes[componentType])
      table.insert(columnTypes, dataType)
    end

    entityTable = EntityTable.new(entityType, columnTypes)
    table.insert(self.entityTables, entityTable)
    node[0] = entityTable
  end

  return entityTable
end

function M:handleEvent(event, ...)
end

return M
