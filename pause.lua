Pause = {}

function Pause:enter()
    self.selection = 1
    self.options = {'Resume', 'Main Menu'}
end

function Pause:keypressed(key)
    if key == 'up' or key == 'w' then
        self.selection = math.max(1, self.selection - 1)

    elseif key == 'down' or key == 's' then
        self.selection = math.min(#self.options, self.selection + 1)

    elseif key == 'return' then
        if self.selection == 1 then
            Gamestate.pop() -- oyuna geri dön

        elseif self.selection == 2 then
            Gamestate.switch(Menu)
        end
    end
end

function Pause:draw()
    love.graphics.printf("PAUSED", 0, 40, 800, "center")

    for i, option in ipairs(self.options) do
        local y = 120 + i * 30

        if i == self.selection then
            love.graphics.setColor(1, 0.5, 0.5)
        else
            love.graphics.setColor(1,1,1)
        end

        love.graphics.printf(option, 0, y, 800, "center")
    end

    love.graphics.setColor(1,1,1)
end