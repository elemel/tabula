local Class = require("heartable.Class")
local ffi = require("ffi")

local M = Class.new()

function M:init(name, fields)
  self.name = assert(name)

  local fieldDecls = {}

  for fieldName, fieldType in pairs(fields) do
    local fieldDecl = fieldType .. " " .. fieldName .. ";"
    table.insert(fieldDecls, fieldDecl)
  end

  local structDecl = "typedef struct " .. self.name .. " {\n  " .. table.concat(fieldDecls, "\n  ") .. "\n} " .. self.name .. ";"

  ffi.cdef(structDecl)
  self.arrayType = ffi.typeof(self.name .. "[?]")
end

function M:allocateArray(size)
  return self.arrayType(size)
end

return M
