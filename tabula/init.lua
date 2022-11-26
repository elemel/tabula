local data = require("tabula.data")
local Engine = require("tabula.Engine")

local M = {}

M.newDataType = data.newDataType
M.newEngine = Engine.new

return M
