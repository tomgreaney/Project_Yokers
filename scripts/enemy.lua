local enemy = {
    enemyImage = nil,
    aiState = "roaming",
    targetX = 0,
    targetY = 0,
    aiLoopTimer = nil,
    type = 0, -- 0 is normal, red is 1, blue is 2, black is 3
    health = 1,
    pushActive = false,
    pushAmount = 0,
    pushX = 0,
    pushY = 0,
    pushFrame = 0,
    currentMovementSpeed = 0,
    readyToFire = true,
    bossHealthPhase = 0,
    damageTimer = 0,
    bossSpeedTimer = 0,
    bossInvincibilityTimer = 0
}
enemy.__index = enemy
local movementSpeed = 250
local dropHeart = false
local dropHeartx = 0
local dropHearty = 0
local iceChickenAcceleratedSpeed = 600
local fireballLifetime = 5
local timeBetweenFireballs = 1
local fireballDamage = 1
local bossInvincibilityTimer
--local flashFactor = 0.04
--local playerAttackDistance = 600 -- If the player comes closer than this distance, the enemy attacks
--local playerForgetDistance = 900 -- If the player gets this far away, the enemy will forget about them and go back to the coops

local explosionSound = audio.loadSound("audio/Explosion.wav")
local chickenHurt = audio.loadSound("audio/ChickenHurt.wav")
local enemyDamageTime = 1000

--      AI States: 
-- roaming - Randomly wandering around.
-- attackCoop - Going after the closest chicken coop
-- attackPlayer - Going after the player
-- retreating - Running away from the player (black chicken only)
--      AI Transitions between States:
-- Roaming will become attackCoop after waiting a random amount of time
-- roaming/attackCoop will become attackPlayer if the player comes really close or if the player attacks
-- attackPlayer will become roaming if the player gets far away
-- retreating will become attackPlayer once the enemy gets far enough away

function enemy.start()
    SpawnBoss = false
    enemyDamageTime = 1000
    movementSpeed = 250
    dropHeart = false
    dropHeartx = 0
    dropHearty = 0
    iceChickenAcceleratedSpeed = 600
    fireballLifetime = 5
    timeBetweenFireballs = 1
    fireballDamage = 1
end

local function spawnBossAmmo()
    local ammoCoop
    ammoCoop = Coops[1]
    for i=1, CoopsAlive do
        if Coops[i].health > ammoCoop.health then
            ammoCoop = Coops[i]
        end
    end
    ammoCoop.ammo = ammoCoop.ammo + math.ceil((1/MinPlayerAccuracy*BossHealth)/5) 
    ammoCoop.eggImage = display.newImageRect(BackgroundGroup, "assets/egg.png", 300 / 8, 380 / 8)
    ammoCoop.eggImage.x = ammoCoop.x
    ammoCoop.eggImage.y = ammoCoop.y-100    
end

