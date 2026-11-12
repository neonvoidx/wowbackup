local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then addon = _G[parentAddonName] else error(parentAddonName .. " is not loaded") end
local CP = addon.Aura.CooldownPanels

function CP:GetTotemDurationObject(entry)
	if not (entry and entry.type == "TOTEM" and GetTotemDuration) then return nil end
	local slot = tonumber(entry.totemSlot)
	if not slot or slot < 1 or slot > (_G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4) then return nil end
	-- A nil duration identifies an empty slot even when GetTotemInfo is secret.
	return GetTotemDuration(slot)
end

function CP:AddAllTotemEntries(panelId)
	if not GetTotemDuration then return false end
	local added = false
	for slot = 1, (_G.GetNumTotemSlots and _G.GetNumTotemSlots() or MAX_TOTEMS or 4) do
		if not self:FindEntryByValue(panelId, "TOTEM", slot) then
			if self:AddEntrySafe(panelId, "TOTEM", slot) then added = true end
		end
	end
	return added
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TOTEM_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
	local root = CP:GetRoot()
	for _, panel in pairs(root and root.panels or {}) do
		for _, entry in pairs(panel.entries or {}) do
			if entry.type == "TOTEM" then
				CP:RequestUpdate({ cause = "Totem", fullRefresh = true })
				return
			end
		end
	end
end)
