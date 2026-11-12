local addonName, addon = ...

addon.EditMode = addon.EditMode or {}
local EditMode = addon.EditMode

local LibEditMode = addon.EditModeLib
assert(LibEditMode, "EnhanceQoL Edit Mode integration is not loaded")

local DEFAULT_LAYOUT = "_Global"
local SHARED_STORAGE_KEY = "editModeData"
local HIDDEN_FRAMES_KEY = "editModeHiddenFrames"
local MANAGER_PANEL_POSITION_KEY = "editModeManagerPanelPosition"
local LEGACY_LAYOUTS_KEY = "editModeLayouts"
local PROFILE_MIGRATION_FLAG = "_editModeDataMigratedV1"
local ROOT_MIGRATION_FLAG = "_editModeDataMigratedAllProfilesV1"
local POSITION_ONLY_FLAG = "_editModeDataPositionOnlyV1"
local ROOT_POSITION_ONLY_FLAG = "_editModeDataPositionOnlyAllProfilesV1"
local POSITION_FIELDS = {
	point = true,
	relativePoint = true,
	x = true,
	y = true,
}

local function snapToPixel(value, region)
	if addon.PixelUtil and addon.PixelUtil.Snap then return addon.PixelUtil.Snap(value, region) end
	return tonumber(value) or 0
end

local function usesStoredPosition(entry) return not (entry and entry.persistPosition == false) end

local function getSelection(lib, frame)
	if not lib then return nil end
	if lib.selectionRegistry and lib.selectionRegistry[frame] then return lib.selectionRegistry[frame] end
	if lib.frameSelections and lib.frameSelections[frame] then return lib.frameSelections[frame] end
	return nil
end

local function copyDefaults(target, defaults)
	if not defaults then return end
	for key, value in pairs(defaults) do
		if target[key] == nil then
			if type(value) == "table" then
				target[key] = CopyTable(value)
			else
				target[key] = value
			end
		end
	end
end

EditMode.frames = EditMode.frames or {}
EditMode.lib = LibEditMode
EditMode.managerCategories = EditMode.managerCategories or {
	unitFrames = { labelKey = "Unit Frames", order = 100 },
	resourceBars = { labelKey = "Resource Bars", order = 200 },
	dataPanels = { labelKey = "DataPanel", order = 300 },
	trackers = { labelKey = "Dynamic Anchor Group Trackers", order = 400 },
	dungeonRaid = { labelKey = "ProfileImportProtectionDungeonRaid", order = 500 },
	loot = { labelKey = "Loot", order = 600 },
	damageMeter = { labelKey = "damageMeterTitle", order = 700 },
	utilities = { labelKey = "UIUtilities", order = 800 },
}

function EditMode:IsAvailable() return self.lib ~= nil end

function EditMode:IsInEditMode() return self:IsAvailable() and self.lib:IsInEditMode() end

function EditMode:IsFrameVisibleInEditMode() return true end

function EditMode:IsFrameVisibleInEditMode(id)
	local hidden = addon.db and addon.db[HIDDEN_FRAMES_KEY]
	return not (type(hidden) == "table" and hidden[tostring(id)] == true)
end

function EditMode:SetFrameVisibleInEditMode(id, visible)
	if not (addon.db and id) then return false end
	id = tostring(id)
	local wasVisible = self:IsFrameVisibleInEditMode(id)
	local hidden = addon.db[HIDDEN_FRAMES_KEY]
	if type(hidden) ~= "table" then
		hidden = {}
		addon.db[HIDDEN_FRAMES_KEY] = hidden
	end
	if visible then
		hidden[id] = nil
	else
		hidden[id] = true
	end
	if next(hidden) == nil then addon.db[HIDDEN_FRAMES_KEY] = nil end

	local entry = self.frames[id]
	if entry then
		if not visible and self.lib and self.lib.HideSettingsDialog then self.lib:HideSettingsDialog(entry.frame) end
		self:_applyVisibility(entry, nil, nil, true)
		if entry.onVisibilityChanged then entry.onVisibilityChanged(visible, entry.frame) end
		if visible and not wasVisible and self:IsInEditMode() and entry.onEnter and self:_isEntryEnabled(entry) then
			entry.onEnter(entry.frame, self:GetActiveLayoutName(), self:EnsureLayoutData(entry.id))
		end
	end
	return true
end

function EditMode:GetManagerCategory(categoryId, locale)
	categoryId = type(categoryId) == "string" and categoryId or "utilities"
	local definition = self.managerCategories[categoryId] or self.managerCategories.utilities
	local labelKey = definition.labelKey
	return {
		id = addonName .. ":" .. categoryId,
		label = locale[labelKey] or labelKey,
		order = definition.order,
		sort = "label",
	}
end

