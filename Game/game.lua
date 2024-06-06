-- game.lua
local game = {}
local settings = require("settings")

local notes = {}
local noteSpeed = settings.getNoteSpeed()
local noteSize = 20
local hitLineY = 500
local songTime = 0
local activeHoldNote = nil
local score = 0
local misses = 0
local combo = 0
local music
local musicDelay = 1
local musicStartTime = nil
local chartEndTime = 0
local endGameCallback
local hitEffects = {}
local hitEffectDuration = 0.2

function game.start(chartFile, musicFile, callback)
    songTime = 0
    score = 0
    combo = 0
    misses = 0
    activeHoldNote = nil
    musicStartTime = love.timer.getTime() + musicDelay
    music = love.audio.newSource(musicFile, "stream")
    music:setVolume(settings.getVolume())
    music:stop()
    loadChart(chartFile)
    endGameCallback = callback
    hitEffects = {}
    noteSpeed = settings.getNoteSpeed()
end

function loadChart(filename)
    notes = {}
    local chart = love.filesystem.read(filename)
    for line in chart:gmatch("[^\r\n]+") do
        local time, x, holdTime = line:match("([%d%.]+) ([%d%.]+) ([%d%.]+)")
        time = tonumber(time)
        x = tonumber(x)
        holdTime = tonumber(holdTime)
        table.insert(notes, {time = time, x = x, hold = holdTime > 0, holdTime = holdTime, y = hitLineY})
        chartEndTime = math.max(chartEndTime, time + holdTime)
    end
end

function game.update(dt)
    local currentTime = love.timer.getTime()

    if currentTime >= musicStartTime and not music:isPlaying() then
        music:play()
    end

    if currentTime < musicStartTime then
        return
    end

    songTime = songTime + dt

    for i = #notes, 1, -1 do
        local note = notes[i]
        note.y = hitLineY - (note.time - songTime) * noteSpeed

        if note.y > hitLineY + noteSize + (note.hold and note.holdTime * noteSpeed or 0) then
            table.remove(notes, i)
            misses = misses + 1
            combo = 0
        end
    end

    -- Update hit effects
    for i = #hitEffects, 1, -1 do
        local effect = hitEffects[i]
        effect.time = effect.time - dt
        if effect.time <= 0 then
            table.remove(hitEffects, i)
        end
    end

    -- Check if all notes are gone and the song has ended
    if #notes == 0 and songTime > chartEndTime then
        music:stop()
        if endGameCallback then
            endGameCallback()
        end
    end
end

function game.draw()
    love.graphics.line(0, hitLineY, love.graphics.getWidth(), hitLineY)

    for _, note in ipairs(notes) do
        if note.y then -- Ensure note.y is not nil
            if note.hold then
                love.graphics.rectangle("fill", note.x, note.y - noteSpeed * note.holdTime, noteSize, noteSize + noteSpeed * note.holdTime)
            else
                love.graphics.rectangle("fill", note.x, note.y, noteSize, noteSize)
            end
        end
    end

    -- Draw hit effects
    for _, effect in ipairs(hitEffects) do
        love.graphics.setColor(1, 1, 0, effect.time / hitEffectDuration) -- Fade out effect
        love.graphics.circle("fill", effect.x + noteSize / 2, hitLineY, 30)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    love.graphics.print("Press any key to hit notes, hold any key for hold notes!", 10, 10)
    love.graphics.print("Score: " .. score, 10, 40)
    love.graphics.print("Misses: " .. misses, 10, 70)
    love.graphics.print("Combo: " .. combo, 500, 70)

    -- Draw time bar
    drawTimeBar()
end

function drawTimeBar()
    local screenWidth = love.graphics.getWidth()
    local barHeight = 20
    local progress = songTime / chartEndTime
    love.graphics.setColor(0, 0.8, 0)
    love.graphics.rectangle("fill", 0, 0, screenWidth * progress, barHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 0, 0, screenWidth, barHeight)
    love.graphics.print("Time: " .. string.format("%.2f", songTime) .. " / " .. string.format("%.2f", chartEndTime), 10, barHeight / 2 - 6)
end

function game.keypressed(key)
    for i = #notes, 1, -1 do
        local note = notes[i]
        if note.hold then
            if note.y and note.y >= hitLineY - noteSize and note.y <= hitLineY + noteSize then
                activeHoldNote = note
            end
        elseif note.y and note.y >= hitLineY - noteSize and note.y <= hitLineY + noteSize then
            table.insert(hitEffects, {x = note.x, time = hitEffectDuration})
            table.remove(notes, i)
            score = score + 100
            combo = combo + 1
            love.audio.play(hitsound)
            break
        end
    end
end

function game.keyreleased(key)
    if activeHoldNote then
        if activeHoldNote.y and activeHoldNote.y - noteSpeed * activeHoldNote.holdTime <= hitLineY then
            for i = #notes, 1, -1 do
                if notes[i] == activeHoldNote then
                    table.insert(hitEffects, {x = activeHoldNote.x, time = hitEffectDuration})
                    table.remove(notes, i)
                    score = score + 100
                    combo = combo + 1
                    love.audio.play(hitsound)
                    break
                end
            end
        end
        activeHoldNote = nil
    end
end

return game
