local Class = require("tabula.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(vlaType)
  self.vlaType = assert(vlaType)
end

function M:allocateArray(size)
  return self.vlaType(size)
end

return M
