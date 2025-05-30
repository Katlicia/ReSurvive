local Player = {}

function Player:load(uiRef)
    -- Load shaders
    self.ui = uiRef
    xpShader = love.graphics.newShader("Shaders/bar_shader.glsl")
    xpBgShader = love.graphics.newShader("Shaders/bar_shader.glsl")

    xpShader:send("color1", {1.0, 1.0, 0.2, 1.0})
    xpShader:send("color2", {1.0, 0.8, 0.0, 1.0})

    xpBgShader:send("color1", {0.08, 0.1, 0.25, 1.0})
    xpBgShader:send("color2", {0.02, 0.02, 0.1, 1.0})

    greenHpShader = love.graphics.newShader("Shaders/bar_shader.glsl")
    redHpShader = love.graphics.newShader("Shaders/bar_shader.glsl")
    
    greenHpShader:send("color1", {0.0, 1.0, 0.0, 1.0})
    greenHpShader:send("color2", {0.0, 0.3, 0.0, 1.0})

    redHpShader:send("color1", {0.9, 0.1, 0.1, 1.0})
    redHpShader:send("color2", {0.3, 0.0, 0.0, 1.0})

    auraShader = love.graphics.newShader("Shaders/aura_shader.glsl")

    levelShader = love.graphics.newShader("Shaders/level_text_shader.glsl")
    
    -- Level up effects
    self.levelUpEffectTimer = 0
    self.levelUpEffectDuration = 2.0
    self.levelUpActive = false
    self.levelUpTextScale = 0.5
    self.levelUpCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())


    self.sprite = love.graphics.newImage("Player/Assets/Sprites/playersheet.png")
    self.auraImage = love.graphics.newImage("Player/Assets/Sprites/aura.png")
    
    -- Player dimensions
    self.x = 1920 / 2 - 64
    self.y = 1080 / 2 - 64
    self.width = 128
    self.height = 128
    
    -- Player stats
    self.maxHp = 100
    self.maxHpBar = 200
    self.hp = self.maxHp
    self.alive = true
    self.baseSpeed = 250
    self.speed = self.baseSpeed
    self.maxSkillLevel = 10

    -- Xp and level
    self.level = 1
    self.xp = 0
    self.nextLevelXp = 10
    self.xpBarValue = 0
    self.xpLerpSpeed = 4
    self.xpAnimationQueue = {}
    self.displayedXp = 0
    self.xpRadius = 150

    -- Frame state
    self.frozen = false

    anim = {
        spriteWidth = 512,
        spriteHeight = 192,
        quadWidth = 64,
        quadHeight = 64,
        totalFrames = 8,
        currentFrame = 1,
        direction = "right",
        moving = false,
        timer = 0,
        frameDelay = 0.1,
        currentRow = 0,
        rows = {
            idle = 0,
            walk = 1,
            death = 2
        }
    }

    self.playingDeathAnim = false
    self.deathAnimDone = false
    self.quads = {}
    self:generateQuads(anim.rows.idle) -- Idle anim at first

    -- Weapons
    self.whip = {
        name = "Whip",
        icon = love.graphics.newImage("Player/Assets/Sprites/whip-icon.png"),
        level = 1,
        sprite = love.graphics.newImage("Player/Assets/Sprites/slash_sheet.png"),
        spriteWidth = 288,
        spriteHeight = 48,
        quadWidth = 48,
        quadHeight = 48,
        totalFrames = 6,
        currentFrame = 1,
        cooldown = 2.4,
        timer = 0,
        visibleTimer = 0,
        attack = false,
        damage = 5,
        animTimer = 0,
        frameDelay = 0.1,
        width = self.height + 70,
        height = self.width / 2 + 10,
        sound = love.audio.newSource("Player/Assets/Sounds/whip.ogg", "static"),
        hasHitEnemies = {}
    }

    self.timeStop = {
        name = "Clock",
        icon = love.graphics.newImage("Player/Assets/Sprites/timestop-icon.png"),
        level = 0,
        sound = love.audio.newSource("Player/Assets/Sounds/time.ogg", "static"),
        timer = 0,
        transitionTime = 0,
        sumTime = 0,
        duration = 4,
        transitionActive = false,
        baseCooldown = 120,
        getCooldown = function(self)
            if self.level == 0 then
                return self.baseCooldown
            end
            local reductionFactor = 1 - (self.level - 1) * 0.10
            return math.max(40, self.baseCooldown * reductionFactor)
        end
    }

    self.wing = {
        name = "Boots",
        icon = love.graphics.newImage("Player/Assets/Sprites/wing-icon.png"),
        level = 0,
        boost = function(level)
            return Player.baseSpeed * (1 + 0.1 * level)
        end
    }

    self.whipQuads = {}
    self:generateWhipQuads()

    self.weapons = {
        self.whip
    }
    
    self.guardianAngel = {
        name = "Guardian Angel",
        icon = love.graphics.newImage("Player/Assets/Sprites/xp.png"),
        level = 0,
        used = false,
        addedToUI = false,
        reviveEffectDuration = 2.0,
        reviveEffectTimer = 0,
        reviveEffectActive = false,
        reviveShader = love.graphics.newShader("Shaders/revive_shader.glsl"),
        reviveColor = {1.0, 1.0, 1.0, 1.0},
        sound = love.audio.newSource("Player/Assets/Sounds/revive.ogg", "static")
    }
