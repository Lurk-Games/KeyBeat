repeat
	wait()
until game:IsLoaded() -- Wait until game loads

-- Variables
local player = game:GetService("Players").LocalPlayer
local character = player.Character

local gameui = script.Parent.Game
local BadgeService = game:GetService("BadgeService")

local replicated = game:GetService("ReplicatedStorage")
local user = game:GetService("UserInputService")
local tween = game:GetService("TweenService")
local run = game:GetService("RunService")

local countdown = gameui.Countdown
local maps = replicated.Maps
local resources = replicated.Resources

local primary = "Test"
local current = nil
local playing = false

local perfect = 0
local great = 0
local okay = 0
local miss = 0
local acc = 0
local combo = 0
local score = 0
local key1 = 0
local key2 = 0

-- Settings
local scrollspeed = replicated.Settings.ScrollSpeed.Value
local keybinds = {
	replicated.Controls.Left.Value; -- Left arrow
	replicated.Controls.Right.Value; -- Right arrow
}
local resetKey = replicated.Controls.Reset.Value

---------------------------------------------------------MORE CODE SOON--------------------------------------------------------------------------------------------------------------