function enemy.new(startX, startY)
    local self = setmetatable({}, enemy) -- OOP in Lua is weird...
    local pickred = math.random(RedChance) + Level - 1
    local pickblue = math.random(BlueChance) + Level - 2
    local pickblack = math.random(BlackChance) + Level - 3
    if IsDebug then
        SpawnBoss = true
    end
    if not SpawnBoss then
        if pickred > RedChance then
            self.enemyImage = display.newImageRect(BackgroundGroup, "assets/redenemy.png", 93, 120)
            self.type = 1
            self.health = 1
            self.playerForgetDistance = 900
            self.playerAttackDistance = 600
            self.coopDamagePerHit = 12
            self.currentMovementSpeed = movementSpeed
        elseif pickblue > BlueChance then
            self.enemyImage = display.newImageRect(BackgroundGroup, "assets/blueenemy.png", 93, 120)
            self.type = 2
            self.health = 3
            self.playerForgetDistance = 900
            self.playerAttackDistance = 600
            self.coopDamagePerHit = 12
            self.currentMovementSpeed = movementSpeed
        elseif pickblack > BlackChance then
            self.enemyImage = display.newImageRect(BackgroundGroup, "assets/blackenemy.png", 93, 120)
            self.type = 3
            self.health = 3
            self.playerForgetDistance = 1200
            self.playerAttackDistance = 900
            self.playerRetreatDistance = 500 -- If the player gets closer than this, chicken will retreat.
            self.playerAcceptableDistance = 800 -- The distance the chicken will go when retreating.
            self.coopDamagePerHit = 12
            self.currentMovementSpeed = movementSpeed
        else
            self.enemyImage = display.newImageRect(BackgroundGroup, "assets/enemy.png", 93, 120)
            self.type = 0
            self.health = 1
            self.playerForgetDistance = 900
            self.playerAttackDistance = 600
            self.coopDamagePerHit = 12
            self.currentMovementSpeed = movementSpeed
        end
    else
        self.enemyImage = display.newImageRect(BackgroundGroup, "assets/enemy.png", 197, 256)
        self.type = 4
        self.health = BossHealth
        self.playerForgetDistance = 1300
        self.playerAttackDistance = 1000
        self.coopDamagePerHit = 100
        self.enemyImage.phase = 0
        self.enemyImage.isInvincible = false
        self.allowShoot = false
        self.flashme = false
        self.flashFactor = 0.04
        self.currentMovementSpeed = 100
        self.bossHealthPhase = 4
        SpawnBoss = false
    end
    BackgroundGroup:insert(22+IceLimit+LavaLimit+BrokenCoops,self.enemyImage)
    self.enemyImage.instance = self -- give the image a reference to this script instance for collisionEvent
    Physics.addBody(self.enemyImage, "dynamic")
    self.enemyImage.myName = "enemy"
    self.enemyImage.x = startX
    self.enemyImage.y = startY
    self.aiLoopTimer = timer.performWithDelay(33.333333, function() enemy.aiUpdate(self) end, 0) -- 33.3333 ms delay = 30 times a second, 0 means it will repeat forever
    self.enemyImage.collision = self.collisionEvent
    self.canDamage = true
    self.enemyImage:addEventListener("collision")

    Runtime:addEventListener("enterFrame", function() enemy.enterFrame(self) end)

    self.targetX = math.random(LevelBoundLeft, LevelBoundRight) -- Generate an initial random target (enemy starts in "roaming" mode)
    self.targetY = math.random(LevelBoundTop, LevelBoundBottom)

    local ammoCoop = ClosestCoop(startX, startY)
    if(PlayerActive) and (not(self.type == 4)) then
        if ammoCoop.ammo == 0 then
            ammoCoop.eggImage = display.newImageRect(BackgroundGroup, "assets/egg.png", 300 / 8, 380 / 8)
            ammoCoop.eggImage.x = ammoCoop.x
            ammoCoop.eggImage.y = ammoCoop.y-100
        end
        
        if math.random() < MinPlayerAccuracy then
            ammoCoop.ammo = ammoCoop.ammo + 1 + math.floor(self.type/2)
        else
            ammoCoop.ammo = ammoCoop.ammo + math.random(1,MaxEggsPerEnemy+math.floor(self.type/2))
        end
    elseif(PlayerActive) then
        spawnBossAmmo()      
    end
    return self
end

function enemy.nukeEnemies()
    local nuke = display.newImageRect(BackgroundGroup, "assets/blank.png", 30000,30000)
    nuke.x = 0
    nuke.y = 0
    Physics.addBody(nuke, "static")
    nuke.myName= "nuke"
    nuke.collision = enemy.collisionEvent
    nuke:addEventListener("collision")
end

