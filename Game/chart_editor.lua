local chartEditor = {}

local notes = {}
local selectedNote = nil
local noteSize = 20
local hitLineY = 500
local gridSize = 10
local chartSpeed = 100
local chartTime = 0
local isPlaying = false
local music = nil
local chartEndTime = 0
local musicStartTime = nil

local filePicker = {
    isOpen = false,
    files = {},
    onSelect = nil,
    x = 100,
    y = 100,
    width = 400,
    height = 300
}

function chartEditor.start()
    notes = {}
    selectedNote = nil
    chartTime = 0
    isPlaying = false
    music = nil
    chartEndTime = 0
    musicStartTime = nil
end

function chartEditor.loadChart(filename)
    notes = {}
    local chart = love.filesystem.read(filename)
    for line in chart:gmatch("[^\r\n]+") do
        local time, x, holdTime = line:match("([%d%.]+) ([%d%.]+) ([%d%.]+)")
        time = tonumber(time)
        x = tonumber(x)
        holdTime = tonumber(holdTime)
        table.insert(notes, {time = time, x = x, hold = holdTime > 0, holdTime = holdTime})
        chartEndTime = math.max(chartEndTime, time + holdTime)
    end
end

function chartEditor.saveChart(filename)
    local chartData = ""
    for _, note in ipairs(notes) do
        chartData = chartData .. string.format("%.3f %.0f %.3f\n", note.time, note.x, note.holdTime)
    end
    love.filesystem.write(filename, chartData)
end

function chartEditor.update(dt)
    if isPlaying then
        chartTime = chartTime + dt
        if chartTime > chartEndTime then
            isPlaying = false
            if music then
                music:stop()
            end
        end
    end
end

function chartEditor.draw()
    love.graphics.line(0, hitLineY, love.graphics.getWidth(), hitLineY)
    for _, note in ipairs(notes) do
        local y = hitLineY - (note.time - chartTime) * chartSpeed
        local color = {1, 1, 1}
        if note == selectedNote then
            color = {1, 0, 0}
        end
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", note.x - noteSize / 2, y - noteSize / 2, noteSize, noteSize)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Chart Editor Mode", 10, 10)
    love.graphics.print("Press 'S' to save, 'L' to load, 'N' to create new chart", 10, 30)
    love.graphics.print("Press 'P' to play/pause, 'M' to load music", 10, 50)
    love.graphics.print("Left click to add/move note, Right click to delete note", 10, 70)

    if filePicker.isOpen then
        chartEditor.drawFilePicker()
    end
end

function chartEditor.drawFilePicker()
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", filePicker.x, filePicker.y, filePicker.width, filePicker.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", filePicker.x, filePicker.y, filePicker.width, filePicker.height)
    
    for i, file in ipairs(filePicker.files) do
        love.graphics.print(file, filePicker.x + 10, filePicker.y + 10 + (i - 1) * 20)
    end
end

function chartEditor.openFilePicker(callback)
    filePicker.isOpen = true
    filePicker.files = love.filesystem.getDirectoryItems("")
    filePicker.onSelect = callback
end

function chartEditor.mousepressed(x, y, button)
    if filePicker.isOpen then
        if button == 1 then
            local relativeX = x - filePicker.x
            local relativeY = y - filePicker.y

            if relativeX > 0 and relativeX < filePicker.width and relativeY > 0 and relativeY < filePicker.height then
                local index = math.floor(relativeY / 20) + 1
                if filePicker.files[index] then
                    filePicker.isOpen = false
                    if filePicker.onSelect then
                        filePicker.onSelect(filePicker.files[index])
                    end
                end
            end
        end
        return
    end

    if button == 1 then
        local noteFound = false
        for _, note in ipairs(notes) do
            local noteY = hitLineY - (note.time - chartTime) * chartSpeed
            if math.abs(note.x - x) < noteSize / 2 and math.abs(noteY - y) < noteSize / 2 then
                selectedNote = note
                noteFound = true
                break
            end
        end
        if not noteFound then
            local newTime = chartTime + (hitLineY - y) / chartSpeed
            table.insert(notes, {time = newTime, x = x, hold = false, holdTime = 0})
        end
    elseif button == 2 then
        for i, note in ipairs(notes) do
            local noteY = hitLineY - (note.time - chartTime) * chartSpeed
            if math.abs(note.x - x) < noteSize / 2 and math.abs(noteY - y) < noteSize / 2 then
                table.remove(notes, i)
                break
            end
        end
    end
end

function chartEditor.mousereleased(x, y, button)
    selectedNote = nil
end

function chartEditor.mousemoved(x, y, dx, dy)
    if selectedNote then
        selectedNote.x = x
        selectedNote.time = chartTime + (hitLineY - y) / chartSpeed
    end
end

function chartEditor.keypressed(key)
    if key == "s" then
        chartEditor.saveChart("chart.txt")
    elseif key == "l" then
        chartEditor.openFilePicker(chartEditor.loadChart)
    elseif key == "n" then
        chartEditor.start()
    elseif key == "p" then
        if isPlaying then
            isPlaying = false
            if music then music:pause() end
        else
            isPlaying = true
            if music then
                if not music:isPlaying() then
                    music:play()
                else
                    music:resume()
                end
            end
        end
    elseif key == "m" then
        chartEditor.openFilePicker(function(filename)
            if filename:match("%.ogg$") or filename:match("%.wav$") or filename:match("%.mp3$") then
                local filePath = love.filesystem.getRealDirectory(filename) .. "/" .. filename
                music = love.audio.newSource(filePath, "stream")
                music:setVolume(1)
                music:stop()
            else
                print("Selected file is not a valid audio file.")
            end
        end)
    end
end

function chartEditor.keyreleased(key)
    -- Implement any necessary logic for when keys are released
end

function chartEditor.textinput(text)
    -- Implement any necessary logic for text input
end

return chartEditor
