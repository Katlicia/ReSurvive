local Enemy = require("Enemy/enemy")

local Skeleton = {}
Skeleton.__index = Skeleton
setmetatable(Skeleton, { __index = Enemy })

function Skeleton:new()
    local self = setmetatable({}, Skeleton)

    local sprite = love.graphics.newImage("Enemy/Assets/skeleton_sheet.png")
    local frameW, frameH = 48, 48
    local totalCols, totalRows = 12, 5
    local animDelay = 0.12

    Enemy.init(self, sprite, frameW, frameH, totalCols, totalRows, animDelay)

    -- Skeleton stats
    self.speed = 80
    self.hp = 10
    self.damage = 0.1

    self.scale = 2

    self:setAnimRow(1)
    -- self:setAnimRow(2)
    self:generateQuads(1)

    return self
end

function Skeleton:update(dt, player)
    Enemy.update(self, dt, player)

    if love.keyboard.isDown("k") then
        self.alive = false
        self.playingDeathAnim = true
        self:setAnimRow(2)
        self.anim.frame = 1
    end
end

return Skeleton
