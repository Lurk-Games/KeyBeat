-- playmenu.lua
local playmenu = {}
local menu = require("menu")
local settings = require("settings")
local RatingEffectImageSize = settings.getRatingSize()
local selectedOption = 1
local options = {}
local optionsLoaded = false  -- Flag to check if options have been loaded
local scrollOffset = 0  -- The current scroll offset
local visibleOptions = 5  -- Number of options visible at a time
local scoreBreakdown = nil
local mouseX, mouseY = 0, 0  -- Variables to store mouse coordinates
local ModifiersButton = love.graphics.newImage("assets/modifiers.png")

function playmenu.load(breakdown)
    if not optionsLoaded then
        loadSongs()
        optionsLoaded = true
    end
    scoreBreakdown = breakdown
end

function loadSongs()
    local songsFolder = "songs"
    for _, folder in ipairs(love.filesystem.getDirectoryItems(songsFolder)) do
        local chartPath = songsFolder .. "/" .. folder .. "/chart.txt"
        local musicPathMp3 = songsFolder .. "/" .. folder .. "/music.mp3"
        local musicPathOgg = songsFolder .. "/" .. folder .. "/music.ogg"
        local backgroundPathPng = songsFolder .. "/" .. folder .. "/background.png"
        local backgroundPathJpg = songsFolder .. "/" .. folder .. "/background.jpg"
        local backgroundPathJpeg = songsFolder .. "/" .. folder .. "/background.jpeg"
        local musicPath = nil
        local backgroundPath = nil
        local infoPath = songsFolder .. "/" .. folder .. "/info.txt"

        -- Check if either .mp3 or .ogg file exists
        if love.filesystem.getInfo(musicPathMp3) then
            musicPath = musicPathMp3
        elseif love.filesystem.getInfo(musicPathOgg) then
            musicPath = musicPathOgg
        end

        -- Check if either .png or .jpg file exists
        if love.filesystem.getInfo(backgroundPathPng) then
            backgroundPath = backgroundPathPng
        elseif love.filesystem.getInfo(backgroundPathJpg) then
            backgroundPath = backgroundPathJpg
        elseif love.filesystem.getInfo(backgroundPathJpeg) then
            backgroundPath = backgroundPathJpeg
        end

        if love.filesystem.getInfo(chartPath) and musicPath then
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
            table.insert(options, {chart = chartPath, music = musicPath, name = folder, credits = credits, difficulty = difficulty, background = backgroundPath})
        end
    end
end

function playmenu.update(dt)
end

function playmenu.draw()
    love.graphics.print("Version: " .. version, 0, love.graphics.getHeight() - 50, 0, 1)
    
    if scoreBreakdown then
        love.graphics.printf("Score Breakdown:", 0, 100, love.graphics.getWidth(), "center")
        love.graphics.printf("Score: " .. scoreBreakdown.score, 0, 150, love.graphics.getWidth(), "center")
        love.graphics.printf("Hits: " .. scoreBreakdown.hits, 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf("Misses: " .. scoreBreakdown.misses, 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("Accuracy: " .. string.format("%.2f", scoreBreakdown.accuracy) .. "%", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.printf("Total Notes: " .. scoreBreakdown.totalNotes, 0, 350, love.graphics.getWidth(), "center")
        
        -- Display grade image
        local gradeImage = love.graphics.newImage("skins/default/" .. scoreBreakdown.grade .. ".png")
        local x = love.graphics.getWidth() / 2 - RatingEffectImageSize / 2
        local y = 400  -- Adjust as needed
        love.graphics.draw(gradeImage, x, y, 0, RatingEffectImageSize / gradeImage:getWidth(), RatingEffectImageSize / gradeImage:getHeight())

        love.graphics.printf("Press SPACE to continue...", 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
    else
        love.graphics.printf("Choose an option:", 0, 100, love.graphics.getWidth(), "center")

        local startY = 150
        for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #options) do
            local option = options[i]
            local bgY = startY + (i - scrollOffset - 1) * 100

            -- Determine if the mouse is over this option
            local mouseXCenter = love.mouse.getX()
            local mouseYCenter = love.mouse.getY()
            local optionTopY = bgY
            local optionBottomY = bgY + 80
            local optionLeftX = love.graphics.getWidth() / 4
            local optionRightX = love.graphics.getWidth() / 4 + love.graphics.getWidth() / 2
            
            local isMouseOver = mouseXCenter >= optionLeftX and mouseXCenter <= optionRightX and
                                 mouseYCenter >= optionTopY and mouseYCenter <= optionBottomY

            -- Highlight selected option or mouse-over option
            if i == selectedOption or isMouseOver then
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end

            -- Draw option background
            love.graphics.rectangle("fill", love.graphics.getWidth() / 4, bgY, love.graphics.getWidth() / 2, 80)
            
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.printf(option.name, love.graphics.getWidth() / 4, bgY + 10, love.graphics.getWidth() / 2, "center")
            love.graphics.printf("Credits: " .. option.credits, love.graphics.getWidth() / 4, bgY + 30, love.graphics.getWidth() / 2, "center")
            love.graphics.printf("Difficulty: " .. option.difficulty, love.graphics.getWidth() / 4, bgY + 50, love.graphics.getWidth() / 2, "center")
        end
    end
end

function playmenu.wheelmoved(x, y)
    if not scoreBreakdown then
        -- Scroll the options list
        scrollOffset = scrollOffset - y
        -- Ensure scrollOffset stays within bounds
        scrollOffset = math.max(0, math.min(#options - visibleOptions, scrollOffset))
    end
end

function playmenu.mousepressed(x, y, button)
    if scoreBreakdown then
        if button == 1 then  -- Left mouse button
            scoreBreakdown = nil
        end
    else
        if button == 1 then  -- Left mouse button
            -- Calculate which option was clicked
            local startY = 150
            local indexClicked = math.floor((y - startY) / 100) + 1 + scrollOffset

            if indexClicked >= 1 and indexClicked <= #options then
                selectedOption = indexClicked
                local selected = options[selectedOption]
                menu.stopMusic()
                startGame(selected.chart, selected.music, selected.background)
            end
        end
    end
end

function playmenu.mousemoved(x, y, dx, dy, istouch)
    mouseX, mouseY = x, y
end


function playmenu.keypressed(key)
    if scoreBreakdown then
        if key == "space" then
            scoreBreakdown = nil
        end
    else
        if key == "return" or key == "space" then
            local selected = options[selectedOption]
            menu.stopMusic()
            startGame(selected.chart, selected.music, selected.background)
        elseif key == "escape" then
            backToMenu()
        end
    end
end

return playmenu
