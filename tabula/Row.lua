local M = {}

function M.new(shard, index)
  return setmetatable({ _shard = shard, _index = index }, M)
end

function M:__index(component)
  local column = self._shard.columns[component]
  return column and column[self._index]
end

function M:__newindex(component, value)
  local column = self._shard.columns[component]
  assert(value ~= nil)
  assert(column ~= nil)
  column[self._index] = value
end

return M
