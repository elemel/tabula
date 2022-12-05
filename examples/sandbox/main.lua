local ffi = require("ffi")
local tabula = require("tabula")

local acos = assert(math.acos)
local sqrt = assert(math.sqrt)

ffi.cdef([[
  typedef struct tag {} tag;

  typedef struct vec2 {
    float x, y;
  } vec2;
]])

local vec2 = ffi.typeof("vec2")

local function sign(x)
  return x > 0 and 1 or x < 0 and -1 or 0 
end

-- http://frederic-wang.fr/decomposition-of-2d-transform-matrices.html
local function decompose2(transform)
  local t11, t12, t13, t14,
    t21, t22, t23, t24,
    t31, t32, t33, t34,
    t41, t42, t43, t44 = transform:getMatrix()

  local x = t14
  local y = t24
  local angle = 0
  local scaleX = t11 * t11 + t21 * t21
  local scaleY = t12 * t12 + t22 * t22
  local shearX = 0
  local shearY = 0

  if scaleX + scaleY ~= 0 then
    local det = t11 * t22 - t12 * t21

    if scaleX >= scaleY then
      shearX = (t11 * t12 + t21 * t22) / scaleX
      scaleX = sqrt(scaleX)
      angle = sign(t21) * acos(t11 / scaleX)
      scaleY = det / scaleX
    else
      shearY = (t11 * t12 + t21 * t22) / scaleY
      scaleY = sqrt(scaleY)
      angle = 0.5 * pi - sign(t22) * acos(-t12 / scaleY)
      scaleX = det / scaleY
    end
  end

  return x, y, angle, scaleX, scaleY, 0, 0, shearX, shearY
end

local function getTransform(row)
  local position = row.localPosition or vec2()
  local rotation = row.localRotation or 0
  return position, rotation
end

local function getLocalToWorld(engine, entity, result)
  result = result or love.math.newTransform()
  local row = engine:getRow(entity)

  if row.parent then
    getLocalToWorld(engine, row.parent, result)
  else
    result:reset()
  end

  if row.localToParent then
    result:apply(row.localToParent)
  end

  return result
end

local function createBodies(engine, dt)
  engine:eachRow("createBodies", function(i, entities, bodyConfigs)
    local world = engine:getProperty("world")
    local entity = entities[i]
    local row = engine:getRow(entity)
    local localToWorld = getLocalToWorld(engine, entity)
    local x, y, angle = decompose2(localToWorld)
    local config = bodyConfigs[i]
    local body =
      love.physics.newBody(world, x, y, config.bodyType)
    body:setUserData(entity)
    body:setAngle(angle)
    row.body = body
  end)
end

local function createFixtures(engine, dt)
  engine:eachRow("createFixtures", function(i, entities, fixtureConfigs)
    local world = engine:getProperty("world")
    local row = engine:getRow(entities[i])
    local body = assert(row.body)
    local shape = love.physics.newRectangleShape(1, 1)
    row.fixture = love.physics.newFixture(body, shape)
  end)
end

local function destroyFixtures(engine, dt)
  engine:eachRow("destroyFixtures", function(i, entities, fixtures)
    local row = engine:getRow(entities[i])
    row.fixture:destroy()
    row.fixture = nil
  end)
end

local function destroyBodies(engine, dt)
  engine:eachRow("destroyBodies", function(i, entities, bodies)
    local row = engine:getRow(entities[i])
    row.body:destroy()
    row.body = nil
  end)
end

local function removeDeadRows(engine, dt)
  engine:eachRow("removeDeadRows", function(i, entities)
    engine:removeRow(entities[i])
  end)
end

local function updateClock(engine, dt)
  local clock = engine:getProperty("clock")
  clock.accumulatedDt =
    math.min(clock.accumulatedDt + dt, clock.maxAccumulatedDt)

  while clock.fixedDt <= clock.accumulatedDt do
    clock.accumulatedDt = clock.accumulatedDt - clock.fixedDt
    engine:handleEvent("fixedUpdate", clock.fixedDt)
  end
end

local function updateWorld(engine, dt)
  local world = engine:getProperty("world")
  world:update(dt)
