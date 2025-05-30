local Slime = require("Enemy/slime")
local Skeleton = require("Enemy/skeleton")
local Boss = require("Enemy/boss")
local XpOrb = require("Player/xp_orb")


local EnemySpawner = {}
EnemySpawner.enemies = {}
EnemySpawner.orbs = {}
EnemySpawner.spawnTimer = 0
EnemySpawner.spawnInterval = 1.0
EnemySpawner.waveTimer = 0
EnemySpawner.nextWaveTime = 10
EnemySpawner.waveSize = 10
EnemySpawner.timeSinceStart = 0
EnemySpawner.spawnTimer = 0


EnemySpawner.enemyTypes = {
    { class = Slime, unlockTime = 0 },
    { class = Skeleton, unlockTime = 20 },
    -- { class = Boss, unlockTime = 10 }
}

function EnemySpawner:update(dt, player)
    if self.timeSinceStart == 0 then
        self:spawnInitialWave(player, 5)
    end

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
        if not enemy.alive and not enemy.counted then
            GameStats.enemiesKilled = GameStats.enemiesKilled + 1
            GameStats.enemiesByType[enemy.__type or "Unknown"] = 
                (GameStats.enemiesByType[enemy.__type or "Unknown"] or 0) + 1
            enemy.counted = true
        end
        if not enemy.alive and enemy.currentAnim.status == "paused" then
            local orb = XpOrb:new(enemy.x, enemy.y, enemy.xpValue, xpSound)
            table.insert(self.orbs, orb)
            table.remove(self.enemies, i)
        end
    end


    for i = #self.orbs, 1, -1 do
        local orb = self.orbs[i]
        orb:update(dt, player)
        if orb.collected then
            table.remove(self.orbs, i)
        end
    end

end

function EnemySpawner:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    for _, orb in ipairs(self.orbs) do
        orb:draw()
    end

end

function EnemySpawner:getAvailableEnemyTypes()
    local available = {}
    for _, e in ipairs(self.enemyTypes) do
        if self.timeSinceStart >= e.unlockTime then
            table.insert(available, e.class)
        end
    end
    return available
end

function EnemySpawner:spawnSingle(player)
    local x, y = self:getOffscreenSpawnPos(player)
    local enemyClass = self:pickRandomEnemy()
    local enemy = enemyClass:new()
    enemy.x = x
    enemy.y = y
    table.insert(self.enemies, enemy)
end

function EnemySpawner:spawnWave(player, count)
    local baseX, baseY = self:getOffscreenSpawnPos(player)
    for i = 1, count do
        local enemyClass = self:pickRandomEnemy()
        local enemy = enemyClass:new()
        enemy.x = baseX + (i % 5) * 60
        enemy.y = baseY + math.floor(i / 5) * 60
        table.insert(self.enemies, enemy)
    end
end

function EnemySpawner:pickRandomEnemy()
    local available = self:getAvailableEnemyTypes()
    return available[math.random(#available)]
end

function EnemySpawner:getOffscreenSpawnPos(player)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local margin = (self.timeSinceStart < 10) and 100 or 200
    local dir = math.random(1, 4)
    local px, py = player.x, player.y

    if dir == 1 then return px - screenW / 2 - margin, py + math.random(-screenH, screenH) end
    if dir == 2 then return px + screenW / 2 + margin, py + math.random(-screenH, screenH) end
    if dir == 3 then return px + math.random(-screenW, screenW), py - screenH / 2 - margin end
    return px + math.random(-screenW, screenW), py + screenH / 2 + margin
end

function EnemySpawner:spawnInitialWave(player, count)
    for i = 1, count do
        local angle = math.rad(math.random(0, 360))
        local x = player.x + math.cos(angle) * 1920
        local y = player.y + math.sin(angle) * 1080

        local enemyClass = self:pickRandomEnemy()
        local enemy = enemyClass:new()
        enemy.x = x
        enemy.y = y
        table.insert(self.enemies, enemy)
    end
end


return EnemySpawner
