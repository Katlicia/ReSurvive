-- EnemySpawner.lua
local Skeleton = require("Enemy/skeleton")

local EnemySpawner = {}
EnemySpawner.enemies = {}
EnemySpawner.spawnTimer = 0
EnemySpawner.spawnInterval = 2.0
EnemySpawner.waveTimer = 0
EnemySpawner.nextWaveTime = 10
EnemySpawner.waveSize = 10
EnemySpawner.timeSinceStart = 0

function EnemySpawner:update(dt, player)
    self.spawnTimer = self.spawnTimer - dt
    self.waveTimer = self.waveTimer + dt
    self.timeSinceStart = self.timeSinceStart + dt

    if self.spawnTimer <= 0 then
        self:spawnSingle(player)
        self.spawnTimer = math.max(0.5, self.spawnInterval - self.timeSinceStart * 0.01)
    end

    if self.waveTimer >= self.nextWaveTime then
        self:spawnWave(player, self.waveSize)
        self.waveTimer = 0
        self.nextWaveTime = math.random(15, 25)
        self.waveSize = self.waveSize + 2
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        enemy:update(dt, player)
        if enemy.deathAnimDone then
            table.remove(self.enemies, i)
        end
    end
end

function EnemySpawner:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

function EnemySpawner:spawnSingle(player)
    local x, y = self:getOffscreenSpawnPos(player)
    local enemy = Skeleton:new()
    enemy.x = x
    enemy.y = y
    table.insert(self.enemies, enemy)
end

function EnemySpawner:spawnWave(player, count)
    local baseX, baseY = self:getOffscreenSpawnPos(player)
    for i = 1, count do
        local enemy = Skeleton:new()
        enemy.x = baseX + (i % 5) * 60
        enemy.y = baseY + math.floor(i / 5) * 60
        table.insert(self.enemies, enemy)
    end
end

function EnemySpawner:getOffscreenSpawnPos(player)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local margin = 200
    local dir = math.random(1, 4)
    local px, py = player.x, player.y

    if dir == 1 then return px - screenW / 2 - margin, py + math.random(-screenH, screenH) end
    if dir == 2 then return px + screenW / 2 + margin, py + math.random(-screenH, screenH) end
    if dir == 3 then return px + math.random(-screenW, screenW), py - screenH / 2 - margin end
    return px + math.random(-screenW, screenW), py + screenH / 2 + margin
end

return EnemySpawner
