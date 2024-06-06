-- main.lua

local menu = require("menu")
local game = require("game")
local settings = require("settings")

gameState = "menu"  -- make gameState global for access in other modules

function love.load()
    love.graphics.setFont(love.graphics.newFont(20))
    hitsound = love.audio.newSource("assets/hitsound.ogg","static")
    menu.load()
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
    elseif gameState == "game" then
        game.update(dt)
    elseif gameState == "settings" then
        settings.update(dt)
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "game" then
        game.draw()
    elseif gameState == "settings" then
        settings.draw()
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "game" then
        game.keypressed(key)
    elseif gameState == "settings" then
        settings.keypressed(key)
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
        gameState = "menu"
        menu.load()
    end)
end

function goToSettings()
    gameState = "settings"
end

function backToMenu()
    gameState = "menu"
end
