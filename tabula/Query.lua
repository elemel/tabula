local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local clear = assert(tableMod.clear)
local insert = assert(table.insert)

local M = Class.new()

function M:init(includes, excludes)
  self.includes = tableMod.copy(includes or {})
  self.excludes = tableMod.copy(excludes or {})

  self.tabletVersion = 0
  self.tablets = {}
end

function M:updateTablets(engine)
  if self.tabletVersion ~= engine._tabletVersion then
    clear(self.tablets)

    for _, tablet in pairs(engine._tablets) do
      local included = true

      for _, component in pairs(self.includes) do
        if not tablet.columnTypes[component] then
          included = false
          break
        end
      end

      for _, component in pairs(self.excludes) do
        if tablet.columnTypes[component] then
          included = false
          break
        end
      end

      if included then
        table.insert(self.tablets, tablet)
      end
    end

    self.tabletVersion = engine._tabletVersion
  end
end

function M:eachShard(callback)
  if #self.includes == 0 then
    self:eachShard0(callback)
  elseif #self.includes == 1 then
    self:eachShard1(callback)
  elseif #self.includes == 2 then
    self:eachShard2(callback)
  elseif #self.includes == 3 then
    self:eachShard3(callback)
  elseif #self.includes == 4 then
    self:eachShard4(callback)
  elseif #self.includes == 5 then
    self:eachShard5(callback)
  elseif #self.includes == 6 then
    self:eachShard6(callback)
  else
    error("Too many components")
  end
end

function M:eachShard0(callback)
  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]
      callback(shard.size)
    end
  end
end

function M:eachShard1(callback)
  local component1 = self.includes[1]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]
      callback(shard.size, shard.columns[component1])
    end
  end
end

function M:eachShard2(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      callback(shard.size, shard.columns[component1], shard.columns[component2])
    end
  end
end

function M:eachShard3(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      callback(
        shard.size,
        shard.columns[component1],
        shard.columns[component2],
        shard.columns[component3]
      )
    end
  end
end

function M:eachShard4(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      callback(
        shard.size,
        shard.columns[component1],
        shard.columns[component2],
        shard.columns[component3],
        shard.columns[component4]
      )
    end
  end
end

function M:eachShard5(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]
  local component5 = self.includes[5]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      callback(
        shard.size,
        shard.columns[component1],
        shard.columns[component2],
        shard.columns[component3],
        shard.columns[component4],
        shard.columns[component5]
      )
    end
  end
end

function M:eachShard6(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]
  local component5 = self.includes[5]
  local component6 = self.includes[6]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      callback(
        shard.size,
        shard.columns[component1],
        shard.columns[component2],
        shard.columns[component3],
        shard.columns[component4],
        shard.columns[component5],
        shard.columns[component6]
      )
    end
  end
end

function M:eachRow(callback)
  if #self.includes == 0 then
    self:eachRow0(callback)
  elseif #self.includes == 1 then
    self:eachRow1(callback)
  elseif #self.includes == 2 then
    self:eachRow2(callback)
  elseif #self.includes == 3 then
    self:eachRow3(callback)
  elseif #self.includes == 4 then
    self:eachRow4(callback)
  elseif #self.includes == 5 then
    self:eachRow5(callback)
  elseif #self.includes == 6 then
    self:eachRow6(callback)
  else
    error("Too many components")
  end
end

function M:eachRow0(callback)
  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      for j = shard.size - 1, 0, -1 do
        callback(j)
      end
    end
  end
end

function M:eachRow1(callback)
  local component1 = self.includes[1]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]
      local column1 = shard.columns[component1]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1)
      end
    end
  end
end

function M:eachRow2(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      local column1 = shard.columns[component1]
      local column2 = shard.columns[component2]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1, column2)
      end
    end
  end
end

function M:eachRow3(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      local column1 = shard.columns[component1]
      local column2 = shard.columns[component2]
      local column3 = shard.columns[component3]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1, column2, column3)
      end
    end
  end
end

function M:eachRow4(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      local column1 = shard.columns[component1]
      local column2 = shard.columns[component2]
      local column3 = shard.columns[component3]
      local column4 = shard.columns[component4]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1, column2, column3, column4)
      end
    end
  end
end

function M:eachRow5(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]
  local component5 = self.includes[5]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      local column1 = shard.columns[component1]
      local column2 = shard.columns[component2]
      local column3 = shard.columns[component3]
      local column4 = shard.columns[component4]
      local column5 = shard.columns[component5]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1, column2, column3, column4, column5)
      end
    end
  end
end

function M:eachRow6(callback)
  local component1 = self.includes[1]
  local component2 = self.includes[2]
  local component3 = self.includes[3]
  local component4 = self.includes[4]
  local component5 = self.includes[5]
  local component6 = self.includes[6]

  for _, tablet in ipairs(self.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      local column1 = shard.columns[component1]
      local column2 = shard.columns[component2]
      local column3 = shard.columns[component3]
      local column4 = shard.columns[component4]
      local column5 = shard.columns[component5]
      local column6 = shard.columns[component6]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1, column2, column3, column4, column5, column6)
      end
    end
  end
end

return M
