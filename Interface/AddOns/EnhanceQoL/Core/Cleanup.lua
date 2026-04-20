local addonName, addon = ...

addon.functions = addon.functions or {}

local PROFILE_DEBUG_KEYS = {
	"_combatTextTraceEnabled",
	"_combatTextTrace",
	"_cooldownPanelsDebugLog",
	"debugCooldownPanelsSession",
	"xpBarDebug",
	"xpBarDebugLast",
	"classBuffReminderSoundDebugTrace",
	"_focusInterruptTrackerTraceEnabled",
	"_focusInterruptTrackerTrace",
}

local TRANSIENT_PROFILE_KEYS = {
	["_eqolFixedLayoutCache"] = true,
	["_eqolDynamicTargetIndices"] = true,
	["_eqolIsStatic"] = true,
	["_eqolCapacity"] = true,
	["_eqolAbsoluteThresholdColorCache"] = true,
	["_eqolAbsoluteThresholdCurveCache"] = true,
	["_eqolRuntimePrepareStamp"] = true,
	["_rbType"] = true,
	["_rbSourceMode"] = true,
	["_rbSourceSlot"] = true,
	["_resolvedDefaultPowerColor"] = true,
	["_autoEnabledRuntime"] = true,
	["_autoEnableInProgress"] = true,
}

local function cleanupDebugArtifactsProfile(profile)
	if type(profile) ~= "table" then return end

	for i = 1, #PROFILE_DEBUG_KEYS do
		profile[PROFILE_DEBUG_KEYS[i]] = nil
	end

	if type(profile.cooldownPanels) == "table" then profile.cooldownPanels._eqolBarsDebug = nil end

	if type(profile._temp) == "table" then
		profile._temp.ufProfileDebug = nil
		profile._temp.ufProfileTrace = nil
		if not next(profile._temp) then profile._temp = nil end
	end
end

local function cleanupCombatMeterProfile(profile)
	if type(profile) ~= "table" then return end
	for key in pairs(profile) do
		if type(key) == "string" and key:lower():find("^combatmeter") then profile[key] = nil end
	end

	local editData = profile.editModeData
	if type(editData) == "table" then
		for id in pairs(editData) do
			if type(id) == "string" and id:lower():find("^combatmeter") then editData[id] = nil end
		end
	end

	-- Legacy fallback for profile versions that still carry layout-keyed data.
	local layouts = profile.editModeLayouts
	if type(layouts) ~= "table" then return end
	for layoutName, layout in pairs(layouts) do
		if type(layout) == "table" then
			for id in pairs(layout) do
				if type(id) == "string" and id:lower():find("^combatmeter") then layout[id] = nil end
			end
			if not next(layout) then layouts[layoutName] = nil end
		end
	end
end

local function cleanupBuffTrackerProfile(profile)
	if type(profile) ~= "table" then return end
	for key in pairs(profile) do
		if type(key) == "string" and key:lower():find("^bufftracker") then profile[key] = nil end
	end
end

local function cleanupTransientProfileCaches(root, seen)
	if type(root) ~= "table" then return end
	seen = seen or {}
	if seen[root] then return end
	seen[root] = true

	for key, value in pairs(root) do
		if TRANSIENT_PROFILE_KEYS[key] then
			root[key] = nil
		elseif type(value) == "table" then
			cleanupTransientProfileCaches(value, seen)
		end
	end
end

function addon.functions.CleanupCombatMeterSettings()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			cleanupCombatMeterProfile(profile)
		end
	elseif addon.db then
		cleanupCombatMeterProfile(addon.db)
	end
end

function addon.functions.CleanupBuffTrackerSettings()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" and type(db.profiles) == "table" then
		for _, profile in pairs(db.profiles) do
			cleanupBuffTrackerProfile(profile)
		end
	elseif addon.db then
		cleanupBuffTrackerProfile(addon.db)
	end
end

function addon.functions.CleanupDebugArtifacts()
	local db = _G.EnhanceQoLDB
	if type(db) == "table" then
		cleanupDebugArtifactsProfile(db)
		if type(db.profiles) == "table" then
			for _, profile in pairs(db.profiles) do
				cleanupDebugArtifactsProfile(profile)
			end
		end
	end

	if addon.db and addon.db ~= db then cleanupDebugArtifactsProfile(addon.db) end
end

function addon.functions.CleanupTransientProfileCaches()
	local db = _G.EnhanceQoLDB
	local seen = {}
	if type(db) == "table" then cleanupTransientProfileCaches(db, seen) end
	if addon.db and addon.db ~= db then cleanupTransientProfileCaches(addon.db, seen) end
end

function addon.functions.CleanupOldStuff()
	addon.functions.CleanupCombatMeterSettings()
	addon.functions.CleanupBuffTrackerSettings()
	addon.functions.CleanupDebugArtifacts()
	addon.functions.CleanupTransientProfileCaches()
end

local cleanupFrame = CreateFrame and CreateFrame("Frame", nil, UIParent or nil)
if cleanupFrame then
	cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
	cleanupFrame:SetScript("OnEvent", function()
		if addon.functions and addon.functions.CleanupTransientProfileCaches then addon.functions.CleanupTransientProfileCaches() end
	end)
end
