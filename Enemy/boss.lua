local Enemy = require("Enemy/enemy")

local Boss = {}
Boss.__index = Boss
setmetatable(Boss, { __index = Enemy })

function Boss:new()
    local self = setmetatable({}, Boss)
    Boss.__type = "Boss"

    local sprite = love.graphics.newImage("Enemy/Assets/boss_sheet.png")
    local frameW, frameH = 32, 160

    Enemy.init(self, sprite, frameW, frameH, '1-12', '1-18', 2, 5)

    -- Slime stats
    self.speed = 40
    self.hp = 30
    self.damage = 1.0
    self.xpValue = 40

    self.scale = 2
    self.flipDirection = true

    return self
end

function Boss:update(dt, player)
    Enemy.update(self, dt, player)

    if not self.alive and self.currentAnim ~= self.animations.death then
        self.currentAnim = self.animations.death
        self.currentAnim:gotoFrame(1)
    end
end

return Boss