end

function Player:update(dt, enemies)
    -- Update anim
    anim.timer = anim.timer + dt
    if anim.timer >= anim.frameDelay then
        anim.timer = 0

        if self.playingDeathAnim then
            if anim.currentFrame < anim.totalFrames then
                anim.currentFrame = anim.currentFrame + 1
            else
                if self.guardianAngel.level > 0 and not self.guardianAngel.used then
                    self.guardianAngel.sound:play()
                    self.guardianAngel.used = true
                    self.alive = true
                    self.hp = self.maxHp
                    self.playingDeathAnim = false
                    self.deathAnimDone = false
                    self.frozen = false
                    self.guardianAngel.reviveEffectActive = true
                    self.guardianAngel.reviveEffectTimer = 0
                    self:generateQuads(anim.rows.idle)
                    anim.currentFrame = 1
                    anim.timer = 0
                else
                    self.playingDeathAnim = false
                    self.deathAnimDone = true
                    self.frozen = true
                end
            end
        elseif not self.frozen then
            anim.currentFrame = anim.currentFrame % anim.totalFrames + 1
        end
    end

    -- Movement control
    anim.moving = false
    local newRow = anim.rows.idle

    if self.alive and not self.frozen then
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            self.y = self.y - self.speed * dt
            anim.moving = true
            newRow = anim.rows.walk
        end
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then 
            self.y = self.y + self.speed * dt
            anim.moving = true
            newRow = anim.rows.walk
        end
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            self.x = self.x - self.speed * dt
            anim.direction = "left"
            anim.moving = true
            newRow = anim.rows.walk
        end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            self.x = self.x + self.speed * dt
            anim.direction = "right"
            anim.moving = true
            newRow = anim.rows.walk
        end
        Player:whipAttack(dt, enemies)
    end

    -- Update animation row if moving
    if not self.playingDeathAnim and newRow ~= anim.currentRow then
        self:generateQuads(newRow)
    end

    if self.whip.attack then
        self.whip.animTimer = self.whip.animTimer + dt
        if self.whip.animTimer >= self.whip.frameDelay then
            self.whip.animTimer = 0
            self.whip.currentFrame = self.whip.currentFrame + 1
            if self.whip.currentFrame > self.whip.totalFrames then
                self.whip.currentFrame = 1
            end
        end
    end

    if self.timeStop.level > 0 then
        self.timeStop.timer = (self.timeStop.timer or 0) + dt
        if self.timeStop.timer >= self.timeStop:getCooldown() then
            self:activateTimeStop()
            self.timeStop.timer = 0
        end
    end


    self:updateTimeStop(dt)
    if self.guardianAngel.reviveEffectActive then
        self.guardianAngel.reviveEffectTimer = self.guardianAngel.reviveEffectTimer + dt
        if self.guardianAngel.reviveEffectTimer >= self.guardianAngel.reviveEffectDuration then
            self.guardianAngel.reviveEffectActive = false
        end
    end

    Player:xpAnim(dt)
    Player:SetShaderTime()
end

