local M = {}

local rowMetatable = {
  __index = function(row, component)
    local column = row._shard.columns[component]
    return column and column[row._index]
  end,

  __newindex = function(row, component, value)
    local column = row._shard.columns[component]
    assert(value ~= nil)
    assert(column ~= nil)
    column[row._index] = value
  end,
}

function M.newRow(shard, index)
  local row = { _shard = shard, _index = index }
  return setmetatable(row, rowMetatable)
end

return M
