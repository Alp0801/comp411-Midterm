

local Player = {}

function Player:load()
   
self.attackTimer = 0
self.attackDuration = 0.3

self.attackX = 0
self.attackY = 0

self.hitEnemies = {}
   self.deathTimer = 0
   self.deathDuration = 1.5
   self.attackTimer = 0
   self.attackDuration = 0.5
   self.x = 100
   self.y = 0
   self.startX = self.x
   self.startY = self.y
   self.width = 20
   self.height = 60
   self.xVel = 0
   self.yVel = 0
   self.maxSpeed = 200
   self.acceleration = 4000
   self.friction = 3500
   self.gravity = 1500
   self.jumpAmount = -500
   self.coins = 0
   self.health = {current = 3, max = 3}

   self.color = {
      red = 1,
      green = 1,
      blue = 1,
      speed = 3,
   }

   self.isAttacking = false
   self.isHit = false
   self.isDead = false


   self.graceTime = 0
   self.graceDuration = 0.1

   self.alive = true
   self.grounded = false
   self.hasDoubleJump = true

   self.direction = "right"
   self.state = "idle"

   self:loadAssets()

   self.physics = {}
   self.physics.body = love.physics.newBody(World, self.x, self.y, "dynamic")
   self.physics.body:setFixedRotation(true)
   self.physics.shape = love.physics.newRectangleShape(self.width, self.height)
   self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)
   self.physics.body:setGravityScale(1)
end

function Player:loadAssets()
   self.animation = {timer = 0, rate = 0.1}

   self.animation.run = {total = 8, current = 1, img = {}}
   for i=1, self.animation.run.total do
    self.animation.run.img[i] = love.graphics.newImage("assets/player/run/tile00"..(i-1)..".png")
   end

   self.animation.idle = {total = 8, current = 1, img = {}}
   for i=1, self.animation.idle.total do
      

-- Yeni düzelmiş satır:
self.animation.idle.img[i] = love.graphics.newImage("assets/player/idle/tile00"..(i-1)..".png")
   end

   self.animation.air = {total = 2, current = 1, img = {}}
   for i=1, self.animation.air.total do
      self.animation.air.img[i] = love.graphics.newImage("assets/player/air/tile00"..(i-1)..".png")
   end


   -- ATTACK
self.animation.attack = {total = 8, current = 1, img = {}}
for i=1, self.animation.attack.total do
    self.animation.attack.img[i] = love.graphics.newImage("assets/player/attack/tile00"..(i-1)..".png")
end

-- HIT
self.animation.hit = {total = 3, current = 1, img = {}}
for i=1, self.animation.hit.total do
    self.animation.hit.img[i] = love.graphics.newImage("assets/player/hit/tile00"..(i-1)..".png")
end

-- DEAD
self.animation.dead = {total = 7, current = 1, img = {}}
for i=1, self.animation.dead.total do
    self.animation.dead.img[i] = love.graphics.newImage("assets/player/dead/tile00"..(i-1)..".png")
end

   self.animation.draw = self.animation.idle.img[1]
   self.animation.width = self.animation.draw:getWidth()
   self.animation.height = self.animation.draw:getHeight()
end

function Player:takeDamage(amount)
   if self.isDead then return end

   self.isHit = true
   self.animation.hit.current = 1

   self:tintRed()

   if self.health.current - amount > 0 then
      self.health.current = self.health.current - amount
   else
      self.health.current = 0
      self:die()
   end

   print("Player health: "..self.health.current)
end

function Player:die()
   self.isDead = true
   self.animation.dead.current = 1
   self.alive = false
end

function Player:respawn()
   if not self.alive then
      self:resetPosition()
      self.health.current = self.health.max
      self.alive = true
   end
end

function Player:resetPosition()
   self.physics.body:setPosition(self.startX, self.startY)
end

function Player:tintRed()
   self.color.green = 0
   self.color.blue = 0
end

function Player:incrementCoins()
   self.coins = self.coins + 1
end

function Player:update(dt)

   -- 💀 DEAD
   if self.isDead then
      self:setState()      -- 🔥 BURAYA EKLE
      self:animate(dt)

      self.deathTimer = self.deathTimer + dt

      if self.deathTimer > self.deathDuration then
         self:respawn()
         self.isDead = false
         self.deathTimer = 0
      end
      

      return
   end



   -- normal
   self:unTint(dt)
   self:setState()
   self:setDirection()
   self:animate(dt)
   self:decreaseGraceTime(dt)
   self:syncPhysics()
   self:move(dt)
   self:applyGravity(dt)
