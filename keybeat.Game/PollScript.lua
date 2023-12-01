local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormRemote = ReplicatedStorage:WaitForChild("FormRemote")
local FormModules = ReplicatedStorage:WaitForChild("FormModules")
local InputType = require(FormModules:WaitForChild("InputType"))
local RemoteType = require(FormModules:WaitForChild("RemoteType"))
local ResponseType = require(FormModules:WaitForChild("ResponseType"))
local Colors = require(FormModules:WaitForChild("Colors"))
local Config = require(FormModules:WaitForChild("Config"))

local FormGui = script.Parent
local ToggleForm = FormGui:WaitForChild("ToggleForm")

local FormFrame = script.FormFrame
local TitleSection = script.TitleSection
local Section = script.Section
local Options = script.Options
local TextBox = script.TextBox
local RadioButtonGroup = script.RadioButtonGroup
local Checkbox = script.Checkbox
local Dropdown = script.Dropdown
local LinearScale = script.LinearScale
local Buttons = script.Buttons

local function GetTextBox(inputType)
	local textBox = TextBox:Clone()

	local isOption = inputType == InputType.Checkbox or inputType == InputType.RadioButton

	if inputType == InputType.ShortText or isOption then
		-- Keep at half width, one line
		local sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.MaxSize = Vector2.new(200, math.huge)
		sizeConstraint.Parent = textBox

		textBox.Size = UDim2.fromScale(0.5, 0)
		textBox.TextWrapped = false
		textBox.MultiLine = false
	end

	if isOption then
		textBox.PlaceholderText = ""
		textBox.LayoutOrder = 2

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 8)
		padding.Parent = textBox
	end

	return textBox
end

local function Themify(text, color)
	return "<font color=\"rgb("
		.. math.floor(color.R*255) .. ","
		.. math.floor(color.G*255) .. ","
		.. math.floor(color.G*255) .. ")\">"
		.. text .. "</font>"
end

-- Validation
local function HasResponseForEntry(entry, data, otherOption)
	for _, dataEntry in ipairs(data) do
		if dataEntry.value ~= nil and dataEntry.entry == entry then
			if dataEntry.value == otherOption.key then
				return HasResponseForEntry(entry .. "." .. otherOption.response, data, otherOption)
			else
				return true
			end
		end
	end
	return false
end

local function ValidateResponse(formData, data, showValidationEvents)
	local isValid = true
	for _, question in ipairs(formData.questions) do
		if question.isRequired then
			local entry = question.entry
			local hasResponse = HasResponseForEntry(entry, data, formData.otherOption)
			if not hasResponse then
				showValidationEvents[entry]:Fire(true)
				isValid = false	
			end
		end
	end
	return isValid
end

local function FormatSeconds(seconds: string)
	return string.format("%02i:%02i:%02i", seconds/60^2, seconds/60%60, seconds%60)
end

local function SendNotification(responseType)
	StarterGui:SetCore("SendNotification", Config.Notifications[responseType])
end

local TouchControlsEnabled = GuiService.TouchControlsEnabled
local FormContainer

local function setFormContainerVisibility(isVisible)
	FormContainer.Visible = isVisible

	if Config.DisableTouchInputs and TouchControlsEnabled then
		GuiService.TouchControlsEnabled = not isVisible
	end
end

