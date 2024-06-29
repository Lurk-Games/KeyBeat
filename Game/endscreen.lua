-- endscreen.lua

local endscreen = {}

local grade = "D"  -- Default grade

function endscreen.load(finalScore, totalNotes, hits, misses)
    -- Calculate grade based on accuracy
    local accuracy = (hits / totalNotes) * 100
    if accuracy == 100 then
        grade = "SS"
    elseif accuracy >= 95 then
        grade = "S"
    elseif accuracy >= 90 then
        grade = "A"
    elseif accuracy >= 80 then
        grade = "B"
    elseif accuracy >= 70 then
        grade = "C"
    else
        grade = "D"
    end
end

function endscreen.update(dt)
end

function endscreen.draw()
    love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Grade: " .. grade, 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Enter to return to the play menu", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
end

function endscreen.keypressed(key)
    if key == "return" then
        goToPlayMenu()
    end
end

return endscreen
