repeat
	wait()
until game:IsLoaded() -- Wait until game loads

-- Variables
local player = game:GetService("Players").LocalPlayer
local character = player.Character

local gameui = script.Parent.Game
local holder = gameui.Holder
local countdown = gameui.Countdown
local background = holder.Background
local notes = holder.Notes
local trigger = background.Trigger

local mainui = script.Parent.Main
local menu = mainui.SongMenu
local songs = menu.Songs
local selected = menu.Selected
local play = menu.Play
local BadgeService = game:GetService("BadgeService")

local replicated = game:GetService("ReplicatedStorage")
local user = game:GetService("UserInputService")
local tween = game:GetService("TweenService")
local run = game:GetService("RunService")

local maps = replicated.Maps
local resources = replicated.Resources

local primary = "Galaxy Collapse"
local Test = require(replicated.ModCharts.PrimaryMaps)
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
local key3 = 0
local key4 = 0

-- Settings
local scrollspeed = replicated.Settings.ScrollSpeed.Value
local keybinds = {
	replicated.Controls.Left.Value; -- Left arrow
	replicated.Controls.Down.Value; -- Up arrow
	replicated.Controls.Up.Value; -- Down arrow
	replicated.Controls.Right.Value; -- Right arrow
}
local resetKey = replicated.Controls.Reset.Value

-- Code
function effect(key,fade)
	local info = TweenInfo.new(
		0.5, -- Fade speed
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)
	if fade then -- Fade in
		local create = tween:Create(trigger[key].Effect,info,{ImageTransparency = 0})
		create:Play()
	else -- Fade out
		local create = tween:Create(trigger[key].Effect,info,{ImageTransparency = 1})
		create:Play()
	end
end

function timing(pos)
	-- 50 ms = Perfect
	if pos >= 0.8-(0.05*scrollspeed) then
		perfect = perfect+1
		combo += 1
		gameui.Wow.Text = "Perfect"
		gameui.Wow.Miss.Enabled = false
		gameui.Wow.Okay.Enabled = false
		gameui.Wow.Great.Enabled = false
		gameui.Wow.Perfect.Enabled = true
		game.Players.LocalPlayer.Character.Humanoid.Health += 15
		game.ReplicatedStorage.Score.PointHolder.Value += 10
		score += 100
		gameui.Stats.Score.Text = score
		gameui.Combo.Text = combo
		-- 100 ms = Great
	elseif pos >= 0.8-(0.1*scrollspeed) then
		great = great+1
		combo += 1
		gameui.Wow.Text = "Great"
		gameui.Wow.Miss.Enabled = false
		gameui.Wow.Great.Enabled = true
		gameui.Wow.Okay.Enabled = false
		gameui.Wow.Perfect.Enabled = false
		game.Players.LocalPlayer.Character.Humanoid.Health += 5
		game.ReplicatedStorage.Score.PointHolder.Value += 5
		score += 50
		gameui.Stats.Score.Text = score
		gameui.Combo.Text = combo
		-- 150 ms = Okay
	elseif pos >= 0.8-(0.15*scrollspeed) then
		okay = okay+1
		combo += 1
		gameui.Wow.Text = "Okay"
		gameui.Wow.Miss.Enabled = false
		gameui.Wow.Okay.Enabled = true
		gameui.Wow.Great.Enabled = false
		gameui.Wow.Perfect.Enabled = false
		game.Players.LocalPlayer.Character.Humanoid.Health += 2
		game.ReplicatedStorage.Score.PointHolder.Value += 2
		score += 25
		gameui.Stats.Score.Text = score
		gameui.Combo.Text = combo
		-- Miss
	--[[else
		miss = miss+1
		combo -= combo
		script.Parent.Game.Score.Miss.Text = "Misses:" .. miss
		gameui.Wow.Text = "Miss"
		gameui.Wow.Miss.Enabled = true
		gameui.Wow.Okay.Enabled = false
		gameui.Wow.Great.Enabled = false
		gameui.Wow.Perfect.Enabled = false
		game.Players.LocalPlayer.Character.Humanoid.Health -= 5
		game.ReplicatedStorage.Score.PointHolder.Value -= 1
		gameui.Score.Combo.Text = "Combo:" .. combo]]
	end
end

function detect(key,press)
	local close = math.huge
	local target = nil
	local endpos = 0

	for i,v in pairs(notes:GetChildren()) do
		if v.Name == key then
			if v.ImageTransparency == 1 then
				endpos = v.Position.Y.Scale+(v.Anchor.Endpoint.Position.Y.Scale/10)
			else
				endpos = v.Position.Y.Scale
			end

			if math.abs(endpos-trigger.Position.Y.Scale) <= close then
				close = math.abs(endpos-trigger.Position.Y.Scale)
				target = v
			end
		end
	end

	if target then
		if press and target.ImageTransparency == 0 then
			timing(target.Position.Y.Scale)
			-- If the notes are 0.2 (200 ms) in [0.8-0.2; judgement pos-0.2]
			if target.Position.Y.Scale >= 0.8-(0.2*scrollspeed) then
				-- If it's a hold note, make the head transparent so all that remains is a tail
				if target:FindFirstChild("Anchor") then
					target.ImageTransparency = 1
					-- If it's a regular note then destroy
				else
					target:Destroy()
				end
			end
		elseif not press and target.ImageTransparency == 1 then
			timing(target.Position.Y.Scale+(target.Anchor.Endpoint.Position.Y.Scale/10))
			-- If the hold note is already held then destroy
			target:Destroy()
		end
	end
end

function makenote()
	local last = tick()
	local time = 0

	for i = 1,#current.notes do
		time = last + (current.notes[i][1]/1000) + (current.offset/1000) + 3

		if tick() <= time then
			repeat
				run.RenderStepped:Wait()
			until tick() > time
		end

		-- Spawn hold note
		if current.notes[i][3] then
			local note = resources.Hold:Clone()
			note.AnchorPoint = trigger[current.notes[i][2]].AnchorPoint
			note.Position = UDim2.new(trigger[current.notes[i][2]].Position.X.Scale,0,-0.2,0)
			note.Rotation = trigger[current.notes[i][2]].Rotation
			note.Name = current.notes[i][2]
			note.Parent = notes
			-- Make hold note tail stand up
			local anchor = note.Anchor
			anchor.Rotation = -note.Rotation
			local tail = anchor.Tail
			tail.Size = UDim2.new(tail.Size.X.Scale,0,(current.notes[i][3]/100)*scrollspeed,0)
			local endpoint = anchor.Endpoint
			endpoint.Position = UDim2.new(0,0,-tail.Size.Y.Scale,0)
		else
			local note = resources.Note:Clone()
			note.AnchorPoint = trigger[current.notes[i][2]].AnchorPoint
			note.Position = UDim2.new(trigger[current.notes[i][2]].Position.X.Scale,0,-0.2,0)
			note.Rotation = trigger[current.notes[i][2]].Rotation
			note.Name = current.notes[i][2]
			note.Parent = notes
		end
	end
end

function start()
	playing = true
	gameui.Enabled = true
	mainui.Enabled = false

	current = require(maps[primary])
	
	
	script.Parent.Game.Thumbnail.Image = current.thumbnail
	script.Parent.Main.Grade.ImageLabel.Image = current.thumbnail
	if replicated.Settings.MapSpeed.Value == true then
		scrollspeed = current.scrollspeed
	elseif replicated.Settings.MapSpeed.Value == false then
		scrollspeed = replicated.Settings.ScrollSpeed.Value
	end
	keybinds = {
		replicated.Controls.Left.Value; -- Left arrow
		replicated.Controls.Down.Value; -- Up arrow
		replicated.Controls.Up.Value; -- Down arrow
		replicated.Controls.Right.Value; -- Right arrow
	}
	

	delay(0,function()
		makenote()
	end)
	for i = 1,3 do
		countdown.Text = 4-i
		wait(1)
	end
	countdown.Text = ""
	wait(1/scrollspeed)
	--wait(0.5)
	workspace.Music.SoundId = "rbxassetid://"..current.id
	workspace.Music:Play()
end

