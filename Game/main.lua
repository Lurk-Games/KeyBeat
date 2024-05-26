-- Define some constants
local noteRadius = 20
local noteSpeed = 200
local chart = {}
local nextNoteIndex = 1
local notes = {}
local score = 0
local misses = 0
local currentScreen = "song_selection" -- Initially set to song selection
local selectedSongIndex = 1 -- Index of the currently selected song
local audioDelay = false -- Flag to control audio delay
local audioStartTime = 0 -- Variable to store the audio start time

-- Define your song list with associated chart and audio file paths
local songs = {
    {
        name = "Galaxy Collapse",
        chart = "Songs/Galaxy Collapse/chart.txt",
        audio = "Songs/Galaxy Collapse/audio.ogg"
    },
    {
        name = "Cute Depressed",
        chart = "Songs/Cute Depressed/chart.txt",
        audio = "Songs/Cute Depressed/audio.ogg"
    },
    {
        name = "Song 3",
        chart = "Songs/Song3/chart.txt",
        audio = "Songs/Song3/audio.ogg"
    }
}

function love.load()
    -- Set up the window
    love.window.setTitle("KeyBeat")
    love.window.setMode(800, 600)

    -- Set up the font
    font = love.graphics.newFont(24)
    love.graphics.setFont(font)
end

function love.update(dt)
    if currentScreen == "game_menu" then -- Execute game logic only when on game menu

        -- Check for audio delay
        if audioDelay then
            local currentTime = love.timer.getTime()
            if currentTime - audioStartTime >= 1 then -- Delay audio for 1 second
                music:play() -- Start playing the music after the delay
                audioDelay = false -- Reset the flag
            end
        end
        
        -- Update notes position
        for i, note in ipairs(notes) do
            note.y = note.y + noteSpeed * dt
            if note.y > love.graphics.getHeight() then
                table.remove(notes, i)
                misses = misses + 1 -- Increment miss count when note falls off the screen
            end
        end

        -- Check if it's time to spawn the next note
        local currentTime = love.timer.getTime() - songStartTime
        if nextNoteIndex <= #chart then
            if currentTime >= chart[nextNoteIndex] then
                table.insert(notes, {x = math.random(noteRadius, love.graphics.getWidth() - noteRadius), y = -noteRadius})
                nextNoteIndex = nextNoteIndex + 1
            end
        end

        -- Check if there are any notes left
        if #notes == 0 and nextNoteIndex > #chart then
            -- Stop the music after a delay of 1 second
            audioDelay = true
            audioStartTime = love.timer.getTime()
            currentScreen = "waiting_for_music_stop"
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
    elseif currentScreen == "waiting_for_music_stop" then
        -- Check for delay before returning to song selection
        local currentTime = love.timer.getTime()
        if currentTime - audioStartTime >= 1 then -- Delay for 1 second
            -- Stop the music
            music:stop()
            -- Change the screen back to song selection
            currentScreen = "song_selection"
        end
    end
end



function love.draw()
    if currentScreen == "song_selection" then
        -- Draw the song selection menu
        love.graphics.clear(0.2, 0.2, 0.2)

        love.graphics.setFont(font)
        love.graphics.printf("Select a song:", 0, 100, love.graphics.getWidth(), "center")

        for i, song in ipairs(songs) do
            if i == selectedSongIndex then
                love.graphics.setColor(1, 0, 0) -- Highlight the selected song
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.printf(song.name, 0, 150 + i * 30, love.graphics.getWidth(), "center")
        end
    elseif currentScreen == "game_menu" then
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
end

function love.keypressed(key)
    if currentScreen == "song_selection" then
        if key == "up" then
            selectedSongIndex = selectedSongIndex - 1
            if selectedSongIndex < 1 then
                selectedSongIndex = #songs
            end
        elseif key == "down" then
            selectedSongIndex = selectedSongIndex + 1
            if selectedSongIndex > #songs then
                selectedSongIndex = 1
            end
        elseif key == "return" then
            -- Load the selected song's chart and audio
            loadSong(songs[selectedSongIndex])
            -- Move to the game menu
            currentScreen = "game_menu"
            songStartTime = love.timer.getTime() -- Record the start time of the song
        end
    elseif currentScreen == "game_menu" then
        -- Your game menu key handling code here
    end
end

function loadSong(song)
    -- Load chart from file
    chart = {}
    for line in love.filesystem.lines(song.chart) do
        table.insert(chart, tonumber(line))
    end
    -- Debugging: print loaded chart
    print("Loaded chart for " .. song.name .. ":")
    for i, time in ipairs(chart) do
        print(i, time)
    end
    
    -- Load audio without delay
    music = love.audio.newSource(song.audio, "stream") -- the "stream" is good for longer music tracks
    music:setLooping(false) -- Ensure the music doesn't loop
    
    -- Reset notes and indices
    notes = {}
    nextNoteIndex = 1
    score = 0
    misses = 0

    -- Set the flag to delay audio
    audioDelay = true
    audioStartTime = love.timer.getTime() -- Record the audio start time
end
