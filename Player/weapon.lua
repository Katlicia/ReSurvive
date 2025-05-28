local Weapon = {}
Weapon.__index = Weapon

function Weapon:new(args)
    local weapon = setmetatable({}, Weapon)

    weapon.cooldown = args.cooldown or 1.0
    weapon.timer = 0
    weapon.damage = args.damage or 1
    weapon.range = args.range or 100
    weapon.onFire = args.onFire or function() end
    weapon.owner = args.owner or nil
    weapon.sound = args.sound or nil
    weapon.effect = args.effect or nil

    return weapon
end

function Weapon:update(dt, enemies)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.timer = self.cooldown
        self:fire(enemies)
    end
end

function Weapon:fire(enemies)
    if self.sound then
        self.sound:play()
    end

    if self.onFire then
        self.onFire(self.owner, enemies, self)
    end
end

return Weapon
