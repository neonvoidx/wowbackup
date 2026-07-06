local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Mover = addon.Mover or {}
addon.Mover.functions = addon.Mover.functions or {}
addon.Mover.variables = addon.Mover.variables or {}
local MouseIsOver = addon.functions and addon.functions.MouseIsOver

local db

local function initDbValue(key, defaultValue)
	if db[key] == nil then db[key] = defaultValue end
end

function addon.Mover.functions.InitDB()
	if type(EnhanceQoLMoverDB) ~= "table" then EnhanceQoLMoverDB = {} end
	addon.Mover.db = EnhanceQoLMoverDB
	db = addon.Mover.db

	initDbValue("enabled", false)
	initDbValue("requireModifier", true)
	initDbValue("modifier", "SHIFT")
	initDbValue("scaleEnabled", false)
	initDbValue("scaleModifier", "CTRL")
	initDbValue("positionPersistence", "reset")
	initDbValue("frames", {})
	if type(db.frames) ~= "table" then db.frames = {} end
	db.frames.LFGDungeonReadyDialog = nil
	db.frames.LFGListInviteDialog = nil
end

local function normalizeDbVarFromId(id)
	if not id or type(id) ~= "string" then return nil end
	return string.lower(string.sub(id, 1, 1)) .. string.sub(id, 2)
end

local function resolveFramePath(path)
	if not path or type(path) ~= "string" then return nil end
	local first, rest = path:match("([^.]+)%.?(.*)")
	local obj = _G[first]
	if not obj then return nil end
	if rest and rest ~= "" then
		for seg in rest:gmatch("([^.]+)") do
			obj = obj and obj[seg]
			if not obj then return nil end
		end
	end
	return obj
end

local registry = addon.Mover.variables.registry or {
	groups = {},
	groupList = {},
	frames = {},
	frameList = {},
	byName = {},
	addonIndex = {},
	noAddonEntries = {},
}
addon.Mover.variables.registry = registry
registry.addonIndex = registry.addonIndex or {}
registry.noAddonEntries = registry.noAddonEntries or {}

local IsAddonLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
local TextureLoadingGroupMixin = _G.TextureLoadingGroupMixin

local runtimeState = addon.Mover.variables.runtimeState
if type(runtimeState) ~= "table" then
	runtimeState = setmetatable({}, { __mode = "k" })
	addon.Mover.variables.runtimeState = runtimeState
end

local function getRuntimeState(object)
	if not object then return nil end
	local state = runtimeState[object]
	if not state then
		state = {}
		runtimeState[object] = state
	end
	return state
end

local function peekRuntimeState(object)
	return object and runtimeState[object] or nil
end

local function entryAddonList(entry)
	local list = {}
	local seen = {}
	if entry then
		if type(entry.addon) == "string" then
			if not seen[entry.addon] then
				seen[entry.addon] = true
				table.insert(list, entry.addon)
			end
		elseif type(entry.addon) == "table" then
			for _, name in ipairs(entry.addon) do
				if type(name) == "string" and not seen[name] then
					seen[name] = true
					table.insert(list, name)
				end
			end
		end
		if type(entry.addons) == "table" then
			for _, name in ipairs(entry.addons) do
				if type(name) == "string" and not seen[name] then
					seen[name] = true
					table.insert(list, name)
				end
			end
		end
	end
	return list
end

local function indexEntryByAddon(entry)
	local list = entryAddonList(entry)
	if #list == 0 then
		table.insert(registry.noAddonEntries, entry)
		return
	end
	for _, name in ipairs(list) do
		registry.addonIndex[name] = registry.addonIndex[name] or {}
		table.insert(registry.addonIndex[name], entry)
	end
end

local function isAnyAddonLoaded(entry)
	local list = entryAddonList(entry)
	if #list == 0 then return true end
	if not IsAddonLoaded then return false end
	for _, name in ipairs(list) do
		if IsAddonLoaded(name) then return true end
	end
	return false
end

local function matchesAddon(entry, addonName)
	if not addonName then return false end
	for _, name in ipairs(entryAddonList(entry)) do
		if name == addonName then return true end
	end
	return false
end

local function resolveEntry(entryOrId)
	if type(entryOrId) == "table" then return entryOrId end
	if type(entryOrId) == "string" then return registry.frames[entryOrId] end
	return nil
end

local POSITION_PERSISTENCE_DEFAULT = "reset"
local POSITION_PERSISTENCE_GLOBAL = "global"
local positionPersistenceModes = {
	close = true,
	lockout = true,
	reset = true,
	off = true,
}

local function normalizePositionPersistence(value)
	return positionPersistenceModes[value] and value or nil
end

local function getGlobalPositionPersistence()
	return normalizePositionPersistence(db and db.positionPersistence) or POSITION_PERSISTENCE_DEFAULT
end

local function getEntryPositionPersistence(_entry, frameDb)
	return normalizePositionPersistence(frameDb and frameDb.positionPersistence) or getGlobalPositionPersistence()
end

local function ensureFrameDb(entry)
	local resolved = resolveEntry(entry)
	if not resolved then return nil end
	local frames = db.frames
	frames[resolved.id] = frames[resolved.id] or {}
	local frameDb = frames[resolved.id]
	if frameDb.enabled == nil then frameDb.enabled = resolved.defaultEnabled ~= false end
	if frameDb.positionPersistence ~= nil and not normalizePositionPersistence(frameDb.positionPersistence) then frameDb.positionPersistence = nil end
	return frameDb
end

function addon.Mover.functions.GetFramePositionPersistence(entry)
	local frameDb = ensureFrameDb(entry)
	return normalizePositionPersistence(frameDb and frameDb.positionPersistence) or POSITION_PERSISTENCE_GLOBAL
end

local function modifierPressed()
	if not db.requireModifier then return true end
	local mod = db.modifier or "SHIFT"
	return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "CTRL" and IsControlKeyDown()) or (mod == "ALT" and IsAltKeyDown())
end

local SCALE_MIN = 0.5
local SCALE_MAX = 2
local SCALE_STEP = 0.05

local function clampScale(value)
	if type(value) ~= "number" then return 1 end
	if value < SCALE_MIN then return SCALE_MIN end
	if value > SCALE_MAX then return SCALE_MAX end
	return value
end

local function scaleModifierPressed()
	local mod = db.scaleModifier or "CTRL"
	return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "CTRL" and IsControlKeyDown()) or (mod == "ALT" and IsAltKeyDown())
