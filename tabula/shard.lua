local ffi = require("ffi")

local M = {}

function M.newShard(tablet)
  local shard = {
    tablet = tablet,
    columnData = {},
    columns = {},
    size = 0,
  }

  for component in pairs(tablet.componentSet) do
    local componentType = tablet.engine._componentTypes[component]

    if componentType then
      local valueByteSize = ffi.sizeof(componentType.valueType)
      local columnByteSize = math.max(1, valueByteSize * tablet.shardCapacity)
      local columnData = love.data.newByteData(columnByteSize)
      shard.columnData[component] = columnData
      shard.columns[component] =
        ffi.cast(componentType.pointerType, columnData:getFFIPointer())
    else
      shard.columns[component] = {}
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
    local sourceColumn = sourceShard.columns[component]
    local targetColumn = targetShard.columns[component]
    targetColumn[targetIndex] = sourceColumn[sourceIndex]
  end
end

return M
