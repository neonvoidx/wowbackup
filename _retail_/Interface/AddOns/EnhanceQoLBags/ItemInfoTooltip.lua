local addon = _G.EnhanceQoL
local M = {}
addon.Bags.ItemInfoTooltip = M

-- API identifiers are intentional: these fields are used to inspect category rules.
M.fields = {
	"itemName", "itemLink", "itemQuality", "itemLevel", "itemMinLevel", "itemType", "itemSubType", "itemStackCount", "itemEquipLoc",
	"itemTexture", "sellPrice", "classID", "subclassID", "bindType", "expansionID", "setID", "isCraftingReagent", "itemDescription",
}

function M.IsSecret(value)
	return issecretvalue and issecretvalue(value)
end

function M.GetOwner(tooltip)
	if tooltip ~= GameTooltip then return end
	local owner = tooltip:GetOwner()
	if owner and owner._eqolBagItemInfoOwner and owner:IsShown() and addon.Bags.IsEnabled() then return owner end
end

function M.Format(value)
	if M.IsSecret(value) then return UNKNOWN end
	if value == nil then return "nil" end
	if value == true then return "true" end
	if value == false then return "false" end
	if value == "" then return '""' end
	return tostring(value)
end

function M.Append(tooltip)
	if not M.GetOwner(tooltip) or tooltip._eqolItemInfoAdded then return end
	if not addon.GetSettings().itemInfoTooltip or not IsAltKeyDown() then return end
	local _, link = tooltip:GetItem()
	if M.IsSecret(link) or not link then return end
	local itemID = tonumber(link:match("item:(%d+)"))
	if not itemID then return end
	local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
	if not getter then return end
	local values = { getter(link) }
	tooltip._eqolItemInfoAdded = true
	tooltip:AddLine(" ")
	tooltip:AddLine("GetItemInfo", 0.4, 0.75, 1)
	tooltip:AddDoubleLine("itemID", tostring(itemID), 0.8, 0.85, 0.9, 1, 1, 1)
	for index, field in ipairs(M.fields) do
		if field == "itemDescription" then
			tooltip:AddLine(field .. ": " .. M.Format(values[index]), 0.8, 0.85, 0.9, true)
		else
			tooltip:AddDoubleLine(field, M.Format(values[index]), 0.8, 0.85, 0.9, 1, 1, 1)
		end
	end
	if not M.IsSecret(values[1]) and not values[1] then
		M.pendingItemID = itemID
		tooltip:AddLine(RETRIEVING_ITEM_INFO, 1, 0.82, 0)
	else
		M.pendingItemID = nil
	end
	tooltip:Show()
end

function M.Refresh()
	if not GameTooltip:IsShown() then return end
	local owner = M.GetOwner(GameTooltip)
	if not owner then return end
	local onEnter = owner:GetScript("OnEnter")
	if onEnter then onEnter(owner) end
end

GameTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip._eqolItemInfoAdded = nil end)
if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, M.Append)
elseif GameTooltip:HasScript("OnTooltipSetItem") then
	GameTooltip:HookScript("OnTooltipSetItem", M.Append)
end

M.events = CreateFrame("Frame")
M.events:RegisterEvent("MODIFIER_STATE_CHANGED")
M.events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
M.events:SetScript("OnEvent", function(_, event, itemID, success)
	if event == "MODIFIER_STATE_CHANGED" then
		if addon.GetSettings().itemInfoTooltip then M.Refresh() end
	elseif success and itemID == M.pendingItemID and IsAltKeyDown() then
		M.pendingItemID = nil
		M.Refresh()
	end
end)
