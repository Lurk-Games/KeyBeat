local on = false
local player = game.Players.LocalPlayer

script.Parent.MouseButton1Click:Connect(function()
	if on == false then
	    on = true
	    script.Parent.BackgroundTransparency = 0
		game.Players.LocalPlayer.Modifiers.Disco.Value = true
		player.PlayerGui.Game.Disco.Visible = true
	elseif on == true then
		on = false
		script.Parent.BackgroundTransparency = 1
		game.Players.LocalPlayer.Modifiers.Disco.Value = false
		player.PlayerGui.Game.Disco.Visible = false
	end
end)
