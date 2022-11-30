local ffi = require("ffi")

local M = {}

function M.newShard(tablet)
  local shard = {
    _tablet = tablet,
    _data = {},
    _size = 0,
  }

  for component in pairs(tablet.componentSet) do
    local componentType = tablet.engine._componentTypes[component]

    if componentType then
      local valueByteSize = ffi.sizeof(componentType.valueType)
      local columnByteSize = math.max(1, valueByteSize * tablet.shardCapacity)
      local columnData = love.data.newByteData(columnByteSize)
      shard._data[component] = columnData
      shard[component] =
        ffi.cast(componentType.pointerType, columnData:getFFIPointer())
    else
      shard[component] = {}
    end
  end

  return shard
end

function M.copyRow(
  componentSet,
  sourceShard,
  sourceIndex,
  targetShard,
  targetIndex
)
  for component in pairs(componentSet) do
    local sourceColumn = sourceShard[component]
    local targetColumn = targetShard[component]
    targetColumn[targetIndex] = sourceColumn[sourceIndex]
  end
end

return M
