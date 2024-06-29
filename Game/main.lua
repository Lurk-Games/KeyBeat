-- main.lua

local menu = require("menu")
local game = require("game")
local settings = require("settings")
local playmenu = require("playmenu")
local endscreen = require("endscreen")  -- Add this line
--local chartEditor = require("chart_editor")
version = "prototype-0.1.1"

gameState = "menu"  -- make gameState global for access in other modules

function love.load()
    songFolder2 = love.filesystem.createDirectory("songs")
    skinFolder = love.filesystem.createDirectory("skins")
    love.graphics.setFont(love.graphics.newFont(20))
    hitsound = love.audio.newSource("assets/hitsound.ogg", "static")
    miss = love.audio.newSource("assets/miss.ogg", "static")
    cursor = love.mouse.newCursor("assets/cursor.png", 0, 0)
    menu.load()
    settings.load() -- Load settings, including skins
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
    elseif gameState == "game" then
        game.update(dt)
    elseif gameState == "settings" then
        settings.update(dt)
    elseif gameState == "playmenu" then
        playmenu.update(dt)
    elseif gameState == "endscreen" then  -- Add this block
        endscreen.update(dt)
    --[[elseif gameState == "chartEditor" then
        chartEditor.update(dt)]]
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
        love.mouse.setCursor(cursor)
    elseif gameState == "game" then
        game.draw()
        love.mouse.setCursor(cursor)
    elseif gameState == "settings" then
        settings.draw()
        love.mouse.setCursor(cursor)
    elseif gameState == "playmenu" then
        playmenu.draw()
        love.mouse.setCursor(cursor)
    elseif gameState == "endscreen" then  -- Add this block
        endscreen.draw()
        love.mouse.setCursor(cursor)
    --[[elseif gameState == "chartEditor" then
        chartEditor.draw()]]
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "game" then
        game.keypressed(key)
    elseif gameState == "settings" then
        settings.keypressed(key)
    elseif gameState == "playmenu" then
        playmenu.keypressed(key)
    elseif gameState == "endscreen" then  -- Add this block
        endscreen.keypressed(key)
    --[[elseif gameState == "chartEditor" then
        chartEditor.keypressed(key)]]
    end
end

function love.keyreleased(key)
    if gameState == "game" then
        game.keyreleased(key)
   --[[ elseif gameState == "chartEditor" then
        chartEditor.keyreleased(key)]]
    end
end

function love.textinput(text)
   --[[if gameState == "chartEditor" then
    chartEditor.textinput(text)
    end]]
end

function startGame(chartFile, musicFile, songName, songCredits)
    gameState = "game"
    game.start(chartFile, musicFile, songName, songCredits, function()
        gameState = "endscreen"
        endscreen.load(songName, songCredits, score, totalNotes, hits, misses)
    end)
end

function goToSettings()
    gameState = "settings"
end

function backToMenu()
    gameState = "menu"
    menu.load()
end

function goToPlayMenu()
    gameState = "playmenu"
    playmenu.load()
end

--[[function goToChartEditor()
    gameState = "chartEditor"
    chartEditor.start()
end]]