function enemy.collisionEvent(self, event)
    -- In this case, "self" refers to "enemyImage"
    if event.phase == "began" then
        if event.other.myName == "player" and self.myName == "heart" then
            Player.damage(-1)
            timer.cancel(self.blink)
            timer.cancel(self.despawnTimer)
            self:removeSelf()
            return
        end
        if event.other.myName == "nuke" and self.myName == "enemy" then
            self.instance.health = 0
            print("nuked")
        end
        if event.other.myName == "playerProjectile" and self.myName == "enemy" then
            if(event.other.isFireEgg) then
                event.other.fireEggImage:removeSelf()
                if not self.instance.type == 4 then
                    self.instance.health = 0
                elseif not self.isInvincible then
                    self.instance.health = self.instance.health - (self.instance.health % 10)  -- brings boss to next phase
                end
                Decor.SparkExplosion(event.other.x,event.other.y)
                audio.play(explosionSound,{channel = 9, loops = 0, duration = 5000})
                Explosion = true
                ExplosionX = event.other.x
                ExplosionY = event.other.y
            else
                if not self.instance.type == 4 or not self.isInvincible then
                    self.instance.health = self.instance.health - 1
                    if self.instance.type > 1 then
                        audio.play(chickenHurt, {channel = 12, loops = 0, duration = 700})
                    end
                end
            end
            timer.cancel(event.other.despawnTimer)
            event.other:removeSelf()
            if not self.instance.type == 4 or not self.isInvincible then
                local pushX = (event.other.x - event.target.x)
                local pushY = (event.other.y - event.target.y)
                self.instance:push(0.1, pushX, pushY)
            end
        elseif (event.other.myName == "cactus" or event.other.myName == "lavaLake" or event.other.myName == "explosion") and self.myName == "enemy" then
            self.instance.health = self.instance.health - 1
            if event.other.myName == "explosion" then
                timer.cancel(event.other.timer)
                event.other:removeSelf()
            else
                if self.instance.type == 2 and event.other.myName == "lavaLake" then
                    self.instance.health = 0 -- blue chickens die instantly in lava
                end
                if ((self.instance.type == 1 or (self.instance.type == 4 and self.isInvincible)) and event.other.myName == "cactus") then
                    self.instance.health = self.instance.health + 1 -- red chickens are immune to cacti
                end
                if((self.instance.type == 3 or (self.instance.type == 4 and self.isInvincible)) and event.other.myName == "lavaLake") then
                    self.instance.health = self.instance.health + 1--black chickens are immune to lava
                end
            end
        elseif event.other.myName == "iceLake" and self.instance.type == 2 then
            self.instance.currentMovementSpeed = iceChickenAcceleratedSpeed -- ice chickens move faster on ice lakes
        end
        if self.myName == "enemy" and event.other.myName == "coop" and self.instance.canDamage and event.other.isActive then
            self.instance.canDamage = false
            CoopDamage(event.other, self.instance.coopDamagePerHit)
            self.damageTimer = timer.performWithDelay(enemyDamageTime, function() self.instance.canDamage = true end, 1)
        end
        if self.myName == "enemy" and self.instance.type == 4 and not self.isInvincible and self.instance.health % 10 == 0 then
            --after 10 hits the boss turns invincible and goes on a rampage at high speed
            if not bossInvincibilityTimer == nil then
                timer.cancel(bossInvincibilityTimer)
            end
            self.instance.flashme = false
            self.isInvincible = true
            if not self.fill.effect == nil then
                self.fill.effect.a = 0.8 --keeps the bosses phase color, looks cool imo
            end
            self.instance.allowShoot = false
            self.instance.health = self.instance.health - 1 -- to stop the trigger looping ie. makes his health 45 in reality
            if(self.instance.health <= (self.instance.bossHealthPhase/5)*BossHealth) then
                spawnBossAmmo()
                self.instance.bossHealthPhase = self.instance.bossHealthPhase - 1
            end
            self.instance.currentMovementSpeed = 400 + 50*self.phase
            self.phase = self.phase + 1
            self.bossSpeedTimer = timer.performWithDelay(8000, function() self.instance.currentMovementSpeed = 100 self.instance.allowShoot = true end, 1)
        end
        if self.myName == "enemy" and self.instance.health <= 0 then
            timer.cancel(self.instance.aiLoopTimer)
            if not (self.instance.projectileReadyTimer == nil) then
                timer.cancel(self.instance.projectileReadyTimer)
            end
            EnemyAmount = EnemyAmount - 1
            dropHeart = true
            dropHeartx = self.x
            dropHearty = self.y
            self:removeSelf()
        end
    elseif event.phase == "ended" then
        if event.other.myName == "iceLake" and self.instance.type == 2 then
            self.instance.currentMovementSpeed = movementSpeed
        end
    end
