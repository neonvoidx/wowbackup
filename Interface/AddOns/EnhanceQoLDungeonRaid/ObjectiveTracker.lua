-- luacheck: globals C_DelvesUI
local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.MythicPlus = addon.MythicPlus or {}
addon.MythicPlus.functions = addon.MythicPlus.functions or {}
addon.MythicPlus.variables = addon.MythicPlus.variables or {}

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local frameLoad = CreateFrame("Frame")
local hiddenElements = {}
local alreadyHooked = {}
local objectiveTrackerUpdateToken = 0

local OBJECTIVE_TRACKER_DEFAULT_SCOPE = "dungeonMythicPlus"
local OBJECTIVE_TRACKER_SCOPE_GROUPS = {
	{ key = "dungeonNormal", difficulties = { 1, 150, 205, 216 } },
	{ key = "dungeonHeroic", difficulties = { 2 } },
	{ key = "dungeonMythic", difficulties = { 23 } },
	{ key = OBJECTIVE_TRACKER_DEFAULT_SCOPE, difficulties = { 8 } },
	{ key = "dungeonTimewalking", difficulties = { 24 } },
	{ key = "raidLfr", difficulties = { 7, 17, 151 } },
	{ key = "raidNormal", difficulties = { 3, 4, 9, 14, 18, 220 } },
	{ key = "raidHeroic", difficulties = { 5, 6, 15 } },
	{ key = "raidMythic", difficulties = { 16, 233 } },
	{ key = "raidTimewalking", difficulties = { 33 } },
	{ key = "scenarioDelve", difficulties = { 11, 12, 20, 30, 38, 39, 40, 147, 149, 152, 153, 167, 168, 169, 170, 171, 208 } },
}
local OBJECTIVE_TRACKER_SCOPE_LOOKUP = {}
for _, group in ipairs(OBJECTIVE_TRACKER_SCOPE_GROUPS) do
	for _, difficultyID in ipairs(group.difficulties) do
		OBJECTIVE_TRACKER_SCOPE_LOOKUP[difficultyID] = group.key
	end
end

local function hasActiveDelve()
	if not (C_DelvesUI and C_DelvesUI.HasActiveDelve and UnitPosition) then return false end
	local _, _, _, mapID = UnitPosition("player")
	if not mapID then return false end
	return C_DelvesUI.HasActiveDelve(mapID)
end

local function getObjectiveTrackerScopeSelection()
	if not addon.db then return nil end
	local selection = addon.db["mythicPlusObjectiveTrackerScopes"]
	if type(selection) ~= "table" then
		selection = { [OBJECTIVE_TRACKER_DEFAULT_SCOPE] = true }
		addon.db["mythicPlusObjectiveTrackerScopes"] = selection
	end
	return selection
end

local function shouldManageObjectiveTracker()
	if not (addon.db and addon.db["mythicPlusEnableObjectiveTracker"] and IsInInstance and GetInstanceInfo) then return false end
	if not IsInInstance() then return false end

	local difficultyID = select(3, GetInstanceInfo())
	local scopeKey = hasActiveDelve() and "scenarioDelve" or OBJECTIVE_TRACKER_SCOPE_LOOKUP[difficultyID]
	if not scopeKey then return false end

	local selection = getObjectiveTrackerScopeSelection()
	return selection and selection[scopeKey] == true
end

function addon.MythicPlus.functions.setObjectiveFrames()
	if shouldManageObjectiveTracker() then
		for i, v in pairs(addon.MythicPlus.variables.objectiveTrackerFrames) do
			if not v.frame and v.name then v.frame = _G[v.name] end
			local frame = v.frame
			if frame then
				if frame:IsVisible() then
					frame:Hide()
					table.insert(hiddenElements, v)
				end
				if not alreadyHooked[frame] then
					frame:HookScript("OnShow", function(self)
						if shouldManageObjectiveTracker() then self:Hide() end
					end)
					alreadyHooked[frame] = true
				end
			end
		end
	elseif #hiddenElements > 0 then
		for i, v in pairs(hiddenElements) do
			if not v.frame and v.name then v.frame = _G[v.name] end
			local frame = v.frame
			if frame and not frame:IsVisible() then frame:Show() end
		end
		wipe(hiddenElements)
	end
end

local function runObjectiveTrackerUpdate()
	if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then addon.MythicPlus.functions.setObjectiveFrames() end
end

local function scheduleObjectiveTrackerUpdate()
	objectiveTrackerUpdateToken = objectiveTrackerUpdateToken + 1
	local token = objectiveTrackerUpdateToken
	runObjectiveTrackerUpdate()
	if not (C_Timer and C_Timer.After) then return end
	C_Timer.After(0.25, function()
		if token == objectiveTrackerUpdateToken then runObjectiveTrackerUpdate() end
	end)
	C_Timer.After(1, function()
		if token == objectiveTrackerUpdateToken then runObjectiveTrackerUpdate() end
	end)
end

local eventHandlers = {
	["ACTIVE_DELVE_DATA_UPDATE"] = scheduleObjectiveTrackerUpdate,
	["CHALLENGE_MODE_RESET"] = scheduleObjectiveTrackerUpdate,
	["CHALLENGE_MODE_START"] = scheduleObjectiveTrackerUpdate,
	["INSTANCE_GROUP_SIZE_CHANGED"] = scheduleObjectiveTrackerUpdate,
	["ZONE_CHANGED_NEW_AREA"] = scheduleObjectiveTrackerUpdate,
	["PLAYER_DIFFICULTY_CHANGED"] = scheduleObjectiveTrackerUpdate,
	["PLAYER_ENTERING_WORLD"] = scheduleObjectiveTrackerUpdate,
	["UPDATE_INSTANCE_INFO"] = scheduleObjectiveTrackerUpdate,
}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end
local function eventHandler(self, event, ...)
	if addon.db["mythicPlusEnableObjectiveTracker"] then
		if eventHandlers[event] then eventHandlers[event](...) end
	end
end

function addon.MythicPlus.functions.InitObjectiveTracker()
	if addon.MythicPlus.variables.objectiveTrackerInitialized then return end
	if not addon.db then return end
	addon.MythicPlus.variables.objectiveTrackerInitialized = true
	registerEvents(frameLoad)
	frameLoad:SetScript("OnEvent", eventHandler)
end
