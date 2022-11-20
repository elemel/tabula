local ffi = require("ffi")
local tabula = require("tabula")

local abs = assert(math.abs)

-- See: http://love2d.org/wiki/HSL_color
local function hslToRgb(h, s, l)
  if s <= 0 then
    return l, l, l
  end

  local h, s, l = h * 6, s, l
  local c = (1 - abs(2 * l - 1)) * s
  local x = (1 - abs(h % 2 - 1)) * c
  local m, r, g, b = (l - 0.5 * c), 0, 0, 0

  if h < 1 then
    r, g, b = c, x, 0
  elseif h < 2 then
    r, g, b = x, c, 0
  elseif h < 3 then
    r, g, b = 0, c, x
  elseif h < 4 then
    r, g, b = 0, x, c
  elseif h < 5 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  return r + m, g + m, b + m
end

function drawBoxes(engine)
  love.graphics.push("all")
  love.graphics.setBlendMode("add")

  engine:eachRow("drawBoxes", function(i, boxes, colors, positions)
    love.graphics.setColor(colors[i].r, colors[i].g, colors[i].b, colors[i].a)

    love.graphics.rectangle(
      "fill",
      positions[i].x - 0.5 * boxes[i].x,
      positions[i].y - 0.5 * boxes[i].y,
      boxes[i].x,
      boxes[i].y
    )
  end)

  love.graphics.pop()
end

function handleMouseMoved(engine, x, y, dx, dy, isTouch)
  engine:eachRow("handleMouseMoved", function(i, positions)
    positions[i].y = y
  end)
end

function updateVelocityPositions(engine, dt)
  engine:eachRow(
    "updateVelocityPositions",
    function(i, positions, previousPositions, velocities)
      previousPositions[i] = positions[i]

      positions[i].x = positions[i].x + velocities[i].x * dt
      positions[i].y = positions[i].y + velocities[i].y * dt
    end
  )
end

function updateWallCollisions(engine, dt)
  engine:eachRow(
    "updateWallCollisions",
    function(i, boxes, positions, velocities)
      if positions[i].y - 0.5 * boxes[i].y < 0 and velocities[i].y < 0 then
        velocities[i].y = -velocities[i].y
      elseif
        positions[i].y + 0.5 * boxes[i].y > 600 and velocities[i].y > 0
      then
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
    end
  )
end

function updatePaddleCollisions(engine, dt)
  engine:eachRow("updatePaddleCollisions", function(i, boxes, positions)
    local paddleBox = boxes[i]
    local paddlePosition = positions[i]

    engine:eachRow(
      "updatePaddleBallCollisions",
      function(i, boxes, colors, positions, previousPositions, velocities)
        if
          positions[i].y - 0.5 * boxes[i].y
            < paddlePosition.y + 0.5 * paddleBox.y
          and positions[i].y + 0.5 * boxes[i].y
            > paddlePosition.y - 0.5 * paddleBox.y
        then
          if velocities[i].x < 0 and positions[i].x < 400 then
            if
              previousPositions[i].x - 0.5 * boxes[i].x
                >= paddlePosition.x + 0.5 * paddleBox.x
              and positions[i].x - 0.5 * boxes[i].x
                < paddlePosition.x + 0.5 * paddleBox.x
            then
              velocities[i].x = -velocities[i].x

              colors[i].r = velocities[i].x
              colors[i].b = -velocities[i].x
            end
          elseif velocities[i].x > 0 and positions[i].x > 400 then
            if
              previousPositions[i].x + 0.5 * boxes[i].x
                <= paddlePosition.x - 0.5 * paddleBox.x
              and positions[i].x + 0.5 * boxes[i].x
                > paddlePosition.x - 0.5 * paddleBox.x
            then
              velocities[i].x = -velocities[i].x

              colors[i].r = velocities[i].x
              colors[i].b = -velocities[i].x
            end
          end
        end
      end
    )
  end)
end