end


function enemy.SpawnHeart(heartx, hearty)
    if math.random(1,HeartDropChance) == HeartDropChance then
        local heartPickup = display.newImageRect(BackgroundGroup, "assets/fullheart.png", 48, 42)
        local blink = false
        heartPickup.x = heartx
        heartPickup.y = hearty
        Physics.addBody(heartPickup, "static", {isSensor = true})
        heartPickup.myName = "heart"
        heartPickup.collision = enemy.collisionEvent
        heartPickup:addEventListener("collision")
        heartPickup.despawnTimer = timer.performWithDelay(HeartLifeTime * 1000, function() heartPickup:removeSelf() end, 1)
        heartPickup.blink = timer.performWithDelay(200, function() if blink then heartPickup.alpha = 1.0 else heartPickup.alpha = 0.4 end blink = not(blink) end, 0)
    end
end

function enemy:push(_pushAmount, _pushX, _pushY)
    self.pushAmount = _pushAmount
    self.pushX = _pushX
    self.pushY = _pushY
    self.pushActive = true
end

function enemy:enterFrame()
    if self.enemyImage.y == nil then -- chicken has already died
        return
    end
    if self.flashme then
        self.flashloop = self.flashloop + self.flashFactor
        self.enemyImage.fill.effect = "filter.monotone"
        if self.enemyImage.phase == 1 then
            self.enemyImage.fill.effect.r = 1
            self.enemyImage.fill.effect.g = 1
            self.enemyImage.fill.effect.b = 1
        elseif self.enemyImage.phase == 2 then
            self.enemyImage.fill.effect.r = 1
            self.enemyImage.fill.effect.g = 1
            self.enemyImage.fill.effect.b = 0
        elseif self.enemyImage.phase == 3 then
            self.enemyImage.fill.effect.r = 1
            self.enemyImage.fill.effect.g = 0.5
            self.enemyImage.fill.effect.b = 0
        else
            self.enemyImage.fill.effect.r = 1
            self.enemyImage.fill.effect.g = 0
            self.enemyImage.fill.effect.b = 0
        end
        self.enemyImage.fill.effect.a = self.flashloop * 0.7
        if self.flashloop >= 1 then
            self.flashFactor = -1 * self.flashFactor
        elseif self.flashloop <= 0 then
            self.flashFactor = -1 * self.flashFactor
        end
    end
    if dropHeart then
        dropHeart = false
        enemy.SpawnHeart(dropHeartx, dropHearty)
    end
    -- Point towards the target position
    self.enemyImage.rotation = math.deg(math.atan2(self.enemyImage.y - self.targetY, self.enemyImage.x - self.targetX)) - 90
    -- Move towards the target position
    if not self.pushActive then
        local angle = math.rad(self.enemyImage.rotation - 90)
        self.enemyImage:setLinearVelocity(math.cos(angle) * self.currentMovementSpeed, math.sin(angle) * self.currentMovementSpeed)
    end

    if self.pushActive and self.pushFrame < 30 then
        if self.enemyImage.x <= LevelBoundLeft or self.enemyImage.x >= LevelBoundRight or self.enemyImage.y <= LevelBoundTop or self.enemyImage.y >= LevelBoundBottom then
            self.pushFrame = 29
        end
        self.enemyImage:setLinearVelocity(self.pushAmount * self.pushX * -40, self.pushAmount * self.pushY * -40)
        self.pushAmount = self.pushAmount - (self.pushAmount / 30)
        self.pushFrame = self.pushFrame + 1
    elseif self.pushFrame >= 30 and self.pushActive then
        self.pushFrame = 0
        self.pushActive = false
    end
end

