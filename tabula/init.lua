local data = require("tabula.data")
local Engine = require("tabula.Engine")
local Query = require("tabula.Query")

local M = {}

M.newDataType = data.newDataType
M.newEngine = Engine.new
M.newQuery = Query.new

return M
