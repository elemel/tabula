local CType = require("tabula.CType")
local Engine = require("tabula.Engine")
local Query = require("tabula.Query")
local ValueType = require("tabula.ValueType")

local M = {}

M.newCType = CType.new
M.newEngine = Engine.new
M.newQuery = Query.new
M.newValueType = ValueType.new

return M
