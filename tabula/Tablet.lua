local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local M = Class.new()

function M:init(engine, archetype)
  self.engine = assert(engine)
  self.archetype = tableMod.copy(archetype)

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}
end

return M