function drawFps(engine)
  local text = love.timer.getFPS() .. " FPS"
  local font = love.graphics.getFont()

  local width = font:getWidth(text)
  local height = font:getHeight()

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(text)
end

function love.load()
  love.mouse.setVisible(false)

  engine = tabula.newEngine()

  ffi.cdef([[
    typedef struct color4 {
      float r, g, b, a;
    } color4;

    typedef struct tag {} tag;

    typedef struct vec2 {
      float x, y;
    } vec2;
  ]])

  engine:addType("double", tabula.newCType("double"))
  engine:addType("color4", tabula.newCType("color4"))
  engine:addType("tag", tabula.newCType("tag"))
  engine:addType("vec2", tabula.newCType("vec2"))

  engine:addColumn("entity", "double")
  engine:addColumn("position", "vec2")
  engine:addColumn("previousPosition", "vec2")
  engine:addColumn("velocity", "vec2")
  engine:addColumn("box", "vec2")
  engine:addColumn("color", "color4")
  engine:addColumn("paddleTag", "tag")
  engine:addColumn("playerTag", "tag")
  engine:addColumn("ballTag", "tag")

  engine:addRow({
    box = { 10, 50 },
    color = { 0.9, 0.3, 0.1, 1 },
    paddleTag = {},
    position = { 100, 300 },
  })

  engine:addRow({
    box = { 10, 50 },
    color = { 0, 0.5, 1, 1 },
    paddleTag = {},
    playerTag = {},
    position = { 700, 300 },
  })

  engine:addRow({
    box = { 2, 600 },
    color = { 0.2, 0.8, 0, 1 },
    position = { 400, 300 },
  })

  engine:addRow({
    box = { 2, 600 },
    color = { 1, 0.3, 0.7, 1 },
    position = { 0, 300 },
  })

  engine:addRow({
    box = { 2, 600 },
    color = { 0.7, 0.3, 1, 1 },
    position = { 800, 300 },
  })

  for i = 1, 65536 do
    local centerX = love.math.randomNormal(100, 400)
    local centerY = love.math.randomNormal(100, 300)

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

    local r, g, b = hslToRgb(h, s, l)

    local a = love.math.randomNormal(0.1, 0.5)

    engine:addRow({
      box = { 2, 2 },
      color = { r, g, b, a },
      ballTag = {},
      previousPosition = { x, y },
      position = { x, y },
      velocity = { velocityX, velocityY },
    })
  end

  engine:addEvent("draw")
  engine:addEvent("mouseMoved")
  engine:addEvent("update")

  engine:addSystem("draw", drawBoxes)
  engine:addSystem("draw", drawFps)
  engine:addSystem("mouseMoved", handleMouseMoved)
  engine:addSystem("update", updateVelocityPositions)
  engine:addSystem("update", updateWallCollisions)
  engine:addSystem("update", updatePaddleCollisions)

  engine:addQuery("drawBoxes", tabula.newQuery({ "box", "color", "position" }))
  engine:addQuery(
    "handleMouseMoved",
    tabula.newQuery({ "position", "paddleTag", "playerTag" })
  )

  engine:addQuery(
    "updateVelocityPositions",
    tabula.newQuery({ "position", "previousPosition", "velocity" })
  )

  engine:addQuery(
    "updateWallCollisions",
    tabula.newQuery({ "box", "position", "velocity", "ballTag" })
  )

  engine:addQuery(
    "updatePaddleCollisions",
    tabula.newQuery({ "box", "position", "paddleTag" })
  )

  engine:addQuery(
    "updatePaddleBallCollisions",
    tabula.newQuery({
      "box",
      "color",
      "position",
      "previousPosition",
      "velocity",
      "ballTag",
    })
  )
end

function love.draw(...)
  engine:handleEvent("draw", ...)
end

function love.mousemoved(...)
  engine:handleEvent("mouseMoved", ...)
end

function love.update(...)
  engine:handleEvent("update", ...)
end
