local Class = require("tabula.Class")
local tableMod = require("tabula.table")

local M = Class.new()

function M:init(engine, archetype)
  self.engine = assert(engine)
  self.archetype = tableMod.copy(archetype)

  self.columnTypes = {}

  self.shards = {}
  self.shardCapacity = 256

  self.parents = {}
  self.children = {}

  self.columnTypes.entity =
    assert(engine.dataTypes[engine.componentTypes.entity])

  for component in pairs(self.archetype) do
    self.columnTypes[component] =
      assert(engine.dataTypes[engine.componentTypes[component]])
  end
end

return M
