local GWTVersion, seasonActive, currentGladAchievementId, currentLegendAchievementId, currentBlitzAchievementId
local GWT_Button, SWT_Button, BWT_Button

local function normalizeBool(value, default)
	if value == true or value == "true" then
		return true
	end
	if value == false or value == "false" then
		return false
	end
	return default
end

local function initializeSavedVariables()
	GWT_HideButton = normalizeBool(GWT_HideButton, false)
	SWT_HideButton = normalizeBool(SWT_HideButton, false)
	BWT_HideButton = normalizeBool(BWT_HideButton, false)
	GWT_LoginIntro = normalizeBool(GWT_LoginIntro, true)
end

StaticPopupDialogs["GSBT_ALERT_POPUP"] = StaticPopupDialogs["GSBT_ALERT_POPUP"] or {
	text = "%s",
	button1 = OKAY,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	OnShow = function(self)
		local popupText = _G[self:GetName() .. "Text"]
		if popupText and GameFontHighlightLarge then
			local font, size, flags = GameFontHighlightLarge:GetFont()
			popupText:SetFont(font, size, flags)
		end
	end,
}

local function showAlertMessage(text)
	if not text then
		return
	end

	StaticPopup_Show("GSBT_ALERT_POPUP", text)
end

local function showNoActiveSeasonAlert()
	showAlertMessage("|cffffff00No active PVP season found.|r")
end

local function showIDMissingForSeasonAlert()
	showAlertMessage("|cffffff00Achievement missing for current season - please update addon.|r")
end

local function showAlreadyCompletedAlert()
	showAlertMessage("|cFF00FF00This character has already completed the achievement.|r")
end

local function shouldShowGladButton()
	return not GWT_HideButton
end

local function shouldShowShuffleButton()
	return not SWT_HideButton
end

local function shouldShowBlitzButton()
	return not BWT_HideButton
end

local function updateButtonsVisibility()
	local function setButtonVisibility(button, show)
		if not button then
			return
		end

		if show then
			button:Show()
		else
			button:Hide()
		end
	end

	setButtonVisibility(GWT_Button, shouldShowGladButton())
	setButtonVisibility(SWT_Button, shouldShowShuffleButton())
	setButtonVisibility(BWT_Button, shouldShowBlitzButton())
end

local function setCharGladSavedVariable(state)
	if state == "hide" then
		GWT_HideButton = true
	elseif state == "show" then
		GWT_HideButton = false
	elseif state == "reset" then
		GWT_HideButton = false
	end

	if GWT_Button then
		updateButtonsVisibility()
	end
end

local function setCharShuffleSavedVariable(state)
	if state == "hide" then
		SWT_HideButton = true
	elseif state == "show" then
		SWT_HideButton = false
	elseif state == "reset" then
		SWT_HideButton = false
	end

	if SWT_Button then
		updateButtonsVisibility()
	end
end

local function setCharBlitzSavedVariable(state)
	if state == "hide" then
		BWT_HideButton = true
	elseif state == "show" then
		BWT_HideButton = false
	elseif state == "reset" then
		BWT_HideButton = false
	end

	if BWT_Button then
		updateButtonsVisibility()
	end
end

local function setAccountSavedVariable(state)
	if state == "hide" then
		GWT_LoginIntro = false
	elseif state == "show" then
		GWT_LoginIntro = true
	end
end

local function setGWTVersion()
	local version = C_AddOns.GetAddOnMetadata("GladiatorShuffleBlitzWinsTracker", "Version")
	GWTVersion = version
end

local function setCurrentPVPSeasonAchievementIds()
	local currentPVPSeason = GetCurrentArenaSeason()

	seasonActive = currentPVPSeason ~= 0

	currentGladAchievementId = AchievementIDs.Gladiator[currentPVPSeason] or 0
	currentLegendAchievementId = AchievementIDs.ShuffleLegend[currentPVPSeason] or 0
	currentBlitzAchievementId = AchievementIDs.BlitzStrategist[currentPVPSeason] or 0
end

local function createButton(name, parentFrame, achievementId)
	local button = CreateFrame("Button", name, parentFrame, "UIPanelButtonTemplate")
	button:SetSize(25, 25)
	button:SetText(">")
	button:SetPoint("RIGHT", 10, 0)

	button:SetScript("OnClick", function()
		if not seasonActive then
			showNoActiveSeasonAlert()
		elseif achievementId == 0 then
			showIDMissingForSeasonAlert()
		else
			local id, _, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achievementId)
			if completed and wasEarnedByMe then
				showAlreadyCompletedAlert()
			else
				C_ContentTracking.ToggleTracking(2, achievementId, 2)
			end
		end
	end)

	return button
end

local function canCreateButtons()
	return ConquestFrame and ConquestFrame.Arena3v3 and ConquestFrame.RatedSoloShuffle and ConquestFrame.RatedBGBlitz
end

local function createButtons()
	if not canCreateButtons() then
		return false
	end

	GWT_Button = createButton("GWTButton", ConquestFrame.Arena3v3, currentGladAchievementId)
	SWT_Button = createButton("SWTButton", ConquestFrame.RatedSoloShuffle, currentLegendAchievementId)
	BWT_Button = createButton("BWTButton", ConquestFrame.RatedBGBlitz, currentBlitzAchievementId)

	return true
