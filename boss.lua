local Boss = {}
Boss.__index = Boss

local ActiveBosses = {}

-- ======================
-- REMOVE ALL
-- ======================
function Boss.removeAll()
   for i, v in ipairs(ActiveBosses) do
      if v.physics and v.physics.body and not v.physics.body:isDestroyed() then
         v.physics.body:destroy()
      end
   end
   ActiveBosses = {}
end

-- ======================
-- LOAD ASSETS
-- ======================
function Boss.loadAssets()
   local states = {
      {name = "fly", frames = 8},
      {name = "attack", frames = 8},
      {name = "hit", frames = 4}
   }

   for _, state in ipairs(states) do
      Boss[state.name .. "Anim"] = {}

      for i = 0, state.frames - 1 do
         local fileName = string.format("tile%03d.png", i)
         local path = "assets/boss/" .. state.name .. "/" .. fileName

         if love.filesystem.getInfo(path) then
            table.insert(Boss[state.name .. "Anim"], love.graphics.newImage(path))
         end
      end
   end

   if #Boss.flyAnim > 0 then
      Boss.width = Boss.flyAnim[1]:getWidth()
      Boss.height = Boss.flyAnim[1]:getHeight()
   else
      Boss.width = 64
      Boss.height = 64
   end
end

-- ======================
-- CREATE
-- ======================
function Boss.new(x, y)
   local self = setmetatable({}, Boss)

   self.x = x
   self.y = y
   self.startY = y

   self.maxHealth = 3
   self.health = self.maxHealth
   self.state = "fly"

   self.flySpeed = 2
   self.attackTimer = 0
   self.attackRate = 1.5
   self.sightRange = 500

   self.bullets = {}
   self.animation = {timer = 0, rate = 0.12}

   local states = {"fly", "attack", "hit"}
   for _, s in ipairs(states) do
      local animData = Boss[s .. "Anim"]
      self.animation[s] = {
         total = #animData,
         current = 1,
         img = animData
      }
   end

   if self.animation.fly.total > 0 then
      self.animation.draw = self.animation.fly.img[1]
   end

   self.physics = {}
   self.physics.body = love.physics.newBody(World, x, y, "dynamic")
   self.physics.body:setGravityScale(0)
   self.physics.shape = love.physics.newRectangleShape(50, 50)
   self.physics.fixture = love.physics.newFixture(self.physics.body, self.physics.shape)

   table.insert(ActiveBosses, self)
   return self
end

-- ======================
-- UPDATE
-- ======================
function Boss:update(dt)
   if self.health <= 0 then return end
   if not self.physics or not self.physics.body or self.physics.body:isDestroyed() then return end

   local offset = math.sin(love.timer.getTime() * self.flySpeed) * 40
   self.physics.body:setY(self.startY + offset)

   self.x = self.physics.body:getX()
   self.y = self.physics.body:getY()

   if Player and Player.physics then
      local px, py = Player.physics.body:getPosition()
      local dx = px - self.x
      local dy = py - self.y
      local distance = math.sqrt(dx*dx + dy*dy)

      if distance < self.sightRange then
         self.attackTimer = self.attackTimer + dt
         if self.attackTimer >= self.attackRate then
            self.attackTimer = 0
            self:shoot()
         end
      end
   end

   self:updateBullets(dt)
   self:animate(dt)
end

-- ======================
-- TAKE DAMAGE & GAME OVER CHECK
-- ======================
function Boss:takeDamage(amount)
   if self.health <= 0 then return end

   self.health = self.health - amount
   self.state = "hit"
   self.animation.hit.current = 1

   if self.health <= 0 then
      -- Fiziği temizle
      if self.physics and self.physics.body then
         self.physics.body:destroy()
         self.physics.body = nil
      end
      
      -- Ana menüye dönmek için gameOver fonksiyonunu çağır
      if _G.gameOver then
          _G.gameOver("win")
      end
   end
end

function Boss:shoot()
   if not Player or not Player.physics then return end
   local px, py = Player.physics.body:getPosition()
   local dx = px - self.x
   local dy = py - self.y
   local len = math.sqrt(dx*dx + dy*dy)
   if len == 0 then return end

   table.insert(self.bullets, {
      x = self.x,
      y = self.y,
      dx = dx / len,
      dy = dy / len,
      speed = 300
   })

   self.state = "attack"
   self.animation.attack.current = 1
end

function Boss:updateBullets(dt)
   for i = #self.bullets, 1, -1 do
      local b = self.bullets[i]
      b.x = b.x + b.dx * b.speed * dt
      b.y = b.y + b.dy * b.speed * dt

      if Player and Player.physics then
         local px, py = Player.physics.body:getPosition()
         local dist = math.sqrt((px - b.x)^2 + (py - b.y)^2)
         if dist < 40 then
            Player:takeDamage(1)
            table.remove(self.bullets, i)
         end
      end
   end
end

function Boss.checkPlayerAttack()
   if not Player.isAttacking then return end
   for _, b in ipairs(ActiveBosses) do
      if not Player.hitEnemies[b] then
         local px = Player.attackX or Player.x
         local py = Player.attackY or Player.y
         local dx = math.abs(px - b.x)
         local dy = math.abs(py - b.y)

         if dx < 100 and dy < 80 then
            b:takeDamage(1)
            Player.hitEnemies[b] = true
         end
      end
   end
end

function Boss:animate(dt)
   self.animation.timer = self.animation.timer + dt
   if self.animation.timer > self.animation.rate then
      self.animation.timer = 0
      local anim = self.animation[self.state]
      if anim and anim.total > 0 then
         anim.current = anim.current + 1
         if anim.current > anim.total then
            anim.current = 1
            if self.state == "attack" or self.state == "hit" then
               self.state = "fly"
            end
         end
         self.animation.draw = anim.img[anim.current]
      end
   end
end

function Boss:draw()
   if self.animation.draw then
      love.graphics.draw(self.animation.draw, self.x, self.y, 0, 1, 1, Boss.width / 2, Boss.height / 2)
   end
   love.graphics.setColor(1, 0, 0)
   for _, b in ipairs(self.bullets) do
      love.graphics.circle("fill", b.x, b.y, 4)
   end
   love.graphics.setColor(1, 1, 1)
end

function Boss.updateAll(dt)
   for i = #ActiveBosses, 1, -1 do
      ActiveBosses[i]:update(dt)
   end
   Boss.checkPlayerAttack()
end

function Boss.drawAll()
   for _, b in ipairs(ActiveBosses) do
      b:draw()
   end
end

return Boss