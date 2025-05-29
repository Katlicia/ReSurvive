local UI = require("ui")
push = require "lib/push"
Player = require "Player/player"
camera = require "lib/camera"
EnemySpawner = require "Enemy/enemy_spawner"
local ui

math.randomseed(os.time())

local WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()
VIRTUAL_WIDTH = WINDOW_WIDTH
VIRTUAL_HEIGHT = WINDOW_HEIGHT

GameState = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    DEAD = "dead",
    SETTINGS = "settings"
}

function love.load()
    menuBgShader = love.graphics.newShader("Shaders/menu_background.glsl")
    ui = UI:new()
    ui:setState(GameState.MENU)

    music = love.audio.newSource("Assets/music/out_of_body.mp3", "stream")
    music:setLooping(true)
    music:setVolume(0.5)

    -- love.mouse.setVisible(false)
    love.graphics.setDefaultFilter("nearest", "nearest")
    defaultFont = love.graphics.newFont("Assets/font/Pixeled.ttf", 16)
    love.graphics.setFont(defaultFont)
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
    ui:update(dt)
    if ui.state == GameState.MENU  or ui.state == GameState.SETTINGS then
        menuBgShader:send("iTime", love.timer.getTime())
        menuBgShader:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight(), 1.0})
    end

    music:setVolume(ui.musicVolume)

    if ui.state == GameState.PLAYING then
        if not music:isPlaying() then
            music:play()
        end
        camera.x = Player.x + Player.width / 2 - love.graphics.getWidth() / 2
        camera.y = Player.y + Player.height / 2 - love.graphics.getHeight() / 2
        EnemySpawner:update(dt, Player)
        Player:update(dt, EnemySpawner.enemies)
        cam:lookAt(Player.x + Player.width / 2, Player.y + Player.height / 2)
    end
end

function love.draw()
    push:start()

    if ui.state == GameState.MENU or ui.state == GameState.SETTINGS then
        love.graphics.setShader(menuBgShader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()
    end
    ui:draw()

    if ui.state == GameState.PLAYING then
        -- background
        love.graphics.setShader(spaceShader)
        spaceShader:send("time", love.timer.getTime())
        spaceShader:send("cameraPos", {camera.x, camera.y})
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()

        love.graphics.setShader(nebulaShader)
        nebulaShader:send("time", love.timer.getTime())
        nebulaShader:send("cameraPos", {camera.x, camera.y})

        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()

        -- 3. camera and game objects
        cam:attach()
        Player:draw()
        EnemySpawner:draw()
        cam:detach()

        -- 4. HUD
        Player:drawXpBar()
    end
    push:finish()
    if ui.state == GameState.PLAYING then
        if not Player.frozen then
            Player:drawLevelUpText()
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and ui then
        ui:mousereleased(x, y)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and ui then
        ui:mousepressed(x, y)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        if ui.state == GameState.SETTINGS then
            ui:setState(GameState.MENU)
        elseif ui.state == GameState.PLAYING then
            ui:setState(GameState.PAUSED)
        elseif ui.state == GameState.PAUSED then
            ui:setState(GameState.PLAYING)
        end
    end
end