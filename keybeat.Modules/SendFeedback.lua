local id = "" --ID IS HIDDEN
local url = "https://script.google.com/macros/s/" .. id .. "/exec"
local https = game:GetService('HttpService')


function SendFeedback(feedback: {string})
	
	local feedbackUrl = url .. "?UserId=" .. feedback.UserId .. "&Subject=" .. feedback.Subject .. "&Body=" .. feedback.Body
	
	local success, response = pcall(function()
		return https:GetAsync(feedbackUrl)
	end)
	
	if success and response == "success" then
		print("Successfully sent feedback!")
	else
		print("Failed to send feedback: " .. response)
	end
end

return SendFeedback
