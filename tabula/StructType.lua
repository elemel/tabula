local Class = require("tabula.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name, members)
  self.name = assert(name)

  local structDecl = "typedef struct " .. self.name .. " { " .. members .. " } " .. self.name .. ";"
  ffi.cdef(structDecl)

  self.structType = ffi.typeof(self.name)
  self.arrayType = ffi.typeof(self.name .. "[?]")
end

function M:allocateArray(size)
  return self.arrayType(size)
end

return M
