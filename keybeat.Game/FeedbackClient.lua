local gui = script.Parent
local button = gui.Menu:WaitForChild("FeedbackButton")
local frame = gui:WaitForChild("FeedbackFrame"); frame.Visible = false
local closeBtn = frame:WaitForChild("CloseButton")
local subjectBox = frame:WaitForChild("SubjectContainer"):WaitForChild("SubjectBox")
local bodyBox = frame:WaitForChild("BodyContainer"):WaitForChild("BodyBox")
local submitBtn = frame:WaitForChild("SubmitButton")

local remoteEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("OnFeedbackSubmitted")


function Open()
	
	frame.Visible = true
end

function Close()
	
	frame.Visible = false
end

function OpenClicked()
	
	if frame.Visible == true then
		Close()
	else
		Open()
	end
end

function CloseClicked()
	
	Close()
end

button.MouseButton1Click:Connect(OpenClicked)

closeBtn.MouseButton1Click:Connect(CloseClicked)


function GetInput()
	
	local subject = subjectBox.Text
	local body = bodyBox.Text
	
	if string.len(string.gsub(subject, " ", "")) > 0 and string.len(string.gsub(body, " ", "")) > 0 then
		
		local input = {
			Subject = subject,
			Body = body,
		}
		
		return input
	end
end

function SubmitClicked()
	
	local input = GetInput()
	
	if not input then return end
	
	Close()
	
	remoteEvent:FireServer(input)
end

submitBtn.MouseButton1Click:Connect(SubmitClicked)
