local game = {}
local settings = require("settings")

local notes = {}
local noteSpeed = settings.getNoteSpeed()
local noteSize = settings.getNoteSize()
local hitboxSize = 40 -- Increase hitbox size without changing note size
local hitLineY = 500
local songTime = 0
local activeHoldNote = nil
local score = 0
local misses = 0
local hits = 0
local totalNotes = 0
local accuracy = 100
local music
local background
local musicDelay = 1
local musicStartTime = nil
local chartEndTime = 0
local endGameCallback
local hitEffects = {}
local hitEffectDuration = 0.2
local noteImage -- Variable to hold the note image
local holdNoteImage -- Variable to hold the hold note image
local hitEffectImage -- Variable to hold the hit effect image
local missImage -- Variable to hold the miss image
local RatingEffectImageSize = settings.getRatingSize()  -- Size of the miss image
local missTextDuration = 1  -- Duration in seconds for the miss image to fade out
local missTextEffects = {}
local ratingTextDuration = 0.5 -- Duration for rating text to fade out
local ratingTextEffects = {}

local perfectImage
local goodImage
local okayImage
local badImage

local timingWindows = {
    perfect = 0.05,
    good = 0.1,
    okay = 0.2,
    bad = 0.3
}

local function displayScoreBreakdown()
    local breakdown = {
        score = score,
        hits = hits,
        misses = misses,
        accuracy = accuracy,
        totalNotes = totalNotes,
    }
    if endGameCallback then
        endGameCallback(breakdown)
    end
end

function game.start(chartFile, musicFile, callback, backgroundFile)
    songTime = 0
    score = 0
    combo = 0
    accuracy = 100
    hits = 0
    misses = 0
    totalNotes = 0
    activeHoldNote = nil
    musicStartTime = love.timer.getTime() + musicDelay
    music = love.audio.newSource(musicFile, "stream")
    music:setVolume(settings.getVolume())
    music:stop()
    loadChart(chartFile)
    endGameCallback = callback
    hitEffects = {}
    ratingTextEffects = {}
    if backgroundFile then
        background = love.graphics.newImage(backgroundFile)
    else
        background = nil
    end
    noteSpeed = settings.getNoteSpeed()
    noteSize = settings.getNoteSize()
    
    -- Load the selected skin images
    local selectedSkin = settings.getSelectedSkin() or "default"
    noteImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Note.png")
    holdNoteImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Hold.png")
    hitEffectImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Splash.png")
    missImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Miss.png") -- Load miss image

    -- Load rating images
    perfectImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Perfect.png")
    goodImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Good.png")
    okayImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Okay.png")
    badImage = love.graphics.newImage("skins/" .. selectedSkin .. "/Bad.png")
end

function loadChart(filename)
    notes = {}
    local chart = love.filesystem.read(filename)
    for line in chart:gmatch("[^\r\n]+") do
        local time, x, holdTime = line:match("([%d%.]+) ([%d%.]+) ([%d%.]+)")
        time = tonumber(time)
        x = tonumber(x)
        holdTime = tonumber(holdTime)
        table.insert(notes, {time = time, x = x, hold = holdTime > 0, holdTime = holdTime})
        chartEndTime = math.max(chartEndTime, time + holdTime)
    end
    totalNotes = #notes -- Update total notes count
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
            table.insert(missTextEffects, {time = missTextDuration})  -- Add miss effect
            table.remove(notes, i)
            misses = misses + 1
            combo = 0
            love.audio.play(miss)
            updateAccuracy()
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

    -- Update miss text effects
    for i = #missTextEffects, 1, -1 do
        local effect = missTextEffects[i]
        effect.time = effect.time - dt
        if effect.time <= 0 then
            table.remove(missTextEffects, i)
        end
    end

    -- Update rating text effects
    for i = #ratingTextEffects, 1, -1 do
        local effect = ratingTextEffects[i]
        effect.time = effect.time - dt
        if effect.time <= 0 then
            table.remove(ratingTextEffects, i)
        end
    end

    -- Check if all notes are gone and the song has ended
    if #notes == 0 and songTime > chartEndTime then
        music:stop()
        displayScoreBreakdown()
    end
end

