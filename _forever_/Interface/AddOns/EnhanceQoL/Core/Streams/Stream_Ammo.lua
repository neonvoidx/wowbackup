local _, addon = ...
local M = addon.ClassicResources
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local function update(stream)
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.ammo = addon.db.datapanel.ammo or {}
	local db = addon.db.datapanel.ammo
	local data = M.Read()
	local parts, tooltip = {}, { L["ammoTracking"] }
	if data.count ~= nil then
		local icon = data.icon or data.weaponIcon
		parts[#parts + 1] = (db.hideIcon ~= true and icon and ("|T%s:14:14|t "):format(icon) or "") .. data.count
		local name = data.itemID and C_Item.GetItemNameByID(data.itemID) or _G.AMMO
		tooltip[#tooltip + 1] = (name or L["ammoTracking"]) .. ": " .. data.count
	end
	if data.durability then
		if db.showDurability ~= false then parts[#parts + 1] = data.durability .. "%" end
		tooltip[#tooltip + 1] = (_G.DURABILITY or L["ammoTracking"]) .. ": " .. data.durability .. "%"
	end
	if data.customCount ~= nil then
		parts[#parts + 1] = tostring(data.customCount)
		tooltip[#tooltip + 1] = (C_Item.GetItemNameByID(data.customID) or tostring(data.customID)) .. ": " .. data.customCount
	end
	stream.snapshot.text = #parts > 0 and table.concat(parts, " | ") or "—"
	stream.snapshot.fontSize = db.fontSize or 14
	stream.snapshot.tooltip = table.concat(tooltip, "\n")
end
local function request(stream) addon.DataHub:RequestUpdate(stream) end
local provider = {
	id = "ammo", version = 1, title = L["ammoTracking"], update = update,
	events = { PLAYER_LOGIN = request, PLAYER_ENTERING_WORLD = request, BAG_UPDATE_DELAYED = request, PLAYER_EQUIPMENT_CHANGED = request, UPDATE_INVENTORY_DURABILITY = request, GET_ITEM_INFO_RECEIVED = request },
	OnClick = function(_, button)
		if button == "RightButton" then addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_ammo_fontSize") end
	end,
}
addon.DataHub.RegisterStream(provider)
return provider