-- Show form
local function createForm(formId, formData)
	-- Color
	assert(formData.color ~= nil)
	local themeColor = formData.color
	script.Parent:SetAttribute("ThemeColor", themeColor)

	-- Container
	local FormFrame = FormFrame:Clone()
	FormContainer = FormFrame -- Keep a reference
	FormContainer:SetAttribute("FormId", formId)
	setFormContainerVisibility(true)

	FormFrame.Parent = FormGui

	local Contents = FormFrame.ScrollingFrame.Contents

	-- Title Section
	local titleSection = TitleSection:Clone()
	titleSection.Parent = Contents

	-- Title
	assert(formData.title ~= nil)
	titleSection.Title.Text = formData.title

	-- Description
	if formData.description and #formData.description > 0 then
		titleSection.Description.Visible = true
		titleSection.Description.Text = formData.description
	end

	-- Create data object
	local data = {}

	-- Validation
	local showValidationEvents = {}
	
	-- Metadata
	local metadata = {}
	
	-- Questions
	assert(formData.questions ~= nil)
	for _, question in ipairs(formData.questions) do
		local dataEntry = { entry = question.entry, value = nil }
		table.insert(data, dataEntry)
		
		assert(question.inputLabel ~= nil)
		
		if question.inputLabel == Config.Metadata.Username then
			local username = Players.LocalPlayer.Name
			table.insert(metadata, "<b>" .. username  .."</b>")
			dataEntry.value = username
			continue
		elseif question.inputLabel == Config.Metadata.DisplayName then
			local displayName = Players.LocalPlayer.DisplayName
			table.insert(metadata, "<smallcaps>" .. displayName .. "</smallcaps>")
			dataEntry.value = displayName
			continue
		elseif question.inputLabel == Config.Metadata.UserId then
			local userId = Players.LocalPlayer.UserId
			table.insert(metadata, tostring(userId))
			dataEntry.value = userId
			continue
		elseif question.inputLabel == Config.Metadata.PlaceId then
			local placeId = game.PlaceId
			table.insert(metadata, "<font face=\"RobotoMono\">🌎 " .. placeId .. "</font>")
			dataEntry.value = game.PlaceVersion
			continue
		elseif question.inputLabel == Config.Metadata.PlaceVersion then
			local placeVersion = game.PlaceVersion
			table.insert(metadata, "<font face=\"RobotoMono\">🌐 v" .. placeVersion .. "</font>")
			dataEntry.value = placeVersion
			continue
		elseif question.inputLabel == Config.Metadata.ClientVersion then
			local clientVersion = version()
			table.insert(metadata, "<font face=\"RobotoMono\">🖥️ v" .. clientVersion .. "</font>")
			dataEntry.value = clientVersion
			continue
		elseif question.inputLabel == Config.Metadata.Time then
			local timeValue = time()
			table.insert(metadata, "🕑 " .. FormatSeconds(timeValue))
			dataEntry.value = timeValue
			continue
		elseif question.inputLabel == Config.Metadata.ElapsedTime then
			local elapsedTimeValue = elapsedTime()
			table.insert(metadata, "⌛ " .. FormatSeconds(elapsedTimeValue))
			dataEntry.value = elapsedTimeValue
			continue
		elseif question.inputLabel == Config.Metadata.GcInfo then
			local gcInfo = gcinfo()
			table.insert(metadata, "🗑️ " .. gcInfo .. "")
			dataEntry.value = gcInfo
			continue
		elseif question.inputLabel == Config.Metadata.ServerSize then
			local serverSize = #Players:GetPlayers()
			table.insert(metadata, "👥 " .. serverSize .. "")
			dataEntry.value = serverSize
			continue
		end
		
		local section = Section:Clone()
		local ShowValidation = section.ShowValidation

		local label = section.Question.Label
		label.Text = question.inputLabel
		
		if question.description then
			local description = section.Question.Description
			description.Visible = true
			description.Text = question.description
		end

		if question.isRequired then
			showValidationEvents[question.entry] = ShowValidation

			titleSection.Divider.Visible = true
			titleSection.Required.Visible = true

			label.RichText = true
			label.Text = question.inputLabel .. " " .. Themify("*", themeColor)
		end

		local input
		if question.inputType == InputType.ShortText or question.inputType == InputType.LongText then
			input = GetTextBox(question.inputType)

			input.FocusLost:Connect(function ()
				if #input.Text > 0 then
					dataEntry.value = input.Text
					ShowValidation:Fire(false)
				else
					dataEntry.value = nil
				end
			end)
		elseif question.inputType == InputType.RadioButton or question.inputType == InputType.LinearScale then
			local isLinearScale = question.inputType == InputType.LinearScale
			input = if isLinearScale then LinearScale:Clone() else RadioButtonGroup:Clone()

			local radioButtonTemplate = input:WaitForChild("RadioButton")
			radioButtonTemplate.Parent = nil

			for i, option in ipairs(question.options) do
				local radioButton = radioButtonTemplate:Clone()

				radioButton.Value.Value = option
				radioButton.Label.Text = option
				radioButton.Parent = input

				local isOtherOption = option == formData.otherOption.key
				if isOtherOption then
					radioButton.Label.Text = formData.otherOption.label
					radioButton.Label.UIPadding.PaddingRight = UDim.new(0, 0)

					-- Add text input
					local textBox = GetTextBox(InputType.RadioButton)
					textBox.Parent = radioButton

					local radioButtonOtherDataEntry = {
						entry = question.entry .. "." .. formData.otherOption.response,
						value = nil
					}
					table.insert(data, radioButtonOtherDataEntry)

					textBox.Focused:Connect(function ()
						input.Value.Value = radioButton.Value
					end)

					textBox.FocusLost:Connect(function ()
						if #textBox.Text > 0 then
							radioButtonOtherDataEntry.value = textBox.Text
							ShowValidation:Fire(false)
						else
							radioButtonOtherDataEntry.value = nil
						end
					end)
				end
			end
			
			if isLinearScale then
				-- Start and end labels
				local startLabel = input:WaitForChild("StartLabel")
				startLabel.Text = question.startLabel
				
				local endLabel = input:WaitForChild("EndLabel")
				endLabel.Text = question.endLabel
			end

			input.Value.Changed:Connect(function ()
				dataEntry.value = input.Value.Value.Value
				ShowValidation:Fire(false)
			end)
		elseif question.inputType == InputType.Checkbox then
			input = Options:Clone()

			-- Each checkbox gets its own response field
			table.remove(data, #data)

			for i, option in ipairs(question.options) do
				local checkbox = Checkbox:Clone()

				checkbox.Checked.Value = false
				checkbox.Label.Text = option
				checkbox.Parent = input

				local checkboxDataEntry = { entry = question.entry, value = nil }
				table.insert(data, checkboxDataEntry)

				local isOtherOption = option == formData.otherOption.key
				if isOtherOption then
					checkbox.Label.Text = formData.otherOption.label
					checkbox.Label.UIPadding.PaddingRight = UDim.new(0, 0)

					-- Add text input
					local textBox = GetTextBox(InputType.Checkbox)
					textBox.Parent = checkbox

					local checkboxOtherDataEntry = {
						entry = question.entry .. "." .. formData.otherOption.response,
						value = nil
					}
					table.insert(data, checkboxOtherDataEntry)

					textBox.Focused:Connect(function ()
						checkbox.Checked.Value = true
					end)

					textBox.FocusLost:Connect(function ()
						if #textBox.Text > 0 then
							checkboxOtherDataEntry.value = textBox.Text
							ShowValidation:Fire(false)
						else
							checkboxOtherDataEntry.value = nil
						end
					end)
				end

				checkbox.Checked.Changed:Connect(function ()
					checkboxDataEntry.value = option
					ShowValidation:Fire(false)
				end)
			end
		elseif question.inputType == InputType.Dropdown then
			input = Dropdown:Clone()

			local dropdownOptionTemplate = input:WaitForChild("Option")
			dropdownOptionTemplate.Parent = nil

			for i, option in ipairs(question.options) do
				local dropdownOption = dropdownOptionTemplate:Clone()

				dropdownOption.Value.Value = option
				dropdownOption.Label.Text = option
				dropdownOption.Parent = input
			end

			input.Value.Changed:Connect(function ()
				dataEntry.value = input.Value.Value.Value
				ShowValidation:Fire(false)
			end)
		end

		if input ~= nil then
			input.Parent = section
			section.Parent = Contents
		else
			warn("Unsupported input type: " .. question.inputType)
		end
	end
	
	-- Metadata
	local metadataString = table.concat(metadata, Themify(" <b>•</b> ", themeColor))
	if string.len(metadataString) > 0 then
		titleSection.Shared.Visible = true
		titleSection.Shared.Text = metadataString .. " <i>(shared)</i>"
	end
	
	-- Buttons
	local buttons = Buttons:Clone()
	buttons.Parent = Contents

	local cancel = buttons.Cancel
	cancel.Activated:Connect(function ()
		setFormContainerVisibility(false)
		FormContainer = nil
		FormFrame:Destroy()
	end)

	local submit = buttons.Submit
	local gradient = submit.UIGradient

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In, 10)
	submit.Activated:Connect(function ()
		-- Validation
		local isValid = ValidateResponse(formData, data, showValidationEvents)

		if not isValid then
			return
		end

		gradient.Enabled = true

		local shimmer = TweenService:Create(gradient, tweenInfo, { Offset = Vector2.new(1, 0) })
		shimmer:Play()
		
		local requestData = { formId = formId, formData = data }
		local responseType = FormRemote:InvokeServer(RemoteType.SubmitFormData, requestData)

		shimmer:Cancel()
		
		setFormContainerVisibility(false)
		FormContainer = nil
		FormFrame:Destroy()
		
		SendNotification(responseType)
	end)
end

local isLocked = false
ToggleForm.OnInvoke = function (formId)
	while isLocked do
		wait()
	end

	if FormContainer and FormContainer:GetAttribute("FormId") == formId then
		setFormContainerVisibility(not FormContainer.Visible)
	else
		if FormContainer then
			local FormFrame = FormContainer
			
			setFormContainerVisibility(false)
			FormContainer = nil
			FormFrame:Destroy()
		end

		isLocked = true

		local requestData = { formId = formId }
		local responseType, formData = FormRemote:InvokeServer(RemoteType.FetchFormData, requestData)
		
		isLocked = false

		if formData then
			createForm(formId, formData)
		else
			SendNotification(responseType)
			return false
		end
	end
	return true
end