function Player:draw()
    local scaleX = (anim.direction == "left") and -2 or 2
    local originX = (anim.direction == "left") and anim.quadWidth or 0

    if self.guardianAngel.reviveEffectActive then
        love.graphics.setShader(self.guardianAngel.reviveShader)
        self.guardianAngel.reviveShader:send("time", love.timer.getTime())
        self.guardianAngel.reviveShader:send("color", self.guardianAngel.reviveColor)
    else
        love.graphics.setShader()
    end


    if not self.frozen then
        if self.guardianAngel.reviveEffectActive then
            love.graphics.setShader(self.guardianAngel.reviveShader)
            self.guardianAngel.reviveShader:send("time", love.timer.getTime())
            self.guardianAngel.reviveShader:send("color", self.guardianAngel.reviveColor)

        elseif self.levelUpActive then
            love.graphics.setShader(auraShader)
            love.graphics.setColor(1, 1, 1, 1)

            local scale = 2.0
            local cx = self.x + self.width / 2
            local cy = self.y + self.height / 2

            local auraW = self.auraImage:getWidth() * scale
            local auraH = self.auraImage:getHeight() * scale

            love.graphics.draw(self.auraImage, cx - auraW / 2, cy - auraH / 2, 0, scale, scale)

        else
            love.graphics.setShader()
        end
        love.graphics.draw(self.sprite, self.quads[anim.currentFrame], self.x, self.y, 0, scaleX, 2, originX, 0)
        self:drawHpBar()

        -- WHIP
        if self.whip.attack then
            love.graphics.setColor(255, 255, 255)
            local quad = self.whipQuads[self.whip.currentFrame]
            local sx = 8
            local sy = 4
            if anim.direction == "right" then
                -- love.graphics.rectangle("fill", self.x + self.width - self.width / 2, self.y + 20, self.whip.width + self.width / 2, self.whip.height)
                love.graphics.draw(self.whip.sprite, quad, self.x, self.y - 30, 0, sx, sy)
            else
                -- love.graphics.rectangle("fill", self.x - self.whip.width, self.y + 20, self.whip.width + self.width / 2, self.whip.height)
                love.graphics.draw(self.whip.sprite, quad, self.x + self.width, self.y - 30, 0, -sx, sy)
            end
        end
    end
end

-- Prepares quads for a specific row
function Player:generateQuads(row)
    self.quads = {}
    local y = row * anim.quadHeight
    for i = 1, anim.totalFrames do
        self.quads[i] = love.graphics.newQuad(
            (i - 1) * anim.quadWidth,
            y,
            anim.quadWidth,
            anim.quadHeight,
            anim.spriteWidth,
            anim.spriteHeight
        )
    end
    anim.currentRow = row
end

function Player:generateWhipQuads()
    self.whipQuads = {}
    local y = 0 * self.whip.quadHeight
    for i = 1, self.whip.totalFrames do
        self.whipQuads[i] = love.graphics.newQuad(
            (i - 1) * self.whip.quadWidth,
            y,
            self.whip.quadWidth,
            self.whip.quadHeight,
            self.whip.spriteWidth,
            self.whip.spriteHeight
        )
    end
end

function Player:takeDamage(amount)
    if not self.alive then return end

    if self.guardianAngel.reviveEffectActive then
        return
    end
	self.hp = math.max(self.hp - amount, 0)
	if self.hp <= 0 then
		self.hp = 0
		self.alive = false
        self.playingDeathAnim = true
        self.deathAnimDone = false
        self:generateQuads(anim.rows.death)
        anim.currentFrame = 1
	end
end

function Player:addXp(amount)
    local xpToAdd = amount
    while xpToAdd > 0 do
        local needed = self.nextLevelXp - self.xp
        local chunk = math.min(xpToAdd, needed)
        table.insert(self.xpAnimationQueue, chunk)
        self.xp = self.xp + chunk
        xpToAdd = xpToAdd - chunk

        if self.xp >= self.nextLevelXp then
            self.xp = self.xp - self.nextLevelXp
            self.level = self.level + 1
            self.nextLevelXp = math.floor(self.nextLevelXp * 1.5)
            self.levelUpActive = true
            self.levelUpEffectTimer = 0
            self.levelUpTextScale = 0.5
            if self.ui and self.ui.showLevelUp then
                self.ui:showLevelUp()
            end
        end
    end
end

function Player:drawHpBar()
    local barWidth = math.min(self.maxHpBar, self.maxHp)
    local barHeight = 8
    local x = self.x + self.width / 2 - barWidth / 2
    local y = self.y - 10
    local ratio = self.hp / self.maxHp

    love.graphics.setShader(redHpShader)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)
    love.graphics.setShader()
    -- Draw green part of the HP bar

    love.graphics.setShader(greenHpShader)
    love.graphics.rectangle("fill", x, y, barWidth * ratio, barHeight)
    love.graphics.setShader()

    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, barWidth, barHeight)
end

function Player:drawXpBar()
    love.graphics.setShader(nil)
    local vw = love.graphics.getWidth()
    local width = vw / 2
    local height = 20
    local x = (vw - width) / 2
    local y = 10
    local ratio = self.xp / self.nextLevelXp

    love.graphics.setShader(xpBgShader)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setShader()

    love.graphics.setShader(xpShader)
    love.graphics.rectangle("fill", x, y, width * ratio, height)
    love.graphics.setShader()

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height)
    -- love.graphics.printf("XP: " .. self.xp .. "/" .. self.nextLevelXp .. "  LVL: " .. self.level, x, y-20, width, "center")
