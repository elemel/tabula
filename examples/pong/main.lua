local World = require("heartable.World")
local StructType = require("heartable.StructType")

function love.load()
  love.window.setTitle("Pong")

  world = World.new()
  world:addEntity({[world.names.name] = "position"})
end

function love.draw(...)
  world:handleEvent("draw", ...)
end

function love.update(...)
  world:handleEvent("update", ...)
end
