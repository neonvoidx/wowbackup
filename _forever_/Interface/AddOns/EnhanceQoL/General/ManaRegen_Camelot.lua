local _, addon = ...
local C_DurationUtil = _G.C_DurationUtil

if not (addon.variables and addon.variables.isForever) then return end
if not (C_CurveUtil and C_CurveUtil.CreateCurve and C_DurationUtil and C_DurationUtil.CreateDuration and UnitPowerPercent) then return end

local M = { active = {}, overlays = {} }
addon.ManaRegen = M
local MANA = Enum.PowerType.Mana

local function isSecret(value) return issecretvalue and issecretvalue(value) end

function M.RefreshAlpha()
	-- The native curve result can be secret; pass it directly to the renderer.
	for _, overlay in pairs(M.active) do
		overlay:SetAlpha(UnitPowerPercent("player", MANA, false, M.alphaCurve))
	end
end

function M.Layout(bar)
	local overlay = M.active[bar]
	if not overlay then return end
	local vertical = bar:GetOrientation() == "VERTICAL"
	local reverse = bar:GetReverseFill()
	overlay:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
	overlay:SetReverseFill(reverse)
	overlay:SetFrameStrata(bar:GetFrameStrata())
	overlay:SetFrameLevel(bar:GetFrameLevel() + 2)
	local spark = overlay.spark
	spark:ClearAllPoints()
	if vertical then
		spark:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
		spark:SetSize(bar:GetWidth(), 8)
		spark:SetPoint("CENTER", overlay:GetStatusBarTexture(), reverse and "BOTTOM" or "TOP", 0, 0)
	else
		spark:SetTexCoord(0, 1, 0, 1)
		spark:SetSize(8, bar:GetHeight())
		spark:SetPoint("CENTER", overlay:GetStatusBarTexture(), reverse and "LEFT" or "RIGHT", 0, 0)
	end
end

function M.Stop()
	if M.timer then M.timer:Cancel() end
	M.timer = nil
	for _, overlay in pairs(M.active) do
		overlay:Hide()
	end
end

function M.StartSweep()
	local seconds = 5
	if M.timer then M.timer:Cancel() end
	M.duration:SetTimeFromStart(GetTime(), seconds)
	M.RefreshAlpha()
	for _, overlay in pairs(M.active) do
		overlay:SetTimerDuration(M.duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
		overlay:Show()
	end
	M.timer = C_Timer.NewTimer(seconds, M.Stop)
end

function M.SpellCostsMana(spellID)
	if isSecret(spellID) or type(spellID) ~= "number" then return false end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if isSecret(costs) or type(costs) ~= "table" then return false end
	for _, cost in ipairs(costs) do
		if not isSecret(cost) and not isSecret(cost.type) and cost.type == MANA then
			local requiredAura = cost.requiredAuraID
			local inactiveCost = not isSecret(requiredAura) and type(requiredAura) == "number" and requiredAura ~= 0
				and not isSecret(cost.hasRequiredAura) and cost.hasRequiredAura == false
			if not inactiveCost then
				local amount = cost.cost
				if isSecret(amount) then return true end
				if type(amount) == "number" and amount > 0 then return true end
			end
		end
	end
	return false
end

function M.OnEvent(_, event, _, powerOrCastGUID, spellID)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
		M.Stop()
		M.RefreshAlpha()
		return
	end
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		if M.SpellCostsMana(spellID) then
			M.StartSweep()
		end
		return
	end
	if isSecret(powerOrCastGUID) or powerOrCastGUID ~= "MANA" then return end
	M.RefreshAlpha()
end

function M.SetEnabled(bar, enabled, refreshLayout)
	if not bar then return end
	if not enabled then
		local overlay = M.active[bar]
		if not overlay then return end
		overlay:Hide()
		M.active[bar] = nil
		if not next(M.active) then
			M.events:UnregisterAllEvents()
			M.Stop()
		end
		return
	end
	if M.active[bar] then
		if refreshLayout then M.Layout(bar) end
		return
	end
	if not M.events then
		M.alphaCurve = C_CurveUtil.CreateCurve()
		M.alphaCurve:SetType(Enum.LuaCurveType.Step)
		M.alphaCurve:AddPoint(0, 1)
		M.alphaCurve:AddPoint(1, 0)
		M.duration = C_DurationUtil.CreateDuration()
		M.events = CreateFrame("Frame")
		M.events:SetScript("OnEvent", M.OnEvent)
	end
	local first = not next(M.active)
	local overlay = M.overlays[bar]
	if not overlay then
		overlay = CreateFrame("StatusBar", nil, bar)
		overlay:SetAllPoints(bar)
		overlay:EnableMouse(false)
		overlay:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		overlay:GetStatusBarTexture():SetAlpha(0)
		overlay:SetMinMaxValues(0, 1)
		overlay:SetValue(0)
		overlay.spark = overlay:CreateTexture(nil, "OVERLAY")
		overlay.spark:SetAtlas("ui-castingbar-pip", false)
		overlay.spark:SetBlendMode("ADD")
		M.overlays[bar] = overlay
		bar:HookScript("OnSizeChanged", M.Layout)
	end
	M.active[bar] = overlay
	M.Layout(bar)
	overlay:SetAlpha(UnitPowerPercent("player", MANA, false, M.alphaCurve))
	if M.timer then
		overlay:SetTimerDuration(M.duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)
		overlay:Show()
	else
		overlay:Hide()
	end
	if first then
		M.events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
		M.events:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
		M.events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
		M.events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		M.events:RegisterEvent("PLAYER_ENTERING_WORLD")
		M.events:RegisterEvent("PLAYER_DEAD")
		M.events:RegisterEvent("PLAYER_ALIVE")
	end
end
