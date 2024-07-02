local menu = {}
local selectedOption = 1
local options = {}
local menuBackgroundsFolder = "menuBackgrounds"
local backgrounds = {}
local currentBackground
local backgroundScaleX, backgroundScaleY

function menu.load()
    options = {"Start Game", "Settings"}

    -- Load all images from the menuBackgrounds folder
    local files = love.filesystem.getDirectoryItems(menuBackgroundsFolder)
    for _, file in ipairs(files) do
        local filePath = menuBackgroundsFolder .. "/" .. file
        local image = love.graphics.newImage(filePath)
        table.insert(backgrounds, image)
    end

    -- Select a random background only if it's not already set
    if not currentBackground then
        currentBackground = backgrounds[love.math.random(#backgrounds)]
    end

    -- Calculate the scale factors
    updateBackgroundScale()
end

function menu.update(dt)
    -- Check if the window size has changed
    local windowWidth, windowHeight = love.graphics.getDimensions()
    if windowWidth ~= previousWindowWidth or windowHeight ~= previousWindowHeight then
        updateBackgroundScale()
        previousWindowWidth = windowWidth
        previousWindowHeight = windowHeight
    end
end

function menu.draw()
    -- Draw the current background scaled to the window size
    love.graphics.draw(currentBackground, 0, 0, 0, backgroundScaleX, backgroundScaleY)

    -- Draw the dimming overlay
    love.graphics.setColor(0, 0, 0, 0.5)  -- Set color to black with 50% opacity
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white with 100% opacity

    -- Draw the rest of the assets
    love.graphics.print("Version: " .. version, 0, 725, 0, 1)
    love.graphics.print("© 2024 Moonwave Studios. All rights reserved.", 900, 725, 0, 1)
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
            gameState = "game"
            goToPlayMenu()
        elseif options[selectedOption] == "Settings" then
            gameState = "settings"
            goToSettings()
        end
    elseif key == "escape" then
        love.event.quit()
    end
end

function updateBackgroundScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    backgroundScaleX = windowWidth / currentBackground:getWidth()
    backgroundScaleY = windowHeight / currentBackground:getHeight()
end

return menu
