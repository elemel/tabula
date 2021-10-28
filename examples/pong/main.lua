local World = require("heartable.World")
local StructType = require("heartable.StructType")
local ValueType = require("heartable.ValueType")

function drawBoxes(world)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.box then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local positions = shard.columns.position
          local boxes = shard.columns.box

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              love.graphics.rectangle(
                "fill",
                positions[i].x - 0.5 * boxes[i].x,
                positions[i].y - 0.5 * boxes[i].y,
                boxes[i].x,
                boxes[i].y)
            end
          end
        end
      end
    end
  end
end

function love.load()
  love.window.setTitle("Pong")

  world = World.new()

  world.dataTypes.value = ValueType.new()
  world.componentTypes.struct = "value"

  world.dataTypes.vec2 = StructType.new("vec2", [[
    float x, y;
  ]])

  world:addEntity({name = "position", dataType = "vec2"})
  world.componentTypes.position = "vec2"

  world:addEntity({name = "box", dataType = "vec2"})
  world.componentTypes.box = "vec2"

  world:addEntity({name = "isPaddle", dataType = "tag"})
  world.componentTypes.isPaddle = "tag"

  world:addEntity({
    isPaddle = true,
    position = {x = 100, y = 300},
    box = {x = 10, y = 50}
  })

  world:addEntity({
    isPaddle = true,
    position = {x = 700, y = 300},
    box = {x = 10, y = 50}
  })

  world:addEvent("draw")
  world:addEvent("update")

  world:addSystem("draw", drawBoxes)
end

function love.draw(...)
  world:handleEvent("draw", ...)
end

function love.update(...)
  world:handleEvent("update", ...)
end