function EditMode:_configureManagerTogglePanel()
	if self.managerTogglePanelConfigured or not (self.lib and self.lib.ConfigureManagerTogglePanel) then return end
	self.managerTogglePanelConfigured = true
	local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
	self.lib:ConfigureManagerTogglePanel({
		title = L["EditModeFrameVisibilityPanel"],
		showAll = L["EditModeFrameVisibilityShowAll"],
		hideAll = L["EditModeFrameVisibilityHideAll"],
		menuTitle = L["EditModeFrameVisibilityMenu"],
		menuDescription = L["EditModeFrameVisibilityMenuDesc"],
		menuIconTexture = addon.variables.isTBC and "Interface\\AddOns\\EnhanceQoL\\Assets\\TBC\\EditModeMenu.tga" or nil,
		getPosition = function()
			local position = addon.db and addon.db[MANAGER_PANEL_POSITION_KEY]
			if type(position) ~= "table" or position.relativeToManager ~= true or type(position.point) ~= "string" then return nil end
			return position
		end,
		setPosition = function(point, relativePoint, x, y)
			if not addon.db or type(point) ~= "string" then return end
			addon.db[MANAGER_PANEL_POSITION_KEY] = {
				relativeToManager = true,
				point = point,
				relativePoint = type(relativePoint) == "string" and relativePoint or point,
				x = tonumber(x) or 0,
				y = tonumber(y) or 0,
			}
		end,
	})
end

local function copyValue(value)
	if type(value) == "table" then return CopyTable(value) end
	return value
end

