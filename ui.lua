local UI = {}
UI.__index = UI

function UI:new()
    local this = {
        font = love.graphics.newFont("Assets/font/Pixeled.ttf", 32),
        smallFont = love.graphics.newFont("Assets/font/Pixeled.ttf", 12),
        state = nil,
        visible = true,
        buttons = {},
        hoveredIndex = nil,
        mouseDownIndex = nil,
        musicVolume = 0.5,
        sfxVolume = 0.5,
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
        self:createButton("PLAY", (VIRTUAL_WIDTH / 4), (VIRTUAL_HEIGHT / 2) * 1.5, 300, 150, function() gameState = GameState.PLAYING; self:setState(GameState.PLAYING) end)
        self:createButton("SETTINGS", (VIRTUAL_WIDTH / 2), (VIRTUAL_HEIGHT / 2) * 1.5, 300, 150, function() gameState = GameState.SETTINGS; self:setState(GameState.SETTINGS) end)
        self:createButton("EXIT", (VIRTUAL_WIDTH / 4) * 3, (VIRTUAL_HEIGHT / 2) * 1.5, 300, 150, function() love.event.quit() end)
    elseif state == "settings" then
        self:createSlider("Music Volume", VIRTUAL_WIDTH / 2 - 150, VIRTUAL_HEIGHT / 2 - 100, 400, 40, function(value) self.musicVolume = value music:setVolume(value) end, self.musicVolume)
        self:createSlider("SFX Volume", VIRTUAL_WIDTH / 2 - 150, VIRTUAL_HEIGHT / 2, 400, 40, function(value) self.sfxVolume = value end, self.sfxVolume)
        self:createButton("MAIN MENU", VIRTUAL_WIDTH / 2 , VIRTUAL_HEIGHT / 2 + 100, 300, 150, function() self:setState(GameState.MENU) end)
    elseif state == "paused" then
        self:createSlider("MUSIC", 110, 50, 100, 20, function(value) self.musicVolume = value music:setVolume(value) end, self.musicVolume)
        self:createSlider("SFX", 110, 90, 100, 20, function(value) self.sfxVolume = value end, self.sfxVolume)
        self:createButton("MAIN MENU", VIRTUAL_WIDTH / 6 + 180, VIRTUAL_HEIGHT / 7 + VIRTUAL_HEIGHT - 380, 120, 50, function() gameState = GameState.MENU; self:setState(GameState.MENU) end)
        self:createButton("CONTINUE", VIRTUAL_WIDTH / 6 + VIRTUAL_WIDTH - 700, VIRTUAL_HEIGHT / 7 + VIRTUAL_HEIGHT - 380, 120, 50, function() gameState = GameState.PLAYING; self:setState(GameState.PLAYING) end)
    end
end

            -- local panelWidth = VIRTUAL_WIDTH - 700
            -- local panelHeight = VIRTUAL_HEIGHT - 300
            -- local panelX = VIRTUAL_WIDTH / 6
            -- local panelY = VIRTUAL_HEIGHT / 7

function UI:createButton(text, x, y, w, h, callback)
    local button = {
        text = text,
        x = x - 150,
        y = y,
        -- width = 300,
        width = w,
        height = h,
        -- height = 150,
        callback = callback,
        clicked = false
    }
    table.insert(self.buttons, button)
end

function UI:createSlider(label, x, y, w, h, onChange, initialValue)
    table.insert(self.buttons, {
        type = "slider",
        label = label,
        x = x - 40,
        y = y,
        width = w,
        -- width = 400,
        height = h,
        -- height = 40,
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
        love.graphics.setFont(self.smallFont)
            local panelWidth = VIRTUAL_WIDTH - 700
            local panelHeight = VIRTUAL_HEIGHT - 300
            local panelX = VIRTUAL_WIDTH / 6
            local panelY = VIRTUAL_HEIGHT / 7

            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12, 12)

            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12, 12)

            local playerStats = {
                { label = "Level", value = Player.level },
                { label = "XP", value = Player.xp .. " / " .. Player.nextLevelXp },
                { label = "Max HP", value = Player.maxHp },
                { label = "HP", value = Player.hp },
                { label = "Speed", value = Player.speed }
            }

            local weaponStats = {}

            for _, weapon in ipairs(Player.weapons) do
                if weapon.name and weapon.damage and weapon.cooldown then
                    table.insert(weaponStats, { label = weapon.name .. " Damage", value = weapon.damage })
                    table.insert(weaponStats, { label = weapon.name .. " Cooldown", value = string.format("%.1f", weapon.cooldown) })
                end
            end

            local x = panelX + 30
            local y = panelY + 40
            local lineHeight = 30
            local labelOffset = 160
            local maxLineWidth = 300

            love.graphics.print("Player Stats", x, y)
            y = y + lineHeight

            love.graphics.setColor(1, 1, 1, 0.2)
            love.graphics.setLineWidth(1)
            love.graphics.line(x-5, y+5, x + maxLineWidth, y+5)
            y = y + 10

            for _, stat in ipairs(playerStats) do
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(stat.label .. ":", x, y)

                love.graphics.setColor(1, 1, 0.5)
                love.graphics.print(tostring(stat.value), x + labelOffset, y)

                y = y + lineHeight
            end

            if #weaponStats > 0 then
                y = y + 10
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Weapon Stats", x, y)
                y = y + lineHeight

                love.graphics.setLineWidth(1)
                love.graphics.setColor(1, 1, 1, 0.4)
                love.graphics.line(x-5, y+5, x + maxLineWidth, y+5)
                y = y + 10

                for _, stat in ipairs(weaponStats) do
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(stat.label .. ":", x, y)

                    love.graphics.setColor(1, 1, 0.5)
                    love.graphics.print(tostring(stat.value), x + labelOffset, y)

                    y = y + lineHeight
                end
            end

            love.graphics.setLineWidth(1)
        for i, button in ipairs(self.buttons) do
            if button.type == "slider" then
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(button.label, button.x - 60, button.y -10, button.width)

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

    elseif self.state == "dead" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("OLDUN", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf("R - Yeniden Başla", 0, 260, love.graphics.getWidth(), "center")
    end
end


return UI