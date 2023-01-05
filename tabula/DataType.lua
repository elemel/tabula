local Class = require("tabula.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name)
  self.name = assert(name)
  self.type = ffi.typeof(name)
  self.size = ffi.sizeof(name)
  self.arrayType = ffi.typeof(name .. "[?]")
  self.pointerType = ffi.typeof(name .. "*")
end

return M
