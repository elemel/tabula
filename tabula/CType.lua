local Class = require("tabula.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name)
  self.type = ffi.typeof(name)
  self.vlaType = ffi.typeof(name .. "[?]")

  self.defaultValue = self.type()
end

function M:allocateArray(size)
  return self.vlaType(size)
end

return M