function enemy:aiUpdate() -- Called 30 times a second
    local playerX, playerY = Player.getPosition()
    local playerDistance = CalculateDistance(self.enemyImage.x, self.enemyImage.y, playerX, playerY)
    local closestCoop = ClosestCoop(self.enemyImage.x, self.enemyImage.y) -- Find the closest coop to this enemy
    if self.aiState == "roaming" then
        if math.random(0, 200) == 0 then -- 1 in 200 chance, 30 times a second - on average will roam for 6 seconds
            self.aiState = "attackCoop"
        end
        if playerDistance < self.playerAttackDistance then
            self.aiState = "attackPlayer"
        end
        if CalculateDistance(self.enemyImage.x, self.enemyImage.y, self.targetX, self.targetY) < 100 then
            -- When the enemy arrives at the target position, generate a new target position
            self.targetX = math.random(LevelBoundLeft, LevelBoundRight)
            self.targetY = math.random(LevelBoundTop, LevelBoundBottom)
        end
    elseif self.aiState == "attackCoop" then
        if playerDistance < self.playerAttackDistance then
            self.aiState = "attackPlayer"
        end
        if(PlayerActive) then
            self.targetX = closestCoop.x
            self.targetY = closestCoop.y
        end
    elseif self.aiState == "attackPlayer" then
        if playerDistance > self.playerForgetDistance then
            self.aiState = "attackCoop"
        end
        if self.type == 3 and playerDistance < self.playerRetreatDistance then
            self.aiState = "retreating"
        end
        if (self.type == 3 or (self.type == 4 and math.random(30) == 30) and self.allowShoot) and self.readyToFire == true then
            self:fireProjectile()
            if self.type == 4 then
                self.enemyImage.isInvincible = false
                self.allowShoot = false
                self.flashme = true
                self.flashloop = 0
                self.bossInvincibilityTimer = timer.performWithDelay(5000, function() self.enemyImage.isInvincible = true self.flashme = false self.allowShoot = true end, 1)
            end
        end
        self.targetX = playerX
        self.targetY = playerY
    elseif self.aiState == "retreating" then
        if playerDistance > self.playerAcceptableDistance then
            self.aiState = "attackPlayer"
        end
        local deltaX = self.enemyImage.x - playerX
        local deltaY = self.enemyImage.y - playerY
        self.targetX = self.enemyImage.x + (2 * deltaX)
        self.targetY = self.enemyImage.y + (2 * deltaY)
    end

    if playerDistance < 150 or (self.type == 4 and playerDistance < 200) then
        local playerDamage = 1
        if self.type == 1 or self.type == 4 then
            playerDamage = 2
        end
        Player.damage(playerDamage)
    end
end

local function fireballCollision(self, event)
    if event.other.myName == "player" then
        Player.damage(fireballDamage)
        timer.cancel(self.despawnTimer)
        self:removeSelf()
    end
end

function enemy:fireProjectile()
    local newProjectile = display.newImageRect(BackgroundGroup, "assets/fireBall.png", 300 / 8, 380 / 8)
    BackgroundGroup:insert(22+IceLimit+LavaLimit+BrokenCoops,newProjectile)
    Physics.addBody(newProjectile, "dynamic", {isSensor=true})
    newProjectile.isBullet = true -- makes collision detection "continuous" (more accurate)
    newProjectile.myName = "enemyProjectile" -- also used for collision detection
    newProjectile.x = self.enemyImage.x
    newProjectile.y = self.enemyImage.y
    newProjectile.rotation = self.enemyImage.rotation
    local angle = math.rad(newProjectile.rotation - 90) -- use the projectile's direction to see which way it should go
    newProjectile:setLinearVelocity(math.cos(angle) * FireBallSpeed, math.sin(angle) * FireBallSpeed)
    newProjectile.despawnTimer = timer.performWithDelay(fireballLifetime * 1000, function() newProjectile:removeSelf() end, 1)
    self.readyToFire = false
    self.projectileReadyTimer = timer.performWithDelay(timeBetweenFireballs * 1000, function() self.readyToFire = true end)
    newProjectile.collision = fireballCollision
    newProjectile:addEventListener("collision")
end

function ClosestCoop(enemyX,enemyY)
    local lowestDistance = 100000
    local closestCoop = nil
    for i=1, CoopsAlive do
        local coop = Coops[i]
        local distance = CalculateDistance(enemyX, enemyY, coop.x, coop.y)
        if distance < lowestDistance or closestCoop == nil then
            lowestDistance = distance
            closestCoop = coop
        end
    end
    return closestCoop
end

return enemy