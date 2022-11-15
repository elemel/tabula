local Class = require("tabula.Class")

local tagArray = setmetatable({}, {
  __index = function(t, k)
    return true
  end,

  __newindex = function(t, k, v)
    assert(v == true, "Tag value must be true")
  end,
})

local M = Class.new()
M.defaultValue = true

function M:init() end

function M:allocateArray(size)
  return tagArray
end

return M
