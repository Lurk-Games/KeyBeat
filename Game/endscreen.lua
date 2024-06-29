-- endscreen.lua

local endscreen = {}

local grade = "D"  -- Default grade
local songName = ""
local credits = ""
local finalScore = 0
local accuracy = 0

function endscreen.load(name, creds, score, totalNotes, hits, misses)
    songName = name
    credits = creds
    finalScore = score

    -- Calculate accuracy
    accuracy = (hits / totalNotes) * 100

    -- Calculate grade based on accuracy
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
    love.graphics.printf("Game Over", 0, love.graphics.getHeight() / 2 - 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Song: " .. songName, 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Credits: " .. credits, 0, love.graphics.getHeight() / 2 - 70, love.graphics.getWidth(), "center")
    love.graphics.printf("Score: " .. finalScore, 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
    love.graphics.printf("Accuracy: " .. string.format("%.2f", accuracy) .. "%", 0, love.graphics.getHeight() / 2 - 10, love.graphics.getWidth(), "center")
    love.graphics.printf("Grade: " .. grade, 0, love.graphics.getHeight() / 2 + 20, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Enter to return to the play menu", 0, love.graphics.getHeight() / 2 + 50, love.graphics.getWidth(), "center")
end

function endscreen.keypressed(key)
    if key == "return" then
        goToPlayMenu()
    end
end

return endscreen
