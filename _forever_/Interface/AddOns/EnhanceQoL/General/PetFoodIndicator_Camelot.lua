local addonName, addon = ...

local trackedButtons = setmetatable({}, { __mode = "k" })
local _, playerClass = UnitClass("player")
local isHunter = playerClass == "HUNTER"
local PetInfo = _G.C_PetInfo
local anchors = {
	TOPLEFT = { 2, -2 },
	TOPRIGHT = { -2, -2 },
	BOTTOMLEFT = { 2, 2 },
	BOTTOMRIGHT = { -2, 2 },
}

local function updateButton(button, itemID, surface)
	if not isHunter or not button then return end
	local info = trackedButtons[button]
	if not info then
		info = {}
		trackedButtons[button] = info
	end
	info.itemID, info.surface = itemID, surface
	local enabled = addon.db and addon.db[surface == "custom" and "petFoodIndicatorCustom" or "petFoodIndicatorBlizzard"] == true
	local canEat = enabled and itemID and PetInfo and PetInfo.CanPetEatItem and PetInfo.CanPetEatItem(itemID) == true
	if not canEat then
		if button.EQOLPetFoodIcon then button.EQOLPetFoodIcon:Hide() end
		return
	end

	local icon = button.EQOLPetFoodIcon
	if not icon then
		icon = button:CreateTexture(nil, "OVERLAY", nil, 7)
		icon:SetAtlas("UI-PetHappiness", false)
		button.EQOLPetFoodIcon = icon
	end
	local position = addon.db.petFoodIndicatorPosition or "BOTTOMLEFT"
	local offsets = anchors[position] or anchors.BOTTOMLEFT
	local size = tonumber(addon.db.petFoodIndicatorSize) or 14
	icon:ClearAllPoints()
	icon:SetPoint(position, button, position, offsets[1], offsets[2])
	icon:SetSize(size, size)
	icon:Show()
end

addon.functions.UpdatePetFoodIndicator = updateButton

function addon.functions.RefreshPetFoodIndicators()
	for button, info in pairs(trackedButtons) do
		updateButton(button, info.itemID, info.surface)
	end
end

if isHunter then
	local events = CreateFrame("Frame")
	events:RegisterEvent("UNIT_PET")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:SetScript("OnEvent", function(_, event, unit)
		if event == "UNIT_PET" and unit ~= "player" then return end
		addon.functions.RefreshPetFoodIndicators()
	end)
end
