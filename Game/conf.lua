-- conf.lua
function love.conf(t)
    t.window.title = "KeyBeat"
    t.window.fullscreen = true
    t.window.vsync = 1 -- Enable vertical sync
    t.window.resizable = true -- Disable window resizing
    t.window.fullscreentype = "desktop" -- Use the current desktop resolution
end