love.graphics.setDefaultFilter("nearest", "nearest")

Player = require("player")
local Coin = require("coin")
local GUI = require("gui")
local Spike = require("spike")
local Stone = require("stone")
local Camera = require("camera")
local Enemy = require("enemy")
local Boss = require("boss")
local Map = require("map")

local gameState = "menu"
local lastResult = nil

-- ======================
-- GAME RESET / END
-- ======================
function gameOver(result)
    gameState = "menu"
    lastResult = result

    Enemy.removeAll()
    Boss.removeAll()

    -- Oyuncuyu ve dünyayı sıfırla
    Player = require("player")
    Player:load()

    Map:load()

    Camera.x = 0
    Camera.y = 0

    print(result == "win" and "YOU WIN - Back to Menu" or "GAME OVER - Back to Menu")
end

_G.gameOver = gameOver -- Global yaparak diğer dosyalardan erişimi garantiliyoruz

-- ======================
-- LOAD
-- ======================
function love.load()
    love.physics.setMeter(32)
    World = love.physics.newWorld(0, 9.81 * 64, true)

    Enemy.loadAssets()
    Boss.loadAssets()
    Map:load()

    background = love.graphics.newImage("assets/background.png")

    GUI:load()
    Player:load()

    mainFont = love.graphics.newFont(20)
    titleFont = love.graphics.newFont(40)

    World:setCallbacks(beginContact, endContact)
end

-- ======================
-- UPDATE
-- ======================
function love.update(dt)
    if gameState == "play" then
        World:update(dt)
        Player:update(dt)
        Coin.updateAll(dt)
        Spike.updateAll(dt)
        Stone.updateAll(dt)
        Enemy.updateAll(dt)
        Boss.updateAll(dt)
        Map:update(dt)

        Camera:setPosition(Player.x, 0)
        GUI:update(dt)
    end
end

-- ======================
-- DRAW
-- ======================
function love.draw()
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "play" or gameState == "pause" then
        love.graphics.draw(background)
        Map.level:draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)

        Camera:apply()
            Player:draw()
            Enemy.drawAll()
            Boss.drawAll()
            Coin.drawAll()
            Spike.drawAll()
            Stone.drawAll()
        Camera:clear()

        GUI:draw()

        if gameState == "pause" then
            drawPauseScreen()
        end
    elseif gameState == "highscore" then
        drawHighscoreScreen()
    end
end

function drawMenu()
    love.graphics.setFont(titleFont)
    love.graphics.printf("MACERA OYUNU", 0, 120, love.graphics.getWidth(), "center")

    love.graphics.setFont(mainFont)
    love.graphics.printf("ENTER - Başla", 0, 220, love.graphics.getWidth(), "center")
    love.graphics.printf("H - Highscore", 0, 260, love.graphics.getWidth(), "center")
    love.graphics.printf("ESC - Çıkış", 0, 300, love.graphics.getWidth(), "center")

    if lastResult == "win" then
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf("TEBRİKLER! BOSS YENİLDİ!", 0, 380, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    elseif lastResult == "lose" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("ELENDİNİZ. TEKRAR DENEYİN.", 0, 380, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1)
    end
end

-- (Pause ve Highscore ekranları fonksiyonları senin orijinal kodundaki gibi kalabilir)
function drawPauseScreen()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.printf("PAUSED", 0, 200, love.graphics.getWidth(), "center")
end

function drawHighscoreScreen()
    love.graphics.setFont(titleFont)
    love.graphics.printf("HIGHSCORE", 0, 100, love.graphics.getWidth(), "center")
    love.graphics.setFont(mainFont)
    love.graphics.printf("ESC - Geri", 0, 450, love.graphics.getWidth(), "center")
end

-- ======================
-- INPUT
-- ======================
function love.keypressed(key)
    if gameState == "menu" then
        if key == "return" then gameState = "play"
        elseif key == "h" then gameState = "highscore"
        elseif key == "escape" then love.event.quit() end
    elseif gameState == "play" then
        Player:jump(key)
        if key == "space" then Player:attack()
        elseif key == "p" then gameState = "pause" end
    elseif gameState == "pause" then
        if key == "p" then gameState = "play"
        elseif key == "m" then gameState = "menu" end
    elseif gameState == "highscore" then
        if key == "escape" then gameState = "menu" end
    end
end

-- ======================
-- PHYSICS CALLBACKS
-- ======================
function beginContact(a, b, collision)
    if gameState ~= "play" then return end
    if Coin.beginContact(a, b, collision) then return end
    if Spike.beginContact(a, b, collision) then return end
    Enemy.beginContact(a, b, collision)
    Player:beginContact(a, b, collision)
end

function endContact(a, b, collision)
    if gameState == "play" then
        Player:endContact(a, b, collision)
    end
end