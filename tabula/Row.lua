local M = {}

local rowMetatable = {
  __index = function(row, component)
    local column = row._shard[component]
    return column and column[row._index]
  end,

  __newindex = function(row, component, value)
    local column = row._shard[component]
    assert(value ~= nil)
    assert(column ~= nil)
    column[row._index] = value
  end,
}

function M.newRow(shard, index)
  local row = { _shard = shard, _index = index }
  return setmetatable(row, rowMetatable)
end

function swap(a, b)
  assert(a._shard.tablet == b._shard.tablet)

  for component in pairs(a._shard.columns) do
    a[component], b[component] = b[component], a[component]
  end

  a._shard, b._shard = b._shard, a._shard
  a._index, b._index = b._index, a._index
end

return M
