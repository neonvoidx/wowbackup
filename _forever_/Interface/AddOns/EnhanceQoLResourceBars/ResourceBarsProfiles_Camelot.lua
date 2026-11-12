local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local ResourceBars = addon.Aura.ResourceBars
local Profile = {
	kind = "EQOL_RESOURCE_BAR_PROFILE",
	slots = { "HEALTH", "MAIN", "SECONDARY", "TERTIARY" },
	classes = { WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true, SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true },
	visibilityKeys = { MAIN = true, SECONDARY = true, TERTIARY = true, BEAR = true, CAT = true, MOONKIN = true, HUMANOID = true },
	globalKeys = {
		"resourceBarsDruidFixedMana",
		"resourceBarsHideOutOfCombat",
		"resourceBarsHideMounted",
		"resourceBarsHideVehicle",
		"resourceBarsHidePetBattle",
		"resourceBarsHideClientScene",
		"resourceBarsHideWhenEmpty",
	},
}

function Profile.ResolveDB(profileName)
	if type(profileName) == "string" and profileName ~= "" then
		local profiles = EnhanceQoLDB and EnhanceQoLDB.profiles
		return type(profiles) == "table" and profiles[profileName] or nil
	end
	return addon.db
end

function Profile.CopyVisibility(entry)
	local copy = {}
	if type(entry) == "table" then
		if type(entry.assignments) == "table" then copy.assignments = CopyTable(entry.assignments) end
		for key in pairs(Profile.visibilityKeys) do
			if entry[key] == false then copy[key] = false end
		end
	end
	return copy
end

function Profile.CopySharedSettings(store, createDefaults)
	local copy = {}
	for _, slot in ipairs(Profile.slots) do
		local cfg = type(store) == "table" and store[slot] or nil
		if type(cfg) == "table" or createDefaults then
			cfg = type(cfg) == "table" and CopyTable(cfg) or { enabled = true }
			if ResourceBars.NormalizeVisibilityConfig then
				local visibility = ResourceBars.NormalizeVisibilityConfig(cfg.visibility, cfg)
				cfg.visibility = visibility and CopyTable(visibility) or nil
			else
				local visibility = {}
				if type(cfg.visibility) == "table" then
					for key, enabled in pairs(cfg.visibility) do
						if enabled == true then visibility[key] = true end
					end
				end
				if not next(visibility) then
					if cfg.hideOutOfCombat == true then visibility.ALWAYS_IN_COMBAT = true end
					if cfg.hideMounted == true then visibility.PLAYER_NOT_MOUNTED = true end
				end
				if visibility.ALWAYS_HIDDEN then visibility = { ALWAYS_HIDDEN = true } end
				cfg.visibility = next(visibility) and visibility or nil
			end
			cfg.hideOutOfCombat = nil
			cfg.hideMounted = nil
			copy[slot] = cfg
		end
	end
	return copy
end

function Profile.CopyGlobals(source)
	local globals = { resourceBarsDruidFixedMana = source.resourceBarsDruidFixedMana == true }
	for _, key in ipairs(Profile.globalKeys) do
		if source[key] ~= nil then globals[key] = source[key] and true or false end
	end
	if source.resourceBarsHidePetBattle == nil and source.auraHideInPetBattle ~= nil then globals.resourceBarsHidePetBattle = source.auraHideInPetBattle and true or false end
	return globals
end

function Profile.Export(scopeKey, profileName)
	scopeKey = scopeKey or "ALL"
	if scopeKey ~= "ALL" and scopeKey ~= "ALL_CLASSES" then return nil, "NO_SPEC" end
	local classKey = addon.variables and addon.variables.unitClass
	if not Profile.classes[classKey] then return nil, "NO_CLASS" end
	local db = Profile.ResolveDB(profileName)
	if type(db) ~= "table" then return nil, "NO_DATA" end
	local globals = Profile.CopyGlobals(db)
	globals.sharedResourceBarSettings = Profile.CopySharedSettings(db.sharedResourceBarSettings, true)
	globals.sharedResourceBarVisibility = {}
	local visibility = type(db.sharedResourceBarVisibility) == "table" and db.sharedResourceBarVisibility or {}
	for classTag in pairs(Profile.classes) do
		if scopeKey == "ALL_CLASSES" or classTag == classKey then
			local classStore = visibility[classTag]
			local entry = type(classStore) == "table" and classStore.FOREVER or nil
			globals.sharedResourceBarVisibility[classTag] = { FOREVER = Profile.CopyVisibility(entry) }
		end
	end
	local payload = {
		kind = Profile.kind,
		version = 4,
		flavor = "forever",
		class = scopeKey == "ALL_CLASSES" and "ALL" or classKey,
		enableResourceFrame = db.enableResourceFrame and true or false,
		globalSettings = globals,
	}
	local serializer = LibStub("AceSerializer-3.0")
	local deflate = LibStub("LibDeflate")
	return deflate:EncodeForPrint(deflate:CompressDeflate(serializer:Serialize(payload)))
end

function Profile.Import(encoded, scopeKey)
	scopeKey = scopeKey or "ALL"
	if scopeKey ~= "ALL" and scopeKey ~= "ALL_CLASSES" then return false, "NO_SPEC" end
	if type(encoded) ~= "string" then return false, "NO_INPUT" end
	encoded = encoded:match("^%s*(.-)%s*$")
	if encoded == "" then return false, "NO_INPUT" end
	local deflate = LibStub("LibDeflate")
	local serializer = LibStub("AceSerializer-3.0")
	local decoded = deflate:DecodeForPrint(encoded) or deflate:DecodeForWoWChatChannel(encoded) or deflate:DecodeForWoWAddonChannel(encoded)
	if not decoded then return false, "DECODE" end
	local decompressed = deflate:DecompressDeflate(decoded)
	if not decompressed then return false, "DECOMPRESS" end
	local ok, data = serializer:Deserialize(decompressed)
	if not ok or type(data) ~= "table" then return false, "DESERIALIZE" end
	if data.kind ~= Profile.kind then return false, "WRONG_KIND" end
	local classKey = addon.variables and addon.variables.unitClass
	if not Profile.classes[classKey] then return false, "NO_CLASS" end
	if data.class and data.class ~= classKey and data.class ~= "ALL" then return false, "WRONG_CLASS", data.class end
	local globals = type(data.globalSettings) == "table" and data.globalSettings or data.global
	if type(globals) ~= "table" or type(globals.sharedResourceBarSettings) ~= "table" then return false, "NO_SPECS" end
	local shared = Profile.CopySharedSettings(globals.sharedResourceBarSettings)
	if not next(shared) then return false, "NO_SPECS" end
	local globalSettings = Profile.CopyGlobals(globals)
	local visibility = type(globals.sharedResourceBarVisibility) == "table" and globals.sharedResourceBarVisibility or {}
	local importedVisibility = {}
	for classTag in pairs(Profile.classes) do
		if scopeKey == "ALL_CLASSES" or classTag == classKey then
			local classStore = visibility[classTag]
			if type(classStore) == "table" and type(classStore.FOREVER) == "table" then importedVisibility[classTag] = Profile.CopyVisibility(classStore.FOREVER) end
		end
	end

	-- Shared layouts apply to every class. Only the selected Forever visibility entries
	-- are replaced; Retail specialization settings and modes remain untouched.
	addon.db = addon.db or {}
	if addon.EditModeLib and addon.EditModeLib.InvalidateContext then addon.EditModeLib:InvalidateContext("resource-profile") end
	addon.db.sharedResourceBarSettings = shared
	for key, value in pairs(globalSettings) do
		addon.db[key] = value
	end
	if next(importedVisibility) then
		if type(addon.db.sharedResourceBarVisibility) ~= "table" then addon.db.sharedResourceBarVisibility = {} end
		for classTag, entry in pairs(importedVisibility) do
			if type(addon.db.sharedResourceBarVisibility[classTag]) ~= "table" then addon.db.sharedResourceBarVisibility[classTag] = {} end
			addon.db.sharedResourceBarVisibility[classTag].FOREVER = entry
		end
	end
	local enableState
	if type(data.enableResourceFrame) == "boolean" then enableState = data.enableResourceFrame end
	return true, {}, enableState, scopeKey
end

ResourceBars.ExportProfile = Profile.Export
ResourceBars.ImportProfile = Profile.Import
addon.Aura.functions.importResourceProfile = Profile.Import
