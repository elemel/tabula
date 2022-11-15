local Class = require("tabula.Class")

-- Default value is nil
local M = Class.new()

function M:init() end

function M:allocateArray(size)
  return {}
end

return M
