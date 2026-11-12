local addon = _G.EnhanceQoL
if not (addon and addon.variables and addon.variables.isForever) then return end

local UF = addon.Aura and addon.Aura.UF
if not UF then return end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local P = {}
UF.PetIndicators = P
P.defaults = {
	petHappiness = { enabled = false, style = "ICON", colorHealthBar = false, size = 18, x = -4, y = 0 },
	petExperience = { enabled = false, height = 6, y = -4, showText = false },
}
P.happinessColors = {
	{ 0.9, 0.18, 0.18, 1 },
	{ 0.95, 0.75, 0.18, 1 },
	{ 0.45, 0.72, 0.28, 1 },
}
P.happinessCoordinates = {
	{ 0.375, 0.5625, 0, 0.359375 },
	{ 0.1875, 0.375, 0, 0.359375 },
	{ 0, 0.1875, 0, 0.359375 },
}

function P.IsHunter() return select(2, UnitClass("player")) == "HUNTER" end

function P.IsPreview()
	return addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() == true
end

function P.GetHealthColor()
	if not (P.cfg and P.cfg.enabled and (P.IsHunter() or P.IsPreview()) and P.GetOption("petHappiness", "colorHealthBar") == true) then return nil end
	local level = P.currentHappiness
	if P.IsPreview() then level = 3 end
	local color = P.happinessColors[level]
	if color then return color[1], color[2], color[3], color[4] end
	return nil
end

function P.GetOption(section, key)
	local cfg = P.cfg and P.cfg[section]
	local value
	if type(cfg) == "table" then value = cfg[key] end
	if value == nil then value = P.defaults[section][key] end
	return value
end

function P.HideTooltip(frame)
	if GameTooltip and GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end

function P.SetVisible(frame, visible)
	if not frame then return end
	frame._eqolPetIndicatorVisible = visible == true
	-- These overlays follow the secure pet frame's visibility through parenting.
	-- Runtime updates only change alpha, never protected visibility or geometry.
	frame:SetAlpha(visible and 1 or 0)
	if not visible then P.HideTooltip(frame) end
end

function P.ShowHappinessTooltip(frame)
	if not (frame._eqolPetIndicatorVisible and GameTooltip and not GameTooltip:IsForbidden()) then return end
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G["PET_HAPPINESS" .. (frame.happiness or 3)] or _G.NONE)
	if frame.damagePercentage then GameTooltip:AddLine(string.format(_G.PET_DAMAGE_PERCENTAGE, frame.damagePercentage), 1, 1, 1) end
	if frame.loyaltyRate and frame.loyaltyRate ~= 0 then GameTooltip:AddLine(frame.loyaltyRate < 0 and _G.LOSING_LOYALTY or _G.GAINING_LOYALTY, 1, 1, 1) end
	if not frame.sample and _G.C_PetInfo and _G.C_PetInfo.GetPetFoodTypes then
		local diet = _G.C_PetInfo.GetPetFoodTypes()
		if type(diet) == "table" then GameTooltip:AddLine(string.format(_G.PET_DIET_TEMPLATE, #diet > 0 and table.concat(diet, _G.PET_FOOD_DELIMIT) or _G.NONE), 1, 1, 1) end
	end
	GameTooltip:Show()
end

function P.ShowExperienceTooltip(frame)
	if not (frame._eqolPetIndicatorVisible and GameTooltip and not GameTooltip:IsForbidden()) then return end
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
	GameTooltip:SetText(L["UFPetExperience"])
	GameTooltip:AddLine(string.format(_G.XP_STATUS_BAR_TEXT, frame.experience, frame.requiredExperience), 1, 1, 1)
	GameTooltip:Show()
end

function P.CreateOverlay(kind, parent, onEnter)
	local frame = CreateFrame(kind, nil, parent)
	frame:SetAlpha(0)
	frame:SetFrameLevel(parent:GetFrameLevel() + 8)
	frame:EnableMouse(true)
	frame:SetMouseClickEnabled(false)
	frame:SetMouseMotionEnabled(true)
	frame:SetScript("OnEnter", onEnter)
	frame:SetScript("OnLeave", P.HideTooltip)
	return frame
end

function P.EnsureFrames()
	local st = P.state
	if not (st and st.frame) or InCombatLockdown() then return end
	if not st.petHappiness then
		st.petHappiness = P.CreateOverlay("Frame", st.frame, P.ShowHappinessTooltip)
		st.petHappiness.icon = st.petHappiness:CreateTexture(nil, "ARTWORK")
		st.petHappiness.icon:SetAllPoints()
		st.petHappiness.icon:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
	end
	if not st.petExperience then
		st.petExperience = P.CreateOverlay("StatusBar", st.frame, P.ShowExperienceTooltip)
		st.petExperience:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		st.petExperience:SetStatusBarColor(0.55, 0.2, 0.85, 1)
		st.petExperience.background = st.petExperience:CreateTexture(nil, "BACKGROUND")
		st.petExperience.background:SetAllPoints()
		st.petExperience.background:SetColorTexture(0.08, 0.08, 0.08, 0.9)
		st.petExperience.text = st.petExperience:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		st.petExperience.text:SetPoint("CENTER")
	end
	if not st._eqolPetIndicatorsShowHook then
		st._eqolPetIndicatorsShowHook = true
		st.frame:HookScript("OnShow", function() if P.state == st then P.Refresh() end end)
	end
end

function P.Layout()
	local st = P.state
	if not (st and st.frame) or InCombatLockdown() then return end
	P.EnsureFrames()
	local anchor = st.barGroup or st.frame
	st.petHappiness:ClearAllPoints()
	st.petHappiness:SetPoint("RIGHT", anchor, "LEFT", P.GetOption("petHappiness", "x"), P.GetOption("petHappiness", "y"))
	local size = math.max(8, math.min(64, tonumber(P.GetOption("petHappiness", "size")) or 18))
	st.petHappiness:SetSize(size, size)
	st.petExperience:ClearAllPoints()
	st.petExperience:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, P.GetOption("petExperience", "y"))
	st.petExperience:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, P.GetOption("petExperience", "y"))
	st.petExperience:SetHeight(math.max(2, math.min(30, tonumber(P.GetOption("petExperience", "height")) or 6)))
end

function P.UpdateHappinessIcon(icon, happiness)
	local style = P.GetOption("petHappiness", "style")
	if style == "DOT" or style == "SQUARE" then
		icon:SetTexture(style == "DOT" and "Interface\\AddOns\\EnhanceQoL\\Assets\\Mouse\\CircleFill.tga" or "Interface\\Buttons\\WHITE8x8")
		icon:SetTexCoord(0, 1, 0, 1)
		icon:SetVertexColor(unpack(P.happinessColors[happiness]))
	else
		icon:SetTexture("Interface\\PetPaperDollFrame\\UI-PetHappiness")
		icon:SetTexCoord(unpack(P.happinessCoordinates[happiness]))
		icon:SetVertexColor(1, 1, 1, 1)
	end
end

function P.Refresh()
	local st = P.state
	if not st then return end
	local enabled = P.cfg and P.cfg.enabled == true
	local sample = enabled and P.IsPreview()
	local _, hunterPet = HasPetUI()
	local hasPet = enabled and P.IsHunter() and UnitExists("pet") and hunterPet == true
	local showHappiness = enabled and P.GetOption("petHappiness", "enabled") == true and (hasPet or sample)
	local colorHealthBar = enabled and (P.IsHunter() or sample) and P.GetOption("petHappiness", "colorHealthBar") == true
	local happiness, damagePercentage, loyaltyRate
	if showHappiness or (colorHealthBar and (hasPet or sample)) then
		if sample then
			happiness, damagePercentage, loyaltyRate = 3, 125, 1
		elseif _G.C_PetInfo and _G.C_PetInfo.GetPetHappiness then
			happiness, damagePercentage, loyaltyRate = _G.C_PetInfo.GetPetHappiness()
		end
	end
	local previousHappiness = P.currentHappiness
	local previousColorEnabled = P.healthColorEnabled
	P.currentHappiness = colorHealthBar and (hasPet or sample) and happiness or nil
	P.healthColorEnabled = colorHealthBar
	if (previousHappiness ~= P.currentHappiness or previousColorEnabled ~= colorHealthBar) and UF.RefreshPetHappinessHealthColor then
		UF.RefreshPetHappinessHealthColor()
	end
	local coordinates = happiness and P.happinessCoordinates[happiness]
	if st.petHappiness and coordinates then
		st.petHappiness.happiness = happiness
		st.petHappiness.damagePercentage = damagePercentage
		st.petHappiness.loyaltyRate = loyaltyRate
		st.petHappiness.sample = sample
		P.UpdateHappinessIcon(st.petHappiness.icon, happiness)
	end
	P.SetVisible(st.petHappiness, showHappiness and coordinates ~= nil)
	local showExperience = enabled and P.GetOption("petExperience", "enabled") == true and (hasPet or sample)
	local experience, required
	if showExperience then
		if sample then
			experience, required = 450, 1000
		elseif _G.GetPetExperience then
			experience, required = _G.GetPetExperience()
		end
	end
	-- Match the pet paper doll: only a positive XP requirement represents a bar.
	showExperience = showExperience and type(experience) == "number" and type(required) == "number" and required > 0
	if showExperience and st.petExperience then
		st.petExperience.experience, st.petExperience.requiredExperience = experience, required
		st.petExperience:SetMinMaxValues(0, required)
		st.petExperience:SetValue(experience)
		st.petExperience.text:SetText(P.GetOption("petExperience", "showText") == true and string.format(_G.XP_STATUS_BAR_TEXT, experience, required) or "")
	end
	P.SetVisible(st.petExperience, showExperience)
	if st.petHappiness and st.petHappiness._eqolPetIndicatorVisible and GameTooltip and GameTooltip:IsOwned(st.petHappiness) then P.ShowHappinessTooltip(st.petHappiness) end
	if st.petExperience and st.petExperience._eqolPetIndicatorVisible and GameTooltip and GameTooltip:IsOwned(st.petExperience) then P.ShowExperienceTooltip(st.petExperience) end
end

function P.OnEvent(_, event, unit)
	if event == "PLAYER_REGEN_ENABLED" then
		P.Apply(P.cfg, P.state)
		return
	end
	if event == "UNIT_PET" and unit ~= "player" then return end
	if (event == "UNIT_HAPPINESS" or event == "UNIT_PET_EXPERIENCE" or event == "UNIT_LEVEL") and unit ~= "pet" and unit ~= "player" then return end
	P.Refresh()
end

function P.Apply(cfg, st)
	if P.state and P.state ~= st then
		P.SetVisible(P.state.petHappiness, false)
		P.SetVisible(P.state.petExperience, false)
	end
	P.cfg, P.state = cfg, st
	local enabled = cfg and cfg.enabled == true
	local hunter = enabled and P.IsHunter()
	local sample = enabled and P.IsPreview()
	local happinessEnabled = enabled and (P.GetOption("petHappiness", "enabled") == true or P.GetOption("petHappiness", "colorHealthBar") == true)
	local experienceEnabled = enabled and P.GetOption("petExperience", "enabled") == true
	if P.listener then P.listener:UnregisterAllEvents() end
	if (happinessEnabled or experienceEnabled) and (hunter or sample) and st and st.frame then
		if not P.listener then
			P.listener = CreateFrame("Frame")
			P.listener:SetScript("OnEvent", P.OnEvent)
		end
		if hunter then
			P.listener:RegisterEvent("PLAYER_ENTERING_WORLD")
			P.listener:RegisterUnitEvent("UNIT_PET", "player")
			P.listener:RegisterEvent("PET_UI_UPDATE")
			if happinessEnabled then P.listener:RegisterUnitEvent("UNIT_HAPPINESS", "pet", "player") end
			if experienceEnabled then
				P.listener:RegisterUnitEvent("UNIT_PET_EXPERIENCE", "pet", "player")
				P.listener:RegisterUnitEvent("UNIT_LEVEL", "pet", "player")
			end
		end
		if InCombatLockdown() then
			P.listener:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			P.Layout()
		end
	end
	P.Refresh()
end

function P.AppendSettings(list, context)
	local function get(section, key)
		local cfg = UF.GetConfig("pet")
		local value
		if type(cfg[section]) == "table" then value = cfg[section][key] end
		if value == nil then value = P.defaults[section][key] end
		return value
	end
	local function set(section, key, value)
		local cfg = UF.GetConfig("pet")
		if type(cfg[section]) ~= "table" then cfg[section] = {} end
		cfg[section][key] = value
		context.refresh()
	end
	local function slider(section, key, label, minimum, maximum)
		local entry = context.slider(label, minimum, maximum, 1, function() return get(section, key) end, function(value) set(section, key, value) end, P.defaults[section][key], section, true)
		entry.isEnabled = function() return get(section, "enabled") == true end
		list[#list + 1] = entry
	end
	for _, section in ipairs({ { "petHappiness", "UFPetHappiness", "UFPetHappinessEnable" }, { "petExperience", "UFPetExperience", "UFPetExperienceEnable" } }) do
		local key = section[1]
		list[#list + 1] = { name = L[section[2]], kind = UF.ui.settingType.Collapsible, id = key, defaultCollapsed = true }
		list[#list + 1] = context.checkbox(L[section[3]], function() return get(key, "enabled") == true end, function(value)
			set(key, "enabled", value == true)
			if context.refreshSettings then context.refreshSettings() end
		end, false, key)
		if key == "petHappiness" then
			list[#list + 1] = context.checkbox(L["UFPetHappinessHealthColor"], function() return get("petHappiness", "colorHealthBar") == true end, function(value)
				set("petHappiness", "colorHealthBar", value == true)
			end, false, "petHappiness")
			slider("petHappiness", "size", L["Icon size"], 8, 64)
			slider("petHappiness", "x", L["X Offset"], -3000, 3000)
			slider("petHappiness", "y", L["Y Offset"], -3000, 3000)
			local style = context.dropdown(L["Style"], {
				{ value = "ICON", label = L["Icon"] },
				{ value = "DOT", label = L["UFPetHappinessStyleDot"] },
				{ value = "SQUARE", label = L["Square"] },
			}, function() return get("petHappiness", "style") end, function(value) set("petHappiness", "style", value) end, P.defaults.petHappiness.style, "petHappiness")
			style.navigationField = "petHappiness.style"
			style.navigationDefaultVerified = true
			style.isEnabled = function() return get("petHappiness", "enabled") == true end
			list[#list + 1] = style
		else
			slider("petExperience", "height", L["Bar height"], 2, 30)
			slider("petExperience", "y", L["Y Offset"], -3000, 3000)
			list[#list + 1] = context.checkbox(L["UFPetExperienceShowText"], function() return get("petExperience", "showText") == true end, function(value) set("petExperience", "showText", value == true) end, false, "petExperience", function() return get("petExperience", "enabled") == true end)
		end
	end
end
