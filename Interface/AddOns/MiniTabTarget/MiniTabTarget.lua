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
	Arena = true,
	SoloShuffle = true,
	Battleground = true,
}

---Which of the three bracket flags the current zone falls under, or nil outside a PvP instance.
---Classic has no C_PvP at all, and some clients carry it without IsSoloShuffle.
local function Bracket()
	local _, instanceType = IsInInstance()

	if instanceType == "arena" then
		if C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle() then
			return "SoloShuffle"
		end

		return "Arena"
	end

	if instanceType == "pvp" then
		return "Battleground"
	end

	return nil
end

---A saved RatedBattleground key marks a save from before the merge, so the fold runs once.
---Folds toward on, so a player who had only one of the two toggles on keeps that bracket.
local function MigrateRatedBattleground()
	local vars = _G.MiniTabTargetDB

	if not vars or vars.RatedBattleground == nil then
		return
	end

	if vars.RatedBattleground then
		vars.Battleground = true
	end

	vars.RatedBattleground = nil
end

---SetBinding is protected, so this only runs out of combat.
local function ApplyBindings()
	local targetKey = db.TargetKey or dbDefaults.TargetKey
	local targetPreviousKey = db.TargetPreviousKey or dbDefaults.TargetPreviousKey

	-- Auto-detect from current keybindings when the user hasn't changed the addon defaults.
	-- Check both PvE and PvP action names since the addon may have previously set either one.
	if targetKey == dbDefaults.TargetKey and targetPreviousKey == dbDefaults.TargetPreviousKey then
		targetKey = GetBindingKey("TARGETNEARESTENEMY") or GetBindingKey("TARGETNEARESTENEMYPLAYER") or targetKey
		targetPreviousKey = GetBindingKey("TARGETPREVIOUSENEMY") or GetBindingKey("TARGETPREVIOUSENEMYPLAYER") or targetPreviousKey
	end

	-- A bracket that is off falls back to the PvE keys, same as no bracket at all.
	local bracket = Bracket()
	local isPvp = bracket ~= nil and db[bracket]

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

local function UpdateBindings()
	mini:RunWhenCombatEnds(ApplyBindings, "MiniTabTarget-UpdateBindings")
end

local function OnEvent()
	UpdateBindings()
end

local function Init()
	MigrateRatedBattleground()

	db = mini:GetSavedVars(dbDefaults)
	addon.Db = db
	addon.UpdateBindings = UpdateBindings

	UpdateBindings()
end

mini:WaitForAddonLoad(Init)

frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- The match type can settle just after the zone change, so the bracket needs another look.
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:SetScript("OnEvent", OnEvent)
