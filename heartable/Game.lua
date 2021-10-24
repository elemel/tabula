local Archetype = require("heartable.Archetype")
local Class = require("heartable.Class")
local PrimitiveType = require("heartable.PrimitiveType")
local StringType = require("heartable.StringType")
local StructType = require("heartable.StructType")
local TagType = require("heartable.TagType")

local M = Class.new()

function M:init()
  self.nextEntity = 1
  self.entities = {}

  self.names = {}
  self.dataTypes = {}
  self.componentTypes = {}

  self.archetypes = {}
  self:bootstrap()
end

function M:bootstrap()
  self.dataTypes.double = PrimitiveType.new("double")
  self.dataTypes.string = StringType.new()
  self.dataTypes.tag = TagType.new()

  -- Test
  self.dataTypes.position = StructType.new("position", {
    x = "double",
    y = "double",
  })

  local nameComponent = self:addEntity({})
  self:addComponent(nameComponent, nameComponent, "name")
  self.names.name = nameComponent
  self:setComponentType(nameComponent, self.dataTypes.string)

  self:addEntity({name = "isComponent"})
end

function M:addEntity(components)
  local entity = self.nextEntity
  self.nextEntity = entity + 1

  local componentIds = {}

  for k, v in pairs(components) do
    if type(k) == "string" then
      k = assert(self.names[k])
    end

    table.insert(componentIds, k)
  end

  table.sort(componentIds)
  local archetype = self:addArchetype(componentIds)
  local row = archetype:addEntity(entity, components)
  self.entities[entity] = {archetype = archetype, row = row}
  return entity
end

function M:addComponent(entity, component, value)
end

function M:removeEntity(entity)
  local archetype, row = unpack(self.entities[entity])
  local movedEntity = archetype:removeEntity(row)

  if movedEntity ~= 0 then
    self.entities[movedEntity].row = row
  end

  self.entities[entity] = nil
end

function M:setComponentType(entity, dataType)
  self.componentTypes[entity] = dataType
end

function M:addArchetype(components)
  local previousComponent = 0
  local archetypes = self.archetypes

  for _, component in ipairs(components) do
    if component <= previousComponent then
      error("Invalid component set")
    end

    local nextArchetypes = archetypes[component]

    if nextArchetypes == nil then
      nextArchetypes = {}
      archetypes[component] = nextArchetypes
    end

    archetypes = nextArchetypes
    previousComponent = component
  end

  local archetype = archetypes[0]

  if archetype == nil then
    archetype = Archetype.new(self.componentTypes, components)
    archetypes[0] = archetype
  end

  return archetype
end

function M:handleEvent(event, ...)
end

return M