function game.draw()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local backgroundWidth = background:getWidth()
    local backgroundHeight = background:getHeight()
    local scaleX = windowWidth / backgroundWidth
    local scaleY = windowHeight / backgroundHeight

    -- Draw the background image
    love.graphics.draw(background, 0, 0, 0, scaleX, scaleY)
    
    -- Draw the dim overlay
    local dim = settings.getBackgroundDim()
    love.graphics.setColor(0, 0, 0, dim)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    
    love.graphics.line(0, hitLineY, love.graphics.getWidth(), hitLineY)

    for _, note in ipairs(notes) do
        if note.y then -- Ensure note.y is not nil
            if note.hold then
                love.graphics.draw(holdNoteImage, note.x, note.y - noteSpeed * note.holdTime, 0, noteSize / holdNoteImage:getWidth(), (noteSize + noteSpeed * note.holdTime) / holdNoteImage:getHeight())
            else
                love.graphics.draw(noteImage, note.x, note.y, 0, noteSize / noteImage:getWidth(), noteSize / noteImage:getHeight())
            end
        end
    end

    -- Draw hit effects
    for _, effect in ipairs(hitEffects) do
        love.graphics.setColor(1, 1, 1, effect.time / hitEffectDuration) -- Fade out effect
        love.graphics.draw(hitEffectImage, effect.x, hitLineY - noteSize / 2, 0, noteSize / hitEffectImage:getWidth(), noteSize / hitEffectImage:getHeight())
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end

    -- Draw miss effects
    for _, effect in ipairs(missTextEffects) do
        love.graphics.setColor(1, 1, 1, effect.time / missTextDuration)  -- Fade out effect
        local x = love.graphics.getWidth() / 2 - RatingEffectImageSize / 2
        local y = love.graphics.getHeight() / 2 - RatingEffectImageSize / 2
        love.graphics.draw(missImage, x, y, 0, RatingEffectImageSize / missImage:getWidth(), RatingEffectImageSize / missImage:getHeight())
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end

    -- Draw rating text effects
    for _, effect in ipairs(ratingTextEffects) do
        love.graphics.setColor(1, 1, 1, effect.time / ratingTextDuration) -- Fade out effect
        local x = love.graphics.getWidth() / 2 - RatingEffectImageSize / 2
        local y = love.graphics.getHeight() / 2 - RatingEffectImageSize / 2
        love.graphics.draw(effect.image, x, y, 0, RatingEffectImageSize / effect.image:getWidth(), RatingEffectImageSize / effect.image:getHeight())
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end

    love.graphics.print("Press any key to hit notes!", 10, 30)
    love.graphics.print("Score: " .. score, 10, 60)
    love.graphics.print("Misses: " .. misses, 10, 90)
    love.graphics.print("Combo: " .. combo, 10, 120)
    love.graphics.print("Accuracy: " .. string.format("%.2f", accuracy) .. "%", 10, 150)

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
    local hitNotes = {}
    for i = #notes, 1, -1 do
        local note = notes[i]
        if note.hold then
            if note.y and note.y >= hitLineY - hitboxSize and note.y <= hitLineY + hitboxSize then
                activeHoldNote = note
                table.insert(hitNotes, i)
                table.insert(hitEffects, {x = note.x, time = hitEffectDuration})
                love.audio.play(hitsound)
                addRatingEffect(note.time - songTime) -- Add rating effect
            end
        elseif note.y and note.y >= hitLineY - hitboxSize and note.y <= hitLineY + hitboxSize then
            table.insert(hitEffects, {x = note.x, time = hitEffectDuration})
            table.insert(hitNotes, i)
            addRatingEffect(note.time - songTime) -- Add rating effect
        end
    end

    -- Process all hit notes at once
    if #hitNotes > 0 then
        for _, index in ipairs(hitNotes) do
            table.remove(notes, index)
        end
        score = score + 100 * #hitNotes
        combo = combo + #hitNotes
        hits = hits + #hitNotes
        love.audio.play(hitsound)
        updateAccuracy()
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
                    hits = hits + 1
                    love.audio.play(hitsound)
                    updateAccuracy()
                    break
                end
            end
        end
        activeHoldNote = nil
    end
end

function addRatingEffect(timingDifference)
    local ratingImage
    local ratingValue
    if math.abs(timingDifference) < timingWindows.perfect then
        ratingImage = perfectImage
        ratingValue = 1
    elseif math.abs(timingDifference) < timingWindows.good then
        ratingImage = goodImage
        ratingValue = 0.75
    elseif math.abs(timingDifference) < timingWindows.okay then
        ratingImage = okayImage
        ratingValue = 0.5
    else
        ratingImage = badImage
        ratingValue = 0.25
    end
    table.insert(ratingTextEffects, {image = ratingImage, time = ratingTextDuration})
    accuracy = (accuracy * (hits + misses - 1) + ratingValue * 100) / (hits + misses) -- Update accuracy
end

function updateAccuracy()
    if totalNotes > 0 then
        accuracy = (hits / (hits + misses)) * 100
    else
        accuracy = 100
    end
end

return game
