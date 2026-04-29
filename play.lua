Play = {}

function Play:enter()
    -- oyun başlatılır
end

function Play:update(dt)
    -- normal game update
end

function Play:draw()
    love.graphics.printf("GAME RUNNING", 0, 40, 800, "center")
end

function Play:keypressed(key)
    if key == "escape" then
        Gamestate.push(Pause) -- pause aç
    end
end