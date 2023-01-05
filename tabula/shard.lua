local ffi = require("ffi")

local M = {}

function M.newShard(tablet)
  local shard = {
    _tablet = tablet,
    _data = {},
    _size = 0,
  }

  for component in pairs(tablet.columnSet) do
    local columnType = tablet.database._columnTypes[component]

    if columnType then
      local columnByteSize = math.max(1, columnType.size * tablet.shardCapacity)
      local columnData = love.data.newByteData(columnByteSize)
      shard._data[component] = columnData
      shard[component] =
        ffi.cast(columnType.pointerType, columnData:getFFIPointer())
    else
      shard[component] = {}
    end
  end

  return shard
end

function M.copyRow(
  columnSet,
  sourceShard,
  sourceIndex,
  targetShard,
  targetIndex
)
  for component in pairs(columnSet) do
    local sourceColumn = sourceShard[component]
    local targetColumn = targetShard[component]
    targetColumn[targetIndex] = sourceColumn[sourceIndex]
  end
end

return M
