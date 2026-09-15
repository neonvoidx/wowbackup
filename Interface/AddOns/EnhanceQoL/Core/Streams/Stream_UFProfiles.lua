-- luacheck: globals EnhanceQoL MenuUtil MenuResponse UNKNOWN hooksecurefunc
local _, addon = ...
local L = addon.L

local stream
local profileHooked

local function getProfiles()
	return addon.Aura and addon.Aura.UF and addon.Aura.UF.Profiles
end

local function requestStreamUpdate()
	if addon.DataHub and stream then addon.DataHub:RequestUpdate(stream) end
end

local function ensureProfileHook()
	if profileHooked then return end
	local profiles = getProfiles()
	if not (profiles and profiles.SetActiveName and hooksecurefunc) then return end
	hooksecurefunc(profiles, "SetActiveName", requestStreamUpdate)
	profileHooked = true
end

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function updateUFProfile(streamObj)
	ensureProfileHook()
	local profiles = getProfiles()
	local activeName = profiles and profiles.GetActiveName and profiles.GetActiveName()
	streamObj.snapshot.fontSize = 14
	streamObj.snapshot.text = activeName or UNKNOWN or "Unknown"

	local title = L["UFProfileMenuTitle"] or "Unit Frames profile"
	local active = (L["UFProfileMenuActive"] or "Active: %s"):format(activeName or UNKNOWN or "Unknown")
	local clickHint = L["UFProfileDataPanelClickHint"] or "Left-click to switch Unit Frames profile"
	local optionsHint = getOptionsHint()
	if optionsHint then
		streamObj.snapshot.tooltip = title .. "\n" .. active .. "\n" .. clickHint .. "\n" .. optionsHint
	else
		streamObj.snapshot.tooltip = title .. "\n" .. active .. "\n" .. clickHint
	end
end

local function showUFProfileMenu(owner)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end
	ensureProfileHook()
	local profiles = getProfiles()
	if not (profiles and profiles.GetSortedNames and profiles.GetActiveName and profiles.SetActiveName) then return end
	local names = profiles.GetSortedNames() or {}
	local activeName = profiles.GetActiveName()

	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_UF_PROFILES")
		rootDescription:CreateTitle(L["UFProfileMenuTitle"] or "Unit Frames profile")

		if #names == 0 then
			local emptyButton = rootDescription:CreateButton(UNKNOWN or "Unknown")
			if emptyButton and emptyButton.SetEnabled then emptyButton:SetEnabled(false) end
			return
		end

		for _, profileName in ipairs(names) do
			rootDescription:CreateRadio(profileName, function()
				return (profiles.GetActiveName and profiles.GetActiveName()) == profileName
			end, function()
				if profileName == ((profiles.GetActiveName and profiles.GetActiveName()) or activeName) then return MenuResponse and MenuResponse.Close end
				local ok, reason = profiles.SetActiveName(profileName, "DATAPANEL_STREAM")
				if not ok then
					local msg = L["UFProfileSetActiveFailed"] or "Could not switch the active Unit Frames profile."
					if reason == "NOT_FOUND" then msg = L["UFProfileSetActiveMissing"] or "That Unit Frames profile does not exist." end
					print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
					return MenuResponse and MenuResponse.Close
				end
				return MenuResponse and MenuResponse.Close
			end)
		end
	end)
end

local provider = {
	id = "ufprofiles",
	version = 1,
	title = L["UFProfileMenuTitle"] or "Unit Frames profile",
	update = updateUFProfile,
	OnClick = function(button, btn)
		if btn == "LeftButton" then showUFProfileMenu(button) end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
