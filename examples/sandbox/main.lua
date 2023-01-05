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
  local t11, t12, t13, t14, t21, t22, t23, t24, t31, t32, t33, t34, t41, t42, t43, t44 =
    transform:getMatrix()

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

local function getLocalToWorld(database, entity, result)
  result = result or love.math.newTransform()
  local row = database:getRow(entity)

  if row.parent then
    getLocalToWorld(database, row.parent, result)
  else
    result:reset()
  end

  if row.localToParent then
    result:apply(row.localToParent)
  end

  return result
end

local function createBodies(database, dt)
  database:eachRow("createBodies", function(i, entities, bodyConfigs)
    local world = database:getProperty("world")
    local entity = entities[i]
    local row = database:getRow(entity)
    local localToWorld = getLocalToWorld(database, entity)
    local x, y, angle = decompose2(localToWorld)
    local config = bodyConfigs[i]
    local body = love.physics.newBody(world, x, y, config.bodyType)
    body:setUserData(entity)
    body:setAngle(angle)
    row.body = body
  end)
end

local function createFixtures(database, dt)
  database:eachRow("createFixtures", function(i, entities, fixtureConfigs)
    local world = database:getProperty("world")
    local row = database:getRow(entities[i])
    local body = assert(row.body)
    local shape = love.physics.newRectangleShape(1, 1)
    row.fixture = love.physics.newFixture(body, shape)
  end)
end

local function destroyFixtures(database, dt)
  database:eachRow("destroyFixtures", function(i, entities, fixtures)
    local row = database:getRow(entities[i])
    row.fixture:destroy()
    row.fixture = nil
  end)
end

local function destroyBodies(database, dt)
  database:eachRow("destroyBodies", function(i, entities, bodies)
    local row = database:getRow(entities[i])
    row.body:destroy()
    row.body = nil
  end)
end

local function removeDeadRows(database, dt)
  database:eachRow("removeDeadRows", function(i, entities)
    database:removeRow(entities[i])
  end)
end

local function updateClock(database, dt)
  local clock = database:getProperty("clock")
  clock.accumulatedDt =
    math.min(clock.accumulatedDt + dt, clock.maxAccumulatedDt)

  while clock.fixedDt <= clock.accumulatedDt do
    clock.accumulatedDt = clock.accumulatedDt - clock.fixedDt
    database:handleEvent("fixedupdate", clock.fixedDt)
  end
end

local function updateWorld(database, dt)
  local world = database:getProperty("world")
  world:update(dt)
end

local function drawBodies(database)
  love.graphics.push("all")

  local width, height = love.graphics.getDimensions()
  love.graphics.translate(0.5 * width, 0.5 * height)
  local scale = 0.1 * height
  love.graphics.scale(scale)
  love.graphics.setLineWidth(1 / scale)

  local world = database:getProperty("world")

  for _, body in ipairs(world:getBodies()) do
    local x, y = body:getPosition()
    love.graphics.line(0, 0, x, y)
  end

  love.graphics.pop()
end

local function drawFixtures(database)
  love.graphics.push("all")

  local width, height = love.graphics.getDimensions()
  love.graphics.translate(0.5 * width, 0.5 * height)
  local scale = 0.1 * height
  love.graphics.scale(scale)
  love.graphics.setLineWidth(1 / scale)

  local world = database:getProperty("world")

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

local function drawFps(database)
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

  database = tabula.newDatabase()

  database:setProperty("clock", {
    fixedDt = 1 / 60,
    accumulatedDt = 0,
    maxAccumulatedDt = 0.1,
  })
  database:setProperty("world", love.physics.newWorld(0, 10))

  database:addDataType("double")
  database:addDataType("float")
  database:addDataType("tag")
  database:addDataType("vec2")

  database:addColumn("body")
  database:addColumn("bodyConfig")
  database:addColumn("children")
  database:addColumn("deadTag", "tag")
  database:addColumn("entity", "double")
  database:addColumn("fixture")
  database:addColumn("fixtureConfig")
  database:addColumn("localToParent")
  database:addColumn("localToWorld")
  database:addColumn("parent", "double")

  database:addQuery(
    "createBodies",
    { "entity", "bodyConfig" },
    { "body", "deadTag" }
  )

  database:addQuery(
    "createFixtures",
    { "entity", "fixtureConfig" },
    { "fixture", "deadTag" }
  )

  database:addQuery("destroyFixtures", { "entity", "fixture", "deadTag" })

  database:addQuery("destroyBodies", { "entity", "body", "deadTag" })

  database:addQuery(
    "removeDeadRows",
    { "entity", "deadTag" },
    { "body", "fixture" }
  )

  database:addEvent("draw")
  database:addEvent("fixedupdate")
  database:addEvent("update")

  database:addSystem("update", updateClock)

  database:addSystem("fixedupdate", createBodies)
  database:addSystem("fixedupdate", createFixtures)
  database:addSystem("fixedupdate", updateWorld)
  database:addSystem("fixedupdate", destroyFixtures)
  database:addSystem("fixedupdate", destroyBodies)
  database:addSystem("fixedupdate", removeDeadRows)

  database:addSystem("draw", drawFixtures)
  database:addSystem("draw", drawFps)

  database:addRow({
    bodyConfig = {},
    fixtureConfig = {},
    localToParent = love.math.newTransform(2, 2),
  })

  database:addRow({
    bodyConfig = { bodyType = "dynamic" },
    fixtureConfig = {},
    localToParent = love.math.newTransform(2.25, -2, 0.125 * math.pi),
  })
end

function love.draw(...)
  database:handleEvent("draw", ...)
end

function love.update(...)
  database:handleEvent("update", ...)
end
