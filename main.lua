push = require "lib/push"
Player = require "Player/player"
camera = require "lib/camera"
EnemySpawner = require "Enemy/enemy_spawner"

math.randomseed(os.time())

local VIRTUAL_WIDTH = 1920
local VIRTUAL_HEIGHT = 1080

local WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest", "nearest")
    defaultFont = love.graphics.newFont("Assets/font/Pixeled.ttf", 16)
    love.graphics.setFont(defaultFont)
    perlinShader = love.graphics.newShader("Shaders/perlin_background.glsl")
    spaceShader = love.graphics.newShader("Shaders/space_shader.glsl")
    nebulaShader = love.graphics.newShader("Shaders/nebula_shader.glsl")


    cam = camera()

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = true,
        pixelperfect = true
    })

    Player:load()
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    camera.x = Player.x + Player.width / 2 - love.graphics.getWidth() / 2
    camera.y = Player.y + Player.height / 2 - love.graphics.getHeight() / 2
    -- perlinShader:send("time", love.timer.getTime())
    -- perlinShader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
    EnemySpawner:update(dt, Player)
    Player:update(dt, EnemySpawner.enemies)
    cam:lookAt(Player.x + Player.width / 2, Player.y + Player.height / 2)
end

function love.draw()
    push:start()

-- 1. space background
love.graphics.setShader(spaceShader)
spaceShader:send("time", love.timer.getTime())
spaceShader:send("cameraPos", {camera.x, camera.y})
love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
love.graphics.setShader()

-- 2. nebula overlay
love.graphics.setShader(nebulaShader)
nebulaShader:send("time", love.timer.getTime())
nebulaShader:send("cameraPos", {camera.x, camera.y})

love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
love.graphics.setShader()

-- 3. kamera ve oyun nesneleri
cam:attach()
Player:draw()
EnemySpawner:draw()
cam:detach()

-- 4. HUD
Player:drawXpBar()
push:finish()
Player:drawLevelUpText()
    -- push:start()

    -- -- love.graphics.setShader(spaceShader)
    -- -- spaceShader:send("time", love.timer.getTime())
    -- love.graphics.setShader(nebulaShader)
    -- nebulaShader:send("time", love.timer.getTime())
    -- love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- love.graphics.setShader()

    -- cam:attach()
    --     Player:draw()
    --     EnemySpawner:draw()
    -- cam:detach()
    
    -- Player:drawXpBar()
    -- push:finish()
    -- Player:drawLevelUpText()
end


