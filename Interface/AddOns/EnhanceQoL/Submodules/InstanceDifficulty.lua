-- luacheck: globals MinimapCluster C_DelvesUI C_GossipInfo C_UIWidgetManager C_Timer Minimap
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local InstanceDifficulty = addon.InstanceDifficulty or {}
addon.InstanceDifficulty = InstanceDifficulty
InstanceDifficulty.enabled = InstanceDifficulty.enabled or false

InstanceDifficulty.frame = InstanceDifficulty.frame or CreateFrame("Frame")

local function getIndicator() return MinimapCluster and MinimapCluster.InstanceDifficulty end
local validAnchors = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local function normalizeAnchor(anchor)
	if type(anchor) == "string" then
		anchor = string.upper(anchor)
		if validAnchors[anchor] then return anchor end
	end
	return "CENTER"
end

local function resolveAnchorTarget(indicator, anchor)
	if anchor ~= "CENTER" and Minimap then return Minimap, anchor end
	return indicator, "CENTER"
end

local function defaultFontFace()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
end

function InstanceDifficulty:EnsureText()
	local indicator = getIndicator()
	if not indicator then return nil end
	if not self.text or self.text:GetParent() ~= indicator then
		self.text = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.text:Hide()
	end
	return self.text
end

function InstanceDifficulty:ApplyTextStyle()
	if not self:EnsureText() then return end
	local fontSize = (addon.db and addon.db["instanceDifficultyFontSize"]) or 14
	local font = defaultFontFace()
	local ok = self.text:SetFont(font, fontSize, "OUTLINE")
	if ok == false then self.text:SetFont((addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT, fontSize, "OUTLINE") end
end

function InstanceDifficulty:DeferredUpdate()
	if self.deferredUpdate then return end
	self.deferredUpdate = true
	C_Timer.After(0.25, function()
		self.deferredUpdate = nil
		self:Update()
	end)
end

local nmNames = {
	[RAID_DIFFICULTY1] = true,
	[RAID_DIFFICULTY2] = true,
	[RAID_DIFFICULTY_10PLAYER] = true,
	[RAID_DIFFICULTY_20PLAYER] = true,
	[RAID_DIFFICULTY_25PLAYER] = true,
	[RAID_DIFFICULTY_40PLAYER] = true,
}

local hcNames = {
	[RAID_DIFFICULTY3] = true,
	[RAID_DIFFICULTY4] = true,
	[RAID_DIFFICULTY_10PLAYER_HEROIC] = true,
	[RAID_DIFFICULTY_25PLAYER_HEROIC] = true,
}

local function hasDelveGossipTierAPI()
	return C_GossipInfo and C_GossipInfo.GetActiveDelveGossip
end

local DELVE_SCENARIO_HEADER_WIDGET_IDS = { 6183, 6184, 6185 }
local DELVE_SCENARIO_HEADER_WIDGET_ID_LOOKUP = {
	[6183] = true,
	[6184] = true,
	[6185] = true,
}

local function hasActiveDelve()
	if not (C_DelvesUI and C_DelvesUI.HasActiveDelve) then return false end
	local _, _, _, mapID = UnitPosition("player")
	if not mapID then return false end
	return C_DelvesUI.HasActiveDelve(mapID)
end

local function getActiveDelveGossipTierText()
	-- Removed on 12.0.5. Keep the old path guarded so the tier display starts working again if Blizzard restores it.
	if not (C_DelvesUI and hasDelveGossipTierAPI()) then return nil end
	if not hasActiveDelve() then return nil end

	local gossipInfo = C_GossipInfo.GetActiveDelveGossip()
	local orderIndex = gossipInfo and gossipInfo.orderIndex
	if type(orderIndex) == "number" and orderIndex >= 0 then return tostring(orderIndex + 1) end

	return nil
end

local function getActiveDelveWidgetTierText()
	if not (C_UIWidgetManager and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo) then return nil end
	if not hasActiveDelve() then return nil end

	for _, widgetID in ipairs(DELVE_SCENARIO_HEADER_WIDGET_IDS) do
		local widgetInfo = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(widgetID)
		if widgetInfo and widgetInfo.shownState ~= 0 then
			local tierText = widgetInfo.tierText
			if type(tierText) == "number" then tierText = tostring(tierText) end
			if type(tierText) == "string" then
				tierText = tierText:gsub("^%s+", ""):gsub("%s+$", "")
				if tierText ~= "" then return tierText end
			end
		end
	end

	return nil
end

local function getActiveDelveTierText()
	local tierText = getActiveDelveGossipTierText()
	if tierText then return tierText end
	if hasDelveGossipTierAPI() then return nil end
	return getActiveDelveWidgetTierText()
end

local function getShortLabel(difficultyID, difficultyName)
	if difficultyID == 1 or difficultyID == 3 or difficultyID == 4 or difficultyID == 14 or difficultyID == 33 or difficultyID == 150 or nmNames[difficultyName] or difficultyID == 12 then
		return "NM"
	elseif difficultyID == 2 or difficultyID == 5 or difficultyID == 6 or difficultyID == 15 or difficultyID == 205 or difficultyID == 230 or hcNames[difficultyName] or difficultyID == 13 then
		return "HC"
	elseif difficultyID == 16 or difficultyID == 23 then
		return "M"
	elseif difficultyID == 8 then
		local level = C_ChallengeMode.GetActiveKeystoneInfo()
		if level and type(level) == "number" and level > 0 then return "M+" .. level end
		return "M+"
	elseif difficultyID == 7 or difficultyID == 17 or difficultyID == 151 then
		return "LFR"
	elseif difficultyID == 24 then
		return "TW"
	elseif difficultyID == 208 then
		local tierText = getActiveDelveTierText()
		if tierText then return "D" .. tierText end
		return "D"
	end
	return difficultyName
end

function InstanceDifficulty:Update()
	local indicator = getIndicator()
	if not self.enabled or not addon.db or not indicator then return end
	if not self:EnsureText() then return end
	if not IsInInstance() then
		self.text:Hide()
		return
	end

	local _, _, difficultyID, difficultyName, _, _, _, _, instanceGroupSize = GetInstanceInfo()
	local short = getShortLabel(difficultyID, difficultyName)
	-- Stable code for color mapping
	local code
	if difficultyID == 1 or difficultyID == 3 or difficultyID == 4 or difficultyID == 14 or difficultyID == 33 or difficultyID == 150 or nmNames[difficultyName] then
		code = "NM"
	elseif difficultyID == 2 or difficultyID == 5 or difficultyID == 6 or difficultyID == 15 or difficultyID == 205 or difficultyID == 230 or hcNames[difficultyName] then
		code = "HC"
	elseif difficultyID == 16 or difficultyID == 23 then
		code = "M"
	elseif difficultyID == 8 then
		code = "MPLUS"
	elseif difficultyID == 7 or difficultyID == 17 or difficultyID == 151 then
		code = "LFR"
	elseif difficultyID == 24 then
		code = "TW"
	end

	local text
	if difficultyID == 208 and not hasDelveGossipTierAPI() then
		text = short
	elseif instanceGroupSize and instanceGroupSize > 0 then
		text = string.format("%d (%s)", instanceGroupSize, short)
	else
		text = short
	end
	local anchor = normalizeAnchor(addon.db and addon.db["instanceDifficultyAnchor"])
	local offX = (addon.db and addon.db["instanceDifficultyOffsetX"]) or 0
	local offY = (addon.db and addon.db["instanceDifficultyOffsetY"]) or 0
	local anchorTarget, relativePoint = resolveAnchorTarget(indicator, anchor)
	self.text:ClearAllPoints()
	self.text:SetPoint(anchor, anchorTarget, relativePoint, offX, offY)

	self.text:SetText(text)
	self:ApplyTextStyle()
	-- Apply optional difficulty colors
	if addon.db and addon.db["instanceDifficultyUseColors"] then
		local colors = addon.db["instanceDifficultyColors"] or {}
		local c = (code and colors[code]) or { r = 1, g = 1, b = 1 }
		self.text:SetTextColor(c.r or 1, c.g or 1, c.b or 1)
	else
		self.text:SetTextColor(1, 1, 1)
	end
	self.text:Show()
end

function InstanceDifficulty:ApplyIndicatorOverride(enabled)
	local indicator = getIndicator()
	if not indicator then return end
	indicator:SetAlpha(1)
	for _, key in ipairs({ "Default", "ChallengeMode", "Guild" }) do
		local child = indicator[key]
		if child then
			if enabled then
				child:Hide()
				child:SetScript("OnShow", child.Hide)
			else
				if child:GetScript("OnShow") == child.Hide then child:SetScript("OnShow", nil) end
			end
		end
	end
	if enabled and not self._indicatorOnShowHooked then
		self._indicatorOnShowHooked = true
		indicator:HookScript("OnShow", function() InstanceDifficulty:Update() end)
	end
end

function InstanceDifficulty:SetEnabled(value)
	self.enabled = value
	if value then
		self:ApplyIndicatorOverride(true)
		self:EnsureText()
		self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
		self.frame:RegisterEvent("GROUP_ROSTER_UPDATE")
		self.frame:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
		self.frame:RegisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:RegisterEvent("CHALLENGE_MODE_START")
		self.frame:RegisterEvent("ACTIVE_DELVE_DATA_UPDATE")
		self:Update()
	else
		self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		self.frame:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED")
		self.frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
		self.frame:UnregisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
		self.frame:UnregisterEvent("UPDATE_INSTANCE_INFO")
		self.frame:UnregisterEvent("CHALLENGE_MODE_START")
		self.frame:UnregisterEvent("ACTIVE_DELVE_DATA_UPDATE")
		if self.text then self.text:Hide() end
		self:ApplyIndicatorOverride(false)
		local indicator = getIndicator()
		if indicator then
			indicator:Show()
			local miniMapInstanceDifficultyUpdate = _G.MiniMapInstanceDifficulty_Update
			if miniMapInstanceDifficultyUpdate then
				pcall(miniMapInstanceDifficultyUpdate)
			elseif indicator.Default then
				indicator.Default:Show()
			elseif indicator.ChallengeMode then
				indicator.ChallengeMode:Show()
			elseif indicator.Guild then
				indicator.Guild:Show()
			end
		end
	end
end

InstanceDifficulty.frame:SetScript("OnEvent", function()
	InstanceDifficulty:DeferredUpdate()
end)
