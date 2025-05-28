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

    love.graphics.setShader(perlinShader)
    perlinShader:send("time", love.timer.getTime())
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()

    cam:attach()
        Player:draw()
        EnemySpawner:draw()
    cam:detach()
    
    Player:drawXpBar()
    push:finish()
    Player:drawLevelUpText()
end