function reset()
	playing = false
	if character.Humanoid.Health > 0 then -- Prevent game to break
		gameui.Enabled = false
		mainui.Enabled = true
	end
	--mainui.Grade.Visible = true
	mainui.Grade.Stats.Great.Text = "Great:" .. great
	mainui.Grade.Stats.Perfect.Text = "Perfect:" .. perfect
	mainui.Grade.Stats.Okay.Text = "Okay:" .. okay
	mainui.Grade.Stats.Miss.Text = "Miss:" .. miss
	mainui.Grade.Stats.Accurancy.Text = "Accurancy:" .. acc
	mainui.Grade.Stats.Score.Text = score
	if acc < 85 then
		mainui.Grade.TextLabel.Text = "D"
	elseif acc == 85 and acc <= 90 then
		mainui.Grade.TextLabel.Text = "C"
	elseif acc >= 90 and acc == 95  then
		mainui.Grade.TextLabel.Text = "A"
	elseif acc > 95 and miss > 0 then
		mainui.Grade.TextLabel.Text = "S"
	elseif acc > 95 and miss == 0 then
		mainui.Grade.TextLabel.Text = "SS"
	end

	for i,v in pairs(notes:GetChildren()) do
		v:Destroy()
	end
	workspace.Music:Stop()
	if game.Players.LocalPlayer.Modifiers.Disco.Value == true then
		replicated.Score.PointHolder.Value *= 2
		game.Players.LocalPlayer.leaderstats.Points.Value += replicated.Score.PointHolder.Value
	else
		game.Players.LocalPlayer.leaderstats.Points.Value += replicated.Score.PointHolder.Value
	end
	if game.Players.LocalPlayer.Modifiers.NF.Value == true then
		game.Players.LocalPlayer.leaderstats.Points.Value += math.floor(replicated.Score.PointHolder.Value / 2)
	else
		game.Players.LocalPlayer.leaderstats.Points.Value += replicated.Score.PointHolder.Value
	end
	replicated.Score.PointHolder.Value = 0
	game.Players.LocalPlayer.leaderstats.Hidden.EXP.Value += 100
	

	-- Reset stats (forgot to show this in video)
	--mainui.Grade.TextButton.MouseButton1Click:Connect(function()
		perfect = 0
		great = 0
		okay = 0
		miss = 0
		acc = 0
		combo = 0
	score = 0
	key1 = 0
	key2 = 0 
	key3 = 0
	key4 = 0
	--end)
end

run.RenderStepped:Connect(function(delta)
	if playing then
		for i,v in pairs(notes:GetChildren()) do
			-- Move note
			v.Position = UDim2.new(v.Position.X.Scale,0,v.Position.Y.Scale+(delta*scrollspeed),0)

			-- Hold note
			if v:FindFirstChild("Anchor") then
				-- Update tail if hold note is held
				if v.ImageTransparency == 1 then
					local tail = v.Anchor.Tail
					local endpoint = v.Anchor.Endpoint
					-- Distance from judgement line to end of hold note tail
					local dist = trigger.Position.Y.Scale-(v.Position.Y.Scale+(endpoint.Position.Y.Scale/10)) --10
					-- Distance from hold note invisible head to judgement line
					local dist2 = (v.Position.Y.Scale-trigger.Position.Y.Scale)*10 --10

					tail.Size = UDim2.new(tail.Size.X.Scale,0,math.clamp(dist*10,0,math.huge),0)
					tail.Position = UDim2.new(tail.Position.X.Scale,0,0.5-dist2,0)

					-- Destroy hold note (held)
					if v.Position.Y.Scale >= 1-(endpoint.Position.Y.Scale/10) then
						miss = miss + 1
						combo -= combo
						script.Parent.Game.Stats.Miss.Text = "Misses:" .. miss
						gameui.Wow.Text = "Miss"
						gameui.Wow.Miss.Enabled = true
						gameui.Wow.Okay.Enabled = false
						gameui.Wow.Great.Enabled = false
						gameui.Wow.Perfect.Enabled = false
						game.Players.LocalPlayer.Character.Humanoid.Health -= 5
						game.ReplicatedStorage.Score.PointHolder.Value -= 10
						score -= 10
						gameui.Stats.Score.Text = score
						gameui.Combo.Text = combo
						v:Destroy()
					end
				else
					-- Destroy hold note (not held)
					if v.Position.Y.Scale >= 1 then
						miss = miss + 1
						combo -= combo
						script.Parent.Game.Stats.Miss.Text = "Misses:" .. miss
						gameui.Wow.Text = "Miss"
						gameui.Wow.Miss.Enabled = true
						gameui.Wow.Okay.Enabled = false
						gameui.Wow.Great.Enabled = false
						gameui.Wow.Perfect.Enabled = false
						game.Players.LocalPlayer.Character.Humanoid.Health -= 5
						game.ReplicatedStorage.Score.PointHolder.Value -= 10
						score -= 10
						gameui.Stats.Score.Text = score
						gameui.Combo.Text = combo
						v:Destroy()
					end
				end
			else
				-- Destroy regular note
				if v.Position.Y.Scale >= 1 then
					miss = miss + 1
					combo -= combo
					script.Parent.Game.Stats.Miss.Text = "Misses:" .. miss
					gameui.Wow.Text = "Miss"
					gameui.Wow.Miss.Enabled = true
					gameui.Wow.Okay.Enabled = false
					gameui.Wow.Great.Enabled = false
					gameui.Wow.Perfect.Enabled = false
					game.Players.LocalPlayer.Character.Humanoid.Health -= 5
					game.ReplicatedStorage.Score.PointHolder.Value -= 10
					score -= 10
					gameui.Stats.Score.Text = score
					gameui.Combo.Text = combo
					v:Destroy()
				end
			end
		end

		-- Accuracy
		local hits = perfect+great+okay
		if hits == 0 then
			acc = 100
			script.Parent.Game.Stats.Accurancy.Text = "Accurancy:" .. acc .. "%"
		else
			acc = (math.floor(((perfect+(great*0.75)+(okay*0.5))/(miss+hits))*10000)/100)
			script.Parent.Game.Stats.Accurancy.Text = "Accurancy:" .. acc .. "%"
		end
	end
end)

