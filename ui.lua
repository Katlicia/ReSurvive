local UI = {}
UI.__index = UI

function UI:new()
    local this = {
        font = love.graphics.newFont("Assets/font/Pixeled.ttf", 32),
        state = nil,
        visible = true,
        buttons = {},
        hoveredIndex = nil,
        mouseDownIndex = nil,
        musicVolume = 0.5,
        sfxVolume = 0.5
    }

    if not UI.buttonShader then
        UI.buttonShader = love.graphics.newShader("Shaders/button_shader.glsl")
    end

    if not UI.sliderShader then
        UI.sliderShader = love.graphics.newShader("Shaders/slider_shader.glsl")
    end


    return setmetatable(this, UI)
end

function UI:setState(state)
    self.state = state
    self.buttons = {}
    if state == "menu" then
        self:createButton("PLAY", (VIRTUAL_WIDTH / 4), (VIRTUAL_HEIGHT / 2) * 1.5, function() gameState = GameState.PLAYING; self:setState(GameState.PLAYING) end)
        self:createButton("SETTINGS", (VIRTUAL_WIDTH / 2), (VIRTUAL_HEIGHT / 2) * 1.5, function() gameState = GameState.SETTINGS; self:setState(GameState.SETTINGS) end)
        self:createButton("EXIT", (VIRTUAL_WIDTH / 4) * 3, (VIRTUAL_HEIGHT / 2) * 1.5, function() love.event.quit() end)
    elseif state == "settings" then
        self:createSlider("Music Volume", VIRTUAL_WIDTH / 2 - 150, VIRTUAL_HEIGHT / 2 - 100, function(value) self.musicVolume = value music:setVolume(value) end, self.musicVolume)
        self:createSlider("SFX Volume", VIRTUAL_WIDTH / 2 - 150, VIRTUAL_HEIGHT / 2, function(value) self.sfxVolume = value end, self.sfxVolume)
        self:createButton("MAIN MENU", VIRTUAL_WIDTH / 2 , VIRTUAL_HEIGHT / 2 + 100, function() self:setState(GameState.MENU) end)
    end
end

function UI:createButton(text, x, y, callback)
    local button = {
        text = text,
        x = x - 150,
        y = y,
        width = 300,
        height = 150,
        callback = callback,
        clicked = false
    }
    table.insert(self.buttons, button)
end

function UI:createSlider(label, x, y, onChange, initialValue)
    table.insert(self.buttons, {
        type = "slider",
        label = label,
        x = x - 40,
        y = y,
        width = 400,
        height = 40,
        value = initialValue or 0.5,
        onChange = onChange
    })
end

function UI:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hoveredIndex = nil
    for i, button in ipairs(self.buttons) do
        if button.type ~= "slider" then
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                self.hoveredIndex = i
            end
        elseif love.mouse.isDown(1) and
               mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
            local ratio = (mx - button.x) / button.width
            ratio = math.min(math.max(ratio, 0), 1)
            button.value = ratio
            button.onChange(ratio)
        end
    end
end


function UI:mousepressed(x, y)
    for i, button in ipairs(self.buttons) do
        if x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height then
            self.mouseDownIndex = i
            button.clicked = true
        end
    end
end

function UI:mousereleased(x, y)
    if self.mouseDownIndex then
        local button = self.buttons[self.mouseDownIndex]
        if button.type ~= "slider" then
            if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
                button.callback()
            end
        end
        button.clicked = false
        self.mouseDownIndex = nil
    end
end

function UI:draw()
    if not self.visible or not self.state then return end

    love.graphics.setFont(self.font)

    if self.state == "menu" or self.state == "settings" then
        love.graphics.setShader()
        love.graphics.setColor(1, 1, 1)

        if self.state == "menu" then
            love.graphics.printf("Re Survive", 0, 150, VIRTUAL_WIDTH, "center")
        elseif self.state == "settings" then
            love.graphics.printf("SETTINGS", 0, 150, VIRTUAL_WIDTH, "center")
            local panelWidth = 500
            local panelHeight = 40*13
            local panelX = (VIRTUAL_WIDTH - panelWidth) / 2
            local panelY = VIRTUAL_HEIGHT / 2 - 200

            love.graphics.setColor(0.1, 0.1, 0.1, 0.4)
            love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12, 12)

            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12, 12)

            love.graphics.setLineWidth(1)
        end

        for i, button in ipairs(self.buttons) do
            if button.type == "slider" then
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(button.label, button.x, button.y - 80, button.width, "center")

                love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
                love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

                love.graphics.setShader(UI.sliderShader)
                UI.sliderShader:send("time", love.timer.getTime())
                UI.sliderShader:send("resolution", {button.width, button.height})

                love.graphics.setColor(0.8, 0.8, 0.2, 1)
                love.graphics.rectangle("fill", button.x, button.y, button.width * button.value, button.height, 8, 8)
                
                love.graphics.setShader()
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)
            else
                local hovered = (i == self.hoveredIndex)
                local clicked = (i == self.mouseDownIndex)

                local scale = clicked and 0.92 or (hovered and 1.02 or 1.0)
                local bx = button.x + button.width * (1 - scale) / 2
                local by = button.y + button.height * (1 - scale) / 2
                local bw = button.width * scale
                local bh = button.height * scale

                love.graphics.setShader(UI.buttonShader)
                UI.buttonShader:send("time", love.timer.getTime())
                UI.buttonShader:send("hovered", hovered)
                UI.buttonShader:send("iResolution", {button.width, button.height})


                if hovered then
                    love.graphics.setColor(1.0, 1.0, 1.0, 0.8)
                else
                    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
                end

                love.graphics.rectangle("fill", bx, by, bw, bh, 8, 8)

                love.graphics.setShader()
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("line", bx, by, bw, bh, 8, 8)
                love.graphics.setShader()

                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(button.text, bx, by + 10, bw, "center")
            end
        end

    elseif self.state == "paused" then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("DURAKLATILDI", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf("ESC - Devam", 0, 260, love.graphics.getWidth(), "center")

    elseif self.state == "dead" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("OLDUN", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf("R - Yeniden Başla", 0, 260, love.graphics.getWidth(), "center")
    end
end


return UI