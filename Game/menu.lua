-- menu.lua
local menu = {}
local selectedOption = 1
local options = {}

function menu.load()
    options = {"Start Game", "Settings"}
end

function menu.update(dt)
end

function menu.draw()
    love.graphics.print("Version: " .. version, 0, 650, 0, 1)
    love.graphics.printf("Choose an option:", 0, love.graphics.getHeight() / 2 - 150, love.graphics.getWidth(), "center")
    for i, option in ipairs(options) do
        if i == selectedOption then
            love.graphics.printf("-> " .. option, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
        else
            love.graphics.printf(option, 0, love.graphics.getHeight() / 2 - 50 + i * 30, love.graphics.getWidth(), "center")
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
            goToPlayMenu()
        elseif options[selectedOption] == "Settings" then
            goToSettings()
        --[[elseif options[selectedOption] == "Chart Editor" then
            goToChartEditor()]]
        else
            local selected = options[selectedOption]
            startGame(selected.chart, selected.music)
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

return menu