user.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode[keybinds[1]] then -- Left arrow
		effect("1",true)
		detect("1",true)
		key1 += 1
		gameui.KeyStrokes.Key1.TextLabel.Text = key1
		
		if replicated.Settings.Hitsound.Value == true then
			workspace.Hitsound:Play()
		end
	elseif input.KeyCode == Enum.KeyCode[keybinds[2]] then -- Up arrow
		effect("2",true)
		detect("2",true)
		key2 += 1
		gameui.KeyStrokes.Key2.TextLabel.Text = key2
		if replicated.Settings.Hitsound.Value == true then
			workspace.Hitsound:Play()
		end
	elseif input.KeyCode == Enum.KeyCode[keybinds[3]] then -- Down arrow
		effect("3",true)
		detect("3",true)
		key3 += 1
		gameui.KeyStrokes.Key3.TextLabel.Text = key3
		if replicated.Settings.Hitsound.Value == true then
			workspace.Hitsound:Play()
		end
	elseif input.KeyCode == Enum.KeyCode[keybinds[4]] then -- Right arrow
		effect("4",true)
		detect("4",true)
		key4 += 1
		gameui.KeyStrokes.Key4.TextLabel.Text = key4
		if replicated.Settings.Hitsound.Value == true then
			workspace.Hitsound:Play()
			
		end
	end
end)

user.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode[keybinds[1]] then -- Left arrow
		effect("1",false)
		detect("1",false)
	elseif input.KeyCode == Enum.KeyCode[keybinds[2]] then -- Up arrow
		effect("2",false)
		detect("2",false)
	elseif input.KeyCode == Enum.KeyCode[keybinds[3]] then -- Down arrow
		effect("3",false)
		detect("3",false)
	elseif input.KeyCode == Enum.KeyCode[keybinds[4]] then -- Right arrow
		effect("4",false)
		detect("4",false)
	end
end)

character:WaitForChild("Humanoid").Died:Connect(function()
	reset()
end)

workspace.Music.Ended:Connect(function()
--{if miss == 0 then
		--local badgeId = 2150283841
		--BadgeService:AwardBadge(player.UserId, badgeId)
	--end}
	reset()
end)

