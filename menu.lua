Menu = {}

function Menu:enter()
    self.selection = 1
    self.options = {'Play', 'High Scores', 'Quit'}
end

function Menu:keypressed(key)
    if key == 'up' or key == 'w' then
        self.selection = math.max(1, self.selection - 1)

    elseif key == 'down' or key == 's' then
        self.selection = math.min(#self.options, self.selection + 1)

    elseif key == 'return' then
        if self.selection == 1 then
            Gamestate.switch(Play)

        elseif self.selection == 2 then
            Gamestate.switch(HighScore)

        elseif self.selection == 3 then
            love.event.quit()
        end
    end
end

function Menu:draw()
    love.graphics.clear(0.05, 0.05, 0.1)

    love.graphics.printf("MAIN MENU", 0, 40, 800, "center")

    for i, option in ipairs(self.options) do
        local y = 120 + i * 30

        if i == self.selection then
            love.graphics.setColor(0.8, 0.9, 0.4)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.printf(option, 0, y, 800, "center")
    end

    love.graphics.setColor(1,1,1)
end