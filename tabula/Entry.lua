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

function M.new(shard, index)
  local entry = {
    _shard = assert(shard),
    _index = assert(index),
  }

  return setmetatable(entry, mt)
end

return M
