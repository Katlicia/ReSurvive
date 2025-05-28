local anim8 = require "lib.anim8"
-- local Enemy = {}
-- Enemy.__index = Enemy

-- function Enemy:init(sprite, frameW, frameH, totalCols, totalRows, animDelay)
--     -- Enemy stats
--     self.speed = 60
--     self.alive = true
--     self.damage = 0.1
--     self.hp = 5

--     self.sprite = sprite
--     self.frameW = frameW
--     self.frameH = frameH
--     self.totalCols = totalCols
--     self.totalRows = totalRows
--     self.currentRow = 1
--     self.x = math.random(0, 1920)
--     self.y = math.random(0, 1080)
--     self.quads = {}
--     sprite:setFilter("nearest", "nearest")

--     self.anim = {
--         frame = 1,
--         timer = 0,
--         delay = animDelay or 0.1,
--         quads = {},
--         direction = "right"
--     }

--     self.scale = 1
--     self.rotation = 0
--     self:setAnimRow(1)

--     self.playingDeathAnim = false
--     self.deathAnimDone = false

--     self:updateHitbox()

-- end

-- function Enemy:update(dt, player)
--     self.anim.timer = self.anim.timer + dt
--     if self.anim.timer >= self.anim.delay then
--         self.anim.timer = 0
        
--         if self.playingDeathAnim then
--             if self.anim.frame < #self.anim.quads then
--                 self.anim.frame = self.anim.frame + 1
--             else
--                 self.playingDeathAnim = false
--                 self.deathAnimDone = true
--                 self.alive = false
--             end
--         else
--             self.anim.frame = self.anim.frame % #self.anim.quads + 1
--         end
--     end

--     if not self.playingDeathAnim then
--         self:updateHitbox()
--         local dx, dy = player.x + 80 - self.x, player.y + 80 - self.y
--         local dist = math.sqrt(dx * dx + dy * dy)
--         if dist > 0 then
--             self.x = self.x + (dx / dist) * self.speed * dt
--             self.y = self.y + (dy / dist) * self.speed * dt

--             if math.abs(dx) > 4 then
--                 self.anim.direction = (dx < 0) and "left" or "right"
--             end
--         end

--         if self:checkCollisionWithPlayer(player) then
--                 player:takeDamage(self.damage)
--                 self.attackTimer = 0
--             end
--     end

-- end


-- function Enemy:draw()
--     if not self.deathAnimDone then
--         love.graphics.setColor(1, 1, 1)
--         local quad = self.anim.quads[self.anim.frame]
--         local ox = self.frameW / 2
--         local oy = self.frameH / 2

--         local scaleX = (self.anim.direction == "left") and -self.scale or self.scale

--         love.graphics.draw(self.sprite, quad,
--             self.x, self.y,
--             0,
--             scaleX, self.scale,
--             ox, oy
--         )
--     end
-- end

-- function Enemy:checkCollisionWithPlayer(player)
--     local pw, ph = player.width, player.height
--     local ew, eh = self.frameW-50, self.frameH-50

--     return self.x < player.x + pw and
--            self.x + ew > player.x and
--            self.y < player.y + ph and
--            self.y + eh > player.y
-- end


-- function Enemy:generateQuads(row)
--     self.quads = {}
--     local y = row * self.frameH
--     for i = 1, self.totalCols do
--         self.quads[i] = love.graphics.newQuad(
--             (i - 1) * self.frameW,
--             y,
--             self.frameW,
--             self.frameH,
--             self.sprite:getWidth(),
--             self.sprite:getHeight()
--         )
--     end
--     self.currentRow = row
-- end

-- function Enemy:setAnimRow(row)
--     self.anim.currentRow = row
--     self.anim.quads = {}
--     for i = 1, self.totalCols do
--         self.anim.quads[i] = love.graphics.newQuad(
--             (i - 1) * self.frameW,
--             (row - 1) * self.frameH,
--             self.frameW, self.frameH,
--             self.sprite:getWidth(), self.sprite:getHeight()
--         )
--     end
-- end

