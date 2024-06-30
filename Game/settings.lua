local settings = {}

local options = {"Volume", "Note Speed", "Note Size", "Skins", "Background Dim"}
local selectedOption = 1
local volume = 1
local noteSpeed = 300
local noteSize = 20
local skins = {}
local selectedSkin = 1
local backgroundDim = 0.5 -- Default dim value

function settings.load()
    -- Load available skins
    local skinFiles = love.filesystem.getDirectoryItems("skins")
    for _, skin in ipairs(skinFiles) do
        if love.filesystem.getInfo("skins/" .. skin, "directory") then
            table.insert(skins, skin)
        end
    end
end

function settings.update(dt)
end

function settings.draw()
    love.graphics.printf("Settings:", 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")
    
    for i, option in ipairs(options) do
        local value = ""
        if option == "Volume" then
            value = tostring(math.floor(volume * 100)) .. "%"
        elseif option == "Note Speed" then
            value = tostring(noteSpeed)
        elseif option == "Note Size" then
            value = tostring(noteSize)
        elseif option == "Skins" then
            value = skins[selectedSkin] or "No skins available"
        elseif option == "Background Dim" then
            value = tostring(math.floor(backgroundDim * 100)) .. "%"
        end
        
        if i == selectedOption then
            love.graphics.printf("-> " .. option .. ": " .. value, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
        else
            love.graphics.printf(option .. ": " .. value, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
        end
    end
end

function settings.keypressed(key)
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
    elseif key == "left" then
        if options[selectedOption] == "Volume" then
            volume = math.max(0, volume - 0.1)
            love.audio.setVolume(volume)
        elseif options[selectedOption] == "Note Speed" then
            noteSpeed = math.max(100, noteSpeed - 50)
        elseif options[selectedOption] == "Note Size" then
            noteSize = math.max(10, noteSize - 5)
        elseif options[selectedOption] == "Skins" then
            selectedSkin = selectedSkin - 1
            if selectedSkin < 1 then
                selectedSkin = #skins
            end
        elseif options[selectedOption] == "Background Dim" then
            backgroundDim = math.max(0, backgroundDim - 0.1)
        end
    elseif key == "right" then
        if options[selectedOption] == "Volume" then
            volume = math.min(1, volume + 0.1)
            love.audio.setVolume(volume)
        elseif options[selectedOption] == "Note Speed" then
            noteSpeed = math.min(1000, noteSpeed + 50)
        elseif options[selectedOption] == "Note Size" then
            noteSize = math.min(100, noteSize + 5)
        elseif options[selectedOption] == "Skins" then
            selectedSkin = selectedSkin + 1
            if selectedSkin > #skins then
                selectedSkin = 1
            end
        elseif options[selectedOption] == "Background Dim" then
            backgroundDim = math.min(1, backgroundDim + 0.1)
        end
    elseif key == "escape" then
        backToMenu()
    end
end

function settings.getVolume()
    return volume
end

function settings.getNoteSpeed()
    return noteSpeed
end

function settings.getNoteSize()
    return noteSize
end

function settings.getSelectedSkin()
    return skins[selectedSkin]
end

function settings.getBackgroundDim()
    return backgroundDim
end

return settings
