local World = require("heartable.World")
local StructType = require("heartable.StructType")
local ValueType = require("heartable.ValueType")
local colorMod = require("heartable.color")

function drawBoxes(world)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.box and tablet.archetype.color then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local positions = shard.columns.position
          local boxes = shard.columns.box
          local colors = shard.columns.color

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              love.graphics.setColor(colors[i].r, colors[i].g, colors[i].b, colors[i].a)

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

function handleMouseMoved(world, x, y, dx, dy, isTouch)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.isPaddle and tablet.archetype.isPlayer then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local positions = shard.columns.position

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              positions[i].y = y
            end
          end
        end
      end
    end
  end
end

function updateVelocityPositions(world, dt)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.previousPosition and tablet.archetype.velocity then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local previousPositions = shard.columns.previousPosition
          local positions = shard.columns.position
          local velocities = shard.columns.velocity

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              previousPositions[i] = positions[i]

              positions[i].x = positions[i].x + velocities[i].x * dt
              positions[i].y = positions[i].y + velocities[i].y * dt
            end
          end
        end
      end
    end
  end
end

function updateWallCollisions(world, dt)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.velocity and tablet.archetype.box and tablet.archetype.isBall then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local positions = shard.columns.position
          local velocities = shard.columns.velocity
          local boxes = shard.columns.box

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              if positions[i].y - 0.5 * boxes[i].y < 0 and velocities[i].y < 0 then
                velocities[i].y = -velocities[i].y
              elseif positions[i].y + 0.5 * boxes[i].y > 600 and velocities[i].y > 0 then
                velocities[i].y = -velocities[i].y
              end

              if positions[i].x - 0.5 * boxes[i].x < 0 and velocities[i].x < 0 then
                velocities[i].x = -velocities[i].x
              elseif positions[i].x + 0.5 * boxes[i].x > 800 and velocities[i].x > 0 then
                velocities[i].x = -velocities[i].x
              end
            end
          end
        end
      end
    end
  end
end

function updatePaddleBallCollisions(world, paddlePosition, paddleBox)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.previousPosition and tablet.archetype.position and tablet.archetype.velocity and tablet.archetype.box and tablet.archetype.isBall then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local entities = shard.entities
          local previousPositions = shard.columns.previousPosition
          local positions = shard.columns.position
          local velocities = shard.columns.velocity
          local boxes = shard.columns.box

          for i = 0, shard.rowCount - 1 do
            if entities[i] ~= 0 then
              if positions[i].y - 0.5 * boxes[i].y < paddlePosition.y + 0.5 * paddleBox.y and
                positions[i].y + 0.5 * boxes[i].y > paddlePosition.y - 0.5 * paddleBox.y then

                if velocities[i].x < 0 then
                  if previousPositions[i].x - 0.5 * boxes[i].x >= paddlePosition.x + 0.5 * paddleBox.x and
                    positions[i].x - 0.5 * boxes[i].x < paddlePosition.x + 0.5 * paddleBox.x then

                    velocities[i].x = -velocities[i].x
                  end
                else
                  if previousPositions[i].x + 0.5 * boxes[i].x <= paddlePosition.x - 0.5 * paddleBox.x and
                    positions[i].x + 0.5 * boxes[i].x > paddlePosition.x - 0.5 * paddleBox.x then

                    velocities[i].x = -velocities[i].x
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

function updatePaddleCollisions(world, dt)
  for _, tablet in pairs(world.tablets) do
    if tablet.archetype.position and tablet.archetype.box and tablet.archetype.isPaddle then
      for _, shard in pairs(tablet.shards) do
        if shard.rowCount >= 1 then
          local paddleEntities = shard.entities
          local paddlePositions = shard.columns.position
          local padddleBoxes = shard.columns.box

          for i = 0, shard.rowCount - 1 do
            if paddleEntities[i] ~= 0 then
              updatePaddleBallCollisions(world, paddlePositions[i], padddleBoxes[i])
            end
          end
        end
      end
    end
  end
end

function drawFps(world)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(love.timer.getFPS())
end

function love.load()
  love.window.setTitle("Pong")
  love.mouse.setVisible(false)

  world = World.new()

  world.componentTypes.struct = "value"

  world.dataTypes.vec2 = StructType.new("vec2", [[
    float x, y;
  ]])

  world.dataTypes.color4 = StructType.new("color4", [[
    float r, g, b, a;
  ]])

  world:addEntity({name = "position", dataType = "vec2"})
  world.componentTypes.position = "vec2"

  world:addEntity({name = "previousPosition", dataType = "vec2"})
  world.componentTypes.previousPosition = "vec2"

  world:addEntity({name = "velocity", dataType = "vec2"})
  world.componentTypes.velocity = "vec2"

  world:addEntity({name = "box", dataType = "vec2"})
  world.componentTypes.box = "vec2"

  world:addEntity({name = "color", dataType = "color4"})
  world.componentTypes.color = "color4"

  world:addEntity({name = "isPaddle", dataType = "tag"})
  world.componentTypes.isPaddle = "tag"

  world:addEntity({name = "isPlayer", dataType = "tag"})
  world.componentTypes.isPlayer = "tag"

  world:addEntity({name = "isBall", dataType = "tag"})
  world.componentTypes.isBall = "tag"

  world:addEntity({
    box = {10, 50},
    color = {1, 0.5, 0, 1},
    isPaddle = true,
    position = {100, 300},
  })

  world:addEntity({
    box = {10, 50},
    color = {0, 0.5, 1, 1},
    isPaddle = true,
    isPlayer = true,
    position = {700, 300},
  })

  local centerX = love.math.randomNormal(100, 400)
  local centerY = love.math.randomNormal(100, 300)

  for i = 1, 100 do
    local positionAngle = love.math.random() * 2 * math.pi
    local positionRadius = love.math.randomNormal(100)

    local x = centerX + math.cos(positionAngle) * positionRadius
    local y = centerY + math.sin(positionAngle) * positionRadius

    local velocity = 100

    local velocityAngle = love.math.random() * 2 * math.pi

    local velocityX = math.cos(velocityAngle) * velocity
    local velocityY = math.sin(velocityAngle) * velocity

    local h = love.math.random()
    local s = love.math.random() * love.math.random()
    local l = love.math.randomNormal(0.1, 0.5)

    local r, g, b = colorMod.hslToRgb(h, s, l)

    local a = 1 - love.math.random() * love.math.random()

    world:addEntity({
      box = {10, 10},
      color = {r, g, b, a},
      isBall = true,
      previousPosition = {x, y},
      position = {x, y},
      velocity = {velocityX, velocityY},
    })
  end

  world:addEvent("draw")
  world:addEvent("mouseMoved")
  world:addEvent("update")

  world:addSystem("draw", drawBoxes)
  world:addSystem("draw", drawFps)
  world:addSystem("mouseMoved", handleMouseMoved)
  world:addSystem("update", updateVelocityPositions)
  world:addSystem("update", updateWallCollisions)
  world:addSystem("update", updatePaddleCollisions)
end

function love.draw(...)
  world:handleEvent("draw", ...)
end

function love.mousemoved(...)
  world:handleEvent("mouseMoved", ...)
end

function love.update(...)
  world:handleEvent("update", ...)
end