selected.Text = primary
for i,v in pairs(maps:GetChildren()) do
	-- Load song selection in menu
	local module = require(v)
	local button = resources.Thumbnail:Clone()
	
	--button.TextLabel.Text = current.difficulty
	button.Name = v.Name
	button.Visible = true
	current = require(maps[v.Name])
	button.Parent = songs[current.category]
	button.Song.Text = v.Name
	button.Image = current.thumbnail
	button.Author.Text = current.credits
	button.Mapper.Text = current.mapper
	button.Difficulty.Text = current.difficulty
	if button.Name == "Normal Dark Dungeon"  then
		button.Name = "Dark Dungeon"
		button.Song.Text = button.Name
	elseif button.Name == "Normal Varcolac" then
		button.Name = "Varcolac"
		button.Song.Text = button.Name
	elseif button.Name == "Easy Nonbinarity(Cut Ver.)" then
		button.Name = "Nonbinarity(Cut Ver.)"
		button.Song.Text = button.Name
		button.Song.TextColor3 = Color3.new(0, 0, 0)
		button.Author.TextColor3 = Color3.new(0, 0, 0)
		button.Mapper.TextColor3 = Color3.new(0, 0, 0)
		button.Difficulty.TextColor3 = Color3.new(0, 0, 0)
	elseif button.Name == "Hard Nonbinarity(Cut Ver.)" then
		button.Name = "Nonbinarity(Cut Ver.)"
		button.Song.Text = button.Name
		button.Song.TextColor3 = Color3.new(0, 0, 0)
		button.Author.TextColor3 = Color3.new(0, 0, 0)
		button.Mapper.TextColor3 = Color3.new(0,0,0)
		button.Difficulty.TextColor3 = Color3.new(0, 0, 0)
	elseif button.Name == "Nonbinarity(Cut Ver.)" then
		button.Song.TextColor3 = Color3.new(0, 0, 0)
		button.Author.TextColor3 = Color3.new(0, 0, 0)
		button.Mapper.TextColor3 = Color3.new(0,0,0)
		button.Difficulty.TextColor3 = Color3.new(0, 0, 0)
	elseif button.Name == "Easy Niflheimr" then
		button.Name = "Niflheimr"
		button.Song.Text = button.Name
	elseif button.Name == "Normal Niflheimr" then
		button.Name = "Niflheimr"
		button.Song.Text = button.Name
	end
	-- Select song
	button.TextButton.MouseButton1Click:Connect(function()
		primary = button.Name
		selected.Text = button.Name
		Test.Primary = button.Name
		menu.Author.Text = button.Author.Text
		menu.Mapper.Text = button.Mapper.Text
		script.Parent.Main.Grade.Frame.MapName.Text = button.Name
		script.Parent.Main.Grade.Frame.Beatmap.Text = current.mapper
	end)
end

play.MouseButton1Click:Connect(function()
	start()
end)

gameui.Mobile.Left.MouseButton1Down:Connect(function(input)
	effect("1",true)
	detect("1",true)
	key1 += 1
	gameui.KeyStrokes.Key1.TextLabel.Text = key1
	if replicated.Settings.Hitsound.Value == true then
		workspace.Hitsound:Play()
	end
end)

gameui.Mobile.Down.MouseButton1Down:Connect(function(input)
	effect("2",true)
	detect("2",true)
	key2 += 1
	gameui.KeyStrokes.Key2.TextLabel.Text = key2
	if replicated.Settings.Hitsound.Value == true then
		workspace.Hitsound:Play()
	end
end)

gameui.Mobile.Up.MouseButton1Down:Connect(function(input)
	effect("3",true)
	detect("3",true)
	key3 += 1
	gameui.KeyStrokes.Key3.TextLabel.Text = key3
	if replicated.Settings.Hitsound.Value == true then
		workspace.Hitsound:Play()
	end
end)
gameui.Mobile.Right.MouseButton1Down:Connect(function(input)
	effect("4",true)
	detect("4",true)
	key4 += 1
	gameui.KeyStrokes.Key4.TextLabel.Text = key4
	if replicated.Settings.Hitsound.Value == true then
		workspace.Hitsound:Play()
	end
end)

gameui.Mobile.Left.MouseButton1Up:Connect(function(input)
	effect("1",false)
	detect("1",false)
end)
gameui.Mobile.Down.MouseButton1Up:Connect(function(input)
	effect("2",false)
	detect("2",false)
end)
gameui.Mobile.Up.MouseButton1Up:Connect(function(input)
	effect("3",false)
	detect("3",false)
end)
gameui.Mobile.Right.MouseButton1Up:Connect(function(input)
	effect("4",false)
	detect("4",false)
end)

user.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode[resetKey] then
		reset()
	end
end)
