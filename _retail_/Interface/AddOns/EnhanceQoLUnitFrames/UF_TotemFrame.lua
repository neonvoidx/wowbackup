local addon = _G.EnhanceQoL
addon.Aura = addon.Aura or {}
addon.Aura.UF = addon.Aura.UF or {}
local M = { buttons = {}, visuals = {} }
M.events = CreateFrame("Frame")
addon.Aura.UF.OwnTotemFrame = M

-- Click targets retain their slot identities. Geometry remains fixed in combat;
-- inactive slots are packed after active slots once protected layout is allowed.
function M.InCombat() return InCombatLockdown and InCombatLockdown() end

function M.Ensure()
	if M.frame then return end
	M.frame = CreateFrame("Frame", nil, UIParent)
	M.frame:SetFrameStrata("MEDIUM")
end

M.events:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_ENABLED" then
			if M.pendingDisable then M.Disable() elseif M.config then M.Apply(M.config, M.defaults, M.parent, M.preview) end
		elseif M.enabled then M.Update() end
end)

function M.CreateSlot(slot)
	local button = CreateFrame("Button", nil, M.frame, "SecureActionButtonTemplate")
	button:RegisterForClicks("AnyDown", "AnyUp")
	button:SetAttribute("type2", "destroytotem")
	button:SetAttribute("totem-slot", slot)
	button:SetScript("OnEnter", function(self)
		if not M.enabled then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetTotem(slot)
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local visual = CreateFrame("Frame", nil, M.frame)
	visual:SetFrameLevel(M.frame:GetFrameLevel() + 1)
	button:SetFrameLevel(visual:GetFrameLevel() + 4)
	visual:EnableMouse(false)
	visual.border = CreateFrame("Frame", nil, visual)
	visual.border:SetAllPoints()
	visual.border:EnableMouse(false)
	visual.icon = visual:CreateTexture(nil, "ARTWORK")
	visual.icon:SetAllPoints()
	visual.cooldown = CreateFrame("Cooldown", nil, visual, "CooldownFrameTemplate")
	visual.cooldown:SetAllPoints()
	visual.cooldown:SetFrameLevel(visual:GetFrameLevel() + 1)
	visual.border:SetFrameLevel(visual:GetFrameLevel() + 2)
	visual.cooldown:EnableMouse(false)
	visual.cooldown:SetDrawEdge(false)
	visual.cooldown:SetDrawBling(false)
	visual.cooldown:SetReverse(true)
	visual.textOverlay = CreateFrame("Frame", nil, visual)
	visual.textOverlay:SetAllPoints()
	visual.textOverlay:SetFrameLevel(visual:GetFrameLevel() + 3)
	visual.textOverlay:EnableMouse(false)
	visual.name = visual.textOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	visual.name:SetPoint("TOP", visual, "BOTTOM", 0, -2)
	M.buttons[slot], M.visuals[slot] = button, visual
end

function M.Value(key, fallback)
	local value = M.config and M.config[key]
	if value == nil then value = M.defaults and M.defaults[key] end
	if value == nil then value = fallback end
	return value
end

function M.Color(prefix, fallback)
	local custom = M.Value(prefix .. "Color", fallback)
	local r, g, b, a = custom[1], custom[2], custom[3], custom[4]
	if a == nil then a = fallback[4] end
	if M.Value(prefix .. "UseClassColor", false) then
		local class = addon.variables and addon.variables.unitClass
		if not class and UnitClass then class = select(2, UnitClass("player")) end
		local classColor = class and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class)
		if not classColor then classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] end
		if classColor then r, g, b = classColor.r, classColor.g, classColor.b end
	end
	return { r, g, b, a }
end

function M.StyleBorder(visual)
	local shapes, functions = addon.IconShape, addon.functions
	local owner = visual.border
	local selected = M.Value("iconShape", "SQUARE")
	local enabled = M.Value("borderEnabled", false)
	local key = M.Value("borderTexture", "DEFAULT")
	local color = M.Color("border", { 0, 0, 0, 1 })
	local size = M.Value("borderSize", 1)
	local offset = M.Value("borderOffset", 0)
	owner:ClearAllPoints()
	owner:SetPoint("TOPLEFT", visual, "TOPLEFT", -offset, offset)
	owner:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", offset, -offset)
	if shapes then shapes.HideBorderTextures(owner) end
	-- The safe square border and shaped texture borders share only their
	-- dedicated owner; clear both representations before switching shapes.
	if functions and functions.SetSafeBorder then
		functions.SetSafeBorder(owner, false, nil, size, color[1], color[2], color[3], color[4], { stateKey = "ownTotem", defaultTexture = "Interface\\Buttons\\WHITE8x8" })
	end
	if not enabled or (shapes and shapes.IsNoBorder(key)) then return end
	if shapes and not shapes.IsBackdropBorderCompatible(selected) then
		local fallback = shapes.GetFirstBorderForShape(selected)
		if shapes.IsBorderCompatible(shapes.BORDER.ROUND_1PX, selected) then fallback = shapes.BORDER.ROUND_1PX end
		key = shapes.NormalizeBorder(key, fallback, selected)
		if shapes.ApplyBorder(owner, key, selected, { borderSize = size, borderOffset = offset, color = color, pointFrame = visual }) then owner:Show() end
	elseif functions and functions.SetSafeBorder then
		if shapes then key = shapes.NormalizeBorder(key, "DEFAULT", selected) end
		functions.SetSafeBorder(owner, true, key, size, color[1], color[2], color[3], color[4], { stateKey = "ownTotem", defaultTexture = "Interface\\Buttons\\WHITE8x8", mediaType = "border" })
	end
end

function M.TextValue(key, legacyKey, fallback)
	local value = M.config and M.config[key]
	if value == nil then value = M.config and M.config[legacyKey] end
	if value == nil then value = M.defaults and M.defaults[key] end
	if value == nil then value = M.defaults and M.defaults[legacyKey] end
	if value == nil then value = fallback end
	return value
end

function M.StyleText(text, prefix)
	if not text then return end
	-- Existing profiles retain their shared typography as a fallback until
	-- individual name or duration fields are configured.
	local font = M.TextValue(prefix .. "Font", "font")
	local size = M.TextValue(prefix .. "FontSize", "fontSize", 12)
	local globalStyle = (addon.functions and addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey()) or "__EQOL_GLOBAL_FONT_STYLE__"
	local outline = M.TextValue(prefix .. "FontOutline", "fontOutline", globalStyle)
	local color = M.TextValue(prefix .. "FontColor", "fontColor", { 1, 1, 1, 1 })
	local helper = addon.Aura.UFHelper
	if helper and helper.applyFont then helper.applyFont(text, font, size, outline) end
	text:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

function M.Style(visual)
	local shape = addon.IconShape
	if shape then
		local selected = M.Value("iconShape", "SQUARE")
		local mask = shape.EnsureMask(visual, selected, "_eqolTotemMask")
		if mask then shape.ApplyTextureMask(visual.icon, mask) else shape.ClearTextureMask(visual.icon) end
		visual.cooldown:SetSwipeTexture(shape.GetCooldownSwipeTexture(selected))
	end
	visual.cooldown:SetHideCountdownNumbers(M.Value("showDuration", true) == false)
	visual.cooldown:SetDrawSwipe(M.Value("showCooldown", true) ~= false)
	local swipeColor = M.Color("swipe", { 0, 0, 0, 0.65 })
	visual.cooldown:SetSwipeColor(swipeColor[1], swipeColor[2], swipeColor[3], swipeColor[4])
	visual.name:ClearAllPoints()
	local nameAnchor = M.Value("nameAnchor", "BOTTOM")
	visual.name:SetPoint(nameAnchor, visual, nameAnchor, M.Value("nameOffsetX", 0), M.Value("nameOffsetY", -2))
	M.StyleBorder(visual)
	local timer = visual.cooldown.GetCountdownFontString and visual.cooldown:GetCountdownFontString()
	if timer then
		if timer:GetParent() ~= visual.textOverlay then timer:SetParent(visual.textOverlay) end
		timer:ClearAllPoints()
		local timerAnchor = M.Value("durationAnchor", "CENTER")
		timer:SetPoint(timerAnchor, visual, timerAnchor, M.Value("durationOffsetX", 0), M.Value("durationOffsetY", 0))
	end
	M.StyleText(visual.name, "name")
	M.StyleText(timer, "duration")
end

function M.UpdateSlot(slot, visual)
	local duration = GetTotemDuration and GetTotemDuration(slot)
	local active, name, start, length, icon
	if duration or not GetTotemDuration then active, name, start, length, icon = GetTotemInfo(slot) end
	if not GetTotemDuration then
		-- Older clients expose ordinary numeric times instead of duration objects.
		if not (issecretvalue and issecretvalue(active)) and active and not (issecretvalue and issecretvalue(length)) and length and length > 0 then
			visual.cooldown:SetCooldown(start, length)
		else active = false end
	else active = duration ~= nil end
	visual.active = active == true or M.preview == true
	if active then
		visual.icon:SetTexture(icon)
		if duration then visual.cooldown:SetCooldownFromDurationObject(duration) end
		if M.Value("showName", false) then visual.name:SetText(name) else visual.name:SetText("") end
		visual:SetAlpha(1)
	elseif M.preview then
		visual.icon:SetTexture(136099)
		if M.Value("showName", false) then
			local sampleName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(2484)) or LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")["Totem Frame"]
			visual.name:SetText(sampleName)
		else visual.name:SetText("") end
		-- A running example exposes the actual countdown typography and swipe
		-- without retaining an additional preview ticker.
		visual.cooldown:SetCooldown(GetTime() - 5, 30)
		visual:SetAlpha(1)
	else
		visual.icon:SetTexture(nil)
		visual.name:SetText("")
		visual.cooldown:Clear()
		visual:SetAlpha(0)
	end
end

function M.SuppressStock()
	local stock = _G.TotemFrame
	if stock then
		if M.stockShown == nil then M.stockShown = stock:IsShown() end
		stock:Hide()
	end
end

function M.LayoutSlots()
	if M.InCombat() then return end
	local size, spacing = M.Value("iconSize", 36), M.Value("spacing", 4)
	local growth = M.Value("growth", "RIGHT")
	local horizontal = growth == "RIGHT" or growth == "LEFT"
	local index = 0
	-- Keep visual and secure click target together, without changing slot actions.
	for _, active in ipairs({ true, false }) do
		for slot, visual in ipairs(M.visuals) do
			if visual.active == active then
				local x = horizontal and index * (size + spacing) * (growth == "LEFT" and -1 or 1) or 0
				local y = not horizontal and index * (size + spacing) * (growth == "DOWN" and -1 or 1) or 0
				for _, target in ipairs({ M.buttons[slot], visual }) do
					target:ClearAllPoints()
					target:SetPoint("CENTER", M.frame, "CENTER", x, y)
				end
				index = index + 1
			end
		end
	end
end

function M.Update()
	if not M.enabled then return end
	M.SuppressStock()
	for slot, visual in ipairs(M.visuals) do M.UpdateSlot(slot, visual) end
	M.LayoutSlots()
end

function M.Apply(config, defaults, parent, preview)
	M.config, M.defaults, M.parent, M.preview = config, defaults, parent, preview
	M.pendingDisable = nil
	if M.enabled then M.SuppressStock() end
	if M.InCombat() then
		if M.events then M.events:RegisterEvent("PLAYER_REGEN_ENABLED") end
		return
	end
	M.Ensure()
	local count = _G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4
	local size, spacing = M.Value("iconSize", 36), M.Value("spacing", 4)
	local growth = M.Value("growth", "RIGHT")
	local horizontal = growth == "RIGHT" or growth == "LEFT"
	-- The anchor describes the first slot, independently of row length or growth.
	M.frame:SetSize(size, size)
	M.frame:ClearAllPoints()
	local anchor = M.Value("anchor", "BOTTOMRIGHT")
	local offset = M.Value("offset", { x = 0, y = 20 })
	local extraY = addon.Aura.UF.GetVirtualUnitFramePointOffsetY and addon.Aura.UF.GetVirtualUnitFramePointOffsetY(parent, anchor) or 0
	local selfPoint = ({
		TOPLEFT = "BOTTOMLEFT", TOP = "BOTTOM", TOPRIGHT = "BOTTOMRIGHT",
		BOTTOMLEFT = "TOPLEFT", BOTTOM = "TOP", BOTTOMRIGHT = "TOPRIGHT",
		LEFT = "RIGHT", RIGHT = "LEFT", CENTER = "CENTER",
	})[anchor] or "TOPRIGHT"
	M.frame:SetPoint(selfPoint, parent, anchor, offset.x or 0, (offset.y or 0) + extraY)
	M.frame:SetScale(1)
	for slot = 1, count do
		if not M.buttons[slot] then M.CreateSlot(slot) end
		local x = horizontal and (slot - 1) * (size + spacing) * (growth == "LEFT" and -1 or 1) or 0
		local y = not horizontal and (slot - 1) * (size + spacing) * (growth == "DOWN" and -1 or 1) or 0
		for _, target in ipairs({ M.buttons[slot], M.visuals[slot] }) do
			target:SetSize(size, size)
			target:ClearAllPoints()
			target:SetPoint("CENTER", M.frame, "CENTER", x, y)
		end
		M.Style(M.visuals[slot])
	end
	M.enabled = true
	M.events:RegisterEvent("PLAYER_TOTEM_UPDATE")
	M.events:RegisterEvent("PLAYER_ENTERING_WORLD")
	M.events:RegisterEvent("PLAYER_REGEN_ENABLED")
	M.frame:Show()
	M.Update()
end

function M.Disable()
	if M.InCombat() then
		M.pendingDisable = true
		if M.events then M.events:RegisterEvent("PLAYER_REGEN_ENABLED") end
		return
	end
	M.pendingDisable, M.enabled, M.config = nil, nil, nil
	if M.events then M.events:UnregisterAllEvents() end
	if M.frame then M.frame:Hide() end
	if M.stockShown ~= nil then
		local stock = _G.TotemFrame
		local shown = M.stockShown
		M.stockShown = nil
		if stock then
			-- The stock pool keeps processing its own events while hidden. Restore
			-- only its visibility; do not execute its secret-reading update in addon code.
			if GetTotemDuration then
				shown = false
				local count = _G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4
				for slot = 1, count do if GetTotemDuration(slot) then shown = true break end end
			end
			stock:SetShown(shown)
		end
	end
end
