local M = {}

function M.new(shard, row)
  return setmetatable({ _shard = shard, _row = row }, M)
end

function M:__index(component)
  local column = self._shard.columns[component]
  return column and column[self._row]
end

function M:__newindex(component, value)
  local column = self._shard.columns[component]
  assert(value ~= nil)
  assert(column ~= nil)
  column[self._row] = value
end

return M
