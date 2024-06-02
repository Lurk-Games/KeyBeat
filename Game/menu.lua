-- menu.lua
local menu = {}
local selectedOption = 1
local options = {}

function menu.load()
    options = {"Start Game", "Settings"}
    loadSongs()
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

function menu.update(dt)
end

function menu.draw()
    love.graphics.printf("Choose an option:", 0, love.graphics.getHeight() / 2 - 150, love.graphics.getWidth(), "center")
    for i, option in ipairs(options) do
        if type(option) == "table" then
            local text = option.name .. " (Credits: " .. option.credits .. ", Difficulty: " .. option.difficulty .. ")"
            if i == selectedOption then
                love.graphics.printf("-> " .. text, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
            else
                love.graphics.printf(text, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
            end
        else
            if i == selectedOption then
                love.graphics.printf("-> " .. option, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
            else
                love.graphics.printf(option, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
            end
        end
    end
end

function menu.keypressed(key)
    if key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #options
        end
    elseif key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #options then
            selectedOption = 1
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
            love.event.quit()
    end
end

return menu
