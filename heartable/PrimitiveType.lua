local Class = require("heartable.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name)
  self.name = assert(name)
  self.arrayType = ffi.typeof(self.name .. "[?]")
end

function M:allocateArray(size)
  return self.arrayType(size)
end

return M
