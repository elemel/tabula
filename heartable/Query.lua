local Class = require("heartable.Class")
local tableMod = require("heartable.table")

local function match(pattern, archetype)
  local result = 0

  for _, component in ipairs(pattern) do
    if archetype[component] then
      result = result + 1
    end
  end

  return result
end

local M = Class.new()

function M:init(world, config)
  self.world = assert(world)
  config = config or {}
  self.allOf = config.allOf or {}
  self.noneOf = config.noneOf or {}

  self.tablets = {}
  self:updateTablets()
end

function M:updateTablets()
  tableMod.clear(self.tablets)

  for _, tablet in ipairs(self.world.tablets) do
    local allOfCount = match(self.allOf, tablet.archetype)
    local noneOfCount = match(self.noneOf, tablet.archetype)

    if allOfCount == #self.allOf and noneOfCount == 0 then
      table.insert(self.tablets, tablet)
    end
  end
end

function M:eachShard(callback)
  if #self.allOf == 0 then
    self:eachShard0(callback)
  elseif #self.allOf == 1 then
    self:eachShard1(callback)
  elseif #self.allOf == 2 then
    self:eachShard2(callback)
  elseif #self.allOf == 3 then
    self:eachShard3(callback)
  else
    error("Too many components")
  end
end

function M:eachShard0(callback)
  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        callback(shard.rowCount, shard.entities)
      end
    end
  end
end

function M:eachShard1(callback)
  local component1 = self.allOf[1]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        callback(
          shard.rowCount,
          shard.entities,
          shard.columns[component1])
      end
    end
  end
end

function M:eachShard2(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        callback(
          shard.rowCount,
          shard.entities,
          shard.columns[component1],
          shard.columns[component2])
      end
    end
  end
end

function M:eachShard3(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]
  local component3 = self.allOf[3]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        callback(
          shard.rowCount,
          shard.entities,
          shard.columns[component1],
          shard.columns[component2],
          shard.columns[component3])
      end
    end
  end
end

function M:eachRow(callback)
  if #self.allOf == 0 then
    self:eachRow0(callback)
  elseif #self.allOf == 1 then
    self:eachRow1(callback)
  elseif #self.allOf == 2 then
    self:eachRow2(callback)
  elseif #self.allOf == 3 then
    self:eachRow3(callback)
  elseif #self.allOf == 4 then
    self:eachRow4(callback)
  elseif #self.allOf == 5 then
    self:eachRow5(callback)
  else
    error("Too many components")
  end
end

function M:eachRow0(callback)
  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities)
          end
        end
      end
    end
  end
end

function M:eachRow1(callback)
  local component1 = self.allOf[1]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities
        local column1 = shard.columns[component1]

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities,
              column1)
          end
        end
      end
    end
  end
end

function M:eachRow2(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities

        local column1 = shard.columns[component1]
        local column2 = shard.columns[component2]

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities,
              column1,
              column2)
          end
        end
      end
    end
  end
end

function M:eachRow3(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]
  local component3 = self.allOf[3]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities

        local column1 = shard.columns[component1]
        local column2 = shard.columns[component2]
        local column3 = shard.columns[component3]

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities,
              column1,
              column2,
              column3)
          end
        end
      end
    end
  end
end

function M:eachRow4(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]
  local component3 = self.allOf[3]
  local component4 = self.allOf[4]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities

        local column1 = shard.columns[component1]
        local column2 = shard.columns[component2]
        local column3 = shard.columns[component3]
        local column4 = shard.columns[component4]

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities,
              column1,
              column2,
              column3,
              column4)
          end
        end
      end
    end
  end
end

function M:eachRow5(callback)
  local component1 = self.allOf[1]
  local component2 = self.allOf[2]
  local component3 = self.allOf[3]
  local component4 = self.allOf[4]
  local component5 = self.allOf[5]

  for _, tablet in ipairs(self.tablets) do
    for _, shard in ipairs(tablet.shards) do
      if shard.rowCount >= 1 then
        local entities = shard.entities

        local column1 = shard.columns[component1]
        local column2 = shard.columns[component2]
        local column3 = shard.columns[component3]
        local column4 = shard.columns[component4]
        local column5 = shard.columns[component5]

        for i = 0, shard.rowCount - 1 do
          if entities[i] ~= 0 then
            callback(i, entities,
              column1,
              column2,
              column3,
              column4,
              column5)
          end
        end
      end
    end
  end
end

return M
