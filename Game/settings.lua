-- settings.lua
local settings = {}

local options = {"Volume", "Note Speed"}
local selectedOption = 1
local volume = 1
local noteSpeed = 300

function settings.load()
    
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
        end
    elseif key == "right" then
        if options[selectedOption] == "Volume" then
            volume = math.min(1, volume + 0.1)
            love.audio.setVolume(volume)
        elseif options[selectedOption] == "Note Speed" then
            noteSpeed = math.min(1000, noteSpeed + 50)
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

return settings
