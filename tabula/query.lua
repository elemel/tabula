local tableMod = require("tabula.table")

local clear = assert(tableMod.clear)
local concat = assert(table.concat)
local copy = assert(tableMod.copy)
local insert = assert(table.insert)

local M = {}

function M.newQuery(allOf, noneOf)
  return {
    allOf = copy(allOf),
    noneOf = copy(noneOf),

    tabletVersion = 0,
    tablets = {},
  }
end

function M.updateTablets(query, engine)
  if query.tabletVersion ~= engine._tabletVersion then
    clear(query.tablets)

    for _, tablet in pairs(engine._tablets) do
      local included = true

      for _, component in pairs(query.allOf) do
        if not tablet.columnSet[component] then
          included = false
          break
        end
      end

      for _, component in pairs(query.noneOf) do
        if tablet.columnSet[component] then
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

function M.generateEachRowCode(arity, buffer)
  buffer = buffer or {}

  insert(
    buffer,
    [[return function(tablets, components, callback)
]]
  )

  for i = 1, arity do
    insert(buffer, "  local component")
    insert(buffer, i)
    insert(buffer, " = components[")
    insert(buffer, i)
    insert(buffer, "]\n")
  end

  insert(
    buffer,
    [[

  for _, tablet in ipairs(tablets) do
    local shards = tablet.shards

    for j = #shards, 1, -1 do
      local shard = shards[j]

]]
  )

  for i = 1, arity do
    insert(buffer, "      local column")
    insert(buffer, i)
    insert(buffer, " = shard[component")
    insert(buffer, i)
    insert(buffer, "]\n")
  end

  insert(
    buffer,
    [[

      for k = shard._size - 1, 0, -1 do
        callback(k]]
  )

  for i = 1, arity do
    insert(buffer, ", column")
    insert(buffer, i)
  end

  insert(
    buffer,
    [[)
      end
    end
  end
end
]]
  )

  return buffer
end

M.eachRowMt = {
  __index = function(self, arity)
    print("Generating row-traversal code for arity " .. arity)
    local buffer = M.generateEachRowCode(arity)
    local code = concat(buffer)

    -- print()
    -- print(code)

    local func = load(code)()
    self[arity] = func
    return func
  end,
}

M.eachRowFuncs = setmetatable({}, M.eachRowMt)

return M
