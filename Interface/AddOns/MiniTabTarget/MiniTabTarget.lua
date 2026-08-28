local _, addon = ...
local frame = CreateFrame("Frame")
---@type MiniFramework
local mini = addon.Framework
---@type Db
local db
---@class Db
local dbDefaults = {
	TargetKey = "TAB",
	TargetPreviousKey = "SHIFT-TAB",
}

local function UpdateBindings()
	if InCombatLockdown() then
		return
	end

	local targetKey = db.TargetKey or dbDefaults.TargetKey
	local targetPreviousKey = db.TargetPreviousKey or dbDefaults.TargetPreviousKey

	-- Auto-detect from current keybindings when the user hasn't changed the addon defaults.
	-- Check both PvE and PvP action names since the addon may have previously set either one.
	if targetKey == dbDefaults.TargetKey and targetPreviousKey == dbDefaults.TargetPreviousKey then
		targetKey = GetBindingKey("TARGETNEARESTENEMY") or GetBindingKey("TARGETNEARESTENEMYPLAYER") or targetKey
		targetPreviousKey = GetBindingKey("TARGETPREVIOUSENEMY") or GetBindingKey("TARGETPREVIOUSENEMYPLAYER") or targetPreviousKey
	end

	local _, instanceType = IsInInstance()
	local isPvp = instanceType == "pvp" or instanceType == "arena"

	if isPvp then
		-- in pvp mode set tab to target player
		SetBinding(targetKey, "TARGETNEARESTENEMYPLAYER")
		SetBinding(targetPreviousKey, "TARGETPREVIOUSENEMYPLAYER")
	else
		-- in pve mode set tab to target enemy
		SetBinding(targetKey, "TARGETNEARESTENEMY")
		SetBinding(targetPreviousKey, "TARGETPREVIOUSENEMY")
	end
end

local function OnEvent()
	UpdateBindings()
end

local function Init()
	db = mini:GetSavedVars(dbDefaults)

	UpdateBindings()
end

mini:WaitForAddonLoad(Init)

frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnEvent)
