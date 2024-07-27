-- settings.lua
local settings = {}

-- Define table.indexOf function
function table.indexOf(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

local options = {"Volume", "Note Speed", "Note Size", "Skins", "Background Dim", "Rating Effect Size", "Fullscreen", "Language"}
local selectedOption = 1
local volume = 1
local noteSpeed = 300
local noteSize = 20
local RatingEffectImageSize = 150
local skins = {}
local selectedSkin = 1
local backgroundDim = 0.5 -- Default dim value
local isFullscreen = false -- Default fullscreen value
local selectedLanguage = "en" -- Default language

local translations = {}
local languages = {"en", "pl", "de"} -- Available languages
local json = require("dkjson") -- Load the JSON library

local function loadTranslations()
    for _, lang in ipairs(languages) do
        local filePath = "Translations/" .. lang .. ".json"
        if love.filesystem.getInfo(filePath) then
            local content = love.filesystem.read(filePath)
            translations[lang] = json.decode(content)
        end
    end
end

local function getTranslation(key)
    return translations[selectedLanguage][key] or key
end

local function saveSettings()
    local data = {
        volume = volume,
        noteSpeed = noteSpeed,
        noteSize = noteSize,
        selectedSkin = selectedSkin,
        backgroundDim = backgroundDim,
        RatingEffectImageSize = RatingEffectImageSize,
        isFullscreen = isFullscreen,
        selectedLanguage = selectedLanguage -- Save the selected language
    }
    
    local encodedData = json.encode(data) -- Encode the data as JSON
    local byteData = love.data.encode("string", "base64", encodedData) -- Convert JSON string to base64 encoded byte data
    local compressedData = love.data.compress("string", "lz4", byteData) -- Compress the base64 encoded byte data using LZ4
    love.filesystem.write("settings.txt", compressedData)
end

local function loadSettings()
    if love.filesystem.getInfo("settings.txt") then
        local compressedData = love.filesystem.read("settings.txt")
        if compressedData then
            local success, decompressedData = pcall(function()
                return love.data.decompress("string", "lz4", compressedData)
            end)
            if success then
                local jsonStr = love.data.decode("string", "base64", decompressedData) -- Decode LZ4 decompressed data from base64 to JSON string
                local data = json.decode(jsonStr) -- Decode the JSON data
                if data then
                    volume = data.volume or volume
                    noteSpeed = data.noteSpeed or noteSpeed
                    noteSize = data.noteSize or noteSize
                    selectedSkin = data.selectedSkin or selectedSkin
                    backgroundDim = data.backgroundDim or backgroundDim
                    RatingEffectImageSize = data.RatingEffectImageSize or RatingEffectImageSize
                    isFullscreen = data.isFullscreen or isFullscreen
                    selectedLanguage = data.selectedLanguage or selectedLanguage -- Load the selected language
                    if selectedLanguage == "jp" then
                        local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24)  -- Adjust size as needed
                        love.graphics.setFont(japaneseFont) -- Set the specific font
                    else
                        local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24)
                        love.graphics.setFont(originalFont)
                    end
                else
                    print("Failed to decode JSON data from decompressed LZ4 data.")
                end
            else
                print("Failed to decompress LZ4 data:", decompressedData)
            end
        else
            print("Failed to read compressed settings data from file.")
        end
    else
        print("Settings file 'settings.txt' not found.")
    end
end

function settings.load()
    -- Load available skins
    local skinFiles = love.filesystem.getDirectoryItems("skins")
    for _, skin in ipairs(skinFiles) do
        if love.filesystem.getInfo("skins/" .. skin, "directory") then
            table.insert(skins, skin)
        end
    end
    loadTranslations()
    loadSettings()
end

function settings.update(dt)
end

function settings.draw()
    love.graphics.printf(getTranslation("Settings") .. ":", 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")
    
    for i, option in ipairs(options) do
        local value = ""
        if option == "Volume" then
            value = tostring(math.floor(volume * 100)) .. "%"
        elseif option == "Note Speed" then
            value = tostring(noteSpeed)
        elseif option == "Note Size" then
            value = tostring(noteSize)
        elseif option == "Skins" then
            value = skins[selectedSkin] or getTranslation("No skins available")
        elseif option == "Background Dim" then
            value = tostring(math.floor(backgroundDim * 100)) .. "%"
        elseif option == "Rating Effect Size" then
            value = tostring(RatingEffectImageSize)
        elseif option == "Fullscreen" then
            value = isFullscreen and getTranslation("On") or getTranslation("Off")
        elseif option == "Language" then
            value = selectedLanguage
        end
        
        local translatedOption = getTranslation(option)
        if i == selectedOption then
            love.graphics.printf("-> " .. translatedOption .. ": " .. value, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
        else
            love.graphics.printf(translatedOption .. ": " .. value, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
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
    elseif key == "left" or key == "right" then
        if options[selectedOption] == "Volume" then
            volume = math.max(0, math.min(1, volume + (key == "left" and -0.1 or 0.1)))
            love.audio.setVolume(volume)
        elseif options[selectedOption] == "Note Speed" then
            noteSpeed = math.max(100, math.min(1000, noteSpeed + (key == "left" and -50 or 50)))
        elseif options[selectedOption] == "Note Size" then
            noteSize = math.max(10, math.min(100, noteSize + (key == "left" and -5 or 5)))
        elseif options[selectedOption] == "Skins" then
            selectedSkin = selectedSkin + (key == "left" and -1 or 1)
            if selectedSkin < 1 then
                selectedSkin = #skins
            elseif selectedSkin > #skins then
                selectedSkin = 1
            end
        elseif options[selectedOption] == "Background Dim" then
            backgroundDim = math.max(0, math.min(1, backgroundDim + (key == "left" and -0.1 or 0.1)))
        elseif options[selectedOption] == "Rating Effect Size" then
            RatingEffectImageSize = math.max(20, RatingEffectImageSize + (key == "left" and -10 or 10))
        elseif options[selectedOption] == "Fullscreen" then
            isFullscreen = not isFullscreen
            love.window.setFullscreen(isFullscreen)
        elseif options[selectedOption] == "Language" then
            local index = table.indexOf(languages, selectedLanguage)
            index = index + (key == "left" and -1 or 1)
            if index < 1 then
                index = #languages
            elseif index > #languages then
                index = 1
            end
            selectedLanguage = languages[index]
            if selectedLanguage == "jp" then
                local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24)  -- Adjust size as needed
                love.graphics.setFont(japaneseFont) -- Set the specific font
            else
                local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24)
                love.graphics.setFont(originalFont)
            end
        end
        saveSettings()
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

function settings.getRatingSize()
    return RatingEffectImageSize
end

function settings.getFullscreen()
    return isFullscreen
end

function settings.getSelectedLanguage()
    return selectedLanguage
end

function settings.getTranslation(key)
    return getTranslation(key)
end

return settings
