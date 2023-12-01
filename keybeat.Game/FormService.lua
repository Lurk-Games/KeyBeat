local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormRemote = Instance.new("RemoteFunction")
FormRemote.Name = "FormRemote"
FormRemote.Parent = ReplicatedStorage

local FormModules = ReplicatedStorage:WaitForChild("FormModules")
local Colors = require(FormModules.Colors)
local Config = require(FormModules.Config)
local InputType = require(FormModules.InputType)
local RemoteType = require(FormModules.RemoteType)
local ResponseType = require(FormModules.ResponseType)
local Utils = require(FormModules.Utils)

local Host = "https://docs.google.com/forms/d/e/"

-- Regexes

local textInputPattern = "<input type=\"text\".-/>"
local textAreaPattern = "<textarea.-</textarea>"
local radioGroupPattern = "role=\"radiogroup\""
local checkboxGroupPattern = "role=\"list\""
local dropdownPattern = "role=\"listbox\""

local labelPattern = "<label.-</label>"
local forPattern = "for=\"(%w+)"
local labelledByPattern = "aria%-labelledby=\"(%w+)\""
local describedByPattern = "aria%-describedby=\"([%w%s]+)\""

local function assertNotNil(...)
	-- Nil arguments are recognized as no arguments.
	local arguments = {...} 
	assert(#arguments > 0, "HTML not parseable. Make sure your form is Public, and you are only using supported components.")
end

local function parseFormHtml(formHtml)
	-- Strip all simple links (keeps the regexes working)
	local linkPattern = "<a href=\".-\">(.-)</a>"
	formHtml = formHtml:gsub(linkPattern, function (text)
		return text
	end)

	-- Goodbye inline styling
	formHtml = formHtml:gsub(" style=\"[^\"]+\"", "")

	-- Strip all the plain spans (same deal)
	local spanPattern = "<span>(.-)</span>"
	formHtml = formHtml:gsub(spanPattern, function (text)
		return text
	end)

	-- Strip out all newlines (<br> elements are used for creating line breaks instead)
	-- This fixes an issue from some WIZARD who was able to get newlines in the source?!?
	formHtml = formHtml:gsub("\n", "")
	
	-- Replace all silly div wrapped <br> elements with just <br>
	local divBrPattern = "<br></div><div>"
	while formHtml:find(divBrPattern) do
		formHtml = formHtml:gsub(divBrPattern, "</div><div><br>")
	end
	
	-- Aaaand all the plain divs
	local divPattern = "<div>(.-)</div>"
	formHtml = formHtml:gsub(divPattern, function (text)
		return text
	end)
	
	-- Also all the plain ps
	local pPattern = "<p>(.-)</p>"
	formHtml = formHtml:gsub(pPattern, function (text)
		return text
	end)
	

	-- Theme
	local themeColor = Colors.DefaultTheme
	local themePattern = "<meta name=\"theme%-color\" content=\"rgb%((%d+), (%d+), (%d+)%)\">"
	local r, g, b = formHtml:match(themePattern)
	if r ~= nil and g ~= nil and b ~= nil then
		themeColor = Color3.fromRGB(r, g, b)
	end

	-- Title
	local formTitlePattern = "<meta property=\"og:title\" content=\"(.-)\">"
	local formTitleMatch = formHtml:match(formTitlePattern)

	assertNotNil(formTitleMatch)
	local formTitle = Utils.SanitizeEncodedHtml(formTitleMatch)

	-- Description
	local formDescription
	local formDescriptionPattern = "<meta property=\"og:description\" content=\"(.-)\">"
	local formDescriptionMatch = formHtml:match(formDescriptionPattern)
	if formDescriptionMatch then
		formDescription = Utils.SanitizeEncodedHtml(formDescriptionMatch)
	end

	-- Split by listItem
	local listItemClassPattern = "<div class=\"(%w+)\" role=\"listitem\">"
	local listItemClassName = formHtml:match(listItemClassPattern)

	-- string.split does not support regex, use exact match
	local listItemElement = "<div class=\"" .. listItemClassName .. "\" role=\"listitem\">"
	local splitHtml = string.split(formHtml, listItemElement)

	local questions = {}

	-- Ignore first element
	for i=2, #splitHtml do
		local html = splitHtml[i]

		local function getTextAssociatedWithId(id, customAttributePattern)
			local labelPattern
			if customAttributePattern then
				labelPattern = "id=\"" .. id .. "\".-" .. customAttributePattern .."=\"(.-)\""
			else
				labelPattern = "id=\"" .. id .. "\".->"
				local htmlTag = html:match("<(%w+) [^>]-" .. labelPattern)
				labelPattern ..= "(.-)</" .. htmlTag .. ">"
			end

			local labelMatch = html:match(labelPattern)

			assertNotNil(labelMatch)
			
			-- Remove any <br> elements - one at the end corresponds to... nothing? very confusing...
			labelMatch = labelMatch:gsub("<br>\n*</", "</")
			-- ... otherwise its a direct 1:1 replace
			labelMatch = labelMatch:gsub("<br>", "\n")

			-- Strip off surrounding html tags
			local spanPattern = "^<span [^>]*>(.-)</span>"
			local spanMatch = string.match(labelMatch, spanPattern)

			local label = Utils.SanitizeEncodedHtml(spanMatch or labelMatch)
			return label
		end

		-- Inputs
		local quotesPattern = "^\"(.-)\"$"
		-- This attempts matches null or &quot; surrounded text.
		-- Because lua doesn't care about later parts of a pattern when matching this needs to be more robust
		-- to not split early if a question has a comma in it.
		local csvTextPattern = "([&n].-[;l])"
		local entryPattern = "data%-params=\"%%%.@%.%[%d+," .. csvTextPattern .. "," .. csvTextPattern .. ",%d+,%[%[(%d+),"
		local foundLabel, foundDescription, entry = html:match(entryPattern)

		assertNotNil(foundLabel, entry)
		local sanitizedLabel = Utils.SanitizeEncodedHtml(foundLabel, "\\")
		local label = string.match(sanitizedLabel, quotesPattern)

		assertNotNil(foundDescription, entry)
		local sanitizedDescription = Utils.SanitizeEncodedHtml(foundDescription, "\\")
		local description = string.match(sanitizedDescription, quotesPattern)
		
		local question = { entry = entry }
		if html:match(radioGroupPattern) then
			-- Either Radio Button or Linear Scale
			question.inputType = InputType.RadioButton
			
			question.options = {}
			for label in string.gmatch(html, labelPattern) do
				local forId = string.match(label, forPattern)
				if forId == nil then
					-- It's a linear scale question
					question.inputType = InputType.LinearScale
					
					local linearScaleOptionPattern = ">([^<]*)</"
					local option = string.match(label, linearScaleOptionPattern)

					assertNotNil(option)
					table.insert(question.options, option)
				else
					local dataValuePattern = "data%-value"
					local option = getTextAssociatedWithId(forId, dataValuePattern)

					table.insert(question.options, option)
				end
			end
			
			if question.inputType == InputType.LinearScale then
				-- Find start and end labels
				local startEndPattern = "%[%[" .. entry .. ",%b[],%w+,%[(.-),(.-)%],"
				local foundStart, foundEnd = html:match(startEndPattern)
				
				assertNotNil(foundStart, foundEnd)
				local sanitizedStart = Utils.SanitizeEncodedHtml(foundStart, "\\")
				local startLabel = string.match(sanitizedStart, quotesPattern)
				question.startLabel = startLabel
				
				local sanitizedEnd = Utils.SanitizeEncodedHtml(foundEnd, "\\")
				local endLabel = string.match(sanitizedEnd, quotesPattern)
				question.endLabel = endLabel
			end
		elseif html:match(checkboxGroupPattern) then
			question.inputType = InputType.Checkbox

			question.options = {}
			for label in string.gmatch(html, labelPattern) do
				local forId = string.match(label, forPattern)

				assertNotNil(forId)
				local dataValuePattern = "data%-answer%-value"
				local option = getTextAssociatedWithId(forId, dataValuePattern)

				table.insert(question.options, option)
			end
		elseif html:match(dropdownPattern) then
			question.inputType = InputType.Dropdown

			question.options = {}
			local optionPattern = "data%-value=(%b\"\").-role=\"option\".->"
			for optionMatch in string.gmatch(html, optionPattern) do
				-- Ignore empty data-values
				if #optionMatch > 2 then
					-- Strip off the first and last characters because of the balanced capture
					local trimmedOption = string.sub(optionMatch, 2, -2)
					local option = Utils.SanitizeEncodedHtml(trimmedOption)

					table.insert(question.options, option)
				end
			end
		elseif html:match(textInputPattern) then
			question.inputType = InputType.ShortText
		elseif html:match(textAreaPattern) then
			question.inputType = InputType.LongText
		end
		
		local labelledById = html:match(labelledByPattern)
		assertNotNil(labelledById)
		
		question.inputLabel = getTextAssociatedWithId(labelledById)
		if not Utils.IsRenderedContentEqual(question.inputLabel, label) then
			warn("Parsed label from data-params not equal to other.")
			warn(question.inputLabel)
			warn(label)
		end
		
		local describedByIdsPattern = "id=\"" .. labelledById .. "\".-" .. describedByPattern
		local describedByIds = html:match(describedByIdsPattern)
		assertNotNil(describedByIds)
		
		for _, describedById in ipairs(string.split(describedByIds, " ")) do
			local describedByLabel = getTextAssociatedWithId(describedById)
			if describedByLabel == " *" then
				question.isRequired = true
			elseif Utils.IsRenderedContentEqual(describedByLabel, description) then
				question.description = describedByLabel
			else
				if describedByLabel == "" then
					-- Label is empty
				elseif describedByLabel == nil  then
					warn("Unable to find label for question " .. describedById)
				end
			end
		end
		
		table.insert(questions, question)
	end

	return {
		color = themeColor,
		title = formTitle,
		description = formDescription,
		questions = questions,
		otherOption = {
			key = "__other_option__",
			response = "other_option_response",
			label = "Other:"
		}
	}
end

-- Remote Functions

local cachedFormData = {}
local function FetchFormData(player, data)
	local formId = data.formId

	local responseType, formData = nil, nil

	if Utils.IsValidFormId(formId) then
		formData = cachedFormData[formId]
		if formData then
			responseType = ResponseType.Success
		else
			if Utils.ThrottleRequest(player, RemoteType.FetchFormData) then
				responseType = ResponseType.RateLimit
			else
				-- Get form html
				local Url = Host .. formId .. "/formResponse"

				local success, formHtml = pcall(function () 
					return HttpService:GetAsync(Url)
				end)

				if success then
					responseType = ResponseType.Success
					formData = parseFormHtml(formHtml)

					if Config.CacheForm then
						cachedFormData[formId] = formData
					end
				else
					responseType = ResponseType.Error
					warn("Failed to fetch form with id: " .. formId)
				end
			end
		end
	else
		responseType = ResponseType.Error
	end

	return responseType, formData
end


local function SubmitFormData(player, data)
	local formId = data.formId
	local formData = data.formData

	local responseType = nil

	if Utils.IsValidFormId(formId) then
		if Utils.ThrottleRequest(player, RemoteType.SubmitFormData) then
			responseType = ResponseType.RateLimit
		else
			if not Config.AllowMultipleResponses and Utils.HasPlayerResponded(player, formId) then
				responseType = ResponseType.NotAllowed
			else
				local formattedData = {}
				for _, data in ipairs(formData) do
					if data.entry ~= nil and data.value ~= nil then
						table.insert(formattedData, "entry." .. data.entry .. "=" .. HttpService:UrlEncode(data.value))
					end
				end

				local Url = Host .. formId .. "/formResponse"
				local body = table.concat(formattedData, "&")

				local success, response = pcall(function () 
					return HttpService:PostAsync(Url, body, Enum.HttpContentType.ApplicationUrlEncoded)
				end)

				if success then
					responseType = ResponseType.Success 

					if not Config.AllowMultipleResponses then
						Utils.SetPlayerFormResponse(player, formId, formData)
					end
				else
					responseType = ResponseType.Error
				end
			end
		end
	else
		responseType = ResponseType.Error
	end

	return responseType
end

local function hashedText(text)
	return string.rep("#", string.len(text))
end

local cachedFilteredText = { [""] = "" }
local function FilterText(player, data)
	local text = data.text

	local responseType, filteredText = nil, ""

	if text ~= nil and typeof(text) == "string" then
		filteredText = cachedFilteredText[text]
		if filteredText then
			responseType = ResponseType.Success
		else
			if Utils.ThrottleRequest(player, RemoteType.FilterText) then
				responseType = ResponseType.RateLimit
				filteredText = hashedText(text)
			else
				local success, result = pcall(function()
					return TextService:FilterStringAsync(text, player.UserId)
				end)

				if success then
					responseType = ResponseType.Success
					filteredText = result:GetNonChatStringForBroadcastAsync()
					cachedFilteredText[text] = filteredText
				else
					responseType = ResponseType.Error
					filteredText = hashedText(text)
				end
			end
		end
	else
		responseType = ResponseType.Error
	end

	return responseType, filteredText
end

local RemoteFunctions = {
	[RemoteType.FetchFormData] = FetchFormData,
	[RemoteType.SubmitFormData] = SubmitFormData,
	[RemoteType.FilterText] = FilterText
}

FormRemote.OnServerInvoke = function (player, remoteType, data)
	local remoteFunction = RemoteFunctions[remoteType]
	if not remoteFunction then
		return
	end

	return remoteFunction(player, data)
end

-- DataStores

Players.PlayerRemoving:Connect(function (player)
	if not Config.AllowMultipleResponses then
		Utils.SavePlayerFormResponses(player)
	end
end)
