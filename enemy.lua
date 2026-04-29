local Enemy = {}
Enemy.__index = Enemy

-- ❌ HATALIYDI
-- local Player = require("player")

-- ✅ GLOBAL Player kullanılacak (main.lua'da global olmalı)

local ActiveEnemies = {}

function Enemy.removeAll()
   for i,v in ipairs(ActiveEnemies) do
      v.physics.body:destroy()
   end
   ActiveEnemies = {}
end

function Enemy.loadAssets()
   local states = {
      {name = "idle", frames = 4},
      {name = "walk", frames = 4},
      {name = "attack", frames = 8}, 
      {name = "hit", frames = 4},
      {name = "death", frames = 4}
   }
   
   for _, state in ipairs(states) do
      Enemy[state.name .. "Anim"] = {}
      for i=0, state.frames - 1 do
         local fileName = string.format("tile%03d.png", i)
         local path = "assets/enemy/"..state.name.."/"..fileName
         if love.filesystem.getInfo(path) then
            Enemy[state.name .. "Anim"][i+1] = love.graphics.newImage(path)
         end
      end
   end

   Enemy.width = Enemy.walkAnim[1]:getWidth()
   Enemy.height = Enemy.walkAnim[1]:getHeight()
end

function Enemy.new(x, y)
   local instance = setmetatable({}, Enemy)
   instance.x, instance.y = x, y
   instance.offsetY = -8
   instance.speed = 100
   instance.xVel = instance.speed
   instance.health = 3
   instance.damage = 1
   instance.state = "walk"
   instance.toBeRemoved = false
   
   instance.animation = {timer = 0, rate = 0.15}
   local animStates = {"idle", "walk", "attack", "hit", "death"}
   for _, s in ipairs(animStates) do
      instance.animation[s] = {
         total = #Enemy[s .. "Anim"], 
         current = 1, 
         img = Enemy[s .. "Anim"]
      }
   end
   instance.animation.draw = instance.animation.walk.img[1]

   instance.physics = {}
   instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "dynamic")
   instance.physics.body:setFixedRotation(true)
   instance.physics.shape = love.physics.newRectangleShape(Enemy.width * 0.4, Enemy.height * 0.75)
   instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
   instance.physics.body:setGravityScale(1)

   table.insert(ActiveEnemies, instance)
end

function Enemy:changeState(newState)
   if self.state == "death" then return end
   if self.state == newState then return end
   self.state = newState
   self.animation[newState].current = 1
end

function Enemy:takeDamage(amount)
   if self.state == "death" then return end
   
   self.health = self.health - amount

   if self.health <= 0 then
      self:changeState("death")
   else
      self:changeState("hit")

      -- 🔥 FIX (getX yerine getPosition)
      local playerX, _ = Player.physics.body:getPosition()
      local dir = (self.x > playerX) and 200 or -200
      self.physics.body:setLinearVelocity(dir, -150)
   end
end

function Enemy:update(dt)
   local vx, vy = self.physics.body:getLinearVelocity()

   if self.state == "death" then
      self.physics.body:setLinearVelocity(0, vy)
   elseif self.state == "hit" then
      self.physics.body:setLinearVelocity(vx * 0.9, vy)
   elseif self.state == "attack" then
      self.physics.body:setLinearVelocity(0, vy)
   else
      self:syncPhysics(vy)
   end

   self:animate(dt)
end

function Enemy:syncPhysics(vy)
   self.x, self.y = self.physics.body:getPosition()

   -- 🔥 FIX
   local playerX, _ = Player.physics.body:getPosition()

   local distance = math.abs(playerX - self.x)
   local sightRange = 400 
   local attackRange = 50 

   if distance < sightRange then
      if playerX < self.x then 
         self.xVel = -self.speed 
      else 
         self.xVel = self.speed 
      end

      if distance < attackRange then
         self:changeState("attack")
      else
         self:changeState("walk")
      end
   end

   self.physics.body:setLinearVelocity(self.xVel, vy)
end

function Enemy:animate(dt)
   self.animation.timer = self.animation.timer + dt
   if self.animation.timer > self.animation.rate then
      self.animation.timer = 0
      self:setNewFrame()
   end
end

function Enemy:setNewFrame()
   local anim = self.animation[self.state]

   if anim and anim.img[anim.current] then
      if anim.current < anim.total then
         anim.current = anim.current + 1
      else
         if self.state == "hit" or self.state == "attack" then
            self:changeState("walk")
         elseif self.state == "death" then
            self.toBeRemoved = true
         else
            anim.current = 1
         end
      end

      self.animation.draw = anim.img[anim.current]
   end
end

function Enemy:draw()
   if not self.animation.draw then return end
   local scaleX = (self.xVel < 0) and -1 or 1

   love.graphics.draw(
      self.animation.draw, 
      self.x, self.y + self.offsetY, 
      0, scaleX, 1, 
      Enemy.width / 2, Enemy.height / 2
   )
end

function Enemy.updateAll(dt)
   for i = #ActiveEnemies, 1, -1 do
      local instance = ActiveEnemies[i]
      instance:update(dt)

      -- 🔥 FIX
      if Player.isAttacking then
         if not Player.hitEnemies[instance] then

            local px = Player.attackX or Player.x
            local py = Player.attackY or Player.y

            local dx = math.abs(px - instance.x)
            local dy = math.abs(py - instance.y)

            if dx < 100 and dy < 80 then
               instance:takeDamage(1)
               Player.hitEnemies[instance] = true
            end
         end
      end

      if instance.toBeRemoved then
         instance.physics.body:destroy()
         table.remove(ActiveEnemies, i)
      end
   end
end

function Enemy.drawAll()
   for _, instance in ipairs(ActiveEnemies) do
      instance:draw()
   end
end

function Enemy.beginContact(a, b, collision)
   for _, instance in ipairs(ActiveEnemies) do
      if a == instance.physics.fixture or b == instance.physics.fixture then
         if a == Player.physics.fixture or b == Player.physics.fixture then
            
            instance:changeState("attack")

            -- 🔥 FIX (if kaldırıldı)
            Player:takeDamage(instance.damage)
         end
      end
   end
end

return Enemy