local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local DevMode = {
	cvars = {
		"addonChatRestrictionsForced",
		"addonChallengeModeRestrictionsForced",
		"addonCombatRestrictionsForced",
		"addonEncounterRestrictionsForced",
		"addonMapRestrictionsForced",
		"addonPvPMatchRestrictionsForced",
	},
}

local frame = CreateFrame("Button", "EQOLDevModeIndicator", UIParent)
frame:SetSize(560, 96)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -12)
frame:SetFrameStrata("TOOLTIP")
frame:RegisterForClicks("LeftButtonUp")
frame.background = frame:CreateTexture(nil, "BACKGROUND")
frame.background:SetAllPoints()
frame.background:SetColorTexture(0, 0, 0, 1)
frame.accent = frame:CreateTexture(nil, "ARTWORK")
frame.accent:SetPoint("TOPLEFT")
frame.accent:SetPoint("BOTTOMLEFT")
frame.accent:SetWidth(4)
frame.accent:SetColorTexture(1, 0.3, 0.1, 1)
frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetSize(64, 64)
frame.icon:SetPoint("LEFT", 16, 0)
frame.icon:SetTexture("Interface\\AddOns\\EnhanceQoL\\Icons\\Icon.tga")
frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.text:SetPoint("TOPLEFT", 96, -10)
frame.text:SetSize(448, 48)
frame.text:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
frame.text:SetJustifyH("LEFT")
frame.text:SetJustifyV("MIDDLE")
frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.hint:SetPoint("TOPLEFT", frame.text, "BOTTOMLEFT", 0, -5)
frame.hint:SetSize(448, 24)
frame.hint:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
frame.hint:SetJustifyH("LEFT")
frame.hint:SetText(L["devModeClickToDisable"])
frame:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
frame:GetHighlightTexture():SetVertexColor(1, 0.5, 0.1, 0.15)
frame:Hide()

function DevMode:GetState()
	local enabled = 0
	for _, name in ipairs(self.cvars) do
		local value = C_CVar.GetCVar(name)
		if value == nil then return "devModeUnavailable" end
		if value == "1" then enabled = enabled + 1 end
	end
	if enabled == #self.cvars then return "devModeActive" end
	if enabled == 0 then return "devModeInactive" end
	return "devModeMixed"
end

function DevMode:Refresh()
	local state = self:GetState()
	frame.text:SetText(L[state])
	frame.text:SetTextColor(1, 0.3, 0.1)
	frame:SetShown(state == "devModeActive" or state == "devModeMixed")
	return state
end

function DevMode:SetEnabled(enabled)
	if self:GetState() ~= "devModeUnavailable" then
		local value = enabled and "1" or "0"
		for _, name in ipairs(DevMode.cvars) do
			-- Keep the final status truthful if the client rejects a CVar write.
			pcall(C_CVar.SetCVar, name, value)
		end
	end
	print("EnhanceQoL: " .. L[DevMode:Refresh()])
end

function addon.functions.ToggleDevMode()
	DevMode:SetEnabled(DevMode:GetState() ~= "devModeActive")
end

frame:SetScript("OnClick", function() DevMode:SetEnabled(false) end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CVAR_UPDATE")
frame:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		DevMode:Refresh()
		return
	end
	for _, cvar in ipairs(DevMode.cvars) do
		if name and name:lower() == cvar:lower() then
			DevMode:Refresh()
			return
		end
	end
end)
