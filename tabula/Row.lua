local M = {}

local rowMetatable = {
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

function M.newRow(shard, index)
  local row = { _shard = shard, _index = index }
  return setmetatable(row, rowMetatable)
end

function M.delete(row)
  local lastRow = assert(row._shard.tablet:findLastRow())
  row:swap(lastRow)
  row._shard.tablet:deleteLastRow()
end

function M.swap(a, b)
  assert(a._shard.tablet == b._shard.tablet)

  for component in pairs(a._shard.columns) do
    a[component], b[component] = b[component], a[component]
  end

  a._shard, b._shard = b._shard, a._shard
  a._index, b._index = b._index, a._index
end

return M
