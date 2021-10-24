local Game = require("heartable.Game")
local Struct = require("heartable.StructType")

function love.load()
  love.window.setTitle("Pong")
  love.physics.setMeter(1)

  game = Game.new()
end

function love.draw(...)
  game:handleEvent("draw", ...)
end

function love.update(...)
  game:handleEvent("update", ...)
end