end

local function createOptionsPanel()
	local frame = CreateFrame("Frame", "GWTOptionsPanel", UIParent)
	frame.name = "Gladiator, Shuffle & Blitz Wins Tracker"

	local function newCheckbox(label, onClick)
		local check = CreateFrame("CheckButton", "GWTCheck" .. label, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetScript("OnClick", function(self)
			local tick = self:GetChecked()
			onClick(self, tick and true or false)
		end)
		check.label = _G[check:GetName() .. "Text"]
		check.label:SetText(label)
		return check
	end

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Gladiator, Shuffle & Blitz Wins Tracker")

	local charTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	charTitle:SetText("|cffffff00Character Specific Settings|r")
	charTitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

	local hideGladCheckbox = newCheckbox("Hide |cff33ff993v3|r button on this character", function(_, value)
		if value then
			setCharGladSavedVariable("hide")
		else
			setCharGladSavedVariable("show")
		end
	end)
	hideGladCheckbox:SetChecked(GWT_HideButton == true)
	hideGladCheckbox:SetPoint("TOPLEFT", charTitle, "BOTTOMLEFT", 20, -16)

	local hideShuffleCheckbox = newCheckbox("Hide |cff33ff99Shuffle|r button on this character", function(_, value)
		if value then
			setCharShuffleSavedVariable("hide")
		else
			setCharShuffleSavedVariable("show")
		end
	end)
	hideShuffleCheckbox:SetChecked(SWT_HideButton == true)
	hideShuffleCheckbox:SetPoint("TOPLEFT", hideGladCheckbox, "BOTTOMLEFT", 0, -8)

	local hideBlitzCheckbox = newCheckbox("Hide |cff33ff99Blitz|r button on this character", function(_, value)
		if value then
			setCharBlitzSavedVariable("hide")
		else
			setCharBlitzSavedVariable("show")
		end
	end)
	hideBlitzCheckbox:SetChecked(BWT_HideButton == true)
	hideBlitzCheckbox:SetPoint("TOPLEFT", hideShuffleCheckbox, "BOTTOMLEFT", 0, -8)

	local resetButton = CreateFrame("Button", "GTWResetButton", frame, "UIPanelButtonTemplate")
	resetButton:SetText("Reset")
	resetButton:SetWidth(90)
	resetButton:SetHeight(30)
	resetButton:SetPoint("TOPLEFT", hideBlitzCheckbox, "BOTTOMLEFT", -20, -15)
	resetButton:SetScript("OnClick", function()
		setCharGladSavedVariable("reset")
		setCharShuffleSavedVariable("reset")
		setCharBlitzSavedVariable("reset")

		hideGladCheckbox:SetChecked(GWT_HideButton == true)
		hideShuffleCheckbox:SetChecked(SWT_HideButton == true)
		hideBlitzCheckbox:SetChecked(BWT_HideButton == true)
	end)

	local accountSettingsTitle = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	accountSettingsTitle:SetText("|cffffff00Account Settings|r")
	accountSettingsTitle:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", -2, -16)

	local hideIntroCheckbox = newCheckbox("Disable login message", function(_, value)
		if value then
			setAccountSavedVariable("hide")
		else
			setAccountSavedVariable("show")
		end
	end)
	hideIntroCheckbox:SetChecked(not GWT_LoginIntro)
	hideIntroCheckbox:SetPoint("TOPLEFT", accountSettingsTitle, "TOPLEFT", 20, -25)

	local versionText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	versionText:SetText("|cffffff00Version:|r |cffffffff" .. (GWTVersion or "Unknown") .. "|r")
	versionText:SetJustifyH("RIGHT")
	versionText:SetSize(600, 40)
	versionText:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -5)

	local authorText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	authorText:SetText("|cffffff00Author:|r |cffffffffDezopri|r")
	authorText:SetJustifyH("RIGHT")
	authorText:SetSize(600, 40)
	authorText:SetPoint("TOPLEFT", versionText, "TOPLEFT", 0, -20)

	return frame
end

local function registerOptionsPanel()
	local optionsPanel = createOptionsPanel()

	local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, "Gladiator, Shuffle & Blitz Wins Tracker")
	Settings.RegisterAddOnCategory(category)

	SLASH_GSBT1 = "/gsbt"
	SlashCmdList["GSBT"] = function()
		Settings.OpenToCategory(category.ID)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "GladiatorShuffleBlitzWinsTracker" then
		initializeSavedVariables()
		setGWTVersion()
		registerOptionsPanel()
	end

	if event == "ADDON_LOADED" and arg1 == "Blizzard_PVPUI" then
		if createButtons() then
			updateButtonsVisibility()
		end
	end

	if event == "PLAYER_LOGIN" then
		setCurrentPVPSeasonAchievementIds()

		if GWT_LoginIntro then
			print("|cff33ff99Gladiator, Shuffle & Blitz Wins Tracker|r - use |cffFF4500 /gsbt |r to open options")
		end
	end
end)
