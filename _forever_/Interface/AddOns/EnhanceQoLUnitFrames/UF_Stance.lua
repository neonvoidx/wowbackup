local addon = _G.EnhanceQoL
local UF = addon.Aura.UF
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local S = { defaults = { enabled = false, size = 20, x = 0, y = 0, anchor = "CENTER", outside = false } }
UF.Stance = S

function S.FormTexture(index)
	local texture, _, _, spellID = GetShapeshiftFormInfo(index)
	if spellID and C_Spell and C_Spell.GetSpellTexture then texture = C_Spell.GetSpellTexture(spellID) or texture end
	return texture
end

function S.Refresh()
	if not S.icon then return end
	local cfg = S.cfg and S.cfg.stance or {}
	local form = GetShapeshiftForm and GetShapeshiftForm() or 0
	local texture
	if form > 0 then texture = S.FormTexture(form) end
	local preview = UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled("player")
	S.icon:SetTexCoord(0, 1, 0, 1)
	if not texture and preview then
		if GetNumShapeshiftForms and GetNumShapeshiftForms() > 0 then texture = S.FormTexture(1) end
		if not texture then
			local class = select(2, UnitClass("player"))
			local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
			if coords then
				texture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
				S.icon:SetTexCoord(unpack(coords))
			end
		end
	end
	S.icon:SetTexture(texture)
	S.icon:SetShown(S.cfg and S.cfg.enabled == true and cfg.enabled == true and texture ~= nil)
end

S.opposite = { TOPLEFT = "BOTTOMRIGHT", TOP = "BOTTOM", TOPRIGHT = "BOTTOMLEFT", LEFT = "RIGHT", CENTER = "CENTER", RIGHT = "LEFT", BOTTOMLEFT = "TOPRIGHT", BOTTOM = "TOP", BOTTOMRIGHT = "TOPLEFT" }
function S.Anchor(opts)
	local anchor = S.opposite[opts.anchor] and opts.anchor or "CENTER"
	return opts.outside == true and S.opposite[anchor] or anchor, anchor
end

function S.Apply(cfg, state)
	S.cfg = cfg
	if not (state and state.frame) then return end
	if InCombatLockdown() then S.Refresh(); return end
	if not S.host and cfg and cfg.stance and cfg.stance.enabled then
		S.host = CreateFrame("Frame", nil, state.frame)
		S.host:EnableMouse(false)
		S.icon = S.host:CreateTexture(nil, "OVERLAY")
		S.icon:SetAllPoints()
	end
	if not S.host then return end
	local opts = cfg.stance or S.defaults
	S.host:SetFrameLevel(state.frame:GetFrameLevel() + 15)
	S.host:SetSize(math.max(8, math.min(80, opts.size or 20)), math.max(8, math.min(80, opts.size or 20)))
	S.host:ClearAllPoints()
	local point, relativePoint = S.Anchor(opts)
	S.host:SetPoint(point, state.frame, relativePoint, opts.x or 0, (opts.y or 0) + UF.GetVirtualUnitFramePointOffsetY(state.frame, relativePoint))
	S.listener = S.listener or CreateFrame("Frame")
	S.listener:UnregisterAllEvents()
	if opts.enabled == true and cfg.enabled == true then
		for _, event in ipairs({ "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "PLAYER_ENTERING_WORLD" }) do S.listener:RegisterEvent(event) end
	end
	S.listener:SetScript("OnEvent", S.Refresh)
	S.Refresh()
end

function S.AppendSettings(list, context)
	local function get(key)
		local cfg = UF.GetConfig("player").stance
		if cfg and cfg[key] ~= nil then return cfg[key] end
		return S.defaults[key]
	end
	local function set(key, value)
		local cfg = UF.GetConfig("player")
		cfg.stance = cfg.stance or {}
		cfg.stance[key] = value
		context.refresh()
	end
	list[#list + 1] = { name = L["UFStance"], kind = UF.ui.settingType.Collapsible, id = "stance", defaultCollapsed = true }
	list[#list + 1] = context.checkbox(L["UFStance"], function() return get("enabled") end, function(value) set("enabled", value) end, false, "stance")
	local anchor = context.dropdown(L["Anchor point"], UF.ui.anchorOptions9, function() return get("anchor") end, function(value) set("anchor", value) end, "CENTER", "stance")
	anchor.navigationField = "stance_anchor"
	anchor.navigationDefaultVerified = true
	anchor.isEnabled = function() return get("enabled") == true end
	list[#list + 1] = anchor
	local placement = context.dropdown(L["UFStancePlacement"], { { value = false, label = L["UFStanceInside"] }, { value = true, label = L["Outside"] } }, function() return get("outside") end, function(value) set("outside", value == true) end, false, "stance")
	placement.navigationField = "stance_outside"
	placement.navigationDefaultVerified = true
	placement.isEnabled = function() return get("enabled") == true and get("anchor") ~= "CENTER" end
	list[#list + 1] = placement
	for _, spec in ipairs({ { "size", L["Icon size"], 8, 80 }, { "x", L["Offset X"], -500, 500 }, { "y", L["Offset Y"], -500, 500 } }) do
		local key = spec[1]
		list[#list + 1] = context.slider(spec[2], spec[3], spec[4], 1, function() return get(key) end, function(value) set(key, value) end, S.defaults[key], "stance", true)
		list[#list].navigationField = "stance_" .. key
		list[#list].navigationDefaultVerified = true
		list[#list].isEnabled = function() return get("enabled") == true end
	end
end
