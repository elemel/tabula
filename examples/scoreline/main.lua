local Query = require("heartable.Query")
local World = require("heartable.World")
local StructType = require("heartable.StructType")
local ValueType = require("heartable.ValueType")
local colorMod = require("heartable.color")

function drawBoxes(world)
  world.queries.drawBoxes:eachRow(function(
    i, entities,
    boxes, colors, positions)

    love.graphics.setColor(colors[i].r, colors[i].g, colors[i].b, colors[i].a)

    love.graphics.rectangle(
      "fill",
      positions[i].x - 0.5 * boxes[i].x,
      positions[i].y - 0.5 * boxes[i].y,
      boxes[i].x,
      boxes[i].y)
  end)
end

function handleMouseMoved(world, x, y, dx, dy, isTouch)
  world.queries.handleMouseMoved:eachRow(function(
    i, entities,
    positions)

    positions[i].y = y
  end)
end

function updateVelocityPositions(world, dt)
  world.queries.updateVelocityPositions:eachRow(function(
    i, entities,
    positions, previousPositions, velocities)

    previousPositions[i] = positions[i]

    positions[i].x = positions[i].x + velocities[i].x * dt
    positions[i].y = positions[i].y + velocities[i].y * dt
  end)
end

function updateWallCollisions(world, dt)
  world.queries.updateWallCollisions:eachRow(function(
    i, entities,
    boxes, positions, velocities)

    if positions[i].y - 0.5 * boxes[i].y < 0 and velocities[i].y < 0 then
      velocities[i].y = -velocities[i].y
    elseif positions[i].y + 0.5 * boxes[i].y > 600 and velocities[i].y > 0 then
      velocities[i].y = -velocities[i].y
    end

    if velocities[i].x < 0 then
      if positions[i].x + 0.5 * boxes[i].x <= 0 then
        positions[i].x = positions[i].x + 800 + boxes[i].x
      end
    else
      if positions[i].x - 0.5 * boxes[i].x >= 800 then
        positions[i].x = positions[i].x - 800 - boxes[i].x
      end
    end
  end)
end

function updatePaddleCollisions(world, dt)
  world.queries.updatePaddleCollisions:eachRow(function(
    i, entities,
    boxes, positions)

    local paddleBox = boxes[i]
    local paddlePosition = positions[i]

    world.queries.updatePaddleBallCollisions:eachRow(function(
      i, entities,
      boxes, colors, positions, previousPositions, velocities)

      if positions[i].y - 0.5 * boxes[i].y < paddlePosition.y + 0.5 * paddleBox.y and
        positions[i].y + 0.5 * boxes[i].y > paddlePosition.y - 0.5 * paddleBox.y then

        if velocities[i].x < 0 and positions[i].x < 400 then
          if previousPositions[i].x - 0.5 * boxes[i].x >= paddlePosition.x + 0.5 * paddleBox.x and
            positions[i].x - 0.5 * boxes[i].x < paddlePosition.x + 0.5 * paddleBox.x then

            velocities[i].x = -velocities[i].x

            colors[i].r = velocities[i].x
            colors[i].b = -velocities[i].x
          end
        elseif velocities[i].x > 0 and positions[i].x > 400 then
          if previousPositions[i].x + 0.5 * boxes[i].x <= paddlePosition.x - 0.5 * paddleBox.x and
            positions[i].x + 0.5 * boxes[i].x > paddlePosition.x - 0.5 * paddleBox.x then

            velocities[i].x = -velocities[i].x

            colors[i].r = velocities[i].x
            colors[i].b = -velocities[i].x
          end
        end
      end
    end)
  end)
end

function drawFps(world)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(love.timer.getFPS())
end

function love.load()
  love.mouse.setVisible(false)
  love.graphics.setBlendMode("add")

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
    color = {0.9, 0.3, 0.1, 1},
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

  world:addEntity({
    box = {2, 600},
    color = {0.2, 0.8, 0, 1},
    position = {400, 300},
  })

  world:addEntity({
    box = {2, 600},
    color = {1, 0.3, 0.7, 1},
    position = {0, 300},
  })

  world:addEntity({
    box = {2, 600},
    color = {0.7, 0.3, 1, 1},
    position = {800, 300},
  })

  local centerX = love.math.randomNormal(100, 400)
  local centerY = love.math.randomNormal(100, 300)

  for i = 1, 100000 do
    local positionAngle = love.math.random() * 2 * math.pi
    local positionRadius = love.math.randomNormal(100)

    local x = centerX + math.cos(positionAngle) * positionRadius
    local y = centerY + math.sin(positionAngle) * positionRadius

    local velocity = 100

    local velocityAngle = love.math.random() * 2 * math.pi

    local velocityX = math.cos(velocityAngle) * velocity
    local velocityY = math.sin(velocityAngle) * velocity

    local h = love.math.randomNormal(0.05, 0.1)
    local s = love.math.randomNormal(0.1, 0.6)
    local l = love.math.randomNormal(0.1, 0.6)

    local r, g, b = colorMod.hslToRgb(h, s, l)

    local a = love.math.randomNormal(0.1, 0.5)

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

  -- world:addSystem("draw", drawBoxes)
  world:addSystem("draw", drawFps)
  world:addSystem("mouseMoved", handleMouseMoved)
  world:addSystem("update", updateVelocityPositions)
  world:addSystem("update", updateWallCollisions)
  world:addSystem("update", updatePaddleCollisions)

  world.queries.drawBoxes = Query.new(world, {
    allOf = {"box", "color", "position"},
  })

  world.queries.handleMouseMoved = Query.new(world, {
    allOf = {"position", "isPaddle", "isPlayer"},
  })

  world.queries.updateVelocityPositions = Query.new(world, {
    allOf = {"position", "previousPosition", "velocity"},
  })

  world.queries.updateWallCollisions = Query.new(world, {
    allOf = {"box", "position", "velocity", "isBall"},
  })

  world.queries.updatePaddleCollisions = Query.new(world, {
    allOf = {"box", "position", "isPaddle"},
  })

  world.queries.updatePaddleBallCollisions = Query.new(world, {
    allOf = {"box", "color", "position", "previousPosition", "velocity", "isBall"},
  })
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
