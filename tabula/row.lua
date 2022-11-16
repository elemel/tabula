local M = {}

local mt = {
  __index = function(row, component)
    local column = row._shard.columns[component]
    return column and column[row._index]
  end,

  __newindex = function(row, component, value)
    local column = row._shard.columns[component]

    if column == nil and value ~= nil then
      error("Not implemented")
    elseif column ~= nil and value ~= nil then
      column[row._index] = value
    elseif column ~= nil and value == nil then
      error("Not implemented")
    end
  end,
}

local invalidMt = {
  __index = function(row, component)
    error("Invalid row")
  end,

  __newindex = function(row, component, value)
    error("Invalid row")
  end,
}

function M.new(shard, index)
  local row = {
    _shard = assert(shard),
    _index = assert(index),
  }

  return setmetatable(row, mt)
end

function M.invalidate(row)
  return setmetatable(row, invalidMt)
end

return M
