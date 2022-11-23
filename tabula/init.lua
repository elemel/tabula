local DataType = require("tabula.DataType")
local Engine = require("tabula.Engine")
local Query = require("tabula.Query")

local M = {}

M.newDataType = DataType.new
M.newEngine = Engine.new
M.newQuery = Query.new

return M
