HighScore = {}

function HighScore:enter()
    self.scores = {1000, 800, 500, 200}
end

function HighScore:keypressed(key)
    if key == "escape" then
        Gamestate.switch(Menu)
    end
end

function HighScore:draw()
    love.graphics.printf("HIGH SCORES", 0, 40, 800, "center")

    for i, score in ipairs(self.scores) do
        love.graphics.printf(i .. ". " .. score, 0, 100 + i * 25, 800, "center")
    end
end