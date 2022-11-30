local shardMod = require("tabula.shard")

local copyRow = assert(shardMod.copyRow)

local M = {}

M.mt = {
  __index = function(row, component)
    local column = row._shard[component]
    return column and column[row._index]
  end,

  __newindex = function(row, component, value)
    local column = row._shard[component]

    if column and value ~= nil then
      column[row._index] = value
    elseif not column and value == nil then
      if not row._shard._tablet.engine._componentSet[component] then
        error("No such component: " .. component)
      end
    else
      local oldTablet = row._shard._tablet
      local newTablet = column and oldTablet:addParent(component)
        or oldTablet:addChild(component)
      local newShard, newIndex = newTablet:pushRow()

      local componentSet = column and newTablet.componentSet
        or oldTablet.componentSet
      copyRow(componentSet, row._shard, row._index, newShard, newIndex)

      if not column then
        newShard[component][newIndex] = value
      end

      oldTablet:removeRow(row._shard, row._index)

      row._shard = newShard
      row._index = newIndex
    end
  end,
}

M.invalidMt = {
  __index = function(row, component)
    error("Invalid row")
  end,

  __newindex = function(row, component, value)
    error("Invalid row")
  end,
}

return M
