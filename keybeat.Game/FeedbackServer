local SendFeedback = require(script:WaitForChild("SendFeedback"))

local subjectLimit = 30
local bodyLimit = 200

local remoteEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("OnFeedbackSubmitted")

local onCoodown = {}


function OnFeedbackSubmitted(feedback: {string})
	
	if not feedback then return end
	
	if string.len(feedback.Subject) > subjectLimit or string.len(feedback.Body) > bodyLimit then return end
	
	if string.len(string.gsub(feedback.Subject, " ", "")) == 0 or string.len(string.gsub(feedback.Body, " ", "")) == 0 then return end
		
	SendFeedback(feedback)
end

remoteEvent.OnServerEvent:Connect(function(plr: Player, feedback: {string})
	
	if onCoodown[plr] then return end
	onCoodown[plr] = true
	
	feedback["UserId"] = plr.UserId
	
	OnFeedbackSubmitted(feedback)
	
	task.wait(0.5)
	onCoodown[plr] = false
end)