end

function Player:unTint(dt)
   self.color.red = math.min(self.color.red + self.color.speed * dt, 1)
   self.color.green = math.min(self.color.green + self.color.speed * dt, 1)
   self.color.blue = math.min(self.color.blue + self.color.speed * dt, 1)
end

function Player:decreaseGraceTime(dt)
   if self.graceTime > 0 then
      self.graceTime = self.graceTime - dt
   end
end

function Player:setState()
   if self.isDead then
      self.state = "dead"
      return
   end

   if self.isAttacking then
      self.state = "attack"
      return
   end

   if self.isHit then
      self.state = "hit"
      return
   end

   if not self.grounded then
      self.state = "air"
   elseif self.xVel == 0 then
      self.state = "idle"
   else
      self.state = "run"
   end
end
function Player:attack()
   if self.isDead then return end
   if self.isAttacking then return end

   self.isAttacking = true
   self.animation.attack.current = 1
   self.hitEnemies = {}

   local px, py = self.physics.body:getPosition()

   local range = 60
   if self.direction == "right" then
      self.attackX = px + range
   else
      self.attackX = px - range
   end

   self.attackY = py
end 
function Player:setDirection()
   if self.xVel < 0 then
      self.direction = "left"
   elseif self.xVel > 0 then
      self.direction = "right"
   end
end

function Player:animate(dt)
   self.animation.timer = self.animation.timer + dt
   if self.animation.timer > self.animation.rate then
      self.animation.timer = 0
      self:setNewFrame()
   end
end

function Player:setNewFrame()
   local anim = self.animation[self.state]

   if anim.current < anim.total then
      anim.current = anim.current + 1
   else
      if self.state == "dead" then
         anim.current = anim.total
         self.animation.draw = anim.img[anim.current]
         return
      end

      -- 🔥 ATTACK BURADA BİTER (EN KRİTİK)
      if self.state == "attack" then
         self.isAttacking = false
      end

      if self.state == "hit" then
         self.isHit = false
      end

      anim.current = 1
   end

   self.animation.draw = anim.img[anim.current]
end

function Player:applyGravity(dt)
   if not self.grounded then
      self.yVel = self.yVel + self.gravity * dt
   end
end

function Player:move(dt)
   if love.keyboard.isDown("d", "right") then
      self.xVel = math.min(self.xVel + self.acceleration * dt, self.maxSpeed)
   elseif love.keyboard.isDown("a", "left") then
      self.xVel = math.max(self.xVel - self.acceleration * dt, -self.maxSpeed)
   else
      self:applyFriction(dt)
   end
end

function Player:applyFriction(dt)
   if self.xVel > 0 then
      self.xVel = math.max(self.xVel - self.friction * dt, 0)
   elseif self.xVel < 0 then
      self.xVel = math.min(self.xVel + self.friction * dt, 0)
   end
end

function Player:syncPhysics()
   self.x, self.y = self.physics.body:getPosition()
   self.physics.body:setLinearVelocity(self.xVel, self.yVel)
end

function Player:beginContact(a, b, collision)
   if self.grounded == true then return end
   local nx, ny = collision:getNormal()
   if a == self.physics.fixture then
      if ny > 0 then
         self:land(collision)
      elseif ny < 0 then
         self.yVel = 0
      end
   elseif b == self.physics.fixture then
      if ny < 0 then
         self:land(collision)
      elseif ny > 0 then
         self.yVel = 0
      end
   end
end

function Player:land(collision)
   self.currentGroundCollision = collision
   self.yVel = 0
   self.grounded = true
   self.hasDoubleJump = true
   self.graceTime = self.graceDuration
end

function Player:jump(key)
   if (key == "w" or key == "up") then
      if self.grounded or self.graceTime > 0 then
         self.yVel = self.jumpAmount
         self.graceTime = 0
      elseif self.hasDoubleJump then
         self.hasDoubleJump = false
         self.yVel = self.jumpAmount * 0.8
      end
   end
end

function Player:endContact(a, b, collision)
   if a == self.physics.fixture or b == self.physics.fixture then
      if self.currentGroundCollision == collision then
         self.grounded = false
      end
   end
end

function Player:draw()
   local scaleX = 1
   if self.direction == "left" then
      scaleX = -1
   end
   love.graphics.setColor(self.color.red, self.color.green, self.color.blue)
   love.graphics.draw(self.animation.draw, self.x, self.y, 0, scaleX, 1, self.animation.width / 2, self.animation.height / 2)
   love.graphics.setColor(1,1,1,1)

end

return Player
