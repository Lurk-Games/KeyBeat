-- playmenu.lua
local playmenu = {}
local selectedOption = 1
local options = {}
local optionsLoaded = false  -- Flag to check if options have been loaded
local scrollOffset = 0  -- The current scroll offset
local visibleOptions = 5  -- Number of options visible at a time

function playmenu.load()
    if not optionsLoaded then
        loadSongs()
        optionsLoaded = true
    end
end

function loadSongs()
    local songsFolder = "songs"
    for _, folder in ipairs(love.filesystem.getDirectoryItems(songsFolder)) do
        local chartPath = songsFolder .. "/" .. folder .. "/chart.txt"
        local musicPath = songsFolder .. "/" .. folder .. "/music.ogg"
        local infoPath = songsFolder .. "/" .. folder .. "/info.txt"
        if love.filesystem.getInfo(chartPath) and love.filesystem.getInfo(musicPath) then
            local credits, difficulty = "Unknown", "Unknown"
            if love.filesystem.getInfo(infoPath) then
                local info = love.filesystem.read(infoPath)
                for line in info:gmatch("[^\r\n]+") do
                    local key, value = line:match("([^:]+):%s*(.+)")
                    if key and value then
                        if key == "Credits" then
                            credits = value
                        elseif key == "Difficulty" then
                            difficulty = value
                        end
                    end
                end
            end
            table.insert(options, {chart = chartPath, music = musicPath, name = folder, credits = credits, difficulty = difficulty})
        end
    end
end

function playmenu.update(dt)
end

function playmenu.draw()
    love.graphics.printf("Choose an option:", 0, 100, love.graphics.getWidth(), "center")

    local startY = 150
    for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #options) do
        local option = options[i]
        local bgY = startY + (i - scrollOffset - 1) * 100
        if i == selectedOption then
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, bgY, love.graphics.getWidth() / 2, 80)
        
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(option.name, love.graphics.getWidth() / 4, bgY + 10, love.graphics.getWidth() / 2, "center")
        love.graphics.printf("Credits: " .. option.credits, love.graphics.getWidth() / 4, bgY + 30, love.graphics.getWidth() / 2, "center")
        love.graphics.printf("Difficulty: " .. option.difficulty, love.graphics.getWidth() / 4, bgY + 50, love.graphics.getWidth() / 2, "center")
    end
end

function playmenu.keypressed(key)
    if key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #options
        end
        if selectedOption <= scrollOffset and scrollOffset > 0 then
            scrollOffset = scrollOffset - 1
        end
    elseif key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #options then
            selectedOption = 1
        end
        if selectedOption > scrollOffset + visibleOptions then
            scrollOffset = scrollOffset + 1
        end
    elseif key == "return" or key == "space" then
        if options[selectedOption] == "Start Game" then
            selectedOption = 2
        elseif options[selectedOption] == "Settings" then
            goToSettings()
        else
            local selected = options[selectedOption]
            startGame(selected.chart, selected.music)
        end
    elseif key == "escape" then
        backToMenu()
    end
end

return playmenu
