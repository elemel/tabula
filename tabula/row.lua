local shardMod = require("tabula.shard")

local M = {}

M.mt = {
  __index = function(row, component)
    local column = row._shard.columns[component]
    return column and column[row._index]
  end,

  __newindex = function(row, component, value)
    local column = row._shard.columns[component]

    if column ~= nil and value ~= nil then
      column[row._index] = value
    elseif column == nil and value ~= nil then
      local oldTablet = row._shard.tablet
      local newTablet = oldTablet:addChild(component)
      local newShard, newIndex = newTablet:pushRow()

      shardMod.copyRow(
        oldTablet.componentSet,
        row._shard,
        row._index,
        newShard,
        newIndex
      )
      newShard.columns[component][newIndex] = value
      oldTablet:removeRow(row._shard, row._index)

      row._shard = newShard
      row._index = newIndex
    elseif column ~= nil and value == nil then
      local oldTablet = row._shard.tablet

      local newTablet = oldTablet:addParent(component)
      local newShard, newIndex = newTablet:pushRow()

      shardMod.copyRow(
        newTablet.componentSet,
        row._shard,
        row._index,
        newShard,
        newIndex
      )
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
