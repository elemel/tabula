local World = require("heartable.World")
local StructType = require("heartable.StructType")

function love.load()
  love.window.setTitle("Pong")

  world = World.new()
  local names = assert(world.names)

  world.dataTypes.position = StructType.new("position", {
    x = "double",
    y = "double",
  })

  world:addEntity({[names.name] = "isPaddle", [names.isComponent] = true})
end

function love.draw(...)
  world:handleEvent("draw", ...)
end

function love.update(...)
  world:handleEvent("update", ...)
end