end

local function drawBodies(engine)
  love.graphics.push("all")

  local width, height = love.graphics.getDimensions()
  love.graphics.translate(0.5 * width, 0.5 * height)
  local scale = 0.1 * height
  love.graphics.scale(scale)
  love.graphics.setLineWidth(1 / scale)

  local world = engine:getProperty("world")

  for _, body in ipairs(world:getBodies()) do
    local x, y = body:getPosition()
    love.graphics.line(0, 0, x, y)
  end

  love.graphics.pop()
end

local function drawFixtures(engine)
  love.graphics.push("all")

  local width, height = love.graphics.getDimensions()
  love.graphics.translate(0.5 * width, 0.5 * height)
  local scale = 0.1 * height
  love.graphics.scale(scale)
  love.graphics.setLineWidth(1 / scale)

  local world = engine:getProperty("world")

  for _, body in ipairs(world:getBodies()) do
    for _, fixture in ipairs(body:getFixtures()) do
      local shape = fixture:getShape()
      local shapeType = shape:getType()

      if shapeType == "circle" then
        local x, y = body:getWorldPoint(shape:getPoint())
        local radius = shape:getRadius()
        love.graphics.circle("line", x, y, radius)
      elseif shapeType == "polygon" then
        love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
      else
        print("Unknown shape type: " .. shapeType)
      end
    end
  end

  love.graphics.pop()
end

local function drawFps(engine)
  love.graphics.push("all")

  local text = love.timer.getFPS() .. " FPS"
  local font = love.graphics.getFont()

  local width = font:getWidth(text)
  local height = font:getHeight()

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(text)

  love.graphics.pop()
end

function love.load()
  love.physics.setMeter(1)

  engine = tabula.newEngine()

  engine:setProperty("clock", {
    fixedDt = 1 / 60,
    accumulatedDt = 0,
    maxAccumulatedDt = 0.1,
  })
  engine:setProperty("world", love.physics.newWorld(0, 10))

  engine:addDataType("double")
  engine:addDataType("float")
  engine:addDataType("tag")
  engine:addDataType("vec2")

  engine:addColumn("body")
  engine:addColumn("bodyConfig")
  engine:addColumn("children")
  engine:addColumn("deadTag", "tag")
  engine:addColumn("entity", "double")
  engine:addColumn("fixture")
  engine:addColumn("fixtureConfig")
  engine:addColumn("localToParent")
  engine:addColumn("localToWorld")
  engine:addColumn("parent", "double")

  engine:addQuery(
    "createBodies",
    { "entity", "bodyConfig" },
    { "body", "deadTag" }
  )

  engine:addQuery(
    "createFixtures",
    { "entity", "fixtureConfig" },
    { "fixture", "deadTag" }
  )

  engine:addQuery("destroyFixtures", { "entity", "fixture", "deadTag" })

  engine:addQuery("destroyBodies", { "entity", "body", "deadTag" })

  engine:addQuery(
    "removeDeadRows",
    { "entity", "deadTag" },
    { "body", "fixture" }
  )

  engine:addEvent("draw")
  engine:addEvent("fixedUpdate")
  engine:addEvent("update")

  engine:addSystem("update", updateClock)

  engine:addSystem("fixedUpdate", createBodies)
  engine:addSystem("fixedUpdate", createFixtures)
  engine:addSystem("fixedUpdate", updateWorld)
  engine:addSystem("fixedUpdate", destroyFixtures)
  engine:addSystem("fixedUpdate", destroyBodies)
  engine:addSystem("fixedUpdate", removeDeadRows)

  engine:addSystem("draw", drawFixtures)
  engine:addSystem("draw", drawFps)

  engine:addRow({
    bodyConfig = {},
    fixtureConfig = {},
    localToParent = love.math.newTransform(2, 2),
  })

  engine:addRow({
    bodyConfig = { bodyType = "dynamic" },
    fixtureConfig = {},
    localToParent = love.math.newTransform(2.25, -2, 0.125 * math.pi),
  })
end

function love.draw(...)
  engine:handleEvent("draw", ...)
end

function love.update(...)
  engine:handleEvent("update", ...)
end
