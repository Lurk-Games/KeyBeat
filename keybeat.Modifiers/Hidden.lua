local on = false
local player = game.Players.LocalPlayer
local character = player.Character
local Humanoid = character:WaitForChild('Humanoid')

script.Parent.MouseButton1Click:Connect(function()
	if on == false then
	    on = true
	    script.Parent.BackgroundTransparency = 0
		game.Players.LocalPlayer.Modifiers.Hidden.Value = true
		player.PlayerGui.Game.HiddenMod.Visible = true
	elseif on == true then
		on = false
		script.Parent.BackgroundTransparency = 1
		game.Players.LocalPlayer.Modifiers.Hidden.Value = false
		player.PlayerGui.Game.HiddenMod.Visible = true
	end
end)