local function sortedKeys(source)
	local result = {}
	if type(source) ~= "table" then return result end
	for key in pairs(source) do
		if type(key) == "string" then result[#result + 1] = key end
	end
	table.sort(result)
	return result
end

local function mergeMissingRecord(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then return end
	for key, value in pairs(source) do
		if target[key] == nil then target[key] = copyValue(value) end
	end
end

local function mergeMissingFrames(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then return end
	for frameId, data in pairs(source) do
		if type(data) == "table" then
			local existing = target[frameId]
			if type(existing) ~= "table" then
				target[frameId] = copyValue(data)
			else
				mergeMissingRecord(existing, data)
			end
		end
	end
end

local function pruneRecordToPositionOnly(record)
	if type(record) ~= "table" then return end
	for field in pairs(record) do
		if not POSITION_FIELDS[field] then record[field] = nil end
	end
end

local function pruneStoreToPositionOnly(store)
	if type(store) ~= "table" then return end
	for id, record in pairs(store) do
		if type(record) == "table" then
			pruneRecordToPositionOnly(record)
		else
			store[id] = nil
		end
	end
end

local function pickPreferredLegacyLayout(layouts)
	if type(layouts[DEFAULT_LAYOUT]) == "table" and next(layouts[DEFAULT_LAYOUT]) ~= nil then return DEFAULT_LAYOUT end
	for _, key in ipairs(sortedKeys(layouts)) do
		local layout = layouts[key]
		if type(layout) == "table" and next(layout) ~= nil then return key end
	end
	return nil
end

function EditMode:_migrateLegacyLayoutStore(profile)
	if type(profile) ~= "table" then return end
	if profile[PROFILE_MIGRATION_FLAG] and profile[POSITION_ONLY_FLAG] and profile[LEGACY_LAYOUTS_KEY] == nil and type(profile[SHARED_STORAGE_KEY]) == "table" then return end

	local target = profile[SHARED_STORAGE_KEY]
	if type(target) ~= "table" then
		target = {}
		profile[SHARED_STORAGE_KEY] = target
	end

	local legacyLayouts = profile[LEGACY_LAYOUTS_KEY]
	if type(legacyLayouts) == "table" then
		if next(target) == nil then
			local preferred = pickPreferredLegacyLayout(legacyLayouts)
			if preferred and type(legacyLayouts[preferred]) == "table" then mergeMissingFrames(target, legacyLayouts[preferred]) end
		end

		for _, key in ipairs(sortedKeys(legacyLayouts)) do
			local layout = legacyLayouts[key]
			if type(layout) == "table" then mergeMissingFrames(target, layout) end
		end

	end
	profile[LEGACY_LAYOUTS_KEY] = nil

	pruneStoreToPositionOnly(target)

	profile[PROFILE_MIGRATION_FLAG] = true
	profile[POSITION_ONLY_FLAG] = true
end

function EditMode:MigrateProfileData(profile) self:_migrateLegacyLayoutStore(profile) end

function EditMode:_migrateAllProfiles()
	local db = _G.EnhanceQoLDB
	if type(db) ~= "table" then return end
	if db[ROOT_MIGRATION_FLAG] and db[ROOT_POSITION_ONLY_FLAG] then return end
	local profiles = db.profiles
	if type(profiles) ~= "table" then
		db[ROOT_MIGRATION_FLAG] = true
		db[ROOT_POSITION_ONLY_FLAG] = true
		return
	end

	for _, profile in pairs(profiles) do
		self:_migrateLegacyLayoutStore(profile)
	end

	db[ROOT_MIGRATION_FLAG] = true
	db[ROOT_POSITION_ONLY_FLAG] = true
end

function EditMode:_ensureDB()
	if not addon.db then return nil end
	if self.runtimeProfileRef ~= addon.db then
		self.runtimeProfileRef = addon.db
		self.runtimeLayoutData = {}
	end
	self:_migrateAllProfiles()
	self:_migrateLegacyLayoutStore(addon.db)
	addon.db[SHARED_STORAGE_KEY] = addon.db[SHARED_STORAGE_KEY] or {}
	return addon.db[SHARED_STORAGE_KEY]
end

function EditMode:ClearStoredPosition(id)
	if not id then return end
	id = tostring(id)
	local data = addon and addon.db and addon.db[SHARED_STORAGE_KEY]
	if type(data) == "table" then data[id] = nil end
end

-- Compatibility argument for feature callbacks; positions belong to the addon profile.
function EditMode:GetActiveLayoutName() return DEFAULT_LAYOUT end

function EditMode:_resolveLayoutName() return DEFAULT_LAYOUT end

local function isInCombat() return InCombatLockdown and InCombatLockdown() end

function EditMode:_ensureCombatWatcher()
	if self.combatWatcher then return end
	local watcher = CreateFrame("Frame")
	watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
	watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
	watcher:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_ENABLED" then
			EditMode:_flushPendingLayout()
			EditMode:_flushPendingVisibility()
			EditMode:_refreshAllVisibility()
		else
			EditMode:_refreshAllVisibility()
		end
	end)
	self.combatWatcher = watcher
end

function EditMode:_flushPendingVisibility()
	local pending = self.pendingVisibility
	if not pending then return end
	self.pendingVisibility = nil
	for entry in pairs(pending) do
		if entry then self:_applyVisibility(entry, nil, entry._lastEnabled, true) end
	end
end

function EditMode:_flushPendingLayout()
	local pending = self.pendingLayout
	if not pending then return end
	self.pendingLayout = nil
	for entry, data in pairs(pending) do
		if entry and data then self:_applyLayoutPosition(entry, data, true) end
	end
end

function EditMode:_refreshAllVisibility()
	for _, entry in pairs(self.frames) do
		self:_applyVisibility(entry, nil, entry._lastEnabled, true)
	end
end

function EditMode:_setFrameShown(entry, shouldShow)
	local frame = entry.frame
	if not frame then return end

	local isProtected = frame.IsProtected and frame:IsProtected()
	if isProtected and isInCombat() then
		self.pendingVisibility = self.pendingVisibility or {}
		self.pendingVisibility[entry] = shouldShow
		self:_ensureCombatWatcher()
		return
	end

	if self.pendingVisibility then self.pendingVisibility[entry] = nil end

	local currentlyShown = frame:IsShown()
	if shouldShow then
		if not currentlyShown then frame:Show() end
	else
		if currentlyShown then frame:Hide() end
	end
end

function EditMode:_setEditModeVisibilitySuppressed(entry, suppressed)
	local frame = entry and entry.frame
	if not frame then return end
	local targets = { frame }
	local extraTargets = entry.visibilityFrames
	if type(extraTargets) == "function" then
		local ok, result = pcall(extraTargets, frame)
		if ok then
			extraTargets = result
		else
			extraTargets = nil
			geterrorhandler()(result)
		end
	end
	if type(extraTargets) == "table" then
		for _, target in pairs(extraTargets) do
			if target and target ~= frame then targets[#targets + 1] = target end
		end
	end
	entry._editModeVisibilitySuppressed = suppressed and true or nil
	if suppressed then self:_ensureCombatWatcher() end
	entry._editModeVisibilityHooks = entry._editModeVisibilityHooks or {}
	local currentTargets = {}
	for _, target in ipairs(targets) do currentTargets[target] = true end
	-- Release targets that moved to another entry, while retaining suppression
	-- from any other owner that still includes the same frame.
	for target in pairs(entry._editModeVisibilityTargets or {}) do
		if not currentTargets[target] and target._eqolEditModeVisibilityOwners then
			target._eqolEditModeVisibilityOwners[entry] = nil
			target._eqolEditModeVisibilitySuppressed = next(target._eqolEditModeVisibilityOwners) ~= nil or nil
		end
	end
	entry._editModeVisibilityTargets = currentTargets
	for _, target in ipairs(targets) do
		target._eqolEditModeVisibilityOwners = target._eqolEditModeVisibilityOwners or {}
		target._eqolEditModeVisibilityOwners[entry] = suppressed and true or nil
		target._eqolEditModeVisibilitySuppressed = next(target._eqolEditModeVisibilityOwners) ~= nil or nil
		if suppressed and not entry._editModeVisibilityHooks[target] and target.HookScript then
			entry._editModeVisibilityHooks[target] = true
			target:HookScript("OnShow", function(shownFrame)
				-- A target can move between owners while its old OnShow hook remains.
				if shownFrame._eqolEditModeVisibilitySuppressed and not isInCombat() then shownFrame:Hide() end
			end)
		end
		if suppressed and not isInCombat() and target.IsShown and target:IsShown() then target:Hide() end
	end
end

local function resolveRelativeFrame(entry)
	if not entry then return UIParent end
	local relative = entry.relativeTo
	if type(relative) == "function" then relative = relative() end
	return relative or UIParent
end

function EditMode:_applyLayoutPosition(entry, data, immediate)
	local frame = entry.frame
	if not frame then return end

	if frame.IsProtected and frame:IsProtected() and not immediate and isInCombat() then
		self.pendingLayout = self.pendingLayout or {}
		local config = {
			point = data.point,
			relativePoint = data.relativePoint,
			x = data.x,
			y = data.y,
		}
		self.pendingLayout[entry] = config
		self:_ensureCombatWatcher()
		return
	end

	if self.pendingLayout then self.pendingLayout[entry] = nil end

	local point = data.point
	local relativePoint = data.relativePoint or point
	local x = data.x or 0
	local y = data.y or 0
	local relative = resolveRelativeFrame(entry)

	frame:ClearAllPoints()
	frame:SetPoint(point, relative, relativePoint, x, y)
end

function EditMode:_seedStoredPosition(record, entry)
	record.point = record.point or (entry and entry.defaults and entry.defaults.point) or "CENTER"
	record.relativePoint = record.relativePoint or record.point or (entry and entry.defaults and entry.defaults.relativePoint) or "CENTER"
	if record.x == nil then record.x = (entry and entry.defaults and entry.defaults.x) or 0 end
	if record.y == nil then record.y = (entry and entry.defaults and entry.defaults.y) or 0 end
end

function EditMode:_writeStoredPosition(id, entry, point, relativePoint, x, y)
	local container = self:_ensureDB()
	if not container then return end
	local record = container[id]
	if type(record) ~= "table" then
		record = {}
		container[id] = record
	end
	pruneRecordToPositionOnly(record)
	self:_seedStoredPosition(record, entry)

	if point ~= nil then record.point = point end
	if relativePoint ~= nil then
		record.relativePoint = relativePoint
	elseif point ~= nil then
		record.relativePoint = point
	end
	if x ~= nil then record.x = x end
	if y ~= nil then record.y = y end
	if not record.relativePoint then record.relativePoint = record.point end
end

function EditMode:EnsureLayoutData(id, layoutName)
	local entry = self.frames[id]
	if not entry then return nil end
	local record
	local hadStoredPoint, hadStoredRelativePoint, hadStoredX, hadStoredY
	local storePosition = usesStoredPosition(entry)

	if storePosition then
		local container = self:_ensureDB()
		if not container then
			entry._fallback = entry._fallback or {}
			copyDefaults(entry._fallback, entry.defaults)
			return entry._fallback
		end

		record = container[id]
		if type(record) ~= "table" then
			record = {}
			container[id] = record
		end
		hadStoredPoint = record.point ~= nil
		hadStoredRelativePoint = record.relativePoint ~= nil
		hadStoredX = record.x ~= nil
		hadStoredY = record.y ~= nil
		pruneRecordToPositionOnly(record)
		self:_seedStoredPosition(record, entry)
	else
		self:ClearStoredPosition(id)
	end

	self.runtimeLayoutData = self.runtimeLayoutData or {}
	local runtime = self.runtimeLayoutData[id]
	if type(runtime) ~= "table" then
		runtime = {}
		if entry.legacy then
			for field, key in pairs(entry.legacy) do
				local value = addon.db and addon.db[key]
				if value ~= nil then runtime[field] = value end
			end
		end
		copyDefaults(runtime, entry.defaults)
		self.runtimeLayoutData[id] = runtime
	end

	if storePosition then
		-- Persisted position must always win; for legacy migration, keep runtime values
		-- when no stored position existed yet.
		if hadStoredPoint then
			runtime.point = record.point
		elseif runtime.point == nil then
			runtime.point = record.point or (entry.defaults and entry.defaults.point) or "CENTER"
		end

		if hadStoredRelativePoint then
			runtime.relativePoint = record.relativePoint
		elseif runtime.relativePoint == nil then
			runtime.relativePoint = record.relativePoint or runtime.point
		end

		if hadStoredX then
			runtime.x = record.x
		elseif runtime.x == nil then
			runtime.x = record.x
		end

		if hadStoredY then
			runtime.y = record.y
		elseif runtime.y == nil then
			runtime.y = record.y
		end
	end

	if runtime.point == nil then runtime.point = (entry.defaults and entry.defaults.point) or "CENTER" end
	if runtime.relativePoint == nil then runtime.relativePoint = runtime.point end
	if runtime.x == nil then runtime.x = (entry.defaults and entry.defaults.x) or 0 end
	if runtime.y == nil then runtime.y = (entry.defaults and entry.defaults.y) or 0 end

	if storePosition and (record.point ~= runtime.point or record.relativePoint ~= runtime.relativePoint or record.x ~= runtime.x or record.y ~= runtime.y) then
		self:_writeStoredPosition(id, entry, runtime.point, runtime.relativePoint, runtime.x, runtime.y)
	end

	return runtime
end

function EditMode:GetLayoutData(id, layoutName) return self:EnsureLayoutData(id, layoutName) end

function EditMode:SetFramePosition(id, point, x, y, layoutName, skipApply, relativePoint)
	local data = self:EnsureLayoutData(id, layoutName)
	if not data then return end
	local entry = self.frames[id]

	data.point = point
	data.relativePoint = relativePoint or point
	data.x = x
	data.y = y
	if usesStoredPosition(entry) then self:_writeStoredPosition(id, entry, data.point, data.relativePoint, data.x, data.y) end

	if not skipApply then self:ApplyLayout(id, layoutName) end
end

function EditMode:CalculateUIParentAnchor(frame, nudgeX, nudgeY)
	if not (frame and frame.GetCenter and UIParent and UIParent.GetCenter) then return nil end
	local centerX, centerY = UIParent:GetCenter()
	local uiRight = UIParent.GetRight and UIParent:GetRight() or 0
	local uiTop = UIParent.GetTop and UIParent:GetTop() or 0
	local frameX, frameY = frame:GetCenter()
	if not (frameX and frameY and centerX and centerY) then return nil end

	local point = "BOTTOM"
	local y
	if frameY >= centerY then
		point = "TOP"
		y = -((uiTop or 0) - ((frame.GetTop and frame:GetTop()) or frameY))
	else
		y = (frame.GetBottom and frame:GetBottom()) or frameY
	end

	local x
	if frameX >= ((uiRight or 0) * 2 / 3) then
		point = point .. "RIGHT"
		x = ((frame.GetRight and frame:GetRight()) or frameX) - (uiRight or 0)
	elseif frameX <= ((uiRight or 0) / 3) then
		point = point .. "LEFT"
		x = (frame.GetLeft and frame:GetLeft()) or frameX
	else
		x = frameX - centerX
	end

	x = snapToPixel((x or 0) + (nudgeX or 0), UIParent)
	y = snapToPixel((y or 0) + (nudgeY or 0), UIParent)
	return point, point, x, y
end

function EditMode:NormalizePositionData(id, data, options)
	local entry = type(id) == "table" and id or self.frames[id]
	if not (entry and entry.frame and type(data) == "table") then return data end
	options = type(options) == "table" and options or {}
	local relativeTo = resolveRelativeFrame(entry)
	if relativeTo ~= UIParent then return data end

	local point = data.point or (entry.defaults and entry.defaults.point) or "CENTER"
	local relativePoint = data.relativePoint or point
	if options.preserveCenter ~= false and point == "CENTER" and relativePoint == "CENTER" then
		data.point = "CENTER"
		data.relativePoint = "CENTER"
		data.x = snapToPixel(data.x or 0, UIParent)
		data.y = snapToPixel(data.y or 0, UIParent)
		return data
	end

	if options.quadrantAnchor ~= false then
		local newPoint, newRelativePoint, x, y = self:CalculateUIParentAnchor(entry.frame)
		if newPoint then
			data.point = newPoint
			data.relativePoint = newRelativePoint or newPoint
			data.x = x
			data.y = y
			return data
		end
	end

	data.point = point
	data.relativePoint = relativePoint
	data.x = snapToPixel(data.x or 0, UIParent)
	data.y = snapToPixel(data.y or 0, UIParent)
	return data
end

function EditMode:SetValue(id, field, value, layoutName, skipApply)
	local data = self:EnsureLayoutData(id, layoutName)
	if not data then return end
	local entry = self.frames[id]

	data[field] = value
	if POSITION_FIELDS[field] and usesStoredPosition(entry) then self:_writeStoredPosition(id, entry, data.point, data.relativePoint, data.x, data.y) end
	if not skipApply then self:ApplyLayout(id, layoutName) end
end

function EditMode:GetValue(id, field, layoutName)
	local data = self:EnsureLayoutData(id, layoutName)
	return data and data[field]
end

function EditMode:_isEntryEnabled(entry)
	if entry.isEnabled then
		local ok, result = pcall(entry.isEnabled, entry.frame)
		if not ok then
			geterrorhandler()(result)
			return true
		end
		return not not result
	end
	return true
end

function EditMode:_applyVisibility(entry, layoutName, enabled, forceImmediate)
	local frame = entry.frame
	local lib = self.lib
	if enabled == nil then enabled = self:_isEntryEnabled(entry) end
	entry._lastEnabled = enabled

	local selection = getSelection(lib, frame)
	local inEditMode = self:IsInEditMode()
	local inCombat = (UnitAffectingCombat and UnitAffectingCombat("player")) or isInCombat()
	local visibleInEditMode = true
	visibleInEditMode = self:IsFrameVisibleInEditMode(entry.id)
	self:_setEditModeVisibilitySuppressed(entry, inEditMode and not inCombat and enabled and not visibleInEditMode)

	if frame then
		local shouldShow
		if inEditMode and not inCombat then
			shouldShow = enabled and visibleInEditMode
		elseif entry.manageVisibilityOutsideEditMode then
			shouldShow = enabled and entry.showOutsideEditMode or false
		elseif inEditMode then
			shouldShow = false
		end
		if shouldShow ~= nil then self:_setFrameShown(entry, shouldShow, forceImmediate) end
	end

	if selection then
		if enabled and visibleInEditMode and inEditMode and not inCombat then
			selection:Show()
		else
			selection:Hide()
			selection.isSelected = false
		end
	end

	return enabled
end

function EditMode:SetFrameTitle(id, title)
	local entry = self.frames[id]
	if not entry or not entry.frame then return end
	entry.title = title
	entry.frame.editModeName = title
	local selection = getSelection(self.lib, entry.frame)
	if selection then
		selection.systemBaseName = title
		if selection.Label then selection.Label:SetText(title) end
	end
	local spec = self.lib and self.lib.managerToggleSpecs and self.lib.managerToggleSpecs[entry.managerToggleId]
	if spec then
		spec.label = title
		self.lib:RefreshManagerToggles()
	end
	local dialog = self.lib and self.lib.internal and self.lib.internal.dialog
	if dialog then
		local frame = dialog.context and dialog.context.frame or (dialog.selection and dialog.selection.parent)
		if frame == entry.frame then
			if dialog.context then dialog.context.title = title end
			if dialog.Title then dialog.Title:SetText(title) end
			if dialog.navigationActive then dialog.Navigation.title = title; dialog.Navigation:Queue() end
		end
	end
	if addon.EditModeAnchors then addon.EditModeAnchors:RegisterEntry(entry) end
end

function EditMode:RefreshFrame(id, layoutName)
	local entry = self.frames[id]
	if not entry then return end
	layoutName = self:_resolveLayoutName(layoutName)
	self:ApplyLayout(id, layoutName)
end

-- Restore only the canceled frame after profile mutations in this event settle.
function EditMode:RestoreFrameAfterDragCancel(entry)
	if not entry or entry.cancelRestorePending then return end
	entry.cancelRestorePending = true
	C_Timer.After(0, function()
		entry.cancelRestorePending = nil
		if self.frames[entry.id] == entry then self:ApplyLayout(entry.id) end
	end)
end

function EditMode:ApplyLayout(id, layoutName)
	local entry = self.frames[id]
	if not entry or not entry.frame then return end

	layoutName = self:_resolveLayoutName(layoutName)
	local data = self:EnsureLayoutData(id, layoutName)
	if not data then return end
	if usesStoredPosition(entry) then self:_writeStoredPosition(id, entry, data.point, data.relativePoint, data.x, data.y) end

	if entry.managePosition ~= false then
		local position = {
			point = data.point or entry.defaults.point or "CENTER",
			relativePoint = data.relativePoint or entry.defaults.relativePoint or data.point or entry.defaults.point or "CENTER",
			x = data.x or entry.defaults.x or 0,
			y = data.y or entry.defaults.y or 0,
		}
		self:_applyLayoutPosition(entry, position)
	end

	if entry.onApply then entry.onApply(entry.frame, layoutName, data) end

	self:_applyVisibility(entry, layoutName)
	if addon.EditModeAnchors then
		local anchors = addon.EditModeAnchors
		if anchors:InCombat() then anchors:Queue(entry.id) else anchors:Apply(entry) end
	end
end

function EditMode:_registerCallbacks()
	if self.callbacksRegistered then return end
	if not self:IsAvailable() then return end
	self.callbacksRegistered = true

	self.lib:RegisterCallback("enter", function() self:OnEnterEditMode() end)
	self.lib:RegisterCallback("exit", function() self:OnExitEditMode() end)
end

function EditMode:OnEnterEditMode()
	for _, entry in pairs(self.frames) do
		local layoutName = self:GetActiveLayoutName()
		local enabled = self:_applyVisibility(entry, layoutName)
		if enabled and self:IsFrameVisibleInEditMode(entry.id) and entry.onEnter then entry.onEnter(entry.frame, layoutName, self:EnsureLayoutData(entry.id)) end
	end
end

function EditMode:OnExitEditMode()
	for _, entry in pairs(self.frames) do
		self:_setEditModeVisibilitySuppressed(entry, false)
		if entry.onExit and entry._lastEnabled then entry.onExit(entry.frame, self:GetActiveLayoutName(), self:EnsureLayoutData(entry.id)) end
		self:_applyVisibility(entry, self:GetActiveLayoutName())
	end
end

function EditMode:_prepareSetting(id, setting)
	local copy = {}
	for key, value in pairs(setting) do
		if key ~= "field" and key ~= "onValueChanged" then copy[key] = value end
	end

	local field = setting.field
	copy.navigationField = copy.navigationField or field
	copy.navigationDefaultExplicit = setting.default ~= nil
	local onChange = setting.onValueChanged

	local requiresField = not copy.generator and copy.kind ~= EditMode.lib.SettingType.Label and copy.kind ~= EditMode.lib.SettingType.Divider and copy.kind ~= EditMode.lib.SettingType.Collapsible

	if not copy.get and requiresField then
		assert(field, "setting.field required when getter is omitted")
		copy.get = function(layoutName)
			local data = self:EnsureLayoutData(id, layoutName)
			return data and data[field]
		end
	end

	if not copy.set and requiresField then
		assert(field, "setting.field required when setter is omitted")
		copy.set = function(layoutName, value)
			self:SetValue(id, field, value, layoutName, true)
			local data = self:EnsureLayoutData(id, layoutName)
			if onChange then onChange(layoutName, value, data) end
			self:ApplyLayout(id, layoutName)
		end
	end

	local entry = self.frames[id]
	if requiresField and copy.default == nil and entry and entry.defaults then copy.default = entry.defaults[field] end

	return copy
end

function EditMode:RegisterSettings(id, settings)
	if not settings or #settings == 0 then return end
	if not self:IsAvailable() then return end

	local entry = self.frames[id]
	if not entry or not entry.frame then return end

	if addon.EditModeNavigationSmallFrames then addon.EditModeNavigationSmallFrames.Prepare(id, settings, entry.navigationRegistration or {}) end
	local prepared = {}
	for index = 1, #settings do
		local s = self:_prepareSetting(id, settings[index])
		prepared[index] = s
		if settings[index].field then
			entry.settingsByField = entry.settingsByField or {}
			entry.settingsByField[settings[index].field] = s
		end
	end
	entry.preparedSettings = prepared
	if self.lib.SetFrameSettingsNavigation and entry.navigationRegistration then
		local options = entry.navigationRegistration
		options.settings = settings
		local navigation = options.settingsNavigation
		if navigation == nil and addon.EditModeNavigationProfiles then navigation = addon.EditModeNavigationProfiles.Get(id, options) end
		if navigation == false then self.lib:SetFrameSettingsNavigation(entry.frame, false)
		else self.lib:SetFrameSettingsNavigation(entry.frame, navigation or {}) end
	end

	self.lib:AddFrameSettings(entry.frame, prepared)
end

function EditMode:RegisterButtons(id, buttons)
	if not buttons or #buttons == 0 then return end
	if not self:IsAvailable() then return end

	local entry = self.frames[id]
	if not entry or not entry.frame then return end

	entry.buttons = entry.buttons or {}
	for index = 1, #buttons do
		local source = buttons[index]
		if source and source.text and source.click then
			local prepared = {
				text = source.text,
				click = function(...)
					local ok, err = pcall(source.click, ...)
					if not ok then geterrorhandler()(err) end
				end,
			}
			if source.layout ~= nil then prepared.layout = source.layout end
			self.lib:AddFrameSettingsButton(entry.frame, prepared)
			entry.buttons[#entry.buttons + 1] = prepared
		elseif source and source.text then
			local prepared = {
				text = source.text,
				click = function() end,
			}
			if source.layout ~= nil then prepared.layout = source.layout end
			self.lib:AddFrameSettingsButton(entry.frame, prepared)
			entry.buttons[#entry.buttons + 1] = prepared
		end
	end
end

function EditMode:RegisterFrame(id, opts)
	assert(type(id) == "string" and id ~= "", "frame id must be a non-empty string")
	opts = opts or {}

	local frame = opts.frame
	if not frame and opts.createFrame then frame = opts.createFrame() end
	assert(frame, "EditMode:RegisterFrame requires a frame")

	local defaults = opts.layoutDefaults or {}
	defaults.point = defaults.point or "CENTER"
	defaults.relativePoint = defaults.relativePoint or defaults.point
	defaults.x = defaults.x or 0
	defaults.y = defaults.y or 0

	local entry = {
		id = id,
		frame = frame,
		defaults = defaults,
		legacy = opts.legacyKeys,
		isEnabled = opts.isEnabled,
		managePosition = opts.managePosition,
		persistPosition = opts.persistPosition,
		normalizePosition = opts.normalizePosition,
		normalizePositionOptions = opts.normalizePositionOptions,
		relativeTo = opts.relativeTo,
		showOutsideEditMode = not not opts.showOutsideEditMode,
		manageVisibilityOutsideEditMode = opts.manageVisibilityOutsideEditMode ~= false,
		visibilityFrames = opts.visibilityFrames,
		managerCategory = opts.managerCategory,
		onApply = opts.onApply,
		onEnter = opts.onEnter,
		onExit = opts.onExit,
		onVisibilityChanged = opts.onVisibilityChanged,
		onPositionChanged = opts.onPositionChanged,
		anchorAdapter = opts.anchorAdapter,
		title = opts.title,
		anchorLabel = opts.anchorLabel,
		anchorSelectable = opts.anchorSelectable,
		anchorContext = opts.anchorContext,
	}

	self.frames[id] = entry
	entry.navigationRegistration = opts

	if opts.title then frame.editModeName = opts.title end

	self:EnsureLayoutData(id, nil)

	if entry.manageVisibilityOutsideEditMode and not entry.showOutsideEditMode then frame:Hide() end

	if self:IsAvailable() then
		self:_registerCallbacks()
		self:_configureManagerTogglePanel()

		local defaultPosition = {
			point = self:GetValue(id, "point") or defaults.point,
			relativePoint = self:GetValue(id, "relativePoint") or defaults.relativePoint,
			x = self:GetValue(id, "x") or defaults.x,
			y = self:GetValue(id, "y") or defaults.y,
			enableOverlayToggle = opts.enableOverlayToggle or false,
			overlayColor = opts.overlayColor,
			collapseExclusive = opts.collapseExclusive or false,
			allowDrag = opts.allowDrag,
			settingsSpacing = opts.settingsSpacing,
			sliderHeight = opts.sliderHeight,
			dropdownHeight = opts.dropdownHeight,
			checkboxColorHeight = opts.checkboxColorHeight,
			multiDropdownSummaryHeight = opts.multiDropdownSummaryHeight,
			dividerHeight = opts.dividerHeight,
			showSettingsReset = opts.showSettingsReset,
			showReset = opts.showReset,
			settingsMaxHeight = opts.settingsMaxHeight,
			onDragCancel = function() self:RestoreFrameAfterDragCancel(entry) end,
		}

		self.lib:AddFrame(frame, function(_, layoutName, point, x, y)
			local relativePoint = point
			if frame.GetPoint then
				local currentPoint, _, currentRelativePoint = frame:GetPoint(1)
				if currentPoint == point and currentRelativePoint then relativePoint = currentRelativePoint end
			end
			self:SetFramePosition(id, point, x, y, layoutName, true, relativePoint)
			local data = self:EnsureLayoutData(id, layoutName)
			if entry.normalizePosition then
				data = self:NormalizePositionData(entry, data, entry.normalizePositionOptions)
				if usesStoredPosition(entry) and data then self:_writeStoredPosition(id, entry, data.point, data.relativePoint, data.x, data.y) end
			end
			if opts.onPositionChanged then opts.onPositionChanged(frame, layoutName, data) end
			self:ApplyLayout(id, layoutName)
		end, defaultPosition)

		if opts.settings then self:RegisterSettings(id, opts.settings) end
		if opts.buttons then self:RegisterButtons(id, opts.buttons) end
		if opts.showInManager ~= false and self.lib.AddManagerCheckbox then
			local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
			entry.managerToggleId = addonName .. ":" .. id
			self.lib:AddManagerCheckbox({
				id = entry.managerToggleId,
				label = opts.managerLabel or opts.title or id,
				category = self:GetManagerCategory(entry.managerCategory, L),
				get = function() return self:IsFrameVisibleInEditMode(id) end,
				set = function(_, value) return self:SetFrameVisibleInEditMode(id, value) end,
				isEnabled = function() return self:_isEntryEnabled(entry) end,
			})
		end
	end

	self:ApplyLayout(id, self:GetActiveLayoutName())
	if addon.EditModeAnchors then addon.EditModeAnchors:RegisterEntry(entry) end
	return frame
end

function EditMode:UnregisterFrame(id, purgeData)
	if addon.EditModeAnchors then addon.EditModeAnchors:UnregisterEntry(id, purgeData) end
	if not id then return end
	id = tostring(id)
	local entry = self.frames and self.frames[id]
	if not entry then return end
	self:_setEditModeVisibilitySuppressed(entry, false)

	if self.pendingLayout then self.pendingLayout[entry] = nil end
	if self.pendingVisibility then self.pendingVisibility[entry] = nil end

	if self:IsAvailable() and entry.frame and self.lib then
		local frame = entry.frame
		local lib = self.lib
		if lib.HideSettingsDialog then lib:HideSettingsDialog(frame) end
		local selection = getSelection(lib, frame)
		if selection then
			if lib.internal and lib.internal.magnetismManager and lib.internal.magnetismManager.UnregisterFrame then lib.internal.magnetismManager:UnregisterFrame(selection) end
			selection:Hide()
			selection:SetParent(nil)
			if lib.selectionRegistry then lib.selectionRegistry[frame] = nil end
			if lib.frameSelections then lib.frameSelections[frame] = nil end
		end
		if lib.frameHandlers then lib.frameHandlers[frame] = nil end
		if lib.frameCallbacks then lib.frameCallbacks[frame] = nil end
		if lib.defaultPositions then lib.defaultPositions[frame] = nil end
		if lib.frameDefaults then lib.frameDefaults[frame] = nil end
		if lib.settingSheets then lib.settingSheets[frame] = nil end
		if lib.frameSettings then lib.frameSettings[frame] = nil end
		if lib.buttonSpecs then lib.buttonSpecs[frame] = nil end
		if lib.frameButtons then lib.frameButtons[frame] = nil end
		if lib.overlayToggleFlags then lib.overlayToggleFlags[frame] = nil end
		if lib.dragPredicates then lib.dragPredicates[frame] = nil end
		if lib.collapseFlags then lib.collapseFlags[frame] = nil end
		if lib.collapseExclusiveFlags then lib.collapseExclusiveFlags[frame] = nil end
		if lib.resetToggles then lib.resetToggles[frame] = nil end
		if lib.settingsResetToggles then lib.settingsResetToggles[frame] = nil end
		if lib.settingsSpacingOverrides then lib.settingsSpacingOverrides[frame] = nil end
		if lib.settingsMaxHeightOverrides then lib.settingsMaxHeightOverrides[frame] = nil end
		if lib.sliderHeightOverrides then lib.sliderHeightOverrides[frame] = nil end
		if lib.rowHeightOverrides then lib.rowHeightOverrides[frame] = nil end
		if entry.managerToggleId and lib.RemoveManagerToggle then lib:RemoveManagerToggle(entry.managerToggleId) end
	end

	local data = addon.db and addon.db[SHARED_STORAGE_KEY]
	if purgeData and type(data) == "table" then data[id] = nil end
	local hidden = addon.db and addon.db[HIDDEN_FRAMES_KEY]
	if purgeData and type(hidden) == "table" then
		hidden[id] = nil
		if next(hidden) == nil then addon.db[HIDDEN_FRAMES_KEY] = nil end
	end
	if self.runtimeLayoutData then self.runtimeLayoutData[id] = nil end

	self.frames[id] = nil
end
