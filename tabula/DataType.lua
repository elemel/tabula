local Class = require("tabula.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name)
  self.type = ffi.typeof(name)
  self.vlaType = ffi.typeof(name .. "[?]")
  self.pointerType = ffi.typeof(name .. "*")
  self.size = ffi.sizeof(self.type)
end

return M
