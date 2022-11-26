local tableMod = require("tabula.table")

local clear = assert(tableMod.clear)
local copy = assert(tableMod.copy)
local insert = assert(table.insert)

local M = {}

function M.newQuery(includes, excludes)
  return {
    includes = copy(includes),
    excludes = copy(excludes),

    tabletVersion = 0,
    tablets = {},
  }
end

function M.updateTablets(query, engine)
  if query.tabletVersion ~= engine._tabletVersion then
    clear(query.tablets)

    for _, tablet in pairs(engine._tablets) do
      local included = true

      for _, component in pairs(query.includes) do
        if tablet.columnTypes[component] == nil then
          included = false
          break
        end
      end

      for _, component in pairs(query.excludes) do
        if tablet.columnTypes[component] ~= nil then
          included = false
          break
        end
      end

      if included then
        insert(query.tablets, tablet)
      end
    end

    query.tabletVersion = engine._tabletVersion
  end
end

function M.eachRow(query, callback)
  if #query.includes == 0 then
    M.eachRow0(query, callback)
  elseif #query.includes == 1 then
    M.eachRow1(query, callback)
  elseif #query.includes == 2 then
    M.eachRow2(query, callback)
  elseif #query.includes == 3 then
    M.eachRow3(query, callback)
  elseif #query.includes == 4 then
    M.eachRow4(query, callback)
  elseif #query.includes == 5 then
    M.eachRow5(query, callback)
  elseif #query.includes == 6 then
    M.eachRow6(query, callback)
  else
    error("Too many components")
  end
end

function M.eachRow0(callback)
  for _, tablet in ipairs(query.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]

      for j = shard.size - 1, 0, -1 do
        callback(j)
      end
    end
  end
end

function M.eachRow1(query, callback)
  local component1 = query.includes[1]

  for _, tablet in ipairs(query.tablets) do
    for i = #tablet.shards, 1, -1 do
      local shard = tablet.shards[i]
      local column1 = shard.columns[component1]

      for j = shard.size - 1, 0, -1 do
        callback(j, column1)
      end
    end
  end
end

function M.eachRow2(query, callback)
  local component1 = query.includes[1]
  local component2 = query.includes[2]

  for _, tablet in ipairs(query.tablets) do
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

function M.eachRow3(query, callback)
  local component1 = query.includes[1]
  local component2 = query.includes[2]
  local component3 = query.includes[3]

  for _, tablet in ipairs(query.tablets) do
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

function M.eachRow4(query, callback)
  local component1 = query.includes[1]
  local component2 = query.includes[2]
  local component3 = query.includes[3]
  local component4 = query.includes[4]

  for _, tablet in ipairs(query.tablets) do
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

function M.eachRow5(query, callback)
  local component1 = query.includes[1]
  local component2 = query.includes[2]
  local component3 = query.includes[3]
  local component4 = query.includes[4]
  local component5 = query.includes[5]

  for _, tablet in ipairs(query.tablets) do
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

function M.eachRow6(query, callback)
  local component1 = query.includes[1]
  local component2 = query.includes[2]
  local component3 = query.includes[3]
  local component4 = query.includes[4]
  local component5 = query.includes[5]
  local component6 = query.includes[6]

  for _, tablet in ipairs(query.tablets) do
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
