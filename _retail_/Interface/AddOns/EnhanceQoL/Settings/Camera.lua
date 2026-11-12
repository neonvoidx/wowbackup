local addonName, addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local cameraCVar = "cameraDistanceMaxZoomFactor"
local isForever = addon.variables.isForever
local maximumFactor = 2.6
local previousValue

local CameraZoom = {}
addon.CameraZoom = CameraZoom

function CameraZoom:GetMaxMultiplier()
	local value = tonumber(addon.db and addon.db.cameraZoomAccelerationMax) or 4
	return math.max(2, math.min(4, math.floor(value)))
end

function CameraZoom:Reset()
	if self.session then self.session.lastTime, self.session.lastDirection = nil, nil end
end

function CameraZoom:Stop()
	local session = self.session
	if not session then return end
	-- A later camera wrapper may still call this session. Leave it inert.
	session.active = false
	if _G.CameraZoomIn == session.zoomIn then _G.CameraZoomIn = session.originalIn end
	if _G.CameraZoomOut == session.zoomOut then _G.CameraZoomOut = session.originalOut end
	self.session = nil
end

function CameraZoom:Zoom(session, direction, original, increments, ...)
	if not session.active or not (addon.db and addon.db.cameraZoomAcceleration) then return original(increments, ...) end
	if issecretvalue and issecretvalue(increments) then
		session.lastTime, session.lastDirection = nil, nil
		return original(increments, ...)
	end
	-- Engine stop calls must not break a scroll sequence. Explicit distances
	-- from scripted camera movement pass through without acceleration.
	if increments == 0 then return original(increments, ...) end
	if increments ~= nil and increments ~= 1 then
		session.lastTime, session.lastDirection = nil, nil
		return original(increments, ...)
	end
	local now = GetTime()
	local interval = session.lastTime and (now - session.lastTime)
	local multiplier = 1
	if session.lastDirection == direction and interval and interval >= 0 and interval < 0.200 then
		local strength = math.min(1, (0.200 - interval) / 0.150)
		multiplier = 1 + (self:GetMaxMultiplier() - 1) * strength
	end
	session.lastTime, session.lastDirection = now, direction
	-- Exactly one native call; the camera engine retains control of its limits.
	return original(multiplier, ...)
end

function CameraZoom:Apply()
	addon.functions.InitDBValue("cameraZoomAcceleration", false)
	addon.functions.InitDBValue("cameraZoomAccelerationMax", 4)
	if self.pendingFrame then self.pendingFrame:UnregisterAllEvents() end
	if not addon.db.cameraZoomAcceleration then self:Stop(); return end
	if self.session then self:Reset(); return end
	if InCombatLockdown() then
		if not self.pendingFrame then
			self.pendingFrame = CreateFrame("Frame")
			self.pendingFrame:SetScript("OnEvent", function() self:Apply() end)
		end
		self.pendingFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	if type(_G.CameraZoomIn) ~= "function" or type(_G.CameraZoomOut) ~= "function" then return end
	-- Capture an immutable pair per activation, so re-enabling around an outer
	-- wrapper cannot turn an older, disabled session into a recursion cycle.
	local session = { active = true, originalIn = _G.CameraZoomIn, originalOut = _G.CameraZoomOut }
	session.zoomIn = function(increments, ...) return self:Zoom(session, "in", session.originalIn, increments, ...) end
	session.zoomOut = function(increments, ...) return self:Zoom(session, "out", session.originalOut, increments, ...) end
	self.session = session
	_G.CameraZoomIn, _G.CameraZoomOut = session.zoomIn, session.zoomOut
end

local function isMaximumEnabled()
	local value = tonumber(C_CVar.GetCVar(cameraCVar))
	return value ~= nil and value >= maximumFactor
end

local function setMaximumEnabled(enabled)
	local currentValue = C_CVar.GetCVar(cameraCVar)
	if currentValue == nil then return end
	if enabled then
		-- Preserve an existing larger value instead of reducing the user's range.
		if isMaximumEnabled() then return end
		previousValue = currentValue
		addon.functions.setCVarValue(cameraCVar, maximumFactor)
	else
		if not isMaximumEnabled() then return end
		local restoreValue = previousValue or C_CVar.GetCVarDefault(cameraCVar)
		if restoreValue == nil then return end
		addon.functions.setCVarValue(cameraCVar, restoreValue)
		previousValue = nil
	end
end

local category = addon.SettingsLayout.rootUI
local section
if isForever or addon.variables.isTBC then
	section = addon.functions.SettingsClassicUtilityBlock(CAMERA_LABEL, "camera", 100, isForever and "CameraForever" or "CameraZoom")
else
	section = addon.functions.SettingsCreateExpandableSection(category, {
		name = CAMERA_LABEL, configPageKey = "CameraZoom", modernCategory = "interface",
		iconKey = "settingspage", expanded = false, newTagID = "CameraZoom",
	})
end

addon.functions.SettingsCreateCheckbox(category, {
	var = isForever and "maxCameraZoomForever" or "maxCameraZoom", order = 110,
	text = L["maxCameraZoom"],
	desc = string.format(L["maxCameraZoomDesc"], maximumFactor),
	default = false,
	storage = false,
	newTagID = isForever and "maxCameraZoomForever" or "maxCameraZoom",
	get = isMaximumEnabled,
	func = setMaximumEnabled,
	parentSection = section,
})

addon.functions.SettingsCreateCheckbox(category, {
	var = "cameraZoomAcceleration", order = 120,
	text = L["cameraZoomAcceleration"],
	desc = L["cameraZoomAccelerationDesc"],
	default = false,
	get = function() return addon.db and addon.db.cameraZoomAcceleration == true end,
	func = function(enabled)
		addon.db.cameraZoomAcceleration = enabled == true
		CameraZoom:Apply()
	end,
	newTagID = "cameraZoomAcceleration",
	parentSection = section,
})

addon.functions.SettingsCreateDropdown(category, {
	var = "cameraZoomAccelerationMax", order = 130, orderList = { 2, 3, 4 },
	text = L["cameraZoomAccelerationMax"],
	desc = L["cameraZoomAccelerationMaxDesc"],
	default = 4,
	list = { [2] = "2×", [3] = "3×", [4] = "4×" },
	get = function() return CameraZoom:GetMaxMultiplier() end,
	set = function(value)
		addon.db.cameraZoomAccelerationMax = value
		addon.db.cameraZoomAccelerationMax = CameraZoom:GetMaxMultiplier()
		CameraZoom:Reset()
	end,
	parentCheck = function() return addon.db and addon.db.cameraZoomAcceleration == true end,
	indent = 16,
	newTagID = "cameraZoomAccelerationMax",
	parentSection = section,
})
