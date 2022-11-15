local M = {}

local mt = {
  __index = function(entry, component)
    local column = entry._shard.columns[component]
    return column and column[entry._index]
  end,

  __newindex = function(entry, component, value)
    local column = entry._shard.columns[component]

    if column == nil and value ~= nil then
      error("Not implemented")
    elseif column ~= nil and value ~= nil then
      column[entry._index] = value
    elseif column ~= nil and value == nil then
      error("Not implemented")
    end
  end,
}

local invalidMt = {
  __index = function(entry, component)
    error("Invalid entry")
  end,

  __newindex = function(entry, component, value)
    error("Invalid entry")
  end,
}

function M.new(shard, index)
  local entry = {
    _shard = assert(shard),
    _index = assert(index),
  }

  return setmetatable(entry, mt)
end

function M.invalidate(entry)
  return setmetatable(entry, invalidMt)
end

return M
