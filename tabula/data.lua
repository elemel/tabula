local lton = require("lton")

local M = {}

function M.load(filename)
  local data = love.filesystem.read(filename)
  local func = load("return " .. data)
  setfenv(func, {})
  return func()
end

function M.save(value, filename)
  local buffer = lton.dump(data)
  local data = table.concat(buffer)
  love.filesystem.write(filename, date)
end

return M
