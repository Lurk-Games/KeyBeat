-- credits.lua
local credits = {}

local creditsText = {
    "Game Development Team:",
    "Virus - Lead Programmer and artist",
    "Jake Whittaker - Programmer and Charter",
    "KenneyNL - Cursor Icon",
    "",
    "Special Thanks:",
    "Our Families and Friends",
    "The LOVE2D Community",
}

local scrollSpeed = 50
local yOffset = 600 -- Starting Y offset

function credits.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1) -- Dark background
end

function credits.update(dt)
    yOffset = yOffset - scrollSpeed * dt
    if yOffset < -(#creditsText * 30 + 100) then
        yOffset = 600
    end
end

function credits.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Credits", 0, 50, love.graphics.getWidth(), "center")

    local y = yOffset
    for i, line in ipairs(creditsText) do
        love.graphics.printf(line, 0, y, love.graphics.getWidth(), "center")
        y = y + 30
    end
end

function credits.keypressed(key)
    if key == "escape" then
        backToMenu()
    end
end

return credits
