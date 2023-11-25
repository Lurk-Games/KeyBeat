local on = false
local player = game.Players.LocalPlayer
local character = player.Character
local Humanoid = character:WaitForChild('Humanoid')

script.Parent.MouseButton1Click:Connect(function()
	if on == false then
	    on = true
	    script.Parent.BackgroundTransparency = 0
		game.Players.LocalPlayer.Modifiers.NF.Value = true
		Humanoid.MaxHealth = math.huge
		Humanoid.Health = math.huge
	elseif on == true then
		on = false
		script.Parent.BackgroundTransparency = 1
		game.Players.LocalPlayer.Modifiers.NF.Value = false
		Humanoid.MaxHealth = 100
		Humanoid.Health = 0
	end
end)