-- function Enemy:takeDamage(amount)
--     if not self.alive or self.playingDeathAnim then return end

--     self.hp = self.hp - amount
--     if self.hp <= 0 then
--         self.hp = 0
--         self.alive = false
--         self.playingDeathAnim = true
--         self:setAnimRow(2)
--         self.anim.frame = 1
--     end
-- end

-- function Enemy:updateHitbox()
--     self.hitboxX = self.x - self.frameW - self.scale / 2
--     self.hitboxY = self.y - self.frameH - self.scale / 2
--     self.hitboxW =  self.frameW * self.scale
--     self.hitboxH = self.frameH * self.scale
--     self.hitBox = love.graphics.rectangle("fill", self.hitboxX, self.hitboxY, self.hitboxW, self.frameH * self.scale)
-- end

-- return Enemy

local Enemy = {}
Enemy.__index = Enemy

function Enemy:init(sprite, frameW, frameH, walkFrameCount, deathFrameCount, walkRow, deathRow)
    self.sprite = sprite
    sprite:setFilter("nearest", "nearest")
    self.frameW = frameW
    self.frameH = frameH
    self.walkFrameCount = walkFrameCount
    self.deathFrameCount = deathFrameCount
    self.walkRow = walkRow
    self.deathRow = deathRow
    self.scale = 1
    self.direction = "right"
    self.x = math.random(0, 1920)
    self.y = math.random(0, 1080)

    -- Enemy stats
    self.speed = 60
    self.alive = true
    self.damage = 0.1
    self.hp = 5
    self.xpValue = 3

    -- Default direction (For sprites that have different default rotations)
    self.flipDirection = false


    -- Animation
    local g = anim8.newGrid(self.frameW, self.frameH, self.sprite:getWidth(), self.sprite:getHeight())

    self.animations = {
        walk = anim8.newAnimation(g(self.walkFrameCount, self.walkRow), 0.1),
        death = anim8.newAnimation(g(self.deathFrameCount, self.deathRow), 0.1, "pauseAtEnd")
    }

    self.currentAnim = self.animations.walk

    self:updateHitbox()
end

function Enemy:update(dt, player)
    if self.alive then
        self.currentAnim:update(dt)

        self:updateHitbox()
        local dx, dy = player.x + 80 - self.x, player.y + 80 - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            self.x = self.x + (dx / dist) * self.speed * dt
            self.y = self.y + (dy / dist) * self.speed * dt
            if self.flipDirection then
                self.direction = dx < 0 and "right" or "left"
            else
                self.direction = dx < 0 and "left" or "right"
            end

        end

        if self:checkCollisionWithPlayer(player) then
                player:takeDamage(self.damage)
                self.attackTimer = 0
            end
    else
        self.currentAnim:update(dt)
    end
end


function Enemy:draw()
    local sx = (self.direction == "left") and -self.scale or self.scale
    local ox = self.frameW / 2
    local oy = self.frameH / 2

    self.currentAnim:draw(self.sprite, self.x, self.y, 0, sx, self.scale, ox, oy)
end

function Enemy:checkCollisionWithPlayer(player)
    local pw, ph = player.width, player.height
    local ew, eh = self.frameW-50, self.frameH-50

    return self.x < player.x + pw and
           self.x + ew > player.x and
           self.y < player.y + ph and
           self.y + eh > player.y
end

function Enemy:takeDamage(amount)
    if not self.alive then return end

    self.hp = self.hp - amount
    if self.hp <= 0 then
        self.hp = 0
        self.alive = false
        self.currentAnim = self.animations.death
        self.currentAnim:gotoFrame(1)
    end
end

function Enemy:updateHitbox()
    self.hitboxX = self.x - self.frameW - self.scale / 2
    self.hitboxY = self.y - self.frameH - self.scale / 2
    self.hitboxW =  self.frameW * self.scale
    self.hitboxH = self.frameH * self.scale
    self.hitBox = love.graphics.rectangle("fill", self.hitboxX, self.hitboxY, self.hitboxW, self.frameH * self.scale)
end

return Enemy
