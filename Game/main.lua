-- Define some constants
local noteRadius = 20
local noteSpeed = 200
local chart = {}
local nextNoteIndex = 1
local notes = {}
local score = 0
local misses = 0

function love.load()
    -- Set up the window
    love.window.setTitle("KeyBeat")
    love.window.setMode(800, 600)

    music = love.audio.newSource("Songs/Galaxy Collapse/audio.mp3", "stream") -- the "stream" is good for longer music tracks

    -- Set up the font
    font = love.graphics.newFont(24)
    love.graphics.setFont(font)

    -- Load chart from file
    loadChart("Songs/Galaxy Collapse/chart.txt")
end

function loadChart(filename)
    for line in love.filesystem.lines(filename) do
        table.insert(chart, tonumber(line))
    end
end

function love.update(dt)
    -- Update notes position
    for i, note in ipairs(notes) do
        note.y = note.y + noteSpeed * dt
        if note.y > love.graphics.getHeight() then
            table.remove(notes, i)
            misses = misses + 1 -- Increment miss count when note falls off the screen
        end
    end

    -- Check if it's time to spawn the next note
    if nextNoteIndex <= #chart then
        if love.timer.getTime() >= chart[nextNoteIndex] then
            table.insert(notes, {x = math.random(noteRadius, love.graphics.getWidth() - noteRadius), y = -noteRadius})
            nextNoteIndex = nextNoteIndex + 1
        end
    end

    -- Check for note collision with mouse position
    for i, note in ipairs(notes) do
        local mouseX, mouseY = love.mouse.getPosition()
        if math.sqrt((mouseX - note.x)^2 + (mouseY - note.y)^2) < noteRadius then
            if love.keyboard.isDown("space") then
                table.remove(notes, i)
                score = score + 1 -- Increase score when note is hit
            end
        end
    end
end

function love.draw()
    -- Draw notes
    love.graphics.setColor(1, 0, 0)
    for _, note in ipairs(notes) do
        love.graphics.circle("fill", note.x, note.y, noteRadius)
    end

    -- Draw score
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)

    -- Draw misses
    love.graphics.print("Misses: " .. misses, 10, 40)

    -- Draw instructions
    love.graphics.print("Press space when the mouse is on the note", 10, 70)
end