end

local function resolveScale(_frame, frameDb)
	if not db.scaleEnabled then return nil end
	if frameDb and type(frameDb.scale) == "number" then return clampScale(frameDb.scale) end
	return nil
end

function addon.Mover.functions.RegisterGroup(id, label, opts)
	if not id or id == "" then return nil end
	local group = registry.groups[id]
	if not group then
		group = {
			id = id,
			label = label or id,
			order = opts and opts.order or nil,
			expanded = opts and opts.expanded or false,
		}
		registry.groups[id] = group
		table.insert(registry.groupList, id)
	else
		if label then group.label = label end
		if opts and opts.order ~= nil then group.order = opts.order end
		if opts and opts.expanded ~= nil then group.expanded = opts.expanded end
	end
	return group
end

local function makeSettingKey(id) return "moverFrame_" .. tostring(id):gsub("[^%w]", "_") end

function addon.Mover.functions.RegisterFrame(def)
	if not def or not def.id then return nil end
	if registry.frames[def.id] then return registry.frames[def.id] end

	local names
	if type(def.names) == "table" then
		names = def.names
	elseif type(def.names) == "string" then
		names = { def.names }
	elseif type(def.name) == "string" then
		names = { def.name }
	elseif type(def.frame) == "string" then
		names = { def.frame }
	else
		names = { def.id }
	end

	local handles = {}
	local handlesSeen = {}
	local function addHandle(handle)
		if type(handle) ~= "string" or handle == "" then return end
		if handlesSeen[handle] then return end
		handlesSeen[handle] = true
		table.insert(handles, handle)
	end

	local scaleTargets = {}
	local scaleTargetsSeen = {}
	local function addScaleTarget(path)
		if type(path) ~= "string" or path == "" then return end
		if scaleTargetsSeen[path] then return end
		scaleTargetsSeen[path] = true
		table.insert(scaleTargets, path)
	end

	local function addRelativeHandles(list)
		if type(list) == "string" then list = { list } end
		if type(list) ~= "table" then return end
		for _, rel in ipairs(list) do
			if type(rel) == "string" and rel ~= "" then
				for _, base in ipairs(names) do
					addHandle(base .. "." .. rel)
				end
			end
		end
	end

	if type(def.handles) == "string" then
		addHandle(def.handles)
	elseif type(def.handles) == "table" then
		for _, handle in ipairs(def.handles) do
			addHandle(handle)
		end
	end
	addRelativeHandles(def.handlesRelative or def.dragbars or def.subframes)
	if type(def.scaleTargets) == "string" then
		addScaleTarget(def.scaleTargets)
	elseif type(def.scaleTargets) == "table" then
		for _, path in ipairs(def.scaleTargets) do
			addScaleTarget(path)
		end
	end
	if type(def.scaleTarget) == "string" then addScaleTarget(def.scaleTarget) end

	local disableMove = def and (def.disableMove or def.scaleOnly) or nil
	local entry = {
		id = def.id,
		label = def.label or def.id,
		group = def.group or "default",
		groupLabel = def.groupLabel,
		groupOrder = def.groupOrder,
		defaultEnabled = def.defaultEnabled,
		names = names,
		handles = (#handles > 0) and handles or nil,
		scaleTargets = (#scaleTargets > 0) and scaleTargets or nil,
		addon = def.addon,
		useRootHandle = def.useRootHandle,
		handlesOnly = def.handlesOnly,
		keepTwoPointSize = def.keepTwoPointSize,
		disableMove = disableMove,
		ignoreFramePositionManager = def.ignoreFramePositionManager,
		userPlaced = def.userPlaced,
		skipOnHide = def.skipOnHide,
		settingKey = def.settingKey or makeSettingKey(def.id),
	}

	registry.frames[entry.id] = entry
	table.insert(registry.frameList, entry)

	addon.Mover.functions.RegisterGroup(entry.group, entry.groupLabel, {
		order = entry.groupOrder,
	})

	for _, name in ipairs(entry.names) do
		registry.byName[name] = entry.id
	end

	ensureFrameDb(entry)
	addon.Mover.functions.MigrateLegacyPosition(entry)
	indexEntryByAddon(entry)
	addon.Mover.functions.TryHookEntry(entry)

	return entry
end

function addon.Mover.functions.GetGroups()
	local out = {}
	for _, id in ipairs(registry.groupList) do
		local group = registry.groups[id]
		if group then table.insert(out, group) end
	end
	table.sort(out, function(a, b)
		local ao = a.order or 1000
		local bo = b.order or 1000
		if ao ~= bo then return ao < bo end
		return (a.label or a.id) < (b.label or b.id)
	end)
	return out
end

function addon.Mover.functions.GetEntriesForGroup(groupId)
	local list = {}
	for _, entry in ipairs(registry.frameList) do
		if entry.group == groupId then table.insert(list, entry) end
	end
	table.sort(list, function(a, b) return (a.label or a.id) < (b.label or b.id) end)
	return list
end

function addon.Mover.functions.GetEntryForFrameName(name)
	local id = name and registry.byName[name] or nil
	return id and registry.frames[id] or nil
end

function addon.Mover.functions.IsFrameEnabled(entry)
	local resolved = resolveEntry(entry)
	if not resolved then return false end
	local frameDb = ensureFrameDb(resolved)
	return frameDb and frameDb.enabled ~= false
end

function addon.Mover.functions.SetFrameEnabled(entry, value)
	local resolved = resolveEntry(entry)
	if not resolved then return end
	local frameDb = ensureFrameDb(resolved)
	if frameDb then frameDb.enabled = value and true or false end
end

function addon.Mover.functions.MigrateLegacyPosition(entry)
	local resolved = resolveEntry(entry)
	if not resolved then return end
	local frameDb = ensureFrameDb(resolved)
	if frameDb and frameDb.point then return end
	for _, name in ipairs(resolved.names or {}) do
		local legacyKey = normalizeDbVarFromId(name)
		local legacy = legacyKey and db[legacyKey] or nil
		if legacy and legacy.point and legacy.x and legacy.y then
			frameDb.point = legacy.point
			frameDb.x = legacy.x
			frameDb.y = legacy.y
			return
		end
	end
end

addon.Mover.variables.pendingApply = addon.Mover.variables.pendingApply or {}
addon.Mover.variables.pendingDefaultReset = addon.Mover.variables.pendingDefaultReset or {}
addon.Mover.variables.combatQueue = addon.Mover.variables.combatQueue or {}
addon.Mover.variables.sessionPositions = addon.Mover.variables.sessionPositions or {}

function addon.Mover.functions.deferApply(frame, entry)
	if not frame then return end
	addon.Mover.variables.pendingApply[frame] = entry or true
end

function addon.Mover.functions.deferDefaultReset(frame, entry)
	if not frame then return end
	addon.Mover.variables.pendingDefaultReset[frame] = entry or true
end

local function isEntryActive(entry)
	if not db or not db.enabled then return false end
	return addon.Mover.functions.IsFrameEnabled(entry)
end

addon.Mover.variables.scaleTargets = addon.Mover.variables.scaleTargets or {}
addon.Mover.variables.scaleMouseover = addon.Mover.variables.scaleMouseover or {}
addon.Mover.variables.moveHandles = addon.Mover.variables.moveHandles or {}
addon.Mover.variables.scaleCaptureFrame = addon.Mover.variables.scaleCaptureFrame or nil

local validAnchorPoints = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value > -100000 and value < 100000
end

local function isUsablePositionData(posData)
	return type(posData) == "table" and validAnchorPoints[posData.point] and isFiniteNumber(posData.x) and isFiniteNumber(posData.y)
end

local function isFrameMostlyOnScreen(frame)
	if not frame or not frame.GetLeft or not frame.GetRight or not frame.GetTop or not frame.GetBottom then return true end
	local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	if not (isFiniteNumber(left) and isFiniteNumber(right) and isFiniteNumber(top) and isFiniteNumber(bottom)) then return false end
	local screenWidth = GetScreenWidth and GetScreenWidth() or UIParent:GetWidth()
	local screenHeight = GetScreenHeight and GetScreenHeight() or UIParent:GetHeight()
	if not (isFiniteNumber(screenWidth) and isFiniteNumber(screenHeight) and screenWidth > 0 and screenHeight > 0) then return true end
	local minVisible = 24
	return right >= minVisible and left <= (screenWidth - minVisible) and top >= minVisible and bottom <= (screenHeight - minVisible)
end

local function blockPanelDragCallback() return false end

local function clearPanelDragStartCallback(handle)
	if TextureLoadingGroupMixin and TextureLoadingGroupMixin.RemoveTexture then
		TextureLoadingGroupMixin.RemoveTexture({ textures = handle }, "onDragStartCallback")
	else
		handle.onDragStartCallback = nil
	end
end

-- Determine a valid scale target without stealing wheel from scrollable/clickable frames.
local function findScaleTargetUnderMouse()
	if not GetMouseFoci then return nil end
	local mouseover = addon.Mover.variables.scaleMouseover
	if not mouseover or not next(mouseover) then return nil end
	local scaleTargets = addon.Mover.variables.scaleTargets
	local moveHandles = addon.Mover.variables.moveHandles
	for _, focus in ipairs(GetMouseFoci()) do
		local root = scaleTargets and scaleTargets[focus]
		local rootState = peekRuntimeState(root)
		local entry = rootState and rootState.moverEntry or nil
		local active = entry and isEntryActive(entry)
		if active then return root end

		local isMoveHandle = moveHandles and moveHandles[focus]
		if not active and not isMoveHandle then
			if focus.IsForbidden and focus:IsForbidden() then return nil end
			if IsFrameHandle and IsFrameHandle(focus) then return nil end
			local hasWheel = focus.IsMouseWheelEnabled and focus:IsMouseWheelEnabled()
			local hasClick = focus.IsMouseClickEnabled and focus:IsMouseClickEnabled()
			if issecretvalue and (issecretvalue(hasWheel) or issecretvalue(hasClick)) then return nil end
			if hasWheel or hasClick then return nil end
		end
	end
	return nil
end

function addon.Mover.functions.CheckScaleWheelCapture()
	local captureFrame = addon.Mover.variables.scaleCaptureFrame
	if not captureFrame then return end
	captureFrame:EnableMouseWheel(false)
	if not db or not db.enabled or not db.scaleEnabled then return end
	if not scaleModifierPressed() then return end
	if findScaleTargetUnderMouse() then captureFrame:EnableMouseWheel(true) end
end

function addon.Mover.functions.UpdateScaleWheelCaptureState()
	local captureFrame = addon.Mover.variables.scaleCaptureFrame
	if not captureFrame then return end
	if db and db.enabled and db.scaleEnabled then
		local state = getRuntimeState(captureFrame)
		if not state.modifierEventRegistered then
			captureFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
			state.modifierEventRegistered = true
		end
	else
		local state = peekRuntimeState(captureFrame)
		if state and state.modifierEventRegistered then
			captureFrame:UnregisterEvent("MODIFIER_STATE_CHANGED")
			state.modifierEventRegistered = nil
		end
	end
	if db and db.enabled and db.scaleEnabled and scaleModifierPressed() then
		if captureFrame:GetScript("OnUpdate") == nil then captureFrame:SetScript("OnUpdate", addon.Mover.functions.CheckScaleWheelCapture) end
		addon.Mover.functions.CheckScaleWheelCapture()
	else
		captureFrame:EnableMouseWheel(false)
		if captureFrame:GetScript("OnUpdate") ~= nil then captureFrame:SetScript("OnUpdate", nil) end
	end
end

function addon.Mover.functions.HandleScaleWheel(delta)
	if not db or not db.enabled or not db.scaleEnabled then return end
	if not scaleModifierPressed() then return end
	local target = findScaleTargetUnderMouse()
	local state = peekRuntimeState(target)
	if not (state and state.scaleWheel) then return end
	state.scaleWheel(delta)
end

-- Global capture frame used to proxy mouse wheel scaling when the modifier is held.
function addon.Mover.functions.EnsureScaleCaptureFrame()
	if addon.Mover.variables.scaleCaptureFrame then return end
	local captureFrame = CreateFrame("Frame")
	captureFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	captureFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	captureFrame:SetFrameStrata("TOOLTIP")
	captureFrame:SetFrameLevel(9999)
	captureFrame:EnableMouseWheel(false)
	captureFrame:SetScript("OnEvent", function() addon.Mover.functions.UpdateScaleWheelCaptureState() end)
	captureFrame:SetScript("OnMouseWheel", function(_, delta) addon.Mover.functions.HandleScaleWheel(delta) end)
	addon.Mover.variables.scaleCaptureFrame = captureFrame
	addon.Mover.functions.UpdateScaleWheelCaptureState()
end

local function MoveKeepTwoPointSize(frame, x, y, point, relPoint)
	point = point or "TOPLEFT"
	relPoint = relPoint or point

	local w, h = frame:GetSize()
	if not w or not h or w <= 0 or h <= 0 then
		w = frame:GetWidth() or 700
		h = frame:GetHeight() or 700
	end

	frame:ClearAllPoints()

	frame:SetPoint(point, UIParent, relPoint, x or 0, y or 0)

	frame:SetPoint("BOTTOMRIGHT", UIParent, relPoint, (x or 0) + w, (y or 0) - h)
end

local function captureDefaultPoints(frame)
	if not frame then return end
	local state = getRuntimeState(frame)
	if state.defaultPoints then return end
	local numPoints = frame.GetNumPoints and frame:GetNumPoints() or 0
	if not numPoints or numPoints <= 0 then return end
	local points = {}
	for i = 1, numPoints do
		local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
		if point then
			local relativeName = relativeTo and relativeTo.GetName and relativeTo:GetName() or nil
			points[#points + 1] = {
				point = point,
				relative = relativeTo,
				relativeName = relativeName,
				relativePoint = relativePoint,
				x = xOfs,
				y = yOfs,
			}
		end
	end
	if #points > 0 then state.defaultPoints = points end
end

local function applyDefaultPoints(frame)
	local state = peekRuntimeState(frame)
	local points = state and state.defaultPoints
	if not points or #points == 0 then return false end
	if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return false end
	frame:ClearAllPoints()
	for _, data in ipairs(points) do
		local relative = data.relative
		if type(relative) == "string" then relative = _G[relative] end
		if not relative and data.relativeName then relative = _G[data.relativeName] end
		relative = relative or UIParent
		local relativePoint = data.relativePoint or data.point
		frame:SetPoint(data.point, relative, relativePoint, data.x or 0, data.y or 0)
	end
	return true
end

local function captureDefaultState(frame)
	if not frame then return end
	local state = getRuntimeState(frame)
	if state.moverDefaults then return end
	local defaults = {}
	if frame.IsMovable then defaults.movable = frame:IsMovable() end
	if frame.IsClampedToScreen then defaults.clamped = frame:IsClampedToScreen() end
	if frame.IsMouseEnabled then defaults.mouseEnabled = frame:IsMouseEnabled() end
	if frame.IsMouseWheelEnabled then defaults.mouseWheelEnabled = frame:IsMouseWheelEnabled() end
	if frame.IsUserPlaced then defaults.userPlaced = frame:IsUserPlaced() end
	defaults.ignoreFramePositionManager = frame.ignoreFramePositionManager
	state.moverDefaults = defaults
end

local function applyFrameState(frame, entry, active, useOverlay)
	local state = peekRuntimeState(frame)
	local defaults = state and state.moverDefaults
	if not defaults then return end
	if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end
	if active then
		if frame.SetMovable then frame:SetMovable(true) end
		if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
		if entry.userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(entry.userPlaced) end
		if entry.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = entry.ignoreFramePositionManager end
		if not useOverlay and frame.EnableMouse then frame:EnableMouse(true) end
		return
	end
	if defaults.movable ~= nil and frame.SetMovable then frame:SetMovable(defaults.movable) end
	if defaults.clamped ~= nil and frame.SetClampedToScreen then frame:SetClampedToScreen(defaults.clamped) end
	if not useOverlay and defaults.mouseEnabled ~= nil and frame.EnableMouse then frame:EnableMouse(defaults.mouseEnabled) end
	if defaults.mouseWheelEnabled ~= nil and frame.EnableMouseWheel then frame:EnableMouseWheel(defaults.mouseWheelEnabled) end
	if entry.userPlaced ~= nil and defaults.userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(defaults.userPlaced) end
	if entry.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = defaults.ignoreFramePositionManager end
end

local function applyDragTargetState(frame, active)
	local state = peekRuntimeState(frame)
	local defaults = state and state.moverDefaults
	if not defaults then return end
	if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then return end
	if active then
		if frame.EnableMouse then frame:EnableMouse(true) end
		return
	end
	if defaults.mouseEnabled ~= nil and frame.EnableMouse then frame:EnableMouse(defaults.mouseEnabled) end
	if defaults.mouseWheelEnabled ~= nil and frame.EnableMouseWheel then frame:EnableMouseWheel(defaults.mouseWheelEnabled) end
end

local function getPositionData(entry, frameDb)
	local mode = getEntryPositionPersistence(entry, frameDb)
	if mode == "lockout" then
		local store = addon.Mover.variables.sessionPositions
		return store and store[entry.id] or nil
	end
	if mode == "reset" then return frameDb end
	return nil
end

local function setPositionData(entry, frameDb, point, x, y)
	local mode = getEntryPositionPersistence(entry, frameDb)
	if mode == "close" or mode == "off" then return end
	if mode == "lockout" then
		local store = addon.Mover.variables.sessionPositions
		store = store or {}
		addon.Mover.variables.sessionPositions = store
		store[entry.id] = store[entry.id] or {}
		local data = store[entry.id]
		data.point = point
		data.x = x
		data.y = y
		return
	end
	if frameDb then
		frameDb.point = point
		frameDb.x = x
		frameDb.y = y
	end
end

local function clearPositionData(entry, frameDb)
	local store = addon.Mover.variables.sessionPositions
	if store then store[entry.id] = nil end
	if frameDb then
		frameDb.point = nil
		frameDb.x = nil
		frameDb.y = nil
	end
end

function addon.Mover.functions.SetFramePositionPersistence(entry, value)
	local resolved = resolveEntry(entry)
	if not resolved then return end
	local frameDb = ensureFrameDb(resolved)
	if not frameDb then return end
	local mode = normalizePositionPersistence(value)
	frameDb.positionPersistence = mode
	if (mode or getGlobalPositionPersistence()) == "off" then clearPositionData(resolved, frameDb) end
	addon.Mover.functions.RefreshEntry(resolved)
end

local function isCollectionsMoveEnabled()
	if not db or not db.enabled then return false end
	local entry = addon.Mover.functions.GetEntryForFrameName("CollectionsJournal")
	if not entry then return false end
	return addon.Mover.functions.IsFrameEnabled(entry)
end

local function isPlayerChoiceMoveEnabled()
	if not db or not db.enabled then return false end
	local entry = addon.Mover.functions.GetEntryForFrameName("PlayerChoiceFrame")
	if not entry then return false end
	return addon.Mover.functions.IsFrameEnabled(entry)
end

local function FixWardrobeSecondaryAppearanceLabel()
	if not isCollectionsMoveEnabled() then return false end
	local wardrobe = _G.WardrobeFrame
	local transmog = wardrobe and wardrobe.WardrobeTransmogFrame or _G.WardrobeTransmogFrame
	local checkbox = transmog and transmog.ToggleSecondaryAppearanceCheckbox
	local label = checkbox and checkbox.Label
	if not (checkbox and label and label.ClearAllPoints) then return false end

	label:ClearAllPoints()
	label:SetPoint("LEFT", checkbox, "RIGHT", 2, 1)
	label:SetPoint("RIGHT", checkbox, "RIGHT", 160, 1)
	return true
end

local function FixPlayerChoiceAnchor()
	local frame = _G.PlayerChoiceFrame
	if not frame then return false end
	local state = getRuntimeState(frame)
	if state.fixHooks then return true end
	if not isPlayerChoiceMoveEnabled() then return false end

	state.fixHooks = true
	frame:HookScript("OnHide", function(self)
		if not isPlayerChoiceMoveEnabled() then return end
		if InCombatLockdown() and self:IsProtected() then return end

		local selfState = getRuntimeState(self)
		selfState.isApplying = true
		self:ClearAllPoints()

		self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

		selfState.isApplying = nil
		selfState.needsReapply = true
	end)

	frame:HookScript("OnShow", function(self)
		if not isPlayerChoiceMoveEnabled() then return end
		local selfState = peekRuntimeState(self)
		if not (selfState and selfState.needsReapply) then return end
		selfState.needsReapply = nil

		RunNextFrame(function()
			if self and self:IsShown() then
				local entry = addon.Mover.functions.GetEntryForFrameName("PlayerChoiceFrame")
				if entry then addon.Mover.functions.applyFrameSettings(self, entry) end
			end
		end)
	end)
	return true
end

local function isHeroTalentsMoveEnabled()
	if not db or not db.enabled then return false end
	local entry = addon.Mover.functions.GetEntryForFrameName("HeroTalentsSelectionDialog")
	if not entry then return false end
	return addon.Mover.functions.IsFrameEnabled(entry)
end

local function FixHeroTalentsAnchor()
	if addon.Mover.variables.heroTalentsAnchorFix then return true end
	if not isHeroTalentsMoveEnabled() then return false end
	if not (TalentFrameUtil and TalentFrameUtil.GetNormalizedSubTreeNodePosition) then return false end
	if not (_G.HeroTalentsSelectionDialog and _G.PlayerSpellsFrame) then return false end

	addon.Mover.variables.heroTalentsAnchorFix = true
	local skipHook = false

	hooksecurefunc(TalentFrameUtil, "GetNormalizedSubTreeNodePosition", function(talentFrame)
		if skipHook then return end
		if not isHeroTalentsMoveEnabled() then return end
		local stack = debugstack(3)
		if not stack then return end
		if (stack:find("UpdateContainerVisibility") or stack:find("UpdateHeroTalentButtonPosition") or stack:find("PlaceHeroTalentButton")) and not stack:find("InstantiateTalentButton") then
			skipHook = true
			if talentFrame and talentFrame.EnumerateAllTalentButtons then
				for talentButton in talentFrame:EnumerateAllTalentButtons() do
					local nodeInfo = talentButton and talentButton.GetNodeInfo and talentButton:GetNodeInfo()
					if nodeInfo and nodeInfo.subTreeID and talentButton.ClearAllPoints then talentButton:ClearAllPoints() end
				end
			end
			RunNextFrame(function() skipHook = false end)
		end
	end)
	return true
end

function addon.Mover.functions.applyFrameSettings(frame, entry)
	if not frame then return end
	local resolved = resolveEntry(entry) or addon.Mover.functions.GetEntryForFrameName(frame:GetName() or "")
	if not resolved then return end
	if not isEntryActive(resolved) then return end
	local frameDb = ensureFrameDb(resolved)
	local posData = getPositionData(resolved, frameDb)
	local hasPoint = isUsablePositionData(posData)
	local targetScale = resolveScale(frame, frameDb)
	if not hasPoint and not targetScale then return end
	if InCombatLockdown() and frame:IsProtected() then
		addon.Mover.functions.deferApply(frame, resolved)
		return
	end
	local state = getRuntimeState(frame)
	state.isApplying = true
	if hasPoint then
		if resolved.keepTwoPointSize then
			MoveKeepTwoPointSize(frame, posData.x, posData.y, posData.point, posData.point)
		else
			frame:ClearAllPoints()
			frame:SetPoint(posData.point, UIParent, posData.point, posData.x, posData.y)
		end
	end
	if targetScale and frame.SetScale then frame:SetScale(targetScale) end
	state.isApplying = nil
end

function addon.Mover.functions.ReapplyFrameScaleAfterFit(frame)
	if not (frame and db and db.enabled and db.scaleEnabled) then return end
	local name = frame.GetName and frame:GetName() or nil
	local entry = name and addon.Mover.functions.GetEntryForFrameName(name) or nil
	if not (entry and isEntryActive(entry)) then return end
	local frameDb = ensureFrameDb(entry)
	if not resolveScale(frame, frameDb) then return end
	addon.Mover.functions.applyFrameSettings(frame, entry)
end

function addon.Mover.functions.InstallScaleFitHook()
	if addon.Mover.variables.scaleFitHooked then return end
	if hooksecurefunc and _G.UIPanelUpdateScaleForFit then
		hooksecurefunc("UIPanelUpdateScaleForFit", function(frame)
			addon.Mover.functions.ReapplyFrameScaleAfterFit(frame)
		end)
		addon.Mover.variables.scaleFitHooked = true
	elseif hooksecurefunc and _G.UpdateScaleForFit then
		hooksecurefunc("UpdateScaleForFit", function(frame)
			addon.Mover.functions.ReapplyFrameScaleAfterFit(frame)
		end)
		addon.Mover.variables.scaleFitHooked = true
	end
end

function addon.Mover.functions.StoreFramePosition(frame, entry)
	local resolved = resolveEntry(entry) or addon.Mover.functions.GetEntryForFrameName(frame:GetName() or "")
	if not resolved then return end
	local frameDb = ensureFrameDb(resolved)
	if not frameDb then return end
	local point, _, _, xOfs, yOfs = frame:GetPoint()
	if not isUsablePositionData({ point = point, x = xOfs, y = yOfs }) then return end
	if not isFrameMostlyOnScreen(frame) then return end
	setPositionData(resolved, frameDb, point, xOfs, yOfs)
end

function addon.Mover.functions.createHooks(frame, entry)
	if not frame then return end
	if frame.IsForbidden and frame:IsForbidden() then return end
	local frameState = getRuntimeState(frame)
	if frameState.layoutHooks then return end

	local resolved = resolveEntry(entry) or addon.Mover.functions.GetEntryForFrameName(frame:GetName() or "")
	if not resolved then return end

	captureDefaultPoints(frame)
	captureDefaultState(frame)

	local moveDisabled = resolved.disableMove

	if InCombatLockdown() then
		addon.Mover.variables.combatQueue[frame] = resolved
		return
	end

	frameState.layoutEntryId = resolved.id
	frameState.moverEntry = resolved

	local function onStartDrag(_, button)
		if button and button ~= "LeftButton" then return end
		if not isEntryActive(resolved) then return end
		if not modifierPressed() then return end
		if InCombatLockdown() and frame:IsProtected() then return end
		local userPlaced = frame.IsUserPlaced and frame:IsUserPlaced()
		frameState.isDragging = true
		frame:StartMoving()
		if userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(userPlaced) end
	end

	local function onStopDrag(_, button)
		if button and button ~= "LeftButton" then return end
		if not frameState.isDragging then return end
		if InCombatLockdown() and frame:IsProtected() then return end
		frame:StopMovingOrSizing()
		frameState.isDragging = nil
		if not isEntryActive(resolved) then return end
		addon.Mover.functions.StoreFramePosition(frame, resolved)
		if resolved.keepTwoPointSize then addon.Mover.functions.applyFrameSettings(frame, resolved) end
	end

	local function restoreHandleUserPlaced()
		local userPlaced = frameState.handleUserPlaced
		if userPlaced ~= nil and frame.SetUserPlaced then frame:SetUserPlaced(userPlaced) end
	end

	local function onHandleMouseDown(handle, button)
		if button and button ~= "LeftButton" then return end
		if not isEntryActive(resolved) then return end
		if not modifierPressed() then return end
		frameState.handleUserPlaced = frame.IsUserPlaced and frame:IsUserPlaced()
		frameState.isDragging = true
		clearPanelDragStartCallback(handle)
	end

	local function onHandleDragStart()
		restoreHandleUserPlaced()
	end

	local function onHandleMouseUp(handle, button)
		if button and button ~= "LeftButton" then return end
		handle.onDragStartCallback = blockPanelDragCallback
		if handle.isMovingTarget then return end
		frameState.isDragging = nil
		frameState.handleUserPlaced = nil
	end

	local function onHandleDragStop(handle)
		handle.onDragStartCallback = blockPanelDragCallback
		if not frameState.isDragging then
			frameState.handleUserPlaced = nil
			return
		end
		restoreHandleUserPlaced()
		frameState.isDragging = nil
		frameState.handleUserPlaced = nil
		if not isEntryActive(resolved) then return end
		addon.Mover.functions.StoreFramePosition(frame, resolved)
		if resolved.keepTwoPointSize then addon.Mover.functions.applyFrameSettings(frame, resolved) end
	end

	local function setStoredScale(scale)
		local frameDb = ensureFrameDb(resolved)
		if frameDb then frameDb.scale = scale end
		if InCombatLockdown() and frame:IsProtected() then
			addon.Mover.functions.deferApply(frame, resolved)
			return
		end
		if frame.SetScale then frame:SetScale(scale) end
	end

	local function onScaleWheel(_, delta)
		if not isEntryActive(resolved) then return end
		if not db.scaleEnabled then return end
		if not scaleModifierPressed() then return end
		local frameDb = ensureFrameDb(resolved)
		local current = frameDb and frameDb.scale
		if type(current) ~= "number" and frame.GetScale then current = frame:GetScale() end
		current = clampScale(current or 1)
		local newScale = clampScale(current + (delta * SCALE_STEP))
		setStoredScale(newScale)
	end

	local function onScaleReset(_, button)
		if button ~= "RightButton" then return end
		if not isEntryActive(resolved) then return end
		if not scaleModifierPressed() then return end
		setStoredScale(1)
		local frameDb = ensureFrameDb(resolved)
		clearPositionData(resolved, frameDb)
		if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
			addon.Mover.functions.deferDefaultReset(frame, resolved)
			return
		end
		if frameState.defaultPoints then
			frameState.isApplying = true
			applyDefaultPoints(frame)
			frameState.isApplying = nil
		end
	end

	local function registerScaleHover(target)
		if not target then return end
		local targetState = getRuntimeState(target)
		if targetState.scaleHoverHooked then return end
		targetState.scaleHoverHooked = true
		target:HookScript("OnEnter", function()
			if not isEntryActive(resolved) then return end
			addon.Mover.variables.scaleMouseover[target] = true
			addon.Mover.functions.CheckScaleWheelCapture()
		end)
		target:HookScript("OnLeave", function()
			if not addon.Mover.variables.scaleMouseover[target] then return end
			addon.Mover.variables.scaleMouseover[target] = nil
			addon.Mover.functions.CheckScaleWheelCapture()
		end)
		if MouseIsOver and MouseIsOver(target) then
			local function markHover()
				if not isEntryActive(resolved) then return end
				if MouseIsOver(target) then
					addon.Mover.variables.scaleMouseover[target] = true
					addon.Mover.functions.CheckScaleWheelCapture()
				end
			end
			RunNextFrame(markHover)
		end
	end

	local function registerScaleTarget(target)
		if not target then return end
		local targetState = getRuntimeState(target)
		if targetState.scaleTargetHooked then return end
		targetState.scaleTargetHooked = true
		addon.Mover.variables.scaleTargets[target] = frame
		registerScaleHover(target)
	end

	local function attachScaleReset(target)
		if not target then return end
		local targetState = getRuntimeState(target)
		if targetState.scaleResetHooked then return end
		targetState.scaleResetHooked = true
		target:HookScript("OnMouseUp", onScaleReset)
	end

	local function registerMoveHandle(handle)
		if not handle then return end
		addon.Mover.variables.moveHandles[handle] = true
		registerScaleHover(handle)
		attachScaleReset(handle)
	end

	frameState.scaleWheel = function(delta) onScaleWheel(nil, delta) end
	registerScaleTarget(frame)
	attachScaleReset(frame)

	local function attachScaleTargetPath(path)
		local target = resolveFramePath(path)
		if not target then return end
		if target.IsForbidden and target:IsForbidden() then return end
		registerScaleTarget(target)
		attachScaleReset(target)
	end

	if resolved.scaleTargets then
		for _, path in ipairs(resolved.scaleTargets) do
			attachScaleTargetPath(path)
		end
		frame:HookScript("OnShow", function()
			for _, path in ipairs(resolved.scaleTargets) do
				attachScaleTargetPath(path)
			end
		end)
	end

	local function attachHandle(anchor)
		if not anchor then return nil end
		local handle
		if pcall(function() handle = CreateFrame("Frame", nil, frame, "PanelDragBarTemplate") end) and handle then
			handle.onDragStartCallback = blockPanelDragCallback
			handle:HookScript("OnMouseDown", onHandleMouseDown)
			handle:HookScript("OnMouseUp", onHandleMouseUp)
			handle:HookScript("OnDragStart", onHandleDragStart)
			handle:HookScript("OnDragStop", onHandleDragStop)
		else
			handle = CreateFrame("Frame", nil, anchor)
			if handle.RegisterForDrag then handle:RegisterForDrag("LeftButton") end
			handle:HookScript("OnDragStart", onStartDrag)
			handle:HookScript("OnDragStop", onStopDrag)
		end
		handle:SetAllPoints(anchor)
		getRuntimeState(handle).anchor = anchor
		handle:SetFrameLevel(anchor:GetFrameLevel() + 1)
		if not InCombatLockdown() then
			if handle.SetPropagateMouseMotion then handle:SetPropagateMouseMotion(true) end
			if handle.SetPropagateMouseClicks then handle:SetPropagateMouseClicks(true) end
		end
		if handle.EnableMouse then handle:EnableMouse(true) end
		registerMoveHandle(handle)
		return handle
	end

	local dragTargets = frameState.moveDragTargets or {}
	local function attachDragHandlers(target)
		if not target then return end
		if target.IsForbidden and target:IsForbidden() then return end
		local targetState = getRuntimeState(target)
		if targetState.dragHooked then return end
		targetState.dragHooked = true
		captureDefaultState(target)
		if target ~= frame then dragTargets[target] = true end
		if target.EnableMouse then target:EnableMouse(true) end
		target:HookScript("OnMouseDown", onStartDrag)
		target:HookScript("OnMouseUp", onStopDrag)
		registerScaleTarget(target)
		attachScaleReset(target)
	end

	local useOverlay = false
	if not moveDisabled then
		useOverlay = resolved.useRootHandle
		if resolved.handlesOnly and resolved.handles then
			useOverlay = true
		elseif useOverlay == nil then
			useOverlay = frame:IsProtected()
		end
	end
	if not moveDisabled then
		if useOverlay then
			if not resolved.handlesOnly and resolved.useRootHandle ~= false then frameState.moveHandle = attachHandle(frame) end

			local createdSubs = frameState.moveSubHandles or {}
			if resolved.handles then
				local function attachHandleToPath(path)
					local anchor = resolveFramePath(path)
					if not anchor or createdSubs[anchor] then return end
					if anchor.IsForbidden and anchor:IsForbidden() then return end
					createdSubs[anchor] = attachHandle(anchor)
				end

				for _, path in ipairs(resolved.handles) do
					attachHandleToPath(path)
				end

				frame:HookScript("OnShow", function()
					for _, path in ipairs(resolved.handles) do
						attachHandleToPath(path)
					end
				end)
			end
			frameState.moveSubHandles = createdSubs
		else
			attachDragHandlers(frame)
			if resolved.handles then
				local function attachDragTarget(path)
					local anchor = resolveFramePath(path)
					if not anchor then return end
					attachDragHandlers(anchor)
				end
				for _, path in ipairs(resolved.handles) do
					attachDragTarget(path)
				end
				frame:HookScript("OnShow", function()
					for _, path in ipairs(resolved.handles) do
						attachDragTarget(path)
					end
				end)
			end
		end
	end
	frameState.moveDragTargets = dragTargets

	hooksecurefunc(frame, "SetPoint", function(self)
		if not isEntryActive(resolved) then return end
		local selfState = peekRuntimeState(self)
		if selfState and (selfState.isDragging or selfState.isApplying) then return end
		local frameDb = ensureFrameDb(resolved)
		local posData = getPositionData(resolved, frameDb)
		local hasPoint = isUsablePositionData(posData)
		local targetScale = resolveScale(self, frameDb)
		if not hasPoint and not targetScale then return end
		if InCombatLockdown() and self:IsProtected() then
			addon.Mover.functions.deferApply(self, resolved)
			return
		end
		selfState = getRuntimeState(self)
		selfState.isApplying = true
		if hasPoint then
			if resolved.keepTwoPointSize then
				MoveKeepTwoPointSize(self, posData.x, posData.y, posData.point, posData.point)
			else
				self:ClearAllPoints()
				self:SetPoint(posData.point, UIParent, posData.point, posData.x, posData.y)
			end
		end
		if targetScale and self.SetScale then self:SetScale(targetScale) end
		selfState.isApplying = nil
	end)

	frame:HookScript("OnShow", function(self)
		local selfState = getRuntimeState(self)
		if not selfState.defaultPoints then captureDefaultPoints(self) end
		if selfState.updateHandleState then selfState.updateHandleState() end
		addon.Mover.functions.applyFrameSettings(self, resolved)
		RunNextFrame(function()
			if self and self.IsShown and self:IsShown() then
				selfState = peekRuntimeState(self)
				if selfState and selfState.updateHandleState then selfState.updateHandleState() end
				addon.Mover.functions.applyFrameSettings(self, resolved)
			end
		end)
	end)
	if not resolved.skipOnHide then
		frame:HookScript("OnHide", function(self)
			local frameDb = ensureFrameDb(resolved)
			if getEntryPositionPersistence(resolved, frameDb) ~= "close" then return end
			if not isEntryActive(resolved) then return end
			local selfState = peekRuntimeState(self)
			if selfState and (selfState.isDragging or selfState.isApplying) then return end
			if InCombatLockdown() and self:IsProtected() then return end
			if not (selfState and selfState.defaultPoints) then return end
			selfState.isApplying = true
			applyDefaultPoints(self)
			selfState.isApplying = nil
		end)
	end

	frameState.layoutHooks = true
	addon.Mover.variables.combatQueue[frame] = nil

	local function setHandleEnabled(handle, enabled)
		if not handle then return end
		local handleState = peekRuntimeState(handle)
		local anchor = handleState and handleState.anchor
		local anchorShown = not anchor or not anchor.IsShown or anchor:IsShown()
		local active = enabled and anchorShown
		if handle.EnableMouse then handle:EnableMouse(active) end
		if handle.SetShown then handle:SetShown(active) end
	end

	local function updateHandleState()
		local enabled = isEntryActive(resolved)
		if not moveDisabled then
			applyFrameState(frame, resolved, enabled, useOverlay)
			for target in pairs(dragTargets) do
				applyDragTargetState(target, enabled)
			end
			setHandleEnabled(frameState.moveHandle, enabled)
			for _, handle in pairs(frameState.moveSubHandles or {}) do
				setHandleEnabled(handle, enabled)
			end
		end
		if not enabled then
			local mouseover = addon.Mover.variables.scaleMouseover
			if mouseover then
				mouseover[frame] = nil
				for target in pairs(dragTargets) do
					mouseover[target] = nil
				end
				if frameState.moveHandle then mouseover[frameState.moveHandle] = nil end
				for _, handle in pairs(frameState.moveSubHandles or {}) do
					mouseover[handle] = nil
				end
			end
		elseif MouseIsOver then
			local function markHover(target)
				if target and MouseIsOver(target) then addon.Mover.variables.scaleMouseover[target] = true end
			end
			markHover(frame)
			for target in pairs(dragTargets) do
				markHover(target)
			end
			markHover(frameState.moveHandle)
			for _, handle in pairs(frameState.moveSubHandles or {}) do
				markHover(handle)
			end
		end
		addon.Mover.functions.CheckScaleWheelCapture()
	end

	frameState.updateHandleState = updateHandleState
	updateHandleState()
end

function addon.Mover.functions.TryHookEntry(entry)
	local resolved = resolveEntry(entry)
	if not resolved then return end
	if not isAnyAddonLoaded(resolved) then return end
	if not isEntryActive(resolved) then return end
	for _, name in ipairs(resolved.names or {}) do
		local frame = resolveFramePath(name)
		if frame then
			addon.Mover.functions.createHooks(frame, resolved)
			addon.Mover.functions.applyFrameSettings(frame, resolved)
		end
	end
end

function addon.Mover.functions.TryHookAll()
	for _, entry in ipairs(registry.frameList) do
		addon.Mover.functions.TryHookEntry(entry)
	end
end

function addon.Mover.functions.UpdateHandleState(entry)
	local resolved = resolveEntry(entry)
	if not resolved then return end
	for _, name in ipairs(resolved.names or {}) do
		local frame = resolveFramePath(name)
		local state = peekRuntimeState(frame)
		if state and state.updateHandleState then state.updateHandleState() end
	end
end

function addon.Mover.functions.RefreshEntry(entry)
	addon.Mover.functions.TryHookEntry(entry)
	addon.Mover.functions.UpdateHandleState(entry)
	local resolved = resolveEntry(entry)
	if resolved and resolved.id == "CollectionsJournal" then FixWardrobeSecondaryAppearanceLabel() end
	if resolved and resolved.id == "PlayerChoiceFrame" then FixPlayerChoiceAnchor() end
	if resolved and resolved.id == "HeroTalentsSelectionDialog" then FixHeroTalentsAnchor() end
end

function addon.Mover.functions.ApplyAll()
	for _, entry in ipairs(registry.frameList) do
		addon.Mover.functions.RefreshEntry(entry)
	end
end

local function ensureDb()
	if not db and addon.Mover.functions.InitDB then addon.Mover.functions.InitDB() end
end

function addon.Mover.functions.Initialize()
	ensureDb()
	if addon.Mover.functions.InitRegistry then addon.Mover.functions.InitRegistry() end
	if addon.Mover.functions.InitSettings then addon.Mover.functions.InitSettings() end
	if addon.Mover.functions.ApplyAll then addon.Mover.functions.ApplyAll() end
end

local eventHandlers = {
	["ADDON_LOADED"] = function(arg1)
		if arg1 == addonName then
			addon.Mover.functions.Initialize()
			for _, entry in ipairs(registry.noAddonEntries or {}) do
				addon.Mover.functions.TryHookEntry(entry)
			end
		end
		if arg1 == "Blizzard_Collections" then
			-- Anchoring bug in Blizzards UI
			FixWardrobeSecondaryAppearanceLabel()
		end
		if arg1 == "Blizzard_PlayerChoice" and _G.PlayerChoiceFrame then FixPlayerChoiceAnchor() end
		if arg1 == "Blizzard_PlayerSpells" then FixHeroTalentsAnchor() end
		--[==[@debug@
		-- print(arg1)
		--@end-debug@]==]
		local list = registry.addonIndex and registry.addonIndex[arg1]
		if list then
			for _, entry in ipairs(list) do
				addon.Mover.functions.TryHookEntry(entry)
			end
		end
	end,
	["PLAYER_REGEN_ENABLED"] = function()
		local combatQueue = addon.Mover.variables.combatQueue or {}
		for frame, entry in pairs(combatQueue) do
			combatQueue[frame] = nil
			if frame then addon.Mover.functions.createHooks(frame, entry) end
		end

		local pending = addon.Mover.variables.pendingApply or {}
		for frame, entry in pairs(pending) do
			pending[frame] = nil
			if frame then addon.Mover.functions.applyFrameSettings(frame, entry) end
		end

		local pendingDefaultReset = addon.Mover.variables.pendingDefaultReset or {}
		for frame in pairs(pendingDefaultReset) do
			pendingDefaultReset[frame] = nil
			local state = peekRuntimeState(frame)
			if frame and state and state.defaultPoints then
				state.isApplying = true
				applyDefaultPoints(frame)
				state.isApplying = nil
			end
		end
	end,
}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
	end
end

local function eventHandler(self, event, ...)
	ensureDb()
	if eventHandlers[event] then eventHandlers[event](...) end
end

local frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
frameLoad:SetScript("OnEvent", eventHandler)
