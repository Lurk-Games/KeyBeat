-- main.lua

local menu = require("menu")
local game = require("game")
local settings = require("settings")
local playmenu = require("playmenu")

gameState = "menu"  -- make gameState global for access in other modules

function love.load()
    love.graphics.setFont(love.graphics.newFont(20))
    hitsound = love.audio.newSource("assets/hitsound.ogg","static")
    cursor = love.mouse.newCursor("assets/cursor.png",0,0)
    menu.load()
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
    end
end

function love.keyreleased(key)
    if gameState == "game" then
        game.keyreleased(key)
    end
end

function startGame(chartFile, musicFile)
    gameState = "game"
    game.start(chartFile, musicFile, function()
        gameState = "playmenu"
        playmenu.load()
    end)
end

function goToSettings()
    gameState = "settings"
end

function backToMenu()
    gameState = "menu"
end

function goToPlayMenu()
    gameState = "playmenu"
    playmenu.load()
end