end


function Player:xpAnim(dt)
    local target = self.xp / self.nextLevelXp
    self.xpBarValue = self.xpBarValue + (target - self.xpBarValue) * self.xpLerpSpeed * dt
end

function Player:SetShaderTime()
    local t = love.timer.getTime()
    xpShader:send("time", t)
    xpBgShader:send("time", t)
    greenHpShader:send("time", t)
    redHpShader:send("time", t)
    auraShader:send("time", t)
    levelShader:send("time", t)
end

function Player:LevelUpAnim(dt)
    if self.levelUpActive then
        self.levelUpEffectTimer = self.levelUpEffectTimer + dt

        if self.levelUpTextScale < 1.5 then
            self.levelUpTextScale = self.levelUpTextScale + dt * 1.5
        end

        if self.levelUpEffectTimer >= self.levelUpEffectDuration then
            self.levelUpActive = false
        end
    end
end

function Player:drawLevelUpText()
    if not self.levelUpActive then return end

    local canvas = self.levelUpCanvas
    local text = "LEVEL UP!"
    local scale = self.levelUpTextScale

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(text, 0, 32, canvas:getWidth(), "center")
    love.graphics.setCanvas()

    love.graphics.setShader(levelShader)
    love.graphics.setColor(1, 1, 1, 1)

    local camX = camera and camera.x or 0
    local camY = camera and camera.y or 0

    local x = self.x + self.width / 2 - canvas:getWidth() * scale / 2 - camX
    local y = self.y - 80 - camY

    love.graphics.draw(canvas, x, y, 0, scale, scale)

    love.graphics.setShader()
end

function Player:whipAttack(dt, enemies)
    self.whip.timer = self.whip.timer + dt
    self.whip.visibleTimer = self.whip.visibleTimer + dt

    if self.whip.timer >= self.whip.cooldown then
        self.whip.attack = true
        self.whip.sound:stop()
        self.whip.sound:play()
        self.whip.timer = 0
        self.whip.visibleTimer = 0
        self.whip.hasHitEnemies = {}
    end

    if self.whip.visibleTimer >= 1 then
        self.whip.attack = false
        self.whip.currentFrame = 1
        self.whip.animTimer = 0
    end

    if self.whip.attack and self.whip.currentFrame == 1 then
        for _, enemy in ipairs(enemies) do
            if self:checkWhipHit(enemy) and not self.whip.hasHitEnemies[enemy] then
                enemy:takeDamage(self.whip.damage)
                self.whip.hasHitEnemies[enemy] = true
            end
        end
    end
end

function Player:checkWhipHit(enemy)
    local whipStartX, whipEndX
    local whipY = self.y + 20

    if anim.direction == "right" then
        whipStartX = self.x + self.width - self.width / 2
        whipEndX = whipStartX + self.whip.width + self.width / 2
    else
        whipStartX = self.x - self.whip.width
        whipEndX = whipStartX + self.whip.width + self.width / 2
    end

    return enemy.hitboxX < whipEndX and
           enemy.hitboxX + enemy.hitboxW > whipStartX and
           enemy.hitboxY < whipY + self.whip.height and
           enemy.hitboxY + enemy.hitboxH > whipY
end

function Player:updateTimeStop(dt)
    if self.timeStop.level <= 0 then return end
    if self.timeStop.transitionActive then
        self.timeStop.transitionTime = self.timeStop.transitionTime + dt
        self.timeStop.sumTime = self.timeStop.sumTime + dt
        GameStats.timeStopped = GameStats.timeStopped + dt
        if self.timeStop.transitionTime > self.timeStop.duration then
            self.timeStop.transitionActive = false
        end
    end
end

function Player:drawTimeStopEffect(canvas)
    if not self.timeStop.transitionActive then return end

    love.graphics.setShader(timeStopShader)
    timeStopShader:send("iTime", self.timeStop.transitionTime)
    timeStopShader:send("iChannel1", canvas)
    timeStopShader:send("iResolution", {VIRTUAL_WIDTH, VIRTUAL_HEIGHT})
end

function Player:activateTimeStop()
    if self.timeStop.level <= 0 then return end
    self.timeStop.transitionTime = 0
    self.timeStop.transitionActive = true
    self.timeStop.sound:play()
end

return Player
