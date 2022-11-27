local ffi = require("ffi")

local M = {}

function M.newDataType(name)
  local dt = {}

  dt.name = assert(name)
  dt.valueType = ffi.typeof(name)
  dt.arrayType = ffi.typeof(name .. "[?]")
  dt.pointerType = ffi.typeof(name .. "*")

  return dt
end

return M
