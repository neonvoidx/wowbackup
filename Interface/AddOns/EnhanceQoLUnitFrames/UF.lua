local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
local UF = addon.Aura.UF or {}
addon.Aura.UF = UF
UF.ui = UF.ui or {}
local UFHelper = addon.Aura.UFHelper
UF.AuraUtil = UF.AuraUtil or {}
local AuraUtil = UF.AuraUtil
UF.ClassResourceUtil = UF.ClassResourceUtil or {}
local ClassResourceUtil = UF.ClassResourceUtil
UF.TotemFrameUtil = UF.TotemFrameUtil or {}
local TotemFrameUtil = UF.TotemFrameUtil
addon.variables = addon.variables or {}
addon.variables.ufSampleAbsorb = addon.variables.ufSampleAbsorb or {}
addon.variables.ufSampleHealAbsorb = addon.variables.ufSampleHealAbsorb or {}
UF._editModeSample = UF._editModeSample or {}
-- Keep the legacy status row as a visual coordinate space without retaining it
-- in the secure unit button's clickable height.
UF.STATUS_LAYOUT_HEIGHT = 16
UF.STATUS_PHYSICAL_HEIGHT = 0.001

UF.DYNAMIC_ANCHOR_DEFINITIONS = UF.DYNAMIC_ANCHOR_DEFINITIONS or {
	player = { anchorKey = "EQOL_ANCHOR_PLAYER", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFPlayerFrame"] or PLAYER or "Player" end },
	target = { anchorKey = "EQOL_ANCHOR_TARGET", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFTargetFrame"] or TARGET or "Target" end },
	targettarget = { anchorKey = "EQOL_ANCHOR_TARGETTARGET", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFToTFrame"] or "Target of Target" end },
	focus = { anchorKey = "EQOL_ANCHOR_FOCUS", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFFocusFrame"] or FOCUS or "Focus" end },
	pet = { anchorKey = "EQOL_ANCHOR_PET", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFPetFrame"] or PET or "Pet" end },
	boss = { anchorKey = "EQOL_ANCHOR_BOSS", label = function() local locale = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL") return locale["UFBossFrame"] or BOSS or "Boss" end },
}
UF.DYNAMIC_ANCHOR_FRAME_NAMES = UF.DYNAMIC_ANCHOR_FRAME_NAMES or {
	EQOL_ANCHOR_PLAYER = "EQOLUFPlayerFrame",
	EQOL_ANCHOR_TARGET = "EQOLUFTargetFrame",
	EQOL_ANCHOR_TARGETTARGET = "EQOLUFToTFrame",
	EQOL_ANCHOR_FOCUS = "EQOLUFFocusFrame",
	EQOL_ANCHOR_PET = "EQOLUFPetFrame",
	EQOL_ANCHOR_BOSS = "EQOLUFBossContainer",
}

function UF.NormalizeDynamicAnchorUnit(unit)
	if type(unit) == "string" and unit:match("^boss%d+$") then return "boss" end
	return unit
end

function UF.GetDynamicAnchorId(unit)
	local definition = UF.DYNAMIC_ANCHOR_DEFINITIONS[UF.NormalizeDynamicAnchorUnit(unit)]
	return definition and ("unitFrame:" .. definition.anchorKey) or nil
end

function UF.IsDynamicAnchorEnabled(unit)
	local id = UF.GetDynamicAnchorId(unit)
	return id and addon.DynamicAnchors and addon.DynamicAnchors.IsFrameAssignmentEnabled and addon.DynamicAnchors:IsFrameAssignmentEnabled(id) or false
end

function UF.HasAppliedDynamicAnchor(unit)
	local definition = UF.DYNAMIC_ANCHOR_DEFINITIONS[UF.NormalizeDynamicAnchorUnit(unit)]
	local frameName = definition and UF.DYNAMIC_ANCHOR_FRAME_NAMES[definition.anchorKey]
	local frame = frameName and _G[frameName]
	return frame and frame._eqolDynamicAnchorWinner ~= nil or false
end

function UF.WouldDynamicAnchorFrameLoop(ownerFrame, relativeFrame)
	if not (ownerFrame and relativeFrame) or relativeFrame == UIParent then return false end
	local pending = { relativeFrame }
	local visited = {}
	local index = 1
	local remaining = 32
	while pending[index] and remaining > 0 do
		local current = pending[index]
		index = index + 1
		if current == ownerFrame then return true end
		if current ~= UIParent and not visited[current] then
			visited[current] = true
			if current.GetPoint then
				local count = current.GetNumPoints and current:GetNumPoints() or 1
				for pointIndex = 1, count do
					local _, nextFrame = current:GetPoint(pointIndex)
					nextFrame = type(nextFrame) == "string" and _G[nextFrame] or nextFrame
					if nextFrame == ownerFrame then return true end
					if nextFrame and nextFrame ~= UIParent and not visited[nextFrame] then pending[#pending + 1] = nextFrame end
				end
			end
			remaining = remaining - 1
		end
	end
	return remaining <= 0
end

function UF.GetDynamicAnchorWinner(unit, ownerFrame)
	local id = UF.GetDynamicAnchorId(unit)
	local dynamicAnchors = addon.DynamicAnchors
	if not (id and UF.IsDynamicAnchorEnabled(unit) and dynamicAnchors and dynamicAnchors.ResolveConsumer) then return nil end
	local result = dynamicAnchors:ResolveConsumer(id, { mode = "LIVE" })
	local winner = result and result.winner
	if winner and winner.frame and not UF.WouldDynamicAnchorFrameLoop(ownerFrame, winner.frame) then return winner end
	local fallback = result and result.rule and result.rule.finalFallback
	return {
		targetId = "core:uiparent",
		frame = UIParent,
		placement = fallback and fallback.placement or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
		fallback = true,
	}
end

function UF.ApplyDynamicAnchor(unit)
	unit = UF.NormalizeDynamicAnchorUnit(unit)
	if not UF.DYNAMIC_ANCHOR_DEFINITIONS[unit] then return false end
	if not UF.IsDynamicAnchorEnabled(unit) and not UF.HasAppliedDynamicAnchor(unit) then return false end
	if InCombatLockdown and InCombatLockdown() then
		UF._pendingDynamicAnchorUnits = UF._pendingDynamicAnchorUnits or {}
		UF._pendingDynamicAnchorUnits[unit] = true
		return false
	end
	if unit == "boss" then
		if UF.UpdateBossFrames then UF.UpdateBossFrames(true) end
	elseif UF.RefreshUnit then
		UF.RefreshUnit(unit)
	end
	return true
end

function UF.RegisterDynamicAnchors()
	local dynamicAnchors = addon.DynamicAnchors
	if UF._dynamicAnchorsRegistered or not (dynamicAnchors and dynamicAnchors.RegisterConsumer and dynamicAnchors.GetFrameAssignment) then return UF._dynamicAnchorsRegistered == true end
	for unit, definition in pairs(UF.DYNAMIC_ANCHOR_DEFINITIONS) do
		local dynamicUnit = unit
		local dynamicDefinition = definition
		local id = "unitFrame:" .. dynamicDefinition.anchorKey
		local label = dynamicDefinition.label()
		dynamicAnchors:RegisterConsumer({
			id = id,
			owner = "EnhanceQoLUnitFrames",
			label = label,
			ensureRule = function() return dynamicAnchors:GetFrameAssignment(id, true) end,
			getRule = function()
				local assignment = dynamicAnchors:GetFrameAssignment(id, false)
				if assignment and dynamicAnchors.EnsureAssignmentProfile then dynamicAnchors:EnsureAssignmentProfile(assignment, label) end
				return assignment
			end,
			apply = function() UF.ApplyDynamicAnchor(dynamicUnit) end,
		})
		local frameName = UF.DYNAMIC_ANCHOR_FRAME_NAMES[dynamicDefinition.anchorKey]
		local frame = frameName and _G[frameName]
		if frame and dynamicAnchors.EnsureSimpleTargetHooks then dynamicAnchors:EnsureSimpleTargetHooks(id, frame) end
	end
	UF._dynamicAnchorsRegistered = true
	return true
end

function UF.GetEditModeSampleKey(unit)
	if type(unit) ~= "string" then return nil end
	if unit == "boss" or unit:match("^boss%d+$") then return "boss" end
	return unit
end

function UF.IsEditModeSampleEnabled(unit)
	if not (addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()) then return false end
	unit = UF.GetEditModeSampleKey(unit)
	return unit and UF._editModeSample and UF._editModeSample[unit] == true or false
end

function UF.SetEditModeSampleEnabled(unit, enabled)
	unit = UF.GetEditModeSampleKey(unit)
	if not unit then return end
	UF._editModeSample = UF._editModeSample or {}
	enabled = enabled == true
	if (UF._editModeSample[unit] == true) == enabled then return end
	if enabled then
		UF._editModeSample[unit] = true
	else
		UF._editModeSample[unit] = nil
	end
	if unit == "boss" then
		if UF.UpdateBossFrames then
			UF.UpdateBossFrames(true)
		elseif UF.Refresh then
			UF.Refresh()
		end
	elseif UF.RefreshUnit then
		UF.RefreshUnit(unit)
	elseif UF.Refresh then
		UF.Refresh()
	end
end

function UF.ToggleEditModeSample(unit)
	unit = UF.GetEditModeSampleKey(unit)
	if not unit then return end
	UF.SetEditModeSampleEnabled(unit, not (UF._editModeSample and UF._editModeSample[unit] == true))
end

local maxBossFrames = 8
UF.BOSS_SPACING_MIN = -50
local BOSS_SPACING_MIN = UF.BOSS_SPACING_MIN
local UF_PROFILE_SHARE_KIND = "EQOL_UF_PROFILE"
local smoothFill = Enum.StatusBarInterpolation.ExponentialEaseOut
local TEXT_UPDATE_INTERVAL = 0.1
UF._clientSceneActive = false
local blizzBossKill = {
	looseFrames = {},
	parentHooks = {},
}
blizzBossKill.hiddenParent = CreateFrame("Frame", nil, UIParent)
blizzBossKill.hiddenParent:SetAllPoints()
blizzBossKill.hiddenParent:Hide()
blizzBossKill.watcher = CreateFrame("Frame")
blizzBossKill.watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
blizzBossKill.watcher:SetScript("OnEvent", function()
	for frame in next, blizzBossKill.looseFrames do
		frame:SetParent(blizzBossKill.hiddenParent)
	end
	if table and table.wipe then
		table.wipe(blizzBossKill.looseFrames)
	else
		for frame in pairs(blizzBossKill.looseFrames) do
			blizzBossKill.looseFrames[frame] = nil
		end
	end
end)

local function getSmoothInterpolation(cfg, def)
	if not smoothFill then return nil end
	local flag = cfg and cfg.smoothFill
	if flag == nil and def then flag = def.smoothFill end
	if flag == true then return smoothFill end
	return nil
end

function UF.SetStatusBarValue(bar, value, smooth, forceImmediate)
	if not bar or value == nil then return end
	local helper = UF.GroupFramesHelper
	local pixelHelper = helper and helper.Pixel
	if pixelHelper and pixelHelper.SetStatusBarValue then
		pixelHelper.SetStatusBarValue(bar, value, smooth, forceImmediate)
		return
	end
	if smooth and Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut then
		bar:SetValue(value, Enum.StatusBarInterpolation.ExponentialEaseOut)
	else
		bar:SetValue(value)
	end
end

function UF.StabilizeStatusBarTexture(bar)
	if not bar then return end
	local helper = UF.GroupFramesHelper
	local pixel = helper and helper.Pixel
	if pixel and pixel.DisableSnap then pixel.DisableSnap(bar) end
	if not bar.GetStatusBarTexture then return end
	local tex = bar:GetStatusBarTexture()
	if not tex then return end
	if tex.SetHorizTile then tex:SetHorizTile(false) end
	if tex.SetVertTile then tex:SetVertTile(false) end
	if tex.SetTexCoord then tex:SetTexCoord(0, 1, 0, 1) end
	if pixel and pixel.DisableSnap then pixel.DisableSnap(tex) end
end

local function resetBlizzBossParent(self, parent)
	if parent == blizzBossKill.hiddenParent then return end
	if InCombatLockdown() and self.IsProtected and self:IsProtected() then
		blizzBossKill.looseFrames[self] = true
	else
		self:SetParent(blizzBossKill.hiddenParent)
	end
end

local function disableBlizzBossSubFrame(frame)
	if not frame then return end
	if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
	if (not InCombatLockdown()) or not frame.IsProtected or (not frame:IsProtected()) then
		if frame.Hide then frame:Hide() end
	end
end

local function disableBlizzBossFrame(frame, doNotReparent)
	if not frame then return end
	if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
	if frame.SetAlpha then frame:SetAlpha(0) end
	if (not InCombatLockdown()) or not frame.IsProtected or (not frame:IsProtected()) then
		if frame.Hide then frame:Hide() end
	end
	if not doNotReparent and frame.SetParent then
		if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
			blizzBossKill.looseFrames[frame] = true
		else
			frame:SetParent(blizzBossKill.hiddenParent)
		end
		if not blizzBossKill.parentHooks[frame] then
			hooksecurefunc(frame, "SetParent", resetBlizzBossParent)
			blizzBossKill.parentHooks[frame] = true
		end
	end
	disableBlizzBossSubFrame(
		frame.healthBar
			or frame.healthbar
			or frame.HealthBar
			or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
			or (
				frame.TargetFrameContent
				and frame.TargetFrameContent.TargetFrameContentMain
				and frame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer
				and frame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
			)
	)
	disableBlizzBossSubFrame(
		frame.manabar or frame.ManaBar or (frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain and frame.TargetFrameContent.TargetFrameContentMain.ManaBar)
	)
	disableBlizzBossSubFrame(frame.castBar or frame.spellbar or frame.CastingBarFrame)
	disableBlizzBossSubFrame(frame.powerBarAlt or frame.PowerBarAlt)
	disableBlizzBossSubFrame(frame.BuffFrame or frame.AurasFrame)
	disableBlizzBossSubFrame(frame.petFrame or frame.PetFrame)
	disableBlizzBossSubFrame(frame.totFrame)
	disableBlizzBossSubFrame(frame.CcRemoverFrame)
	disableBlizzBossSubFrame(frame.DebuffFrame)
end

local function DisableBossFrames()
	if not _G.BossTargetFrameContainer then return end
	disableBlizzBossFrame(BossTargetFrameContainer)
	if BossTargetFrameContainer.Selection then
		BossTargetFrameContainer.Selection:SetAlpha(0)
		if (not InCombatLockdown()) or not BossTargetFrameContainer.Selection.IsProtected or (not BossTargetFrameContainer.Selection:IsProtected()) then BossTargetFrameContainer.Selection:Hide() end
	end
	for i = 1, (_G.MAX_BOSS_FRAMES or 5) do
		disableBlizzBossFrame(_G["Boss" .. i .. "TargetFrame"], true)
	end
	if blizzBossKill.throttleHook ~= true then
		blizzBossKill.throttleHook = true
		hooksecurefunc(BossTargetFrameContainer, "SetAlpha", function(self, parent)
			if self:GetAlpha() ~= 0 then self:SetAlpha(0) end
		end)
	end
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local LSM = LibStub("LibSharedMedia-3.0")
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local DEFAULT_NOT_INTERRUPTIBLE_COLOR = { 204 / 255, 204 / 255, 204 / 255, 1 }
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs or function() return 0 end
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs or function() return 0 end
local GetUnitTotalModifiedMaxHealthPercent = _G.GetUnitTotalModifiedMaxHealthPercent or function() return 0 end
local RegisterStateDriver = _G.RegisterStateDriver
local UnregisterStateDriver = _G.UnregisterStateDriver
local IsResting = _G.IsResting
local UnitIsResting = _G.UnitIsResting
local IsTargetLoose = _G.IsTargetLoose
local CreateUnitHealPredictionCalculator = _G.CreateUnitHealPredictionCalculator
local UnitGetDetailedHealPrediction = _G.UnitGetDetailedHealPrediction
local C_PlayerInteractionManager = _G.C_PlayerInteractionManager
local After = C_Timer and C_Timer.After
local NewTicker = C_Timer and C_Timer.NewTicker
local max = math.max
local wipe = wipe or (table and table.wipe)
local SetFrameVisibilityOverride = addon.functions and addon.functions.SetFrameVisibilityOverride
local HasFrameVisibilityOverride = addon.functions and addon.functions.HasFrameVisibilityOverride
local NormalizeUnitFrameVisibilityConfig = addon.functions and addon.functions.NormalizeUnitFrameVisibilityConfig
local ApplyFrameVisibilityConfig = addon.functions and addon.functions.ApplyFrameVisibilityConfig
UF.COMBAT_INDICATOR_DEFAULT_ICON = "DEFAULT"
UF.COMBAT_INDICATOR_DEFAULT_TEXTURE = "Interface\\Addons\\EnhanceQoL\\Assets\\CombatIndicator.tga"
UF.COMBAT_INDICATOR_ICONS = {
	{ value = UF.COMBAT_INDICATOR_DEFAULT_ICON, texture = UF.COMBAT_INDICATOR_DEFAULT_TEXTURE },
	{ value = "ShipMissionIcon-Combat-Mission", atlas = "ShipMissionIcon-Combat-Mission" },
	{ value = "GarrMission_MissionIcon-Combat", atlas = "GarrMission_MissionIcon-Combat" },
	{ value = "Mobile-MechanicIcon-Powerful", atlas = "Mobile-MechanicIcon-Powerful" },
	{ value = "Mobile-CombatIcon-Desaturated", atlas = "Mobile-CombatIcon-Desaturated" },
	{ value = "Mobile-CombatBadgeIcon", atlas = "Mobile-CombatBadgeIcon" },
	{ value = "plunderstorm-pvpqueue-catergory-icon", atlas = "plunderstorm-pvpqueue-catergory-icon" },
	{ value = "combat_swords-icon", atlas = "combat_swords-icon" },
}

function UF.GetCombatIndicatorIconDefinition(value)
	local key = type(value) == "string" and value ~= "" and value or UF.COMBAT_INDICATOR_DEFAULT_ICON
	local fallback
	for _, option in ipairs(UF.COMBAT_INDICATOR_ICONS) do
		if option.value == UF.COMBAT_INDICATOR_DEFAULT_ICON then fallback = option end
		if option.value == key then return option end
	end
	if key ~= UF.COMBAT_INDICATOR_DEFAULT_ICON then return { value = key, atlas = key } end
	return fallback or UF.COMBAT_INDICATOR_ICONS[1]
end

function UF.GetCombatIndicatorIconMarkup(value, size)
	local option = UF.GetCombatIndicatorIconDefinition(value)
	size = tonumber(size) or 18
	if option and option.atlas then return ("|A:%s:%d:%d:0:0|a"):format(option.atlas, size, size) end
	if option and option.texture then return ("|T%s:%d:%d|t"):format(option.texture, size, size) end
	return tostring(value or "")
end

local UNIT = {
	PLAYER = "player",
	TARGET = "target",
	TARGET_TARGET = "targettarget",
	FOCUS = "focus",
	PET = "pet",
}

UF._runtimeConsumers = UF._runtimeConsumers or {
	unit = {},
	group = {},
	unitTotal = 0,
	groupTotal = 0,
	total = 0,
	initialized = false,
}

local function notifyRuntimeConsumerActivityChanged()
	local profiles = UF.Profiles
	if not profiles then return end
	if UF.HasRuntimeConsumers and UF.HasRuntimeConsumers() and profiles._ensureUFProfileEvents then
		profiles._ensureUFProfileEvents()
	elseif profiles.UpdateEventRegistration then
		profiles.UpdateEventRegistration()
	end
end

local function setRuntimeConsumerActive(kind, key, enabled, silent)
	local runtime = UF._runtimeConsumers
	runtime[kind] = runtime[kind] or {}
	local bucket = runtime[kind]
	enabled = enabled == true
	local previous = bucket[key] == true
	if previous == enabled then return false end
	if enabled then
		bucket[key] = true
		runtime.total = (runtime.total or 0) + 1
		runtime[kind .. "Total"] = (runtime[kind .. "Total"] or 0) + 1
	else
		bucket[key] = nil
		runtime.total = math.max((runtime.total or 0) - 1, 0)
		runtime[kind .. "Total"] = math.max((runtime[kind .. "Total"] or 0) - 1, 0)
	end
	runtime.initialized = true
	if not silent then notifyRuntimeConsumerActivityChanged() end
	return true
end

local function canonicalUFConsumerUnit(unit)
	if type(unit) ~= "string" then return nil end
	if unit == "boss" or unit:match("^boss%d+$") then return "boss" end
	return unit
end

function UF.SetRuntimeConsumerActive(kind, key, enabled)
	if kind ~= "unit" and kind ~= "group" then return false end
	key = kind == "unit" and canonicalUFConsumerUnit(key) or tostring(key or "")
	if not key or key == "" then return false end
	return setRuntimeConsumerActive(kind, key, enabled)
end

function UF.RecomputeRuntimeConsumerActivity()
	local runtime = UF._runtimeConsumers
	runtime.unit = runtime.unit or {}
	runtime.group = runtime.group or {}
	for key in pairs(runtime.unit) do
		runtime.unit[key] = nil
	end
	for key in pairs(runtime.group) do
		runtime.group[key] = nil
	end
	runtime.total = 0
	runtime.unitTotal = 0
	runtime.groupTotal = 0

	local db = addon.db
	local frames = db and db.ufFrames
	if type(frames) == "table" then
		for _, key in ipairs({ UNIT.PLAYER, UNIT.TARGET, UNIT.TARGET_TARGET, UNIT.FOCUS, UNIT.PET, "boss" }) do
			local cfg = frames[key]
			if type(cfg) == "table" and cfg.enabled == true then setRuntimeConsumerActive("unit", key, true, true) end
		end
		for key, cfg in pairs(frames) do
			if type(key) == "string" and key:match("^boss%d+$") and type(cfg) == "table" and cfg.enabled == true then
				setRuntimeConsumerActive("unit", "boss", true, true)
				break
			end
		end
	end

	local groupFrames = db and db.ufGroupFrames
	if type(groupFrames) == "table" then
		for key, cfg in pairs(groupFrames) do
			if type(cfg) == "table" and cfg.enabled == true then setRuntimeConsumerActive("group", tostring(key), true, true) end
		end
	end
	runtime.initialized = true
	notifyRuntimeConsumerActivityChanged()
	return runtime.total > 0
end

function UF.HasRuntimeConsumers()
	local runtime = UF._runtimeConsumers
	if not runtime.initialized then return UF.RecomputeRuntimeConsumerActivity() end
	return (runtime.total or 0) > 0
end

function UF.HasUnitRuntimeConsumers()
	local runtime = UF._runtimeConsumers
	if not runtime.initialized then UF.RecomputeRuntimeConsumerActivity() end
	return (runtime.unitTotal or 0) > 0
end
local ENEMY_DEBUFF_FILTER_MODE_PLAYER = "PLAYER"
local ENEMY_DEBUFF_FILTER_MODE_ALL = "ALL"

local UF_FRAME_NAMES = {
	player = {
		frame = "EQOLUFPlayerFrame",
		health = "EQOLUFPlayerHealth",
		power = "EQOLUFPlayerPower",
		secondaryPower = "EQOLUFPlayerSecondaryPower",
		status = "EQOLUFPlayerStatus",
	},
	target = {
		frame = "EQOLUFTargetFrame",
		health = "EQOLUFTargetHealth",
		power = "EQOLUFTargetPower",
		status = "EQOLUFTargetStatus",
	},
	targettarget = {
		frame = "EQOLUFToTFrame",
		health = "EQOLUFToTHealth",
		power = "EQOLUFToTPower",
		status = "EQOLUFToTStatus",
	},
	focus = {
		frame = "EQOLUFFocusFrame",
		health = "EQOLUFFocusHealth",
		power = "EQOLUFFocusPower",
		status = "EQOLUFFocusStatus",
	},
	pet = {
		frame = "EQOLUFPetFrame",
		health = "EQOLUFPetHealth",
		power = "EQOLUFPetPower",
		status = "EQOLUFPetStatus",
	},
}

local BLIZZ_FRAME_NAMES = {
	player = "PlayerFrame",
	target = "TargetFrame",
	targettarget = "TargetFrameToT",
	focus = "FocusFrame",
	pet = "PetFrame",
}
local RelativeAnchor = {
	bossFrameName = "EQOLUFBossContainer",
	map = {
		PlayerFrame = { uf = UF_FRAME_NAMES.player.frame, blizz = BLIZZ_FRAME_NAMES.player, ufKey = "player" },
		EQOLUFPlayerFrame = { uf = UF_FRAME_NAMES.player.frame, blizz = BLIZZ_FRAME_NAMES.player, ufKey = "player" },
		TargetFrame = { uf = UF_FRAME_NAMES.target.frame, blizz = BLIZZ_FRAME_NAMES.target, ufKey = "target" },
		EQOLUFTargetFrame = { uf = UF_FRAME_NAMES.target.frame, blizz = BLIZZ_FRAME_NAMES.target, ufKey = "target" },
		TargetFrameToT = { uf = UF_FRAME_NAMES.targettarget.frame, blizz = BLIZZ_FRAME_NAMES.targettarget, ufKey = "targettarget" },
		EQOLUFToTFrame = { uf = UF_FRAME_NAMES.targettarget.frame, blizz = BLIZZ_FRAME_NAMES.targettarget, ufKey = "targettarget" },
		FocusFrame = { uf = UF_FRAME_NAMES.focus.frame, blizz = BLIZZ_FRAME_NAMES.focus, ufKey = "focus" },
		EQOLUFFocusFrame = { uf = UF_FRAME_NAMES.focus.frame, blizz = BLIZZ_FRAME_NAMES.focus, ufKey = "focus" },
		PetFrame = { uf = UF_FRAME_NAMES.pet.frame, blizz = BLIZZ_FRAME_NAMES.pet, ufKey = "pet" },
		EQOLUFPetFrame = { uf = UF_FRAME_NAMES.pet.frame, blizz = BLIZZ_FRAME_NAMES.pet, ufKey = "pet" },
		BossTargetFrameContainer = { uf = "EQOLUFBossContainer", blizz = "BossTargetFrameContainer", ufKey = "boss" },
		EQOLUFBossContainer = { uf = "EQOLUFBossContainer", blizz = "BossTargetFrameContainer", ufKey = "boss" },
		EQOL_ANCHOR_PLAYER = { uf = UF_FRAME_NAMES.player.frame, blizz = BLIZZ_FRAME_NAMES.player, ufKey = "player" },
		EQOL_ANCHOR_TARGET = { uf = UF_FRAME_NAMES.target.frame, blizz = BLIZZ_FRAME_NAMES.target, ufKey = "target" },
		EQOL_ANCHOR_TARGETTARGET = { uf = UF_FRAME_NAMES.targettarget.frame, blizz = BLIZZ_FRAME_NAMES.targettarget, ufKey = "targettarget" },
		EQOL_ANCHOR_FOCUS = { uf = UF_FRAME_NAMES.focus.frame, blizz = BLIZZ_FRAME_NAMES.focus, ufKey = "focus" },
		EQOL_ANCHOR_PET = { uf = UF_FRAME_NAMES.pet.frame, blizz = BLIZZ_FRAME_NAMES.pet, ufKey = "pet" },
		EQOL_ANCHOR_PARTY = { uf = "EQOLUFPartyAnchor", blizz = "CompactPartyFrame", ufKey = "party" },
		CompactPartyFrame = { uf = "EQOLUFPartyAnchor", blizz = "CompactPartyFrame", ufKey = "party" },
		EQOLUFPartyAnchor = { uf = "EQOLUFPartyAnchor", blizz = "CompactPartyFrame", ufKey = "party" },
		EQOL_ANCHOR_RAID = { uf = "EQOLUFRaidAnchor", blizz = "CompactRaidFrameContainer", ufKey = "raid" },
		CompactRaidFrameContainer = { uf = "EQOLUFRaidAnchor", blizz = "CompactRaidFrameContainer", ufKey = "raid" },
		EQOLUFRaidAnchor = { uf = "EQOLUFRaidAnchor", blizz = "CompactRaidFrameContainer", ufKey = "raid" },
		EQOL_ANCHOR_BOSS = { uf = "EQOLUFBossContainer", blizz = "BossTargetFrameContainer", ufKey = "boss" },
	},
}

function RelativeAnchor.GetFrameNameForKey(ufKey)
	if ufKey == "boss" then return RelativeAnchor.bossFrameName end
	local names = UF_FRAME_NAMES[ufKey]
	return names and names.frame or nil
end

function RelativeAnchor.IsMappedUFEnabled(ufKey)
	if addon.functions and addon.functions.IsEQoLUnitOrGroupFrameEnabled then return addon.functions.IsEQoLUnitOrGroupFrameEnabled(ufKey) end
	local ufCfg = addon.db and addon.db.ufFrames
	local cfg = ufCfg and ufCfg[ufKey]
	if cfg and cfg.enabled == true then return true end
	local groupCfg = addon.db and addon.db.ufGroupFrames
	local group = groupCfg and groupCfg[ufKey]
	return group and group.enabled == true
end

function RelativeAnchor.GetUFRelativeName(relativeName)
	local mapped = RelativeAnchor.map[relativeName]
	if not (mapped and mapped.ufKey) then return nil end
	local ufCfg = addon.db and addon.db.ufFrames
	local cfg = ufCfg and ufCfg[mapped.ufKey]
	local anchor = cfg and cfg.anchor
	return anchor and (anchor.relativeTo or anchor.relativeFrame) or nil
end

function RelativeAnchor.GetResourceBarRelativeName(relativeName)
	if type(relativeName) ~= "string" then return nil end
	local barType = relativeName == "EQOLHealthBar" and "HEALTH" or relativeName:match("^EQOL(.+)Bar$")
	if not barType then return nil end
	local classToken = addon.variables and addon.variables.unitClass
	local specIndex = addon.variables and addon.variables.unitSpec
	local settings = addon.db and addon.db.personalResourceBarSettings
	local classCfg = settings and classToken and settings[classToken]
	local specCfg = classCfg and specIndex and classCfg[specIndex]
	local barCfg = specCfg and specCfg[barType]
	local anchor = type(barCfg) == "table" and barCfg.anchor or nil
	return anchor and anchor.relativeFrame or nil
end

function RelativeAnchor.GetCooldownPanelRelativeName(relativeName)
	if type(relativeName) ~= "string" then return nil end
	local panelIdText = relativeName:match("^EQOL_CooldownPanel(.+)$")
	if not panelIdText then return nil end
	local cooldownPanels = addon.Aura and addon.Aura.CooldownPanels
	local panelId = tonumber(panelIdText) or panelIdText
	local panel = cooldownPanels and cooldownPanels.GetPanel and cooldownPanels:GetPanel(panelId)
	local anchor = panel and panel.anchor
	return anchor and anchor.relativeFrame or nil
end

function RelativeAnchor.GetNextRelativeName(relativeName)
	return RelativeAnchor.GetUFRelativeName(relativeName) or RelativeAnchor.GetResourceBarRelativeName(relativeName) or RelativeAnchor.GetCooldownPanelRelativeName(relativeName)
end

function RelativeAnchor.WouldLoop(relativeName, ownerFrameName)
	if type(relativeName) ~= "string" or relativeName == "" or relativeName == "UIParent" then return false end
	local visited = {}
	if type(ownerFrameName) == "string" and ownerFrameName ~= "" then visited[ownerFrameName] = true end
	local current = relativeName
	local limit = 16
	while type(current) == "string" and current ~= "" and current ~= "UIParent" and limit > 0 do
		if visited[current] then return true, current end
		visited[current] = true
		current = RelativeAnchor.GetNextRelativeName(current)
		limit = limit - 1
	end
	if limit <= 0 then return true, relativeName end
	return false
end

function RelativeAnchor.WouldLiveFrameLoop(relativeName, ownerFrameName)
	if type(relativeName) ~= "string" or relativeName == "" or relativeName == "UIParent" then return false end
	local ownerFrame = type(ownerFrameName) == "string" and _G[ownerFrameName] or ownerFrameName
	if not ownerFrame then return false end
	local current = RelativeAnchor.ResolveSingle(relativeName)
	if not current or current == UIParent then return false end
	if current == ownerFrame then return true, ownerFrameName or (ownerFrame.GetName and ownerFrame:GetName()) or relativeName end
	local visited = {}
	local limit = 16
	while current and current ~= UIParent and limit > 0 do
		if current == ownerFrame then return true, ownerFrameName or (current.GetName and current:GetName()) or relativeName end
		if visited[current] then break end
		visited[current] = true
		if not current.GetPoint then break end
		local _, relativeTo = current:GetPoint(1)
		if relativeTo == ownerFrame then return true, ownerFrameName or (ownerFrame.GetName and ownerFrame:GetName()) or relativeName end
		if type(relativeTo) == "string" and relativeTo ~= "" then
			current = _G[relativeTo]
		else
			current = relativeTo
		end
		limit = limit - 1
	end
	if limit <= 0 then return true, relativeName end
	return false
end

function RelativeAnchor.ResolveSingle(relativeName)
	if type(relativeName) ~= "string" or relativeName == "" or relativeName == "UIParent" then return UIParent end
	local mapped = RelativeAnchor.map[relativeName]
	if mapped then
		if mapped.ufKey and RelativeAnchor.IsMappedUFEnabled(mapped.ufKey) then
			local ufFrame = _G[mapped.uf]
			if ufFrame then return ufFrame end
		end
		local blizzFrame = _G[mapped.blizz]
		if blizzFrame then return blizzFrame end
	end

	local resourceBars = addon.Aura and addon.Aura.ResourceBars
	if resourceBars and resourceBars.ResolveRelativeFrameByName then
		local relFrame = resourceBars.ResolveRelativeFrameByName(relativeName)
		if relFrame and relFrame ~= UIParent then return relFrame end
	end

	local cooldownPanels = addon.Aura and addon.Aura.CooldownPanels
	local panelIdText = relativeName:match("^EQOL_CooldownPanel(.+)$")
	if panelIdText and cooldownPanels then
		local panelId = tonumber(panelIdText) or panelIdText
		local runtime = cooldownPanels.runtime and cooldownPanels.runtime[panelId]
		local panelFrame = runtime and runtime.frame or _G[relativeName]
		if panelFrame then return panelFrame end
	end

	return _G[relativeName] or UIParent
end

local function resolveRelativeAnchorFrame(relativeName, ownerFrameName)
	if type(relativeName) ~= "string" or relativeName == "" or relativeName == "UIParent" then return UIParent end
	local looped, culprit = RelativeAnchor.WouldLoop(relativeName, ownerFrameName)
	if not looped then
		looped, culprit = RelativeAnchor.WouldLiveFrameLoop(relativeName, ownerFrameName)
	end
	if looped then
		print("|cff00ff98Enhance QoL|r: " .. (L["AnchorLoop"] or 'Anchor loop detected for "%s". Resetting to UIParent.'):format(culprit or relativeName))
		return UIParent
	end
	return RelativeAnchor.ResolveSingle(relativeName)
end

function UF.GetAnchorFrameName(unit) return RelativeAnchor.GetFrameNameForKey(unit) end

function UF.ResolveRelativeAnchorFrame(relativeName, ownerFrameName) return resolveRelativeAnchorFrame(relativeName, ownerFrameName) end

function UF.WouldRelativeAnchorLoop(unit, relativeName)
	local ownerFrameName = RelativeAnchor.GetFrameNameForKey(unit)
	local looped = RelativeAnchor.WouldLoop(relativeName, ownerFrameName)
	if not looped then looped = RelativeAnchor.WouldLiveFrameLoop(relativeName, ownerFrameName) end
	return looped == true
end

local MIN_WIDTH = 50
local classResourceFramesByClass = {
	DEATHKNIGHT = {
		{ id = "runes", frameName = "RuneFrame", labelKey = "RUNES", label = "Runes" },
	},
	DRUID = {
		{ id = "druidComboPoints", legacyIds = { "comboPoints" }, frameName = "DruidComboPointBarFrame", labelKey = "COMBO_POINTS", label = "Combo Points" },
	},
	EVOKER = {
		{ id = "essence", frameName = "EssencePlayerFrame", labelKey = "ESSENCE", label = "Essence" },
	},
	MAGE = {
		{ id = "arcaneCharges", frameName = "MageArcaneChargesFrame", labelKey = "ARCANE_CHARGES", label = "Arcane Charges" },
	},
	MONK = {
		{ id = "chi", frameName = "MonkHarmonyBarFrame", labelKey = "CHI", label = "Chi" },
	},
	PALADIN = {
		{ id = "holyPower", frameName = "PaladinPowerBarFrame", labelKey = "HOLY_POWER", label = "Holy Power" },
	},
	ROGUE = {
		{ id = "rogueComboPoints", legacyIds = { "comboPoints" }, frameName = "RogueComboPointBarFrame", labelKey = "COMBO_POINTS", label = "Combo Points" },
	},
	SHAMAN = {
		{ id = "maelstromWeapon", frameName = "ShamanMaelstromWeaponBarFrame", labelKey = "MAELSTROM_WEAPON", label = "Maelstrom Weapon" },
	},
	WARLOCK = {
		{ id = "soulShards", frameName = "WarlockPowerFrame", labelKey = "SOUL_SHARDS", label = "Soul Shards" },
	},
}
local totemFrameClasses = {
	DEATHKNIGHT = true,
	DRUID = true,
	EVOKER = true,
	MAGE = true,
	MONK = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
	WARLOCK = true,
}
local classResourceOriginalLayouts = {}
local classResourceManagedFrames = {}
local classResourceHooks = {}

local function copyClassResourceConfigValue(value)
	if type(value) ~= "table" then return value end
	if addon.functions and addon.functions.copyTable then return addon.functions.copyTable(value) end
	if CopyTable then return CopyTable(value) end
	local out = {}
	for k, v in pairs(value) do
		out[k] = copyClassResourceConfigValue(v)
	end
	return out
end

UF.Profiles = UF.Profiles or {}
local UFProfileManager = UF.Profiles
UFProfileManager.DEFAULT_NAME = UFProfileManager.DEFAULT_NAME or "Default"
UFProfileManager.RUNTIME_KEYS = UFProfileManager.RUNTIME_KEYS or {
	"ufFrames",
	"ufGroupFrames",
	"ufUseCustomClassColors",
	"ufUseCustomPowerColors",
	"ufClassColors",
	"ufPowerColorOverrides",
	"ufNPCColorOverrides",
}

function UFProfileManager.Debug() end
function UFProfileManager.Trace() end

function UFProfileManager._copyProfileValue(value)
	if type(value) ~= "table" then return value end
	if addon.functions and addon.functions.copyTable then return addon.functions.copyTable(value) end
	if CopyTable then return CopyTable(value) end
	local out = {}
	for k, v in pairs(value) do
		out[k] = UFProfileManager._copyProfileValue(v)
	end
	return out
end

function UFProfileManager._trimProfileName(name)
	if type(name) ~= "string" then return nil end
	local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then return nil end
	return trimmed
end

function UFProfileManager._getCurrentPlayerGUID()
	local guid = UnitGUID and UnitGUID("player")
	if issecretvalue and issecretvalue(guid) then guid = nil end
	if type(guid) == "string" and guid ~= "" then return guid end
	local fallback = addon.variables and addon.variables.unitPlayerGUID
	if type(fallback) == "string" and fallback ~= "" then return fallback end
	return nil
end

function UFProfileManager._getCurrentSpecID()
	if C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetConfigIDsBySpecID then
		local activeConfigID = C_ClassTalents.GetActiveConfigID()
		local classID = UnitClass and select(3, UnitClass("player"))
		if issecretvalue and issecretvalue(classID) then classID = nil end
		if type(activeConfigID) == "number" and activeConfigID > 0 and type(classID) == "number" and classID > 0 and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
			local numSpecs = GetNumSpecializationsForClassID(classID)
			if type(numSpecs) == "number" and numSpecs > 0 then
				for index = 1, numSpecs do
					local specID = select(1, GetSpecializationInfoForClassID(classID, index))
					if type(specID) == "number" and specID > 0 then
						local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
						if type(configIDs) == "table" then
							for _, configID in ipairs(configIDs) do
								if configID == activeConfigID then return specID end
							end
						end
					end
				end
			end
		end
	end

	if not (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecializationInfo) then return nil end
	local specIndex = C_SpecializationInfo.GetSpecialization()
	if type(specIndex) ~= "number" or specIndex <= 0 then return nil end
	local specID = C_SpecializationInfo.GetSpecializationInfo(specIndex)
	if type(specID) == "table" then specID = specID.specID end
	if type(specID) ~= "number" or specID <= 0 then return nil end
	return specID
end

function UFProfileManager._getCurrentClassSpecIDs()
	local classID = UnitClass and select(3, UnitClass("player"))
	if issecretvalue and issecretvalue(classID) then classID = nil end
	local specIDs
	if type(classID) == "number" and classID > 0 and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
		local numSpecs = GetNumSpecializationsForClassID(classID)
		if type(numSpecs) == "number" and numSpecs > 0 then
			for index = 1, numSpecs do
				local specID = select(1, GetSpecializationInfoForClassID(classID, index))
				if type(specID) == "number" and specID > 0 then
					specIDs = specIDs or {}
					specIDs[specID] = true
				end
			end
		end
	end
	local currentSpecID = UFProfileManager._getCurrentSpecID()
	if not specIDs and currentSpecID then specIDs = { [currentSpecID] = true } end
	return specIDs, currentSpecID
end

function UFProfileManager._copyUFSpecMappings(map, profiles)
	if type(map) ~= "table" then return nil end
	local copy = {}
	for specKey, profileName in pairs(map) do
		local specID = tonumber(specKey)
		local normalizedName = UFProfileManager._trimProfileName(profileName)
		if specID and specID > 0 and normalizedName and (not profiles or profiles[normalizedName]) then copy[specID] = normalizedName end
	end
	if not next(copy) then return nil end
	return copy
end

function UFProfileManager._scoreUFSpecMappings(map, profiles, classSpecIDs, currentSpecID)
	if type(map) ~= "table" or type(profiles) ~= "table" then return nil end
	local overlap = 0
	local foreign = 0
	local score = 0
	local hasAny = false
	for specKey, profileName in pairs(map) do
		local specID = tonumber(specKey)
		local normalizedName = UFProfileManager._trimProfileName(profileName)
		if specID and specID > 0 and normalizedName and profiles[normalizedName] then
			hasAny = true
			if classSpecIDs and classSpecIDs[specID] then
				overlap = overlap + 1
				score = score + 10
				if currentSpecID and specID == currentSpecID then score = score + 100 end
			elseif classSpecIDs then
				foreign = foreign + 1
				score = score - 5
			end
		end
	end
	if not hasAny then return nil end
	if classSpecIDs and overlap == 0 then return nil end
	return score, overlap, foreign
end

function UFProfileManager._resolveUFSpecMappingsForGUID(profiles, guid, adopt)
	if type(profiles) ~= "table" or type(guid) ~= "string" or guid == "" then return nil end
	local mappings = addon.db and addon.db.ufProfileSpecKeys
	if type(mappings) ~= "table" then return nil end

	local classSpecIDs, currentSpecID = UFProfileManager._getCurrentClassSpecIDs()
	local currentMap = type(mappings[guid]) == "table" and mappings[guid] or nil
	local bestMap = currentMap
	local bestSourceGuid = guid
	local bestScore, bestOverlap, bestForeign = UFProfileManager._scoreUFSpecMappings(currentMap, profiles, classSpecIDs, currentSpecID)

	for sourceGuid, candidateMap in pairs(mappings) do
		if sourceGuid ~= guid and type(candidateMap) == "table" then
			local score, overlap, foreign = UFProfileManager._scoreUFSpecMappings(candidateMap, profiles, classSpecIDs, currentSpecID)
			if score ~= nil then
				local isBetter = bestScore == nil
					or score > bestScore
					or (score == bestScore and (overlap or 0) > (bestOverlap or 0))
					or (score == bestScore and (overlap or 0) == (bestOverlap or 0) and (foreign or math.huge) < (bestForeign or math.huge))
				if isBetter then
					bestMap = candidateMap
					bestSourceGuid = sourceGuid
					bestScore = score
					bestOverlap = overlap
					bestForeign = foreign
				end
			end
		end
	end

	if type(bestMap) ~= "table" then return nil end
	if adopt and bestSourceGuid ~= guid then
		bestMap = UFProfileManager._copyUFSpecMappings(bestMap, profiles)
		if not bestMap then return nil end
		mappings[guid] = bestMap
		UFProfileManager.Debug("adopted UF spec mappings %s -> %s", tostring(bestSourceGuid), tostring(guid))
		UFProfileManager.Trace("SPEC_MAP_ADOPT", string.format("%s->%s", tostring(bestSourceGuid), tostring(guid)))
		return bestMap
	end
	return bestMap
end

function UFProfileManager._resolveUFSpecMappedProfileFromMappings(profiles, byGuid, specID)
	if type(profiles) ~= "table" or type(byGuid) ~= "table" then return nil end
	if type(specID) ~= "number" or specID <= 0 then return nil end
	local mapped = byGuid[specID]
	if type(mapped) ~= "string" or mapped == "" then mapped = byGuid[tostring(specID)] end
	mapped = UFProfileManager._trimProfileName(mapped)
	if not mapped or not profiles[mapped] then return nil end
	return mapped
end

function UFProfileManager._ensureUFProfilePayload(profile)
	if type(profile) ~= "table" then profile = {} end
	profile.ufFrames = type(profile.ufFrames) == "table" and profile.ufFrames or {}
	profile.ufGroupFrames = type(profile.ufGroupFrames) == "table" and profile.ufGroupFrames or {}
	profile.ufUseCustomClassColors = profile.ufUseCustomClassColors == true
	profile.ufUseCustomPowerColors = profile.ufUseCustomPowerColors == true
	profile.ufClassColors = type(profile.ufClassColors) == "table" and profile.ufClassColors or {}
	profile.ufPowerColorOverrides = type(profile.ufPowerColorOverrides) == "table" and profile.ufPowerColorOverrides or {}
	profile.ufNPCColorOverrides = type(profile.ufNPCColorOverrides) == "table" and profile.ufNPCColorOverrides or {}
	return profile
end

function UFProfileManager._buildLegacyUFProfile()
	return UFProfileManager._ensureUFProfilePayload({
		ufFrames = UFProfileManager._copyProfileValue(addon.db and addon.db.ufFrames) or {},
		ufGroupFrames = UFProfileManager._copyProfileValue(addon.db and addon.db.ufGroupFrames) or {},
		ufUseCustomClassColors = addon.db and addon.db.ufUseCustomClassColors == true,
		ufUseCustomPowerColors = addon.db and addon.db.ufUseCustomPowerColors == true,
		ufClassColors = UFProfileManager._copyProfileValue(addon.db and addon.db.ufClassColors) or {},
		ufPowerColorOverrides = UFProfileManager._copyProfileValue(addon.db and addon.db.ufPowerColorOverrides) or {},
		ufNPCColorOverrides = UFProfileManager._copyProfileValue(addon.db and addon.db.ufNPCColorOverrides) or {},
	})
end

function UFProfileManager._getSortedUFProfileNames(profiles)
	local names = {}
	for name in pairs(profiles or {}) do
		names[#names + 1] = name
	end
	table.sort(names, function(a, b)
		local la, lb = tostring(a):lower(), tostring(b):lower()
		if la == lb then return tostring(a) < tostring(b) end
		return la < lb
	end)
	return names
end

function UFProfileManager._markUFProfilesDirty()
	UFProfileManager._profileDedupeVersion = (UFProfileManager._profileDedupeVersion or 0) + 1
end

function UFProfileManager._isUFProfilePayloadNormalized(profile)
	return type(profile) == "table"
		and type(profile.ufFrames) == "table"
		and type(profile.ufGroupFrames) == "table"
		and (profile.ufUseCustomClassColors == true or profile.ufUseCustomClassColors == false)
		and (profile.ufUseCustomPowerColors == true or profile.ufUseCustomPowerColors == false)
		and type(profile.ufClassColors) == "table"
		and type(profile.ufPowerColorOverrides) == "table"
		and type(profile.ufNPCColorOverrides) == "table"
end

function UFProfileManager._ensureUFProfilesRoot()
	if type(addon.db) ~= "table" then return nil end
	if type(addon.db.ufProfiles) ~= "table" then
		addon.db.ufProfiles = {}
		UFProfileManager._markUFProfilesDirty()
	end
	local profiles = addon.db.ufProfiles
	for name, profile in pairs(profiles) do
		if type(name) ~= "string" or name == "" then
			profiles[name] = nil
			UFProfileManager._markUFProfilesDirty()
		else
			local normalized = UFProfileManager._isUFProfilePayloadNormalized(profile)
			profiles[name] = UFProfileManager._ensureUFProfilePayload(profile)
			if not normalized then UFProfileManager._markUFProfilesDirty() end
		end
	end
	if not next(profiles) then
		profiles[UFProfileManager.DEFAULT_NAME] = UFProfileManager._buildLegacyUFProfile()
		UFProfileManager._markUFProfilesDirty()
	end
	return profiles
end

function UFProfileManager._dedupeNestedTableRefs(value, owner, seenTables, recursionGuard)
	if type(value) ~= "table" then return value, 0 end
	seenTables = seenTables or {}
	recursionGuard = recursionGuard or {}
	if recursionGuard[value] then return value, 0 end

	local dedupCount = 0
	local prevOwner = seenTables[value]
	if prevOwner and prevOwner ~= owner then
		value = UFProfileManager._copyProfileValue(value) or {}
		dedupCount = dedupCount + 1
	end
	seenTables[value] = owner

	recursionGuard[value] = true
	for k, v in pairs(value) do
		if type(v) == "table" then
			local newValue, nestedCount = UFProfileManager._dedupeNestedTableRefs(v, owner, seenTables, recursionGuard)
			if newValue ~= v then value[k] = newValue end
			dedupCount = dedupCount + (nestedCount or 0)
		end
	end
	recursionGuard[value] = nil
	return value, dedupCount
end

function UFProfileManager._dedupeUFProfileTables(profiles)
	if type(profiles) ~= "table" then return end
	local seenByKey = {}
	local dedupCount = 0
	for profileName, profile in pairs(profiles) do
		if type(profile) == "table" then
			for _, key in ipairs(UFProfileManager.RUNTIME_KEYS) do
				local value = profile[key]
				if type(value) == "table" then
					seenByKey[key] = seenByKey[key] or {}
					local owner = tostring(profileName) .. ":" .. tostring(key)
					local deduped, count = UFProfileManager._dedupeNestedTableRefs(value, owner, seenByKey[key], {})
					if deduped ~= value then profile[key] = deduped end
					dedupCount = dedupCount + (count or 0)
				end
			end
		end
	end
	if dedupCount > 0 then
		UFProfileManager.Debug("deduped shared UF profile tables (deep): %d", dedupCount)
		UFProfileManager.Trace("DEDUPE_SHARED", tostring(dedupCount))
	end
end

function UFProfileManager._ensureUFProfileTablesDeduped(profiles)
	if type(profiles) ~= "table" then return end
	local version = UFProfileManager._profileDedupeVersion or 0
	if UFProfileManager._dedupeDBRef == addon.db and UFProfileManager._dedupeProfilesRef == profiles and UFProfileManager._dedupeProfilesVersion == version then return end
	UFProfileManager._dedupeUFProfileTables(profiles)
	UFProfileManager._dedupeDBRef = addon.db
	UFProfileManager._dedupeProfilesRef = profiles
	UFProfileManager._dedupeProfilesVersion = version
end

function UFProfileManager._cleanUFProfileReferences(profiles)
	addon.db.ufProfileKeys = type(addon.db.ufProfileKeys) == "table" and addon.db.ufProfileKeys or {}
	addon.db.ufProfileSpecKeys = type(addon.db.ufProfileSpecKeys) == "table" and addon.db.ufProfileSpecKeys or {}

	for guid, name in pairs(addon.db.ufProfileKeys) do
		if type(guid) ~= "string" or guid == "" or type(name) ~= "string" or name == "" or not profiles[name] then addon.db.ufProfileKeys[guid] = nil end
	end

	for guid, map in pairs(addon.db.ufProfileSpecKeys) do
		if type(guid) ~= "string" or guid == "" or type(map) ~= "table" then
			addon.db.ufProfileSpecKeys[guid] = nil
		else
			for specKey, profileName in pairs(map) do
				local specID = tonumber(specKey)
				if not specID or specID <= 0 or type(profileName) ~= "string" or profileName == "" or not profiles[profileName] then map[specKey] = nil end
			end
			if not next(map) then addon.db.ufProfileSpecKeys[guid] = nil end
		end
	end
end

function UFProfileManager._resolveUFGlobalProfile(profiles)
	local globalName = UFProfileManager._trimProfileName(addon.db.ufProfileGlobal)
	if globalName and profiles[globalName] then return globalName end
	local names = UFProfileManager._getSortedUFProfileNames(profiles)
	globalName = names[1] or UFProfileManager.DEFAULT_NAME
	if not profiles[globalName] then
		globalName = UFProfileManager.DEFAULT_NAME
		profiles[globalName] = UFProfileManager._buildLegacyUFProfile()
	end
	addon.db.ufProfileGlobal = globalName
	return globalName
end

function UFProfileManager._deepValueEquals(a, b, seenA, seenB)
	local ta, tb = type(a), type(b)
	if ta ~= tb then return false end
	if ta ~= "table" then return a == b end
	if a == b then return true end

	seenA = seenA or {}
	seenB = seenB or {}
	if seenA[a] and seenB[b] then return true end
	seenA[a] = true
	seenB[b] = true

	for key, value in pairs(a) do
		if not UFProfileManager._deepValueEquals(value, b[key], seenA, seenB) then return false end
	end
	for key in pairs(b) do
		if a[key] == nil then return false end
	end
	return true
end

function UFProfileManager._runtimeMatchesUFProfile(profile)
	if type(profile) ~= "table" or type(addon.db) ~= "table" then return false end
	for _, key in ipairs(UFProfileManager.RUNTIME_KEYS) do
		local runtimeValue = addon.db[key]
		local profileValue = profile[key]
		if key == "ufUseCustomClassColors" or key == "ufUseCustomPowerColors" then
			if (runtimeValue == true) ~= (profileValue == true) then return false end
		elseif not UFProfileManager._deepValueEquals(runtimeValue, profileValue) then
			return false
		end
	end
	return true
end

function UFProfileManager._findRuntimeMatchingUFProfileName(profiles, preferredName)
	if type(profiles) ~= "table" then return nil end
	if preferredName and type(preferredName) == "string" and UFProfileManager._runtimeMatchesUFProfile(profiles[preferredName]) then return preferredName end
	local activeName = UFProfileManager._trimProfileName(UFProfileManager._activeProfileName)
	if activeName and profiles[activeName] and UFProfileManager._runtimeMatchesUFProfile(profiles[activeName]) then return activeName end
	for _, name in ipairs(UFProfileManager._getSortedUFProfileNames(profiles)) do
		if UFProfileManager._runtimeMatchesUFProfile(profiles[name]) then return name end
	end
	return nil
end

function UFProfileManager._resolveUFSpecMappedProfileName(profiles, guid)
	if type(profiles) ~= "table" or type(guid) ~= "string" or guid == "" then return nil end
	local byGuid = UFProfileManager._resolveUFSpecMappingsForGUID(profiles, guid, true)
	if type(byGuid) ~= "table" then return nil end
	local specID = UFProfileManager._getCurrentSpecID()
	return UFProfileManager._resolveUFSpecMappedProfileFromMappings(profiles, byGuid, specID)
end

function UFProfileManager._resolveUFActiveProfileName(profiles)
	local globalName = UFProfileManager._resolveUFGlobalProfile(profiles)
	local guid = UFProfileManager._getCurrentPlayerGUID()
	if not guid then
		local runtimeMatch = UFProfileManager._findRuntimeMatchingUFProfileName(profiles, globalName)
		return runtimeMatch or globalName
	end

	local activeName = UFProfileManager._trimProfileName(addon.db.ufProfileKeys and addon.db.ufProfileKeys[guid])
	if activeName and profiles[activeName] then return activeName end

	local specMapped = UFProfileManager._resolveUFSpecMappedProfileName(profiles, guid)
	if specMapped then
		addon.db.ufProfileKeys[guid] = specMapped
		return specMapped
	end

	local runtimeMatch = UFProfileManager._findRuntimeMatchingUFProfileName(profiles, globalName)
	if runtimeMatch then
		addon.db.ufProfileKeys[guid] = runtimeMatch
		return runtimeMatch
	end

	addon.db.ufProfileKeys[guid] = globalName
	return globalName
end

function UFProfileManager._bindUFProfileToRuntime(profileName)
	local profiles = addon.db and addon.db.ufProfiles
	if type(profiles) ~= "table" then return nil end
	local profile = profiles[profileName]
	if type(profile) ~= "table" then return nil end
	profile = UFProfileManager._ensureUFProfilePayload(profile)
	profiles[profileName] = profile
	for _, key in ipairs(UFProfileManager.RUNTIME_KEYS) do
		local value = profile[key]
		if key == "ufUseCustomClassColors" or key == "ufUseCustomPowerColors" then
			addon.db[key] = value == true
		else
			addon.db[key] = value
		end
	end
	UF._defaultsMerged = setmetatable({}, { __mode = "k" })
	UFProfileManager._activeProfileName = profileName
	local partyEnabled = profile.ufGroupFrames and profile.ufGroupFrames.party and profile.ufGroupFrames.party.enabled == true
	local raidEnabled = profile.ufGroupFrames and profile.ufGroupFrames.raid and profile.ufGroupFrames.raid.enabled == true
	UFProfileManager.Debug("bind runtime -> %s (ufGroupFrames=%s, party=%s, raid=%s)", tostring(profileName), tostring(profile.ufGroupFrames), tostring(partyEnabled), tostring(raidEnabled))
	UFProfileManager.Trace("BIND_RUNTIME", profileName)
	if UF.RecomputeRuntimeConsumerActivity then UF.RecomputeRuntimeConsumerActivity() end
	return profile
end

function UFProfileManager._isUFProfileBound(profileName)
	local profiles = addon.db and addon.db.ufProfiles
	if type(profiles) ~= "table" then return false end
	local profile = profiles[profileName]
	if type(profile) ~= "table" then return false end
	if addon.db.ufFrames ~= profile.ufFrames then return false end
	if addon.db.ufGroupFrames ~= profile.ufGroupFrames then return false end
	if addon.db.ufClassColors ~= profile.ufClassColors then return false end
	if addon.db.ufPowerColorOverrides ~= profile.ufPowerColorOverrides then return false end
	if addon.db.ufNPCColorOverrides ~= profile.ufNPCColorOverrides then return false end
	if (addon.db.ufUseCustomClassColors == true) ~= (profile.ufUseCustomClassColors == true) then return false end
	if (addon.db.ufUseCustomPowerColors == true) ~= (profile.ufUseCustomPowerColors == true) then return false end
	return true
end

function UFProfileManager.ScheduleSpecMappingRetry(source, immediate, initializedProfiles)
	if UF.HasRuntimeConsumers and not UF.HasRuntimeConsumers() then return false, "INACTIVE" end
	local retrySource = tostring(source or "UNKNOWN")
	UFProfileManager._specMappingRetrySource = retrySource
	if immediate ~= false then
		local immediateKey = retrySource .. "|" .. tostring(UFProfileManager._getCurrentSpecID() or "")
		if not UFProfileManager._specMappingRetryPending or UFProfileManager._specMappingRetryImmediateKey ~= immediateKey then
			UFProfileManager._specMappingRetryImmediateKey = immediateKey
			UFProfileManager.ApplySpecMapping(retrySource .. ":Immediate", initializedProfiles)
		end
	end
	if UFProfileManager._specMappingRetryPending or not After then return end
	UFProfileManager._specMappingRetryPending = true
	After(1, function()
		UFProfileManager._specMappingRetryPending = nil
		UFProfileManager._specMappingRetryImmediateKey = nil
		local delayedSource = UFProfileManager._specMappingRetrySource or retrySource
		UFProfileManager._specMappingRetrySource = nil
		UFProfileManager.ApplySpecMapping(delayedSource .. ":Delayed")
	end)
end

function UFProfileManager._ensureUFProfileEvents()
	if UFProfileManager._eventFrame then
		UFProfileManager.UpdateEventRegistration()
		return
	end
	local frame = CreateFrame("Frame")

	frame:SetScript("OnEvent", function(_, event, unit)
		if UF.HasRuntimeConsumers and not UF.HasRuntimeConsumers() then return end
		if event == "PLAYER_REGEN_ENABLED" then
			if UF._pendingProfileApply then UFProfileManager.ApplyCurrent("PLAYER_REGEN_ENABLED") end
			return
		end
		if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
		local ok = UFProfileManager.Initialize()
		if not ok then return end
		if
			event == "PLAYER_LOGIN"
			or event == "PLAYER_SPECIALIZATION_CHANGED"
			or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
			or event == "ACTIVE_TALENT_GROUP_CHANGED"
			or event == "PLAYER_ROLES_ASSIGNED"
		then
			UFProfileManager.ScheduleSpecMappingRetry(event, true, addon.db and addon.db.ufProfiles)
		end
	end)
	UFProfileManager._eventFrame = frame
	UFProfileManager.UpdateEventRegistration()
end

function UFProfileManager.UpdateEventRegistration()
	local frame = UFProfileManager._eventFrame
	if not frame then return end
	local enabled = UF.HasRuntimeConsumers and UF.HasRuntimeConsumers() or false
	if enabled then
		if frame._eqolUFProfileEventsRegistered then return end
		frame:RegisterEvent("PLAYER_LOGIN")
		frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
		frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		frame._eqolUFProfileEventsRegistered = true
		return
	end
	if frame._eqolUFProfileEventsRegistered then
		frame:UnregisterAllEvents()
		frame._eqolUFProfileEventsRegistered = nil
	end
	UFProfileManager._specMappingRetryPending = nil
	UFProfileManager._specMappingRetryImmediateKey = nil
	UFProfileManager._specMappingRetrySource = nil
end

function UFProfileManager.Initialize()
	UFProfileManager.Trace("INIT_BEGIN", "Initialize")
	if type(addon.db) ~= "table" then return false, "NO_DB" end
	local profiles = UFProfileManager._ensureUFProfilesRoot()
	if type(profiles) ~= "table" then return false, "NO_DB" end
	UFProfileManager._ensureUFProfileTablesDeduped(profiles)
	UFProfileManager._cleanUFProfileReferences(profiles)
	local activeName = UFProfileManager._resolveUFActiveProfileName(profiles)
	if not activeName or not profiles[activeName] then return false, "NO_PROFILE" end
	local guid = UFProfileManager._getCurrentPlayerGUID()
	local keyProfile = guid and addon.db.ufProfileKeys and addon.db.ufProfileKeys[guid] or nil
	UFProfileManager.Debug("initialize guid=%s key=%s global=%s resolved=%s", tostring(guid), tostring(keyProfile), tostring(addon.db.ufProfileGlobal), tostring(activeName))
	if not (UFProfileManager._activeProfileName == activeName and UFProfileManager._isUFProfileBound(activeName)) then UFProfileManager._bindUFProfileToRuntime(activeName) end
	UFProfileManager._ensureUFProfileEvents()
	UFProfileManager.UpdateEventRegistration()
	UFProfileManager._dbRef = addon.db
	UFProfileManager.Trace("INIT_DONE", activeName)
	return true
end

function UFProfileManager.MaybeInitialize()
	if type(addon.db) ~= "table" then return false, "NO_DB" end
	if UFProfileManager._dbRef ~= addon.db then
		UFProfileManager.Debug("maybe-init: db ref changed")
		UFProfileManager.Trace("MAYBE_INIT_REINIT", "DB_REF_CHANGED")
		return UFProfileManager.Initialize()
	end
	if not UFProfileManager._activeProfileName then
		UFProfileManager.Debug("maybe-init: missing active profile cache")
		UFProfileManager.Trace("MAYBE_INIT_REINIT", "NO_ACTIVE_CACHE")
		return UFProfileManager.Initialize()
	end
	local profiles = addon.db.ufProfiles
	local activeName = UFProfileManager._activeProfileName
	if type(profiles) ~= "table" or type(profiles[activeName]) ~= "table" then
		UFProfileManager.Debug("maybe-init: active profile payload missing")
		UFProfileManager.Trace("MAYBE_INIT_REINIT", "ACTIVE_PAYLOAD_MISSING")
		return UFProfileManager.Initialize()
	end
	if not UFProfileManager._isUFProfileBound(activeName) then
		UFProfileManager.Debug("maybe-init: runtime binding mismatch for %s", tostring(activeName))
		UFProfileManager.Trace("MAYBE_INIT_REINIT", "RUNTIME_BIND_MISMATCH")
		return UFProfileManager.Initialize()
	end

	local guid = UFProfileManager._getCurrentPlayerGUID()
	if guid and type(addon.db.ufProfileKeys) == "table" then
		local mapped = UFProfileManager._trimProfileName(addon.db.ufProfileKeys[guid])
		if mapped and profiles[mapped] and mapped ~= activeName then
			UFProfileManager.Debug("maybe-init: guid map %s -> %s (cached %s)", tostring(guid), tostring(mapped), tostring(activeName))
			UFProfileManager.Trace("MAYBE_INIT_REINIT", "GUID_MAP_DIFF")
			return UFProfileManager.Initialize()
		end
	end
	return true
end

function UFProfileManager.GetSortedNames()
	if not UFProfileManager.Initialize() then return {} end
	return UFProfileManager._getSortedUFProfileNames(addon.db.ufProfiles)
end

function UFProfileManager.GetActiveName()
	if not UFProfileManager.Initialize() then return nil end
	return UFProfileManager._activeProfileName
end

function UFProfileManager.GetGlobalName()
	if not UFProfileManager.Initialize() then return nil end
	return addon.db.ufProfileGlobal
end

function UFProfileManager.SetGlobalName(name)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	name = UFProfileManager._trimProfileName(name)
	if not name then return false, "INVALID_NAME" end
	if not addon.db.ufProfiles[name] then return false, "NOT_FOUND" end
	addon.db.ufProfileGlobal = name
	UFProfileManager.Trace("SET_GLOBAL", name)
	return true
end

function UFProfileManager.GetActiveProfile()
	if not UFProfileManager.Initialize() then return nil end
	local activeName = UFProfileManager._activeProfileName
	return activeName and addon.db.ufProfiles and addon.db.ufProfiles[activeName] or nil
end

function UFProfileManager.EnsureTableKey(key)
	if type(key) ~= "string" or key == "" then return nil end
	local profile = UFProfileManager.GetActiveProfile()
	if not profile then
		addon.db[key] = addon.db[key] or {}
		return addon.db[key]
	end
	local tbl = profile[key]
	if type(tbl) ~= "table" then
		tbl = {}
		profile[key] = tbl
	end
	addon.db[key] = tbl
	return tbl
end

function UFProfileManager.SetRuntimeKey(key, value)
	if type(key) ~= "string" or key == "" then return false end
	local profile = UFProfileManager.GetActiveProfile()
	if profile then profile[key] = value end
	addon.db[key] = value
	return true
end

function UFProfileManager.SetUseCustomClassColors(value)
	value = value == true
	local profile = UFProfileManager.GetActiveProfile()
	if profile then profile.ufUseCustomClassColors = value end
	addon.db.ufUseCustomClassColors = value
	return true
end

function UFProfileManager.SetUseCustomPowerColors(value)
	value = value == true
	local profile = UFProfileManager.GetActiveProfile()
	if profile then profile.ufUseCustomPowerColors = value end
	addon.db.ufUseCustomPowerColors = value
	return true
end

function UFProfileManager.SetActiveName(name, source)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	name = UFProfileManager._trimProfileName(name)
	if not name then return false, "INVALID_NAME" end
	if not addon.db.ufProfiles[name] then return false, "NOT_FOUND" end

	local guid = UFProfileManager._getCurrentPlayerGUID()
	if guid then
		addon.db.ufProfileKeys[guid] = name
	else
		addon.db.ufProfileGlobal = name
	end
	UFProfileManager.Debug("set active profile -> %s (source=%s, guid=%s)", tostring(name), tostring(source), tostring(guid))
	UFProfileManager.Trace("SET_ACTIVE", string.format("%s|%s", tostring(name), tostring(source)))

	return UFProfileManager.ApplyCurrent(source or "SET_ACTIVE")
end

function UFProfileManager._getSpecMappingFromProfiles(profiles, specID)
	if type(profiles) ~= "table" then return nil end
	local guid = UFProfileManager._getCurrentPlayerGUID()
	if not guid then return nil end
	local byGuid = UFProfileManager._resolveUFSpecMappingsForGUID(profiles, guid, true)
	if type(byGuid) ~= "table" then return nil end
	local key = tonumber(specID)
	if not key then return nil end
	return UFProfileManager._resolveUFSpecMappedProfileFromMappings(profiles, byGuid, key)
end

function UFProfileManager.GetSpecMapping(specID)
	if not UFProfileManager.Initialize() then return nil end
	return UFProfileManager._getSpecMappingFromProfiles(addon.db.ufProfiles, specID)
end

function UFProfileManager.SetSpecMapping(specID, profileName)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	local guid = UFProfileManager._getCurrentPlayerGUID()
	if not guid then return false, "NO_GUID" end
	local key = tonumber(specID)
	if not key or key <= 0 then return false, "INVALID_SPEC" end

	local maps = addon.db.ufProfileSpecKeys
	maps[guid] = type(maps[guid]) == "table" and maps[guid] or {}
	local byGuid = maps[guid]

	if profileName == nil or profileName == "" then
		byGuid[key] = nil
		byGuid[tostring(key)] = nil
		if not next(byGuid) then maps[guid] = nil end
		UFProfileManager.Trace("SET_SPEC_MAP", string.format("%s-><nil>", tostring(key)))
		return true
	end

	profileName = UFProfileManager._trimProfileName(profileName)
	if not profileName then return false, "INVALID_NAME" end
	if not addon.db.ufProfiles[profileName] then return false, "NOT_FOUND" end
	byGuid[key] = profileName
	byGuid[tostring(key)] = nil
	UFProfileManager.Trace("SET_SPEC_MAP", string.format("%s->%s", tostring(key), tostring(profileName)))
	return true
end

function UFProfileManager.Create(name)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	name = UFProfileManager._trimProfileName(name)
	if not name then return false, "INVALID_NAME" end
	if addon.db.ufProfiles[name] then return false, "EXISTS" end
	addon.db.ufProfiles[name] = UFProfileManager._ensureUFProfilePayload({})
	UFProfileManager._markUFProfilesDirty()
	UFProfileManager.Trace("CREATE_PROFILE", name)
	return true
end

function UFProfileManager.CopyToActive(sourceName)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	sourceName = UFProfileManager._trimProfileName(sourceName)
	if not sourceName then return false, "INVALID_NAME" end
	local source = addon.db.ufProfiles[sourceName]
	if type(source) ~= "table" then return false, "NOT_FOUND" end
	local activeName = UFProfileManager._activeProfileName
	if not activeName then return false, "NO_ACTIVE" end
	addon.db.ufProfiles[activeName] = UFProfileManager._ensureUFProfilePayload(UFProfileManager._copyProfileValue(source))
	UFProfileManager._markUFProfilesDirty()
	UFProfileManager.Trace("COPY_TO_ACTIVE", string.format("%s->%s", tostring(sourceName), tostring(activeName)))
	return UFProfileManager.ApplyCurrent("COPY_ACTIVE")
end

function UFProfileManager._removeUFProfileMappings(profileName)
	if type(addon.db.ufProfileKeys) == "table" then
		for guid, mapped in pairs(addon.db.ufProfileKeys) do
			if mapped == profileName then addon.db.ufProfileKeys[guid] = nil end
		end
	end
	if type(addon.db.ufProfileSpecKeys) == "table" then
		for guid, map in pairs(addon.db.ufProfileSpecKeys) do
			if type(map) == "table" then
				for specKey, mapped in pairs(map) do
					if mapped == profileName then map[specKey] = nil end
				end
				if not next(map) then addon.db.ufProfileSpecKeys[guid] = nil end
			else
				addon.db.ufProfileSpecKeys[guid] = nil
			end
		end
	end
end

function UFProfileManager.Delete(name)
	if not UFProfileManager.Initialize() then return false, "NO_DB" end
	name = UFProfileManager._trimProfileName(name)
	if not name then return false, "INVALID_NAME" end
	if not addon.db.ufProfiles[name] then return false, "NOT_FOUND" end
	if addon.db.ufProfileGlobal == name then return false, "PROTECTED" end
	local activeName = UFProfileManager.GetActiveName()
	if activeName == name then return false, "PROTECTED" end

	addon.db.ufProfiles[name] = nil
	UFProfileManager._markUFProfilesDirty()
	UFProfileManager._removeUFProfileMappings(name)
	UFProfileManager.Trace("DELETE_PROFILE", name)

	local names = UFProfileManager._getSortedUFProfileNames(addon.db.ufProfiles)
	if #names == 0 then
		addon.db.ufProfiles[UFProfileManager.DEFAULT_NAME] = UFProfileManager._ensureUFProfilePayload({})
		names[1] = UFProfileManager.DEFAULT_NAME
	end
	if not addon.db.ufProfiles[addon.db.ufProfileGlobal] then addon.db.ufProfileGlobal = names[1] end
	return true
end

function UFProfileManager.ApplyCurrent(reason)
	local ok, initReason = UFProfileManager.Initialize()
	if not ok then return false, initReason end

	local activeName = UFProfileManager._activeProfileName
	if not activeName then return false, "NO_ACTIVE" end

	if InCombatLockdown and InCombatLockdown() then
		UF._pendingProfileApply = true
		UF._pendingProfileApplyReason = reason or "PENDING"
		UFProfileManager.Debug("apply queued in combat (active=%s, reason=%s)", tostring(activeName), tostring(reason))
		UFProfileManager.Trace("APPLY_QUEUED", reason)
		return true, "QUEUED"
	end

	UF._pendingProfileApply = nil
	UF._pendingProfileApplyReason = nil
	UFProfileManager.Debug("apply now (active=%s, reason=%s)", tostring(activeName), tostring(reason))
	UFProfileManager.Trace("APPLY_NOW", reason)

	if UF.GroupFrames and UF.GroupFrames.ApplyProfileChange then UF.GroupFrames:ApplyProfileChange(reason) end
	if addon.Aura and addon.Aura.UFInitialized and UF.Refresh then UF.Refresh() end
	local standalone = addon.Aura and addon.Aura.UFStandaloneCastbar
	if standalone and standalone.Refresh then standalone.Refresh() end
	return true
end

function UFProfileManager.ApplySpecMapping(source, initializedProfiles)
	if UF.HasRuntimeConsumers and not UF.HasRuntimeConsumers() then return false, "INACTIVE" end
	local profiles = type(initializedProfiles) == "table" and initializedProfiles or nil
	if not profiles then
		local ok = UFProfileManager.Initialize()
		if not ok then return false, "NO_DB" end
		profiles = addon.db and addon.db.ufProfiles
	end
	if type(profiles) ~= "table" then return false, "NO_DB" end
	local specID = UFProfileManager._getCurrentSpecID()
	if not specID then return false, "NO_SPEC" end
	local mappedProfile = UFProfileManager._getSpecMappingFromProfiles(profiles, specID)
	if not mappedProfile then
		UFProfileManager.Trace("SPEC_MAP_SKIP", string.format("%s|NO_MAPPING", tostring(specID)))
		return false, "NO_MAPPING"
	end
	if mappedProfile == UFProfileManager._activeProfileName then return true, "UNCHANGED" end
	UFProfileManager.Debug("apply spec mapping spec=%s -> %s (source=%s)", tostring(specID), tostring(mappedProfile), tostring(source))
	UFProfileManager.Trace("SPEC_MAP_APPLY", string.format("%s->%s|%s", tostring(specID), tostring(mappedProfile), tostring(source)))
	return UFProfileManager.SetActiveName(mappedProfile, source or "SPEC_MAPPING")
end

UF._bossUnitLookup = UF._bossUnitLookup or { boss = true }
for i = 1, maxBossFrames do
	UF._bossUnitLookup["boss" .. i] = true
end

local function isBossUnit(unit) return type(unit) == "string" and UF._bossUnitLookup[unit] == true end

local UNITS = {
	player = {
		unit = UNIT.PLAYER,
		frameName = UF_FRAME_NAMES.player.frame,
		healthName = UF_FRAME_NAMES.player.health,
		powerName = UF_FRAME_NAMES.player.power,
		secondaryPowerName = UF_FRAME_NAMES.player.secondaryPower,
		statusName = UF_FRAME_NAMES.player.status,
		dropdown = function(self) ToggleDropDownMenu(1, nil, PlayerFrameDropDown, self, 0, 0) end,
	},
	target = {
		unit = UNIT.TARGET,
		frameName = UF_FRAME_NAMES.target.frame,
		healthName = UF_FRAME_NAMES.target.health,
		powerName = UF_FRAME_NAMES.target.power,
		statusName = UF_FRAME_NAMES.target.status,
		dropdown = function(self) ToggleDropDownMenu(1, nil, TargetFrameDropDown, self, 0, 0) end,
	},
	targettarget = {
		unit = UNIT.TARGET_TARGET,
		frameName = UF_FRAME_NAMES.targettarget.frame,
		healthName = UF_FRAME_NAMES.targettarget.health,
		powerName = UF_FRAME_NAMES.targettarget.power,
		statusName = UF_FRAME_NAMES.targettarget.status,
		dropdown = function(self) ToggleDropDownMenu(1, nil, TargetFrameDropDown, self, 0, 0) end,
	},
	focus = {
		unit = UNIT.FOCUS,
		frameName = UF_FRAME_NAMES.focus.frame,
		healthName = UF_FRAME_NAMES.focus.health,
		powerName = UF_FRAME_NAMES.focus.power,
		statusName = UF_FRAME_NAMES.focus.status,
		dropdown = function(self) ToggleDropDownMenu(1, nil, FocusFrameDropDown, self, 0, 0) end,
	},
	pet = {
		unit = UNIT.PET,
		frameName = UF_FRAME_NAMES.pet.frame,
		healthName = UF_FRAME_NAMES.pet.health,
		powerName = UF_FRAME_NAMES.pet.power,
		statusName = UF_FRAME_NAMES.pet.status,
		dropdown = function(self) ToggleDropDownMenu(1, nil, PetFrameDropDown, self, 0, 0) end,
		disableAbsorb = true,
	},
}
for i = 1, maxBossFrames do
	local unit = "boss" .. i
	UNITS[unit] = {
		unit = unit,
		frameName = "EQOLUFBoss" .. i .. "Frame",
		healthName = "EQOLUFBoss" .. i .. "Health",
		powerName = "EQOLUFBoss" .. i .. "Power",
		statusName = "EQOLUFBoss" .. i .. "Status",
	}
end

function UF.SupportsCombatIndicator(unit) return unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS end

local defaults = {
	player = {
		enabled = false,
		hideInPetBattle = false,
		hideInClientScene = true,
		showTooltip = false,
		tooltipUseEditMode = false,
		smoothFill = false,
		visibilityFadeStrength = 1,
		width = 220,
		healthHeight = 24,
		powerHeight = 16,
		secondaryPowerHeight = 16,
		statusHeight = 16,
		anchor = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = -200 },
		strata = "LOW",
		frameLevel = nil,
		border = {
			enabled = true,
			texture = "DEFAULT",
			color = { 0, 0, 0, 0.8 },
			edgeSize = 1,
			inset = 0,
			detachedPower = false,
			detachedPowerTexture = nil,
			detachedPowerSize = nil,
			detachedPowerOffset = nil,
			detachedSecondaryPower = false,
			detachedSecondaryPowerTexture = nil,
			detachedSecondaryPowerSize = nil,
			detachedSecondaryPowerOffset = nil,
		},
		highlight = {
			enabled = false,
			mouseover = true,
			target = false,
			aggro = true,
			combat = false,
			strata = nil,
			texture = "DEFAULT",
			size = 2,
			color = { 1, 0, 0, 1 },
		},
		health = {
			useCustomColor = false,
			useClassColor = false,
			useTapDeniedColor = true,
			usePercentColorCurve = false,
			percentColorCurveType = "COSINE",
			percentColorCurvePointCount = 2,
			percentColorCurvePoints = {
				{ percent = 0, color = { 0.9, 0.0, 0.0, 1 } },
				{ percent = 60, color = { 0.9, 0.9, 0.0, 1 } },
			},
			percentColorCurveMidpoint = 60,
			percentColorCurveMidColor = { 0.9, 0.9, 0.0, 1 },
			percentColorCurveLowColor = { 0.9, 0.0, 0.0, 1 },
			color = { 0.0, 0.8, 0.0, 1 },
			tapDeniedColor = { 0.5, 0.5, 0.5, 1 },
			absorbColor = { 0.85, 0.95, 1.0, 0.7 },
			absorbEnabled = true,
			absorbUseCustomColor = false,
			showSampleAbsorb = false,
			absorbTexture = "SOLID",
			absorbReverseFill = false,
			absorbOverlayAnchorTop = false,
			incomingHealEnabled = false,
			incomingHealColor = { 0.2, 0.85, 0.35, 0.45 },
			showSampleIncomingHeal = false,
			absorbDontOverflowHealthBar = false,
			useAbsorbGlow = true,
			healAbsorbColor = { 1.0, 0.3, 0.3, 0.7 },
			healAbsorbUseCustomColor = false,
			showSampleHealAbsorb = false,
			healAbsorbTexture = "SOLID",
			healAbsorbReverseFill = true,
			healAbsorbOverlayAnchorTop = false,
			tempMaxHealthLossEnabled = true,
			backdrop = { enabled = true, color = { 0, 0, 0, 0.6 }, texture = "DEFAULT", useClassColor = false, clampToFill = false },
			textLeft = "PERCENT",
			textCenter = "NONE",
			textRight = "CURMAX",
			textDelimiter = " ",
			fontSize = 14,
			font = nil,
			fontOutline = "OUTLINE", -- fallback to default font
			offsetLeft = { x = 6, y = 0 },
			offsetCenter = { x = 0, y = 0 },
			offsetRight = { x = -6, y = 0 },
			useShortNumbers = true,
			hidePercentSymbol = false,
			roundPercent = false,
			texture = "DEFAULT",
			reverseFill = false,
		},
		dataBar = {
			enabled = false,
			position = "BELOW",
			height = 16,
			gap = 0,
			detached = false,
			detachedWidth = nil,
			detachedHeight = nil,
			detachedOffset = { x = 0, y = 0 },
			color = { 0.18, 0.18, 0.22, 1 },
			useClassColor = false,
			customAtlas = "",
			textLeft = "NAME",
			textCenter = "CURMAX",
			textRight = "PERCENT",
			textDelimiter = " ",
			fontSize = 12,
			font = nil,
			fontOutline = "OUTLINE",
			nameMaxChars = 0,
			textColor = { 1, 1, 1, 1 },
			useTextClassColor = false,
			offsetLeft = { x = 6, y = 0 },
			offsetCenter = { x = 0, y = 0 },
			offsetRight = { x = -6, y = 0 },
			useShortNumbers = true,
			hidePercentSymbol = false,
			roundPercent = false,
			texture = "SOLID",
		},
		power = {
			enabled = true,
			detached = false,
			detachedGrowFromCenter = false,
			detachedMatchHealthWidth = false,
			detachedFrameLevelOffset = 5,
			detachedStrata = nil,
			emptyMaxFallback = false,
			color = { 0.1, 0.45, 1, 1 },
			backdrop = { enabled = true, color = { 0, 0, 0, 0.6 }, texture = "DEFAULT" },
			useCustomColor = false,
			textLeft = "PERCENT",
			textCenter = "NONE",
			textRight = "CURMAX",
			textDelimiter = " ",
			fontSize = 14,
			font = nil,
			offsetLeft = { x = 6, y = 0 },
			offsetCenter = { x = 0, y = 0 },
			offsetRight = { x = -6, y = 0 },
			useShortNumbers = true,
			hidePercentSymbol = false,
			roundPercent = false,
			texture = "DEFAULT",
			reverseFill = false,
		},
		secondaryPower = {
			enabled = false,
			allowedTypes = {
				MANA = true,
				STAGGER = true,
				VOID_METAMORPHOSIS = true,
			},
			staggerHighColors = false,
			staggerHighThreshold = 200,
			staggerExtremeThreshold = 300,
			staggerHighColor = { 0.62, 0.2, 1.0, 1 },
			staggerExtremeColor = { 1.0, 0.2, 0.8, 1 },
			detached = false,
			detachedGrowFromCenter = false,
			detachedMatchHealthWidth = false,
			detachedFrameLevelOffset = 5,
			detachedStrata = nil,
			emptyMaxFallback = false,
			color = { 0.1, 0.45, 1, 1 },
			backdrop = { enabled = true, color = { 0, 0, 0, 0.6 }, texture = "DEFAULT" },
			useCustomColor = false,
			textLeft = "PERCENT",
			textCenter = "NONE",
			textRight = "CURMAX",
			textDelimiter = " ",
			fontSize = 14,
			font = nil,
			offsetLeft = { x = 6, y = 0 },
			offsetCenter = { x = 0, y = 0 },
			offsetRight = { x = -6, y = 0 },
			useShortNumbers = true,
			hidePercentSymbol = false,
			roundPercent = false,
			texture = "DEFAULT",
			reverseFill = false,
		},
		status = {
			enabled = true,
			fontSize = 14,
			font = nil,
			fontOutline = "OUTLINE",
			nameColorMode = "CLASS", -- CLASS or CUSTOM
			nameColor = { 0.8, 0.8, 1, 1 },
			nameStrata = nil,
			nameFrameLevelOffset = 5,
			nameUseReactionColor = false,
			targetTargetName = {
				enabled = false,
				anchor = "RIGHT",
				offset = { x = 0, y = 0 },
				fontSize = nil,
			},
			levelColor = { 1, 0.85, 0, 1 },
			levelStrata = nil,
			levelFrameLevelOffset = 5,
			nameOffset = { x = 0, y = 0 },
			levelOffset = { x = 0, y = 0 },
			levelEnabled = true,
			hideLevelAtMax = false,
			classificationIcon = {
				enabled = false,
				hideText = false,
				size = 16,
				offset = { x = -4, y = 0 },
			},
			nameMaxChars = 0,
			unitStatus = {
				enabled = false,
				fontSize = nil,
				font = nil,
				fontOutline = nil,
				showGroup = true,
				groupFormat = "GROUP",
				groupFontSize = nil,
				groupOffset = { x = 0, y = 0 },
				offset = { x = 0, y = 0 },
			},
			combatIndicator = {
				enabled = false,
				size = 18,
				offset = { x = -8, y = 0 },
				icon = UF.COMBAT_INDICATOR_DEFAULT_ICON,
				texture = UF.COMBAT_INDICATOR_DEFAULT_TEXTURE,
				texCoords = { 0, 1, 0, 1 },
			},
			dispelTint = {
				enabled = true,
				filterMode = "MY",
				alpha = 0.25,
				showSample = false,
				fillEnabled = true,
				fillAlpha = 0.2,
				fillColor = { 0, 0, 0, 1 },
				strata = nil,
				frameLevelModel = 2,
				frameLevelOffset = 20,
				glowEnabled = false,
				glowColorMode = "DISPEL",
				glowColor = { 1, 1, 1, 1 },
				glowEffect = "PIXEL",
				glowFrequency = 0.25,
				glowX = 0,
				glowY = 0,
				glowLines = 8,
				glowThickness = 3,
				glowStrata = nil,
				glowFrameLevelModel = 2,
				glowFrameLevelOffset = 21,
			},
		},
		combatFeedback = {
			enabled = false,
			font = nil,
			fontSize = 30,
			anchor = "CENTER",
			location = "STATUS",
			offset = { x = 0, y = 0 },
			sample = false,
			sampleAmount = 12345,
			sampleEvent = "WOUND",
			events = {
				WOUND = true,
				HEAL = true,
				ENERGIZE = true,
				MISS = true,
				DODGE = true,
				PARRY = true,
				BLOCK = true,
				RESIST = true,
				ABSORB = true,
				IMMUNE = true,
				DEFLECT = true,
				REFLECT = true,
				EVADE = true,
				INTERRUPT = true,
			},
		},
		cast = {
			enabled = false,
			standalone = false,
			width = 220,
			height = 16,
			strata = nil,
			frameLevelOffset = nil,
			anchor = "BOTTOM", -- or "TOP"
			offset = { x = 0, y = -4 },
			backdrop = { enabled = true, color = { 0, 0, 0, 0.6 }, texture = "DEFAULT" },
			border = {
				enabled = false,
				color = { 0, 0, 0, 0.8 },
				texture = "DEFAULT",
				edgeSize = 1,
				offset = 1,
			},
			showName = true,
			nameAnchor = "LEFT",
			nameMaxChars = 0,
			showCastTarget = false,
			nameOffset = { x = 6, y = 0 },
			showDuration = true,
			durationFormat = "REMAINING",
			durationOffset = { x = -6, y = 0 },
			font = nil,
			fontSize = 12,
			showIcon = true,
			iconSize = 22,
			iconOffset = { x = -4, y = 0 },
			iconBorder = {
				enabled = false,
				color = { 0, 0, 0, 0.8 },
				texture = "DEFAULT",
				edgeSize = 1,
				offset = 1,
			},
			texture = "DEFAULT",
			color = { 0.9, 0.7, 0.2, 1 },
			useClassColor = false,
			useGradient = false,
			gradientStartColor = { 1, 1, 1, 1 },
			gradientEndColor = { 1, 1, 1, 1 },
			gradientDirection = "HORIZONTAL",
			gradientMode = "CASTBAR",
			notInterruptibleColor = DEFAULT_NOT_INTERRUPTIBLE_COLOR,
			showInterruptFeedback = true,
			showInterruptFeedbackGlow = true,
			interruptFeedbackColor = { 0.85, 0.12, 0.12, 1 },
		},
		resting = {
			enabled = true,
			size = 20,
			offset = { x = 0, y = 0 },
		},
		classResource = {
			enabled = false,
			anchor = "BOTTOM",
			offset = { x = 0, y = -28 },
			scale = 1,
			resources = {},
			totemFrame = {
				enabled = false,
				anchor = "BOTTOMRIGHT",
				offset = { x = 0, y = 20 },
				scale = 1,
				showSample = false,
			},
		},
		raidIcon = {
			enabled = true,
			size = 18,
			offset = { x = 0, y = -2 },
		},
		leaderIcon = {
			enabled = false,
			size = 12,
			offset = { x = 0, y = 0 },
		},
		pvpIndicator = {
			enabled = false,
			size = 20,
			offset = { x = -24, y = -2 },
		},
		roleIndicator = {
			enabled = false,
			size = 18,
			offset = { x = 24, y = -2 },
		},
		portrait = {
			detached = false,
			detachedFrameLevelOffset = 1,
			detachedSize = nil,
			detachedStrata = nil,
			enabled = false,
			mode = "PORTRAIT",
			shape = "SQUARE",
			side = "LEFT",
			squareBackground = true,
			separator = {
				enabled = true,
				texture = "SOLID",
			},
		},
	},
	target = {
		enabled = false,
		showTooltip = false,
		rangeFade = {
			enabled = true,
			alpha = 0.5,
			ignoreUnlimitedSpells = true,
		},
		auraIcons = {
			enabled = true,
			combineLayout = true,
			size = 24,
			debuffSize = nil,
			padding = 2,
			max = 16,
			perRow = 0,
			showCooldown = true,
			showCooldownBuffs = nil,
			showCooldownDebuffs = nil,
			showBuffs = true,
			showDebuffs = true,
			enemyDebuffFilterMode = ENEMY_DEBUFF_FILTER_MODE_PLAYER,
			blizzardDispelBorder = false,
			blizzardDispelBorderAlpha = 1,
			blizzardDispelBorderAlphaNot = 0,
			blizzardStealableBorder = true,
			blizzardStealableGlowStyle = "DEFAULT",
			blizzardStealableGlowInset = 0,
			borderColor = nil,
			borderTexture = "DEFAULT",
			borderRenderMode = "EDGE",
			borderSize = nil,
			borderOffset = 0,
			iconShape = "DEFAULT",
			iconZoom = 0,
			showTooltip = true,
			hidePermanentAuras = false,
			anchor = "BOTTOM",
			offset = { x = 0, y = -24 },
			debuffAnchor = nil, -- falls back to anchor
			debuffOffset = nil, -- falls back to offset
			countAnchor = "BOTTOMRIGHT",
			countOffset = { x = -2, y = 2 },
			countFont = "__EQOL_GLOBAL_FONT__",
			countFontSize = nil,
			countFontSizeBuff = nil,
			countFontSizeDebuff = nil,
			countFontOutline = nil,
			cooldownFontSize = 12,
			cooldownFontSizeBuff = nil,
			cooldownFontSizeDebuff = nil,
		},
		cast = {
			enabled = true,
			width = 200,
			height = 16,
			strata = nil,
			frameLevelOffset = nil,
			anchor = "BOTTOM", -- or "TOP"
			offset = { x = 11, y = -4 },
			backdrop = { enabled = true, color = { 0, 0, 0, 0.6 }, texture = "DEFAULT" },
			border = {
				enabled = false,
				color = { 0, 0, 0, 0.8 },
				texture = "DEFAULT",
				edgeSize = 1,
				offset = 1,
			},
			showName = true,
			nameAnchor = "LEFT",
			nameMaxChars = 0,
			showCastTarget = false,
			nameOffset = { x = 6, y = 0 },
			showDuration = true,
			durationFormat = "REMAINING",
			durationOffset = { x = -6, y = 0 },
			font = nil,
			fontSize = 12,
			showIcon = true,
			iconSize = 22,
			iconOffset = { x = -4, y = 0 },
			iconBorder = {
				enabled = false,
				color = { 0, 0, 0, 0.8 },
				texture = "DEFAULT",
				edgeSize = 1,
				offset = 1,
			},
			texture = "DEFAULT",
			color = { 0.9, 0.7, 0.2, 1 },
			useClassColor = false,
			useGradient = false,
			gradientStartColor = { 1, 1, 1, 1 },
			gradientEndColor = { 1, 1, 1, 1 },
			gradientDirection = "HORIZONTAL",
			gradientMode = "CASTBAR",
			notInterruptibleColor = DEFAULT_NOT_INTERRUPTIBLE_COLOR,
			showInterruptFeedback = true,
			showInterruptFeedbackGlow = true,
			interruptFeedbackColor = { 0.85, 0.12, 0.12, 1 },
		},
		portrait = {
			detached = false,
			detachedFrameLevelOffset = 1,
			detachedSize = nil,
			detachedStrata = nil,
			enabled = false,
			mode = "PORTRAIT",
			shape = "SQUARE",
			side = "LEFT",
			squareBackground = false,
			separator = {
				enabled = true,
				texture = "SOLID",
			},
		},
	},
	targettarget = {
		enabled = false,
		showTooltip = false,
		width = 180,
		healthHeight = 20,
		powerHeight = 12,
		statusHeight = 16,
		anchor = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 520, y = -200 },
		portrait = {
			detached = false,
			detachedFrameLevelOffset = 1,
			detachedSize = nil,
			detachedStrata = nil,
			enabled = false,
			mode = "PORTRAIT",
			shape = "SQUARE",
			side = "LEFT",
			squareBackground = false,
			separator = {
				enabled = true,
				texture = "SOLID",
			},
		},
	},
}

local function hideSettingsReset(frame)
	if frame and addon.EditModeLib and addon.EditModeLib.SetFrameResetVisible then addon.EditModeLib:SetFrameResetVisible(frame, false) end
end

local issecretvalue = _G.issecretvalue
function AuraUtil.canReadAuraData()
	return not addon.AuraCompat or addon.AuraCompat:CanReadAuraData()
end
local mainPowerEnum
local mainPowerToken
local states = {}
local function createAuraCacheState() return { auras = {}, order = {}, indexById = {} } end
local function createAuraKindState()
	return {
		buff = createAuraCacheState(),
		debuff = createAuraCacheState(),
	}
end
local targetAuraKinds = createAuraKindState()
local focusAuraKinds = createAuraKindState()
local playerAuraKinds = createAuraKindState()
local bossAuraStates = {}
local AURA_FILTER_HELPFUL = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
local AURA_FILTER_HARMFUL = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY"
local AURA_FILTER_HARMFUL_ALL = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"
local SAMPLE_BUFF_ICONS = { 136243, 135940, 136085, 136097, 136116, 136048, 135932, 136108 }
local SAMPLE_DEBUFF_ICONS = { 136207, 136160, 136128, 135804, 136168, 132104, 136118, 136214 }
local SAMPLE_DISPEL_TYPES = { "Magic", "Curse", "Disease", "Poison" }
AuraUtil.isAuraFilteredIn = UFHelper.IsAuraFilteredIn
local blizzardPlayerHooked = false
local blizzardTargetHooked = false
local castOnUpdateHandlers = {}
local originalFrameRules = {}
local NIL_VISIBILITY_SENTINEL = {}
local totTicker
local editModeHooked
local bossContainer
local bossLayoutDirty
local bossHidePending
local bossShowPending
local bossInitPending

local function defaultsFor(unit)
	if isBossUnit(unit) then return defaults.boss or defaults.target or defaults.player or {} end
	return defaults[unit] or defaults.player or {}
end

function AuraUtil.normalizeEnemyDebuffFilterMode(value)
	value = type(value) == "string" and value:upper() or nil
	if value == ENEMY_DEBUFF_FILTER_MODE_ALL then return ENEMY_DEBUFF_FILTER_MODE_ALL end
	return ENEMY_DEBUFF_FILTER_MODE_PLAYER
end

function AuraUtil.buildSingleAuraRuntimeConfig(ac, defAc)
	local resolved = {
		buff = AuraUtil.resolveSingleAuraSection(ac, defAc, "buff"),
		debuff = AuraUtil.resolveSingleAuraSection(ac, defAc, "debuff"),
	}
	resolved.combineLayout = AuraUtil.resolveSingleAuraCombineLayout(ac, defAc, resolved.buff, resolved.debuff)
	if resolved.buff.enabled == nil then resolved.buff.enabled = true end
	if resolved.debuff.enabled == nil then resolved.debuff.enabled = true end
	resolved.enabled = (resolved.buff.enabled ~= false) or (resolved.debuff.enabled ~= false)

	local buff = AuraUtil.prepareSingleAuraSectionStyle(resolved.buff)
	local debuff = AuraUtil.prepareSingleAuraSectionStyle(resolved.debuff)
	local showBuffs = buff.enabled ~= false
	local showDebuffs = debuff.enabled ~= false
	local relayoutThreshold
	local helpfulLimit
	local harmfulLimit

	relayoutThreshold = math.max(buff.max or 0, debuff.max or 0) + 1
	helpfulLimit = showBuffs and AuraUtil.normalizeAuraQueryLimit((buff.max or 0) + 1) or nil
	harmfulLimit = showDebuffs and AuraUtil.normalizeAuraQueryLimit((debuff.max or 0) + 1) or nil

	local enemyHarmfulFilter = AURA_FILTER_HARMFUL
	if AuraUtil.normalizeEnemyDebuffFilterMode(debuff.enemyDebuffFilterMode) == ENEMY_DEBUFF_FILTER_MODE_ALL then enemyHarmfulFilter = AURA_FILTER_HARMFUL_ALL end

	return {
		ac = ac,
		defAc = defAc,
		resolved = resolved,
		buff = buff,
		debuff = debuff,
		enabled = resolved.enabled == true,
		showBuffs = showBuffs,
		showDebuffs = showDebuffs,
		combineLayout = resolved.combineLayout == true,
		relayoutThreshold = relayoutThreshold,
		helpfulLimit = helpfulLimit,
		harmfulLimit = harmfulLimit,
		enemyHarmfulFilter = enemyHarmfulFilter,
	}
end

function AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, defAc)
	local st = unit and states[unit]
	local cached = st and st._singleAuraRuntimeConfig
	if cached and cached.ac == ac and cached.defAc == defAc then return cached end

	local runtime = AuraUtil.buildSingleAuraRuntimeConfig(ac, defAc)
	if st then st._singleAuraRuntimeConfig = runtime end
	return runtime
end

function AuraUtil.invalidateUnitSingleAuraRuntimeConfig(unit)
	local st = unit and states[unit]
	if st then
		st._singleAuraRuntimeConfig = nil
		if AuraUtil.ClearNativeAuraIdentityPlan then AuraUtil.ClearNativeAuraIdentityPlan(st) end
	end
end

function AuraUtil.getUnitAuraFilters(unit, auraRuntime)
	if unit == UNIT.PLAYER or unit == "player" then return AURA_FILTER_HELPFUL, AURA_FILTER_HARMFUL_ALL end
	if isBossUnit(unit) and UnitIsFriend and unit and UnitIsFriend("player", unit) then return "HELPFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY", AURA_FILTER_HARMFUL_ALL end
	if UnitIsFriend and unit and UnitIsFriend("player", unit) then return AURA_FILTER_HELPFUL, AURA_FILTER_HARMFUL_ALL end
	return AURA_FILTER_HELPFUL, auraRuntime and auraRuntime.enemyHarmfulFilter or AURA_FILTER_HARMFUL
end

function AuraUtil.getAuraFilters(unit, ac, defAc)
	if unit == UNIT.PLAYER or unit == "player" then return AURA_FILTER_HELPFUL, AURA_FILTER_HARMFUL_ALL end
	if isBossUnit(unit) and UnitIsFriend and unit and UnitIsFriend("player", unit) then return "HELPFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY", AURA_FILTER_HARMFUL_ALL end
	if UnitIsFriend and unit and UnitIsFriend("player", unit) then return AURA_FILTER_HELPFUL, AURA_FILTER_HARMFUL_ALL end

	local harmfulFilter = AURA_FILTER_HARMFUL
	local resolved = AuraUtil.resolveSingleAuraConfig(ac, defAc)
	local debuffSection = resolved and resolved.debuff
	local enemyDebuffFilterMode = AuraUtil.normalizeEnemyDebuffFilterMode(debuffSection and debuffSection.enemyDebuffFilterMode)
	if enemyDebuffFilterMode == ENEMY_DEBUFF_FILTER_MODE_ALL then harmfulFilter = AURA_FILTER_HARMFUL_ALL end

	return AURA_FILTER_HELPFUL, harmfulFilter
end

function AuraUtil.cloneAuraSettingValue(value)
	if type(value) ~= "table" then return value end
	return CopyTable(value)
end

function AuraUtil.copyAuraSectionValues(dest, src)
	if type(dest) ~= "table" or type(src) ~= "table" then return end
	for key, value in pairs(src) do
		dest[key] = AuraUtil.cloneAuraSettingValue(value)
	end
end

AuraUtil._LEGACY_AURA_SECTION_EXCLUDES = {
	buff = true,
	debuff = true,
	enabled = true,
	combineLayout = true,
	combineLayoutModel = true,
	showBuffs = true,
	showDebuffs = true,
	size = true,
	debuffSize = true,
	padding = true,
	spacing = true,
	max = true,
	perRow = true,
	showCooldown = true,
	showCooldownBuffs = true,
	showCooldownDebuffs = true,
	showCooldownText = true,
	showCooldownTextBuffs = true,
	showCooldownTextDebuffs = true,
	showTooltip = true,
	hidePermanentAuras = true,
	hidePermanent = true,
	anchor = true,
	growth = true,
	offset = true,
	separateDebuffAnchor = true,
	debuffAnchor = true,
	debuffGrowth = true,
	debuffOffset = true,
	blizzardDispelBorder = true,
	blizzardDispelBorderAlpha = true,
	blizzardDispelBorderAlphaNot = true,
	blizzardStealableBorder = true,
	blizzardStealableGlowStyle = true,
	blizzardStealableGlowInset = true,
	countFontSize = true,
	countFontSizeBuff = true,
	countFontSizeDebuff = true,
	countFont = true,
	cooldownFontSize = true,
	cooldownFontSizeBuff = true,
	cooldownFontSizeDebuff = true,
	durationTextProfile = true,
	durationTextProfileBuff = true,
	durationTextProfileDebuff = true,
}

function AuraUtil.NormalizeDurationTextProfile(value, fallback)
	local durationText = addon.DurationText
	if durationText and durationText.GetProfileKey then return durationText:GetProfileKey(value or fallback or "MINIMAL") end
	return type(value) == "string" and value ~= "" and value or fallback or "MINIMAL"
end

function AuraUtil.ApplyDurationTextProfileToCooldownFrame(cooldown, profileKey)
	if not (cooldown and addon.functions and addon.functions.ApplyDurationTextProfileToCooldownFrame) then return false end
	return addon.functions.ApplyDurationTextProfileToCooldownFrame(cooldown, AuraUtil.NormalizeDurationTextProfile(profileKey, "MINIMAL"))
end

function AuraUtil.buildLegacyAuraSection(src, isDebuff)
	local section = {}
	if type(src) ~= "table" then return section end

	for key, value in pairs(src) do
		if not AuraUtil._LEGACY_AURA_SECTION_EXCLUDES[key] then section[key] = AuraUtil.cloneAuraSettingValue(value) end
	end

	local enabled
	if src.enabled == false then
		enabled = false
	else
		enabled = isDebuff and src.showDebuffs or src.showBuffs
		if enabled == nil then enabled = src.enabled end
	end
	if enabled ~= nil then section.enabled = enabled and true or false end

	local size = isDebuff and src.debuffSize or src.size
	if size == nil then size = src.size end
	if size ~= nil then section.size = size end

	local spacing = src.spacing
	if spacing == nil then spacing = src.padding end
	if spacing ~= nil then section.spacing = spacing end

	if src.max ~= nil then section.max = src.max end
	if src.perRow ~= nil then section.perRow = src.perRow end
	if src.showTooltip ~= nil then section.showTooltip = src.showTooltip and true or false end
	if isDebuff and src.enemyDebuffFilterMode ~= nil then section.enemyDebuffFilterMode = AuraUtil.normalizeEnemyDebuffFilterMode(src.enemyDebuffFilterMode) end

	local showCooldown = isDebuff and src.showCooldownDebuffs or src.showCooldownBuffs
	if showCooldown == nil then showCooldown = src.showCooldown end
	if showCooldown ~= nil then section.showCooldown = showCooldown and true or false end

	local showCooldownText = isDebuff and src.showCooldownTextDebuffs or src.showCooldownTextBuffs
	if showCooldownText == nil then showCooldownText = src.showCooldownText end
	if showCooldownText == nil then showCooldownText = showCooldown end
	if showCooldownText ~= nil then section.showCooldownText = showCooldownText and true or false end

	local countFontSize = isDebuff and src.countFontSizeDebuff or src.countFontSizeBuff
	if countFontSize == nil then countFontSize = src.countFontSize end
	if countFontSize ~= nil then section.countFontSize = countFontSize end
	if src.countFont ~= nil then section.countFont = src.countFont end

	local cooldownFontSize = isDebuff and src.cooldownFontSizeDebuff or src.cooldownFontSizeBuff
	if cooldownFontSize == nil then cooldownFontSize = src.cooldownFontSize end
	if cooldownFontSize ~= nil then section.cooldownFontSize = cooldownFontSize end

	local durationTextProfile = isDebuff and src.durationTextProfileDebuff or src.durationTextProfileBuff
	if durationTextProfile == nil then durationTextProfile = src.durationTextProfile end
	if durationTextProfile ~= nil then section.durationTextProfile = AuraUtil.NormalizeDurationTextProfile(durationTextProfile, "MINIMAL") end

	local anchor = src.anchor
	local growth = src.growth
	local offset = src.offset
	if isDebuff then
		if src.debuffAnchor ~= nil then anchor = src.debuffAnchor end
		if src.debuffGrowth ~= nil then growth = src.debuffGrowth end
		if type(src.debuffOffset) == "table" then offset = src.debuffOffset end
	end
	if anchor ~= nil then section.anchor = anchor end
	if growth ~= nil then section.growth = growth end
	if type(offset) == "table" then section.offset = AuraUtil.cloneAuraSettingValue(offset) end

	local hidePermanent = src.hidePermanentAuras
	if hidePermanent == nil then hidePermanent = src.hidePermanent end
	if hidePermanent ~= nil then section.hidePermanentAuras = hidePermanent and true or false end

	if isDebuff then
		if src.blizzardDispelBorder ~= nil then section.blizzardDispelBorder = src.blizzardDispelBorder and true or false end
		if src.blizzardDispelBorderAlpha ~= nil then section.blizzardDispelBorderAlpha = src.blizzardDispelBorderAlpha end
		if src.blizzardDispelBorderAlphaNot ~= nil then section.blizzardDispelBorderAlphaNot = src.blizzardDispelBorderAlphaNot end
	elseif not isDebuff then
		if src.blizzardStealableBorder ~= nil then section.blizzardStealableBorder = src.blizzardStealableBorder and true or false end
		if src.blizzardStealableGlowStyle ~= nil then section.blizzardStealableGlowStyle = src.blizzardStealableGlowStyle end
		if src.blizzardStealableGlowInset ~= nil then section.blizzardStealableGlowInset = src.blizzardStealableGlowInset end
	end

	return section
end

function AuraUtil.resolveSingleAuraSection(src, defAc, sectionKey)
	local isDebuff = sectionKey == "debuff"
	local section = {}
	AuraUtil.copyAuraSectionValues(section, AuraUtil.buildLegacyAuraSection(defAc, isDebuff))
	if type(defAc) == "table" and type(defAc[sectionKey]) == "table" then AuraUtil.copyAuraSectionValues(section, defAc[sectionKey]) end
	AuraUtil.copyAuraSectionValues(section, AuraUtil.buildLegacyAuraSection(src, isDebuff))
	if type(src) == "table" and type(src[sectionKey]) == "table" then AuraUtil.copyAuraSectionValues(section, src[sectionKey]) end
	return section
end

function AuraUtil.resolveSingleAuraCombineLayout(src, defAc, buff, debuff)
	if type(src) == "table" then
		if src.combineLayoutModel == 2 and src.combineLayout ~= nil then return src.combineLayout == true end
		if src.separateDebuffAnchor == true then return false end
	end

	-- Profiles created while combined layout support was unavailable may already
	-- contain intentionally independent debuff positioning. Preserve it.
	buff = buff or {}
	debuff = debuff or {}
	local buffAnchor = buff.anchor or "BOTTOM"
	local debuffAnchor = debuff.anchor or buffAnchor
	if debuffAnchor ~= buffAnchor then return false end
	local buffGrowth = buff.growth or ""
	local debuffGrowth = debuff.growth or buffGrowth
	if debuffGrowth ~= buffGrowth then return false end
	local buffOffset = buff.offset or {}
	local debuffOffset = debuff.offset or buffOffset
	if tonumber(debuffOffset.x) ~= tonumber(buffOffset.x) or tonumber(debuffOffset.y) ~= tonumber(buffOffset.y) then return false end
	if type(src) == "table" then
		if src.combineLayout ~= nil then return src.combineLayout == true end
		if src.separateDebuffAnchor ~= nil then return src.separateDebuffAnchor ~= true end
	end
	if type(defAc) == "table" then
		if defAc.combineLayout ~= nil then return defAc.combineLayout == true end
		if defAc.separateDebuffAnchor ~= nil then return defAc.separateDebuffAnchor ~= true end
	end
	return true
end

function AuraUtil.resolveSingleAuraConfig(ac, defAc)
	local resolved = {
		buff = AuraUtil.resolveSingleAuraSection(ac, defAc, "buff"),
		debuff = AuraUtil.resolveSingleAuraSection(ac, defAc, "debuff"),
	}
	resolved.combineLayout = AuraUtil.resolveSingleAuraCombineLayout(ac, defAc, resolved.buff, resolved.debuff)
	if resolved.buff.enabled == nil then resolved.buff.enabled = true end
	if resolved.debuff.enabled == nil then resolved.debuff.enabled = true end
	resolved.enabled = (resolved.buff.enabled ~= false) or (resolved.debuff.enabled ~= false)
	return resolved
end

function AuraUtil.ensureSingleAuraConfig(ac, defAc)
	if type(ac) ~= "table" then return ac end
	local resolved = AuraUtil.resolveSingleAuraConfig(ac, defAc)
	ac.buff = resolved.buff
	ac.debuff = resolved.debuff
	ac.combineLayout = resolved.combineLayout == true
	ac.enabled = resolved.enabled
	ac.showBuffs = resolved.buff.enabled ~= false
	ac.showDebuffs = resolved.debuff.enabled ~= false
	ac.separateDebuffAnchor = ac.combineLayout ~= true
	return ac
end

function AuraUtil.isAuraIconsEnabled(ac, def)
	local defAc = (def and def.auraIcons) or defaults.target.auraIcons
	if type(ac) == "table" and (type(ac.buff) == "table" or type(ac.debuff) == "table") then
		local resolved = AuraUtil.resolveSingleAuraConfig(ac, defAc)
		return resolved.enabled == true
	end
	if ac and ac.enabled ~= nil then return ac.enabled ~= false end
	if type(defAc) == "table" and (type(defAc.buff) == "table" or type(defAc.debuff) == "table") then
		local resolved = AuraUtil.resolveSingleAuraConfig(nil, defAc)
		return resolved.enabled == true
	end
	if defAc and defAc.enabled ~= nil then return defAc.enabled ~= false end
	return true
end

function AuraUtil.getAuraKindCache(unit, kind)
	unit = unit or "target"
	kind = kind == "debuff" and "debuff" or "buff"
	if unit == UNIT.PLAYER or unit == "player" then return playerAuraKinds[kind] end
	if unit == UNIT.TARGET or unit == "target" then return targetAuraKinds[kind] end
	if unit == UNIT.FOCUS or unit == "focus" then return focusAuraKinds[kind] end
	if not isBossUnit(unit) or unit == "boss" then return nil end
	local state = bossAuraStates[unit]
	if not state then
		state = { kinds = createAuraKindState() }
		bossAuraStates[unit] = state
	elseif not state.kinds then
		state.kinds = createAuraKindState()
	end
	return state.kinds[kind]
end

function AuraUtil.clearAuraCache(cache)
	if not cache then return end
	local auras, order, indexById = cache.auras, cache.order, cache.indexById
	if auras then
		for k in pairs(auras) do
			auras[k] = nil
		end
	end
	if order then
		for i = #order, 1, -1 do
			order[i] = nil
		end
	end
	if indexById then
		for k in pairs(indexById) do
			indexById[k] = nil
		end
	end
	cache._orderDirty = nil
end

function AuraUtil.resetTargetAuras(unit)
	AuraUtil.clearAuraCache(AuraUtil.getAuraKindCache(unit, "buff"))
	AuraUtil.clearAuraCache(AuraUtil.getAuraKindCache(unit, "debuff"))
end

local function ensureDB(unit)
	if UFProfileManager and UFProfileManager.MaybeInitialize then UFProfileManager.MaybeInitialize() end
	addon.db = addon.db or {}
	addon.db.ufFrames = addon.db.ufFrames or {}
	local db = addon.db.ufFrames
	local key = unit
	if isBossUnit(unit) then key = "boss" end
	if key == "boss" and not db[key] then
		for i = 1, maxBossFrames do
			if db["boss" .. i] then
				db[key] = db["boss" .. i]
				break
			end
		end
	end
	db[key] = db[key] or {}
	local udb = db[key]
	if (key == UNIT.PLAYER or key == "player") and ClassResourceUtil and ClassResourceUtil.MigrateLegacyConfig then
		ClassResourceUtil.MigrateLegacyConfig(udb.classResource, addon.variables and addon.variables.unitClass)
	end
	UF._defaultsMerged = UF._defaultsMerged or setmetatable({}, { __mode = "k" })
	if UF._defaultsMerged[udb] then return udb end
	local def = defaultsFor(unit)
	for k, v in pairs(def) do
		if udb[k] == nil then
			if type(v) == "table" then
				if addon.functions.copyTable then
					udb[k] = addon.functions.copyTable(v)
				else
					udb[k] = CopyTable(v)
				end
			else
				udb[k] = v
			end
		end
	end
	if (key == UNIT.PLAYER or key == "player") and ClassResourceUtil and ClassResourceUtil.MigrateLegacyConfig then
		ClassResourceUtil.MigrateLegacyConfig(udb.classResource, addon.variables and addon.variables.unitClass)
	end
	UF._defaultsMerged[udb] = true
	return udb
end

function UF.ReanchorFramesAttachedToCooldownPanels(panelIds)
	if type(panelIds) ~= "table" then return end
	if InCombatLockdown and InCombatLockdown() then
		UF._pendingCooldownPanelReanchors = UF._pendingCooldownPanelReanchors or {}
		for _, panelId in ipairs(panelIds) do
			UF._pendingCooldownPanelReanchors[panelId] = true
		end
		if not UF._cooldownPanelReanchorWatcher then
			UF._cooldownPanelReanchorWatcher = CreateFrame("Frame")
			UF._cooldownPanelReanchorWatcher:SetScript("OnEvent", function(self)
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				local pending = UF._pendingCooldownPanelReanchors
				UF._pendingCooldownPanelReanchors = nil
				UF.ReanchorFramesAttachedToCooldownPanels(pending or {})
			end)
		end
		UF._cooldownPanelReanchorWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local targets = {}
	for key, value in pairs(panelIds) do
		local panelId = value == true and key or value
		targets["EQOL_CooldownPanel" .. tostring(panelId)] = true
	end
	for _, unit in ipairs({ UNIT.PLAYER, UNIT.TARGET, UNIT.TARGET_TARGET, UNIT.FOCUS, UNIT.PET }) do
		local cfg = ensureDB(unit)
		local st = states[unit]
		local anchor = cfg and cfg.anchor
		local relativeName = anchor and (anchor.relativeTo or anchor.relativeFrame)
		if cfg and cfg.enabled and st and st.frame and targets[relativeName] then
			local rel = resolveRelativeAnchorFrame(relativeName, st.frame:GetName())
			local anchorPoint = anchor.point or "CENTER"
			local relativePoint = anchor.relativePoint or anchorPoint
			local anchorY = UF.ResolvePhysicalUnitFrameAnchorY(anchorPoint, relativePoint, anchor.y, rel, st.frame._eqolUFStatusHeightDelta)
			st.frame:ClearAllPoints()
			st.frame:SetPoint(anchorPoint, rel or UIParent, relativePoint, anchor.x or 0, anchorY)
		end
	end
end

function UF.GetBossFrameCount(cfg)
	if cfg == nil then cfg = ensureDB("boss") end
	local value = tonumber(cfg and cfg.bossCount)
	if value then value = math.floor(value + 0.5) end
	if not value or value < 1 then value = MAX_BOSS_FRAMES or 5 end
	if value > maxBossFrames then value = maxBossFrames end
	return value
end

UF.GetDefaultBossFrameCount = function() return MAX_BOSS_FRAMES or 5 end
UF.GetSupportedBossFrameCount = function() return maxBossFrames end

local function hasVisibilityRules(cfg)
	if not cfg then return false end
	local raw = cfg.visibility
	return type(raw) == "table" and next(raw) ~= nil
end

function UF.BuildTargetRangeFadeSpellListKey(spellList)
	if type(spellList) ~= "table" or #spellList == 0 then return "" end
	local parts = {}
	for i = 1, #spellList do
		parts[i] = tostring(tonumber(spellList[i]) or 0)
	end
	return table.concat(parts, ",")
end

function UF.BuildTargetRangeFadeSnapshot(cfg, def)
	cfg = cfg or ensureDB(UNIT.TARGET)
	def = def or defaultsFor(UNIT.TARGET)
	local rcfg = (cfg and cfg.rangeFade) or (def and def.rangeFade) or {}
	local blockedByVisibility = hasVisibilityRules(cfg) == true
	local enabled = (cfg and cfg.enabled ~= false) and rcfg.enabled == true and not blockedByVisibility
	local alpha = tonumber(rcfg.alpha)
	if alpha == nil then alpha = 0.5 end
	if alpha < 0 then alpha = 0 end
	if alpha > 1 then alpha = 1 end
	local ignoreUnlimited = rcfg.ignoreUnlimitedSpells
	if ignoreUnlimited == nil then
		ignoreUnlimited = true
	else
		ignoreUnlimited = ignoreUnlimited == true
	end
	local specId = UFHelper and UFHelper.RangeFadeGetCurrentSpecId and UFHelper.RangeFadeGetCurrentSpecId() or nil
	local spellList
	if UFHelper and UFHelper.RangeFadeBuildSpellListForConfig then spellList = UFHelper.RangeFadeBuildSpellListForConfig(rcfg, specId) end
	local spellListKey = UF.BuildTargetRangeFadeSpellListKey(spellList)
	local configKey = (enabled == true and "1" or "0") .. "|" .. (blockedByVisibility == true and "1" or "0") .. "|" .. tostring(alpha) .. "|" .. (ignoreUnlimited == true and "1" or "0")
	return {
		enabled = enabled == true,
		blockedByVisibility = blockedByVisibility == true,
		alpha = alpha,
		ignoreUnlimited = ignoreUnlimited == true,
		spellList = spellList,
		spellListKey = spellListKey,
		configKey = configKey,
	}
end

local function syncTargetRangeFadeConfig(cfg, def)
	local st = states[UNIT.TARGET]
	if not st then
		st = {}
		states[UNIT.TARGET] = st
	end
	local snapshot = UF.BuildTargetRangeFadeSnapshot(cfg or st.cfg or ensureDB(UNIT.TARGET), def)
	local configChanged = st._rangeFadeConfigKey ~= snapshot.configKey
	local spellListChanged = st._rangeFadeSpellListKey ~= snapshot.spellListKey
	st._rangeFadeEnabledCfg = snapshot.enabled
	st._rangeFadeBlockedByVisibility = snapshot.blockedByVisibility
	st._rangeFadeAlphaCfg = snapshot.alpha
	st._rangeFadeIgnoreUnlimited = snapshot.ignoreUnlimited
	st._rangeFadeSpellListCfg = snapshot.spellList
	st._rangeFadeConfigKey = snapshot.configKey
	st._rangeFadeSpellListKey = snapshot.spellListKey
	return configChanged, spellListChanged
end

if UFHelper and UFHelper.RangeFadeRegister then
	UFHelper.RangeFadeRegister(function()
		local st = states[UNIT.TARGET]
		if not st then return false, 0.5, true end
		local enabled = st._rangeFadeEnabledCfg == true
		if addon.EditModeLib and addon.EditModeLib:IsInEditMode() then enabled = false end
		if st._rangeFadeBlockedByVisibility then enabled = false end
		local alpha = st._rangeFadeAlphaCfg
		if type(alpha) ~= "number" then alpha = 0.5 end
		local ignoreUnlimited = st._rangeFadeIgnoreUnlimited
		if ignoreUnlimited == nil then ignoreUnlimited = true end
		return enabled, alpha, ignoreUnlimited
	end, function(targetAlpha, force)
		local st = states[UNIT.TARGET]
		if not st or not st.frame or not st.frame.SetAlpha then return end
		if st._rangeFadeBlockedByVisibility then
			st._rangeFadeAlpha = nil
			return
		end
		if force or st._rangeFadeAlpha ~= targetAlpha then
			st._rangeFadeAlpha = targetAlpha
			st.frame:SetAlpha(targetAlpha)
		end
	end, function()
		local st = states[UNIT.TARGET]
		if not st then return nil end
		return st._rangeFadeSpellListCfg
	end)
end

function UF.RefreshRangeFadeSpellsNow(rebuildSpellList)
	if not UFHelper then return end
	local configChanged, spellListChanged = syncTargetRangeFadeConfig(ensureDB(UNIT.TARGET), defaultsFor(UNIT.TARGET))
	local wantsSpellListRefresh = rebuildSpellList == true or spellListChanged == true
	if not configChanged and not wantsSpellListRefresh then return false end
	if configChanged and UFHelper.RangeFadeMarkConfigDirty then UFHelper.RangeFadeMarkConfigDirty() end
	if wantsSpellListRefresh and UFHelper.RangeFadeMarkSpellListDirty then UFHelper.RangeFadeMarkSpellListDirty() end
	if UFHelper.RangeFadeUpdateSpells then UFHelper.RangeFadeUpdateSpells() end
	return true
end

function UF.ScheduleRangeFadeRefresh(rebuildSpellList)
	if not UFHelper then return end
	if rebuildSpellList == true then UF._rangeFadeRefreshNeedsSpellList = true end
	if UF._rangeFadeRefreshScheduled then return end
	UF._rangeFadeRefreshScheduled = true
	local function run()
		UF._rangeFadeRefreshScheduled = nil
		local wantsSpellListRefresh = UF._rangeFadeRefreshNeedsSpellList == true
		UF._rangeFadeRefreshNeedsSpellList = nil
		UF.RefreshRangeFadeSpellsNow(wantsSpellListRefresh)
	end
	RunNextFrame(run)
end

local function copySettings(fromUnit, toUnit, opts)
	opts = opts or {}
	if not fromUnit or not toUnit or fromUnit == toUnit then return false end
	local src = ensureDB(fromUnit)
	local dest = ensureDB(toUnit)
	if not src or not dest then return false end
	local function cloneSettingValue(value)
		if type(value) ~= "table" then return value end
		if addon.functions and addon.functions.copyTable then return addon.functions.copyTable(value) end
		if CopyTable then return CopyTable(value) end
		local out = {}
		for key, child in pairs(value) do
			out[key] = cloneSettingValue(child)
		end
		return out
	end
	local function getPathValue(root, path)
		if type(root) ~= "table" or type(path) ~= "table" then return nil, false end
		local cur = root
		for i = 1, #path do
			if type(cur) ~= "table" then return nil, false end
			cur = cur[path[i]]
			if cur == nil then return nil, false end
		end
		return cur, true
	end
	local function clearPathValue(root, path)
		if type(root) ~= "table" or type(path) ~= "table" or #path == 0 then return end
		if #path == 1 then
			root[path[1]] = nil
			return
		end
		local cur = root
		local trail = {}
		for i = 1, #path - 1 do
			local key = path[i]
			local nxt = cur[key]
			if type(nxt) ~= "table" then return end
			trail[#trail + 1] = { parent = cur, key = key }
			cur = nxt
		end
		cur[path[#path]] = nil
		for i = #trail, 1, -1 do
			local node = trail[i]
			local child = node.parent[node.key]
			if type(child) == "table" and not next(child) then
				node.parent[node.key] = nil
			else
				break
			end
		end
	end
	local function setPathValue(root, path, value)
		if type(root) ~= "table" or type(path) ~= "table" or #path == 0 then return end
		if value == nil then
			clearPathValue(root, path)
			return
		end
		local cur = root
		for i = 1, #path - 1 do
			local key = path[i]
			if type(cur[key]) ~= "table" then cur[key] = {} end
			cur = cur[key]
		end
		cur[path[#path]] = value
	end
	local function copyPathValue(path)
		local value, exists = getPathValue(src, path)
		if exists then
			setPathValue(dest, path, cloneSettingValue(value))
		else
			clearPathValue(dest, path)
		end
	end
	local copySectionRules = {
		frame = {
			{ "showTooltip" },
			{ "tooltipUseEditMode" },
			{ "hideInVehicle" },
			{ "hideInPetBattle" },
			{ "hideInClientScene" },
			{ "visibility" },
			{ "visibilityFadeStrength" },
			{ "width" },
			{ "anchor" },
			{ "strata" },
			{ "frameLevel" },
			{ "smoothFill" },
			{ "power", "detachedStrata" },
			{ "power", "detachedFrameLevelOffset" },
			{ "secondaryPower", "detachedStrata" },
			{ "secondaryPower", "detachedFrameLevelOffset" },
		},
		layout = {
			{ "spacing" },
			{ "growth" },
		},
		border = {
			{ "border" },
		},
		highlight = {
			{ "highlight" },
		},
		portrait = {
			{ "portrait" },
		},
		rangeFade = {
			{ "rangeFade" },
		},
		health = {
			{ "healthHeight" },
			{ "health" },
		},
		incomingHeal = {
			{ "health", "incomingHealEnabled" },
			{ "health", "absorbLayerOrder" },
			{ "health", "showSampleIncomingHeal" },
			{ "health", "incomingHealTexture" },
			{ "health", "incomingHealColor" },
		},
		absorb = {
			{ "health", "absorbColor" },
			{ "health", "absorbUseCustomColor" },
			{ "health", "useAbsorbGlow" },
			{ "health", "absorbReverseFill" },
			{ "health", "absorbDontOverflowHealthBar" },
			{ "health", "absorbOverlayHeight" },
			{ "health", "absorbOverlayAnchorTop" },
			{ "health", "absorbTexture" },
		},
		healAbsorb = {
			{ "health", "healAbsorbColor" },
			{ "health", "healAbsorbUseCustomColor" },
			{ "health", "healAbsorbReverseFill" },
			{ "health", "healAbsorbOverlayHeight" },
			{ "health", "healAbsorbOverlayAnchorTop" },
			{ "health", "healAbsorbTexture" },
		},
		power = {
			{ "powerHeight" },
			{ "power" },
			{ "secondaryPowerHeight" },
			{ "secondaryPower" },
			{ "border", "detachedSecondaryPower" },
			{ "border", "detachedSecondaryPowerTexture" },
			{ "border", "detachedSecondaryPowerSize" },
			{ "border", "detachedSecondaryPowerOffset" },
		},
		classResource = {
			{ "classResource" },
		},
		totemFrame = {
			{ "classResource", "totemFrame" },
		},
		raidicon = {
			{ "raidIcon" },
		},
		cast = {
			{ "cast" },
		},
		name = {
			{ "status", "enabled" },
			{ "status", "font" },
			{ "status", "fontOutline" },
			{ "status", "nameColorMode" },
			{ "status", "nameColor" },
			{ "status", "nameStrata" },
			{ "status", "nameFrameLevelOffset" },
			{ "status", "nameUseReactionColor" },
			{ "status", "targetTargetName" },
			{ "status", "nameAnchor" },
			{ "status", "nameOffset" },
			{ "status", "nameMaxChars" },
			{ "status", "nameFontSize" },
		},
		level = {
			{ "status", "font" },
			{ "status", "fontOutline" },
			{ "status", "levelEnabled" },
			{ "status", "hideLevelAtMax" },
			{ "status", "levelColorMode" },
			{ "status", "levelColor" },
			{ "status", "levelAnchor" },
			{ "status", "levelOffset" },
			{ "status", "levelStrata" },
			{ "status", "levelFrameLevelOffset" },
			{ "status", "levelFontSize" },
		},
		statusText = {
			{ "status", "unitStatus" },
		},
		unitStatus = {
			{ "status", "classificationIcon" },
			{ "status", "combatIndicator" },
			{ "status", "dispelTint" },
			{ "pvpIndicator" },
			{ "roleIndicator" },
			{ "leaderIcon" },
			{ "resting" },
		},
		combatFeedback = {
			{ "combatFeedback" },
		},
		buffs = {
			{ "auraIcons", "buff" },
		},
		debuffs = {
			{ "auraIcons", "debuff" },
		},
	}
	local keepAnchor = opts.keepAnchor ~= false
	local keepEnabled = opts.keepEnabled ~= false
	local anchor = keepAnchor and dest.anchor and cloneSettingValue(dest.anchor) or dest.anchor
	local enabled = keepEnabled and dest.enabled
	local copied = false
	if type(opts.sections) == "table" then
		for _, sectionId in ipairs(opts.sections) do
			local rules = copySectionRules[sectionId]
			if type(rules) == "table" then
				for _, path in ipairs(rules) do
					copyPathValue(path)
				end
				copied = true
			end
		end
	else
		if wipe then wipe(dest) end
		for k, v in pairs(src) do
			dest[k] = cloneSettingValue(v)
		end
		copied = true
	end
	if not copied then return false end
	if keepAnchor then dest.anchor = anchor end
	if keepEnabled then dest.enabled = enabled end
	return true
end

local function applyRaidIconLayout(unit, cfg)
	local st = states[unit]
	if not st or not st.raidIcon or not st.frame then return end
	local def = defaultsFor(unit)
	local rcfg = (cfg and cfg.raidIcon) or (def and def.raidIcon) or {}
	local offsetDef = def and def.raidIcon and def.raidIcon.offset or {}
	local sizeDef = def and def.raidIcon and def.raidIcon.size or 18
	local enabled = rcfg.enabled ~= false
	local size = UFHelper.clamp(rcfg.size or sizeDef or 18, 10, 30)
	local ox = (rcfg.offset and rcfg.offset.x) or offsetDef.x or 0
	local oy = (rcfg.offset and rcfg.offset.y) or offsetDef.y or -2
	local centerOffset = (st and st._portraitCenterOffset) or 0
	local statusOffsetY = UF.GetStatusVisualOffsetY and UF.GetStatusVisualOffsetY("TOP", st.status and st.status:GetHeight(), st._statusLayoutHeight) or 0
	st.raidIcon:ClearAllPoints()
	st.raidIcon:SetSize(size, size)
	st.raidIcon:SetPoint("TOP", st.frame, "TOP", (ox or 0) + centerOffset, oy + statusOffsetY)
	if not enabled then st.raidIcon:Hide() end
end

function UF.HardHideBlizzFrameObject(frame)
	if not frame or frame._eqolUFHidden then return end

	local function enforceHidden(target)
		if not target then return end
		local canHide = true
		if InCombatLockdown and InCombatLockdown() then
			if target.IsProtected and target:IsProtected() then canHide = false end
		end
		if canHide and target.Hide then
			pcall(target.Hide, target)
		elseif target.SetAlpha then
			target:SetAlpha(0)
			target._eqolAlphaHidden = true
		end
	end

	local related = {
		(frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar) or nil,
		frame.healthBar or frame.healthbar or frame.HealthBar or nil,
		frame.manabar or frame.ManaBar or nil,
		frame.castBar or frame.spellbar or nil,
		frame.petFrame or frame.PetFrame or nil,
		frame.powerBarAlt or frame.PowerBarAlt or nil,
		frame.CastingBarFrame or nil,
		frame.CcRemoverFrame or nil,
		frame.DebuffFrame or nil,
		frame.BuffFrame or frame.AurasFrame or nil,
		frame.totFrame or nil,
	}

	if frame.UnregisterAllEvents then pcall(frame.UnregisterAllEvents, frame) end
	for i = 1, #related do
		local element = related[i]
		if element and element.UnregisterAllEvents then pcall(element.UnregisterAllEvents, element) end
	end
	enforceHidden(frame)
	frame._eqolUFHidden = true
	if not UF._blizzHiddenParent then
		UF._blizzHiddenParent = CreateFrame("Frame")
		UF._blizzHiddenParent:Hide()
	end
	if frame.SetParent then pcall(frame.SetParent, frame, UF._blizzHiddenParent) end
	if not frame._eqolUFHiddenHooks then
		frame._eqolUFHiddenHooks = true
		if frame.Show then hooksecurefunc(frame, "Show", function(f) enforceHidden(f) end) end
		if frame.SetShown then hooksecurefunc(frame, "SetShown", function(f, shown)
			if shown then enforceHidden(f) end
		end) end
	end
end

local function hardHideBlizzFrame(frameName)
	local frame = frameName and _G[frameName]
	UF.HardHideBlizzFrameObject(frame)
	if frameName == BLIZZ_FRAME_NAMES.target then UF.HardHideBlizzFrameObject(_G.ComboFrame) end
	if frameName == BLIZZ_FRAME_NAMES.focus then UF.HardHideBlizzFrameObject(_G.TargetofFocusFrame) end
end

local function checkRaidTargetIcon(unitToken, st, skipLayout)
	if not st or not st.raidIcon then return end
	local cfg = st.cfg or ensureDB(unitToken)
	if not skipLayout then applyRaidIconLayout(unitToken, cfg) end
	local def = defaultsFor(unitToken)
	local rcfg = (cfg and cfg.raidIcon) or (def and def.raidIcon) or {}
	if (cfg and cfg.enabled == false) or rcfg.enabled == false then
		st.raidIcon:Hide()
		return
	end
	if addon.EditModeLib and addon.EditModeLib:IsInEditMode() then
		SetRaidTargetIconTexture(st.raidIcon, 8)
		st.raidIcon:Show()
		return
	end
	local idx = GetRaidTargetIndex(unitToken)
	if idx then
		SetRaidTargetIconTexture(st.raidIcon, idx)
		st.raidIcon:Show()
	else
		st.raidIcon:Hide()
	end
end

local function updateAllRaidTargetIcons()
	checkRaidTargetIcon(UNIT.PLAYER, states[UNIT.PLAYER])
	checkRaidTargetIcon(UNIT.TARGET, states[UNIT.TARGET])
	checkRaidTargetIcon(UNIT.TARGET_TARGET, states[UNIT.TARGET_TARGET])
	checkRaidTargetIcon(UNIT.PET, states[UNIT.PET])
	checkRaidTargetIcon(UNIT.FOCUS, states[UNIT.FOCUS])
	local bossCount = UF.GetBossFrameCount()
	for i = 1, bossCount do
		local u = "boss" .. i
		if states[u] then checkRaidTargetIcon(u, states[u]) end
	end
end

function ClassResourceUtil.getClassResourceDescriptors(classTag)
	if type(classTag) ~= "string" or classTag == "" then classTag = addon.variables and addon.variables.unitClass end
	local descriptors = classTag and classResourceFramesByClass[classTag]
	if type(descriptors) ~= "table" or #descriptors == 0 then return nil end
	return descriptors
end

function ClassResourceUtil.findClassResourceDescriptor(classTag, resourceId)
	if type(resourceId) ~= "string" or resourceId == "" then return nil end
	local descriptors = ClassResourceUtil.getClassResourceDescriptors(classTag)
	if type(descriptors) ~= "table" then return nil end
	for _, descriptor in ipairs(descriptors) do
		if descriptor and descriptor.id == resourceId then return descriptor end
		local legacyIds = descriptor and descriptor.legacyIds
		if type(legacyIds) == "table" then
			for i = 1, #legacyIds do
				if legacyIds[i] == resourceId then return descriptor end
			end
		end
	end
	return nil
end

function ClassResourceUtil.getClassResourceConfigIDs(classTag, resourceId)
	if type(classTag) ~= "string" or classTag == "" then classTag = addon.variables and addon.variables.unitClass end
	local ids = {}
	local seen = {}
	local function appendID(value)
		if type(value) ~= "string" or value == "" or seen[value] then return end
		seen[value] = true
		ids[#ids + 1] = value
	end
	local descriptor = ClassResourceUtil.findClassResourceDescriptor(classTag, resourceId)
	if descriptor then
		appendID(descriptor.id)
		if type(descriptor.legacyIds) == "table" then
			for i = 1, #descriptor.legacyIds do
				appendID(descriptor.legacyIds[i])
			end
		end
	else
		appendID(resourceId)
	end
	return ids
end

function ClassResourceUtil.MigrateLegacyConfig(cfg, classTag)
	if type(cfg) ~= "table" or type(cfg.resources) ~= "table" then return false end
	local descriptors = ClassResourceUtil.getClassResourceDescriptors(classTag)
	if type(descriptors) ~= "table" then return false end
	local migrated = false
	for _, descriptor in ipairs(descriptors) do
		local resourceId = descriptor and descriptor.id
		if type(resourceId) == "string" and resourceId ~= "" and cfg.resources[resourceId] == nil and type(descriptor.legacyIds) == "table" then
			for i = 1, #descriptor.legacyIds do
				local legacyId = descriptor.legacyIds[i]
				local legacyConfig = legacyId and cfg.resources[legacyId]
				if type(legacyConfig) == "table" then
					cfg.resources[resourceId] = copyClassResourceConfigValue(legacyConfig)
					migrated = true
					break
				end
			end
		end
	end
	return migrated
end

function ClassResourceUtil.getClassResourceOptions(classTag)
	local options = {}
	local seen = {}
	local function appendDescriptors(descriptors)
		if type(descriptors) ~= "table" then return end
		for _, descriptor in ipairs(descriptors) do
			local id = descriptor and descriptor.id
			if type(id) == "string" and id ~= "" and not seen[id] then
				seen[id] = true
				local label
				local key = descriptor.labelKey
				local localized = key and _G[key]
				if type(localized) == "string" and localized ~= "" then
					label = localized
				elseif type(descriptor.label) == "string" and descriptor.label ~= "" then
					label = descriptor.label
				else
					label = id
				end
				options[#options + 1] = {
					value = id,
					label = label,
					frameName = descriptor.frameName,
				}
			end
		end
	end
	if classTag == "ALL" then
		for _, descriptors in pairs(classResourceFramesByClass) do
			appendDescriptors(descriptors)
		end
		table.sort(options, function(a, b)
			local la = tostring(a and a.label or ""):lower()
			local lb = tostring(b and b.label or ""):lower()
			if la == lb then return tostring(a and a.value or "") < tostring(b and b.value or "") end
			return la < lb
		end)
		return options
	end
	appendDescriptors(ClassResourceUtil.getClassResourceDescriptors(classTag))
	return options
end

function ClassResourceUtil.getClassResourceFrames()
	local descriptors = ClassResourceUtil.getClassResourceDescriptors()
	if not descriptors then return nil end
	local frames = {}
	for _, descriptor in ipairs(descriptors) do
		local frameName = descriptor and descriptor.frameName
		local frame = frameName and _G[frameName]
		if frame then frames[#frames + 1] = frame end
	end
	return frames
end

function ClassResourceUtil.storeClassResourceDefaults(frame)
	if not frame or classResourceOriginalLayouts[frame] then return end
	local info = {
		parent = frame:GetParent(),
		scale = frame:GetScale(),
		strata = frame:GetFrameStrata(),
		level = frame:GetFrameLevel(),
		ignoreFramePositionManager = frame.ignoreFramePositionManager,
		points = {},
	}
	for i = 1, frame:GetNumPoints() do
		local point, rel, relPoint, x, y = frame:GetPoint(i)
		info.points[#info.points + 1] = { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
	end
	classResourceOriginalLayouts[frame] = info
end

function ClassResourceUtil.restoreClassResourceFrame(frame)
	if not frame then return end
	local info = classResourceOriginalLayouts[frame]
	classResourceManagedFrames[frame] = nil
	if ClassResourceUtil._frameLevelMinimums then ClassResourceUtil._frameLevelMinimums[frame] = nil end
	if not info then return end
	if frame.SetParent and info.parent then frame:SetParent(info.parent) end
	frame:ClearAllPoints()
	if info.points and #info.points > 0 then
		for _, pt in ipairs(info.points) do
			frame:SetPoint(pt.point, pt.relativeTo, pt.relativePoint, pt.x or 0, pt.y or 0)
		end
	end
	if info.scale and frame.SetScale then frame:SetScale(info.scale) end
	if info.strata and frame.SetFrameStrata then frame:SetFrameStrata(info.strata) end
	if info.level and frame.SetFrameLevel then frame:SetFrameLevel(info.level) end
	if info.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = info.ignoreFramePositionManager end
end

function ClassResourceUtil.restoreClassResourceFrames()
	for frame in pairs(classResourceManagedFrames) do
		ClassResourceUtil.restoreClassResourceFrame(frame)
	end
end

function ClassResourceUtil.onClassResourceShow()
	if ClassResourceUtil.ApplyLayout then ClassResourceUtil.ApplyLayout(states[UNIT.PLAYER] and states[UNIT.PLAYER].cfg or ensureDB(UNIT.PLAYER)) end
end

function ClassResourceUtil.SetFrameLevelHookOffset(offset)
	offset = tonumber(offset) or 0
	if offset < 0 then offset = 0 end
	ClassResourceUtil._frameLevelMinimum = 7 + offset
end

function ClassResourceUtil.SetFrameLevelHookMinimum(frame, level)
	if not frame then return end
	level = tonumber(level) or 7
	if level < 0 then level = 0 end
	ClassResourceUtil._frameLevelMinimums = ClassResourceUtil._frameLevelMinimums or {}
	ClassResourceUtil._frameLevelMinimums[frame] = level
end

function ClassResourceUtil.hookClassResourceFrame(frame)
	if not frame or classResourceHooks[frame] then return end
	classResourceHooks[frame] = true
	frame:HookScript("OnShow", ClassResourceUtil.onClassResourceShow)
	if hooksecurefunc and frame.SetFrameLevel then
		hooksecurefunc(frame, "SetFrameLevel", function(self)
			if not classResourceManagedFrames[self] then return end
			if self._eqolClassResourceLevelHook then return end
			local minimums = ClassResourceUtil._frameLevelMinimums
			local minLevel = (minimums and minimums[self]) or ClassResourceUtil._frameLevelMinimum or 7
			if self:GetFrameLevel() >= minLevel then return end
			self._eqolClassResourceLevelHook = true
			self:SetFrameLevel(minLevel)
			self._eqolClassResourceLevelHook = nil
		end)
	end
end

function ClassResourceUtil.GetNestedConfigValue(root, path)
	local cur = root
	if type(cur) ~= "table" then return nil end
	for i = 1, #path do
		if type(cur) ~= "table" then return nil end
		cur = cur[path[i]]
		if cur == nil then return nil end
	end
	return cur
end

function ClassResourceUtil.ResolveClassResourceConfigValue(cfg, def, resourceId, path, fallback)
	local resourceIDs = ClassResourceUtil.getClassResourceConfigIDs(nil, resourceId)
	for i = 1, #resourceIDs do
		local resourceCfg = type(cfg) == "table" and type(cfg.resources) == "table" and cfg.resources[resourceIDs[i]] or nil
		local value = ClassResourceUtil.GetNestedConfigValue(resourceCfg, path)
		if value ~= nil then return value end
	end
	local value = nil
	value = ClassResourceUtil.GetNestedConfigValue(cfg, path)
	if value ~= nil then return value end
	for i = 1, #resourceIDs do
		local resourceDef = type(def) == "table" and type(def.resources) == "table" and def.resources[resourceIDs[i]] or nil
		value = ClassResourceUtil.GetNestedConfigValue(resourceDef, path)
		if value ~= nil then return value end
	end
	value = ClassResourceUtil.GetNestedConfigValue(def, path)
	if value ~= nil then return value end
	return fallback
end

ClassResourceUtil.ApplyLayout = function(cfg)
	local classKey = addon.variables and addon.variables.unitClass
	local descriptors = classKey and ClassResourceUtil.getClassResourceDescriptors(classKey)
	if not descriptors or #descriptors == 0 then
		ClassResourceUtil.restoreClassResourceFrames()
		return
	end
	local st = states[UNIT.PLAYER]
	if not st or not st.frame then return end
	local def = defaultsFor(UNIT.PLAYER)
	local rcfg = (cfg and cfg.classResource) or {}
	local resourceDef = (def and def.classResource) or {}
	if rcfg.enabled == false then
		ClassResourceUtil.restoreClassResourceFrames()
		return
	end
	if InCombatLockdown and InCombatLockdown() then return end
	local activeFrames = {}
	for _, descriptor in ipairs(descriptors) do
		local resourceID = descriptor and descriptor.id
		local frameName = descriptor and descriptor.frameName
		local frame = frameName and _G[frameName]
		if frame and type(resourceID) == "string" and resourceID ~= "" then
			activeFrames[frame] = true
			ClassResourceUtil.storeClassResourceDefaults(frame)
			ClassResourceUtil.hookClassResourceFrame(frame)
			local enabled = ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "enabled" }, true) ~= false
			if enabled then
				local anchor = ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "anchor" }, "TOP")
				local offsetX = tonumber(ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "offset", "x" }, 0)) or 0
				local offsetY = ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "offset", "y" }, nil)
				if offsetY == nil then offsetY = anchor == "TOP" and -5 or 5 end
				offsetY = tonumber(offsetY) or 0
				local scale = tonumber(ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "scale" }, 1)) or 1
				local resourceStrata = ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "strata" }, nil)
				if type(resourceStrata) == "string" and resourceStrata ~= "" then
					resourceStrata = string.upper(resourceStrata)
				else
					resourceStrata = nil
				end
				local frameLevelOffset = tonumber(ClassResourceUtil.ResolveClassResourceConfigValue(rcfg, resourceDef, resourceID, { "frameLevelOffset" }, 5)) or 5
				if frameLevelOffset < 0 then frameLevelOffset = 0 end
				local minLevel = max(0, (st.frame.GetFrameLevel and st.frame:GetFrameLevel() or 0) + frameLevelOffset)
				if ClassResourceUtil.SetFrameLevelHookMinimum then
					ClassResourceUtil.SetFrameLevelHookMinimum(frame, minLevel)
				elseif ClassResourceUtil.SetFrameLevelHookOffset then
					ClassResourceUtil.SetFrameLevelHookOffset(frameLevelOffset)
				end
				classResourceManagedFrames[frame] = true
				frame.ignoreFramePositionManager = true
				frame:ClearAllPoints()
				frame:SetPoint(anchor, st.frame, anchor, offsetX, offsetY + UF.GetVirtualUnitFramePointOffsetY(st.frame, anchor))
				frame:SetParent(st.frame)
				if frame.SetScale then frame:SetScale(scale) end
				if frame.SetFrameStrata and st.frame.GetFrameStrata then frame:SetFrameStrata(resourceStrata or st.frame:GetFrameStrata()) end
				if frame.SetFrameLevel then frame:SetFrameLevel(minLevel) end
				local manageVisibility = frame._eqolManageVisibility == true or type(frame.eqolShouldShowClassResource) == "function"
				if manageVisibility then
					local shouldShow = true
					if type(frame.eqolShouldShowClassResource) == "function" then
						local ok, result = pcall(frame.eqolShouldShowClassResource, frame)
						if ok and result == false then shouldShow = false end
					end
					if shouldShow then
						if frame.Show and frame.IsShown and not frame:IsShown() then frame:Show() end
					elseif frame.Hide then
						frame:Hide()
					end
				end
			else
				ClassResourceUtil.restoreClassResourceFrame(frame)
				if frame.Hide then frame:Hide() end
			end
		end
	end
	for frame in pairs(classResourceManagedFrames) do
		if not activeFrames[frame] then ClassResourceUtil.restoreClassResourceFrame(frame) end
	end
end

function TotemFrameUtil.storeTotemFrameDefaults(frame)
	if not frame or TotemFrameUtil._originalLayout then return end
	local info = {
		parent = frame:GetParent(),
		scale = frame:GetScale(),
		strata = frame:GetFrameStrata(),
		level = frame:GetFrameLevel(),
		ignoreFramePositionManager = frame.ignoreFramePositionManager,
		points = {},
	}
	for i = 1, frame:GetNumPoints() do
		local point, rel, relPoint, x, y = frame:GetPoint(i)
		info.points[#info.points + 1] = { point = point, relativeTo = rel, relativePoint = relPoint, x = x, y = y }
	end
	TotemFrameUtil._originalLayout = info
end

local function normalizeTotemFrameConfig(value)
	if value == true then return { enabled = true } end
	if type(value) == "table" then return value end
	return {}
end

function TotemFrameUtil.ensureSampleFrame(parent)
	local sampleFrame = TotemFrameUtil._sampleFrame
	if not sampleFrame then
		sampleFrame = CreateFrame("Frame", nil, parent)
		sampleFrame.ignoreFramePositionManager = true
		sampleFrame._eqolManageVisibility = true
		sampleFrame:SetSize(37, 37)
		sampleFrame:EnableMouse(false)
		TotemFrameUtil._sampleFrame = sampleFrame
	end
	if parent and sampleFrame:GetParent() ~= parent then sampleFrame:SetParent(parent) end
	return sampleFrame
end

function TotemFrameUtil.hideSampleFrame()
	local sampleFrame = TotemFrameUtil._sampleFrame
	if not sampleFrame then return end
	if sampleFrame._eqolSampleButton then sampleFrame._eqolSampleButton:Hide() end
	sampleFrame:Hide()
end

function TotemFrameUtil.syncSampleFrame(sampleFrame, totemFrame, fallbackParent)
	if not sampleFrame or not totemFrame then return end
	sampleFrame:ClearAllPoints()
	local numPoints = totemFrame.GetNumPoints and totemFrame:GetNumPoints() or 0
	if numPoints > 0 then
		for i = 1, numPoints do
			sampleFrame:SetPoint(totemFrame:GetPoint(i))
		end
	elseif fallbackParent then
		sampleFrame:SetPoint("TOPRIGHT", fallbackParent, "BOTTOMRIGHT", 0, 0)
	end
	if sampleFrame.SetScale and totemFrame.GetScale then sampleFrame:SetScale(totemFrame:GetScale()) end
	if sampleFrame.SetFrameStrata and totemFrame.GetFrameStrata then sampleFrame:SetFrameStrata(totemFrame:GetFrameStrata()) end
	if sampleFrame.SetFrameLevel and totemFrame.GetFrameLevel then sampleFrame:SetFrameLevel(totemFrame:GetFrameLevel()) end
end

function TotemFrameUtil.restoreTotemFrame()
	TotemFrameUtil.hideSampleFrame()
	if not TotemFrameUtil._managed then return end
	local frame = _G.TotemFrame
	if not frame then return end
	local info = TotemFrameUtil._originalLayout
	TotemFrameUtil._managed = nil
	if not info then return end
	if frame._eqolSampleButton then frame._eqolSampleButton:Hide() end
	if frame.SetParent and info.parent then frame:SetParent(info.parent) end
	frame:ClearAllPoints()
	if info.points and #info.points > 0 then
		for _, pt in ipairs(info.points) do
			frame:SetPoint(pt.point, pt.relativeTo, pt.relativePoint, pt.x or 0, pt.y or 0)
		end
	end
	if info.scale and frame.SetScale then frame:SetScale(info.scale) end
	if info.strata and frame.SetFrameStrata then frame:SetFrameStrata(info.strata) end
	if info.level and frame.SetFrameLevel then frame:SetFrameLevel(info.level) end
	if info.ignoreFramePositionManager ~= nil then frame.ignoreFramePositionManager = info.ignoreFramePositionManager end
end

function TotemFrameUtil.onTotemFrameShow()
	if TotemFrameUtil.ApplyLayout then TotemFrameUtil.ApplyLayout(states[UNIT.PLAYER] and states[UNIT.PLAYER].cfg or ensureDB(UNIT.PLAYER)) end
end

function TotemFrameUtil.hookTotemFrame(frame)
	if not frame or TotemFrameUtil._hooked then return end
	TotemFrameUtil._hooked = true
	frame:HookScript("OnShow", TotemFrameUtil.onTotemFrameShow)
	if hooksecurefunc and frame.SetFrameLevel then hooksecurefunc(frame, "SetFrameLevel", function(self)
		if frame:GetFrameLevel() < 7 then frame:SetFrameLevel(7) end
	end) end
end

function TotemFrameUtil.updateSample(frame, shouldShow, activeRefFrame)
	if not frame then return end
	local manageVisibility = frame._eqolManageVisibility == true
	local refFrame = activeRefFrame or frame
	if not shouldShow then
		if frame._eqolSampleButton then frame._eqolSampleButton:Hide() end
		if manageVisibility and frame.Hide then frame:Hide() end
		return
	end
	if refFrame and refFrame.activeTotems and refFrame.activeTotems > 0 then
		if frame._eqolSampleButton then frame._eqolSampleButton:Hide() end
		if manageVisibility and frame.Hide then frame:Hide() end
		return
	end
	local button = frame._eqolSampleButton
	if not button then
		button = CreateFrame("Button", nil, frame, "TotemButtonTemplate")
		frame._eqolSampleButton = button
		button:SetAllPoints(frame)
	end
	button.layoutIndex = 1
	button.slot = 0
	if button.Icon and button.Icon.Texture then
		button.Icon.Texture:SetTexture(136099)
		button.Icon.Texture:Show()
	end
	if button.Icon and button.Icon.Cooldown then button.Icon.Cooldown:Hide() end
	if button.Duration then
		button.Duration:SetText("")
		button.Duration:Hide()
	end
	button:SetScript("OnUpdate", nil)
	button:EnableMouse(false)
	button:Show()
	if manageVisibility and frame.Show then frame:Show() end
	if frame.Layout then frame:Layout() end
end

TotemFrameUtil.ApplyLayout = function(cfg)
	local frame = _G.TotemFrame
	if not frame then
		TotemFrameUtil.hideSampleFrame()
		TotemFrameUtil.restoreTotemFrame()
		return
	end
	local classKey = addon.variables and addon.variables.unitClass
	if not classKey or not totemFrameClasses[classKey] then
		TotemFrameUtil.hideSampleFrame()
		TotemFrameUtil.restoreTotemFrame()
		return
	end
	local st = states[UNIT.PLAYER]
	if not st or not st.frame then
		TotemFrameUtil.hideSampleFrame()
		return
	end
	local def = defaultsFor(UNIT.PLAYER)
	local rcfg = (cfg and cfg.classResource) or (def and def.classResource) or {}
	local tcfg = normalizeTotemFrameConfig(rcfg.totemFrame)
	local tdef = normalizeTotemFrameConfig(def and def.classResource and def.classResource.totemFrame)
	local enabled = tcfg.enabled
	if enabled == nil then enabled = tdef.enabled end
	if enabled ~= true then
		TotemFrameUtil.hideSampleFrame()
		TotemFrameUtil.restoreTotemFrame()
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		TotemFrameUtil.hideSampleFrame()
		return
	end

	TotemFrameUtil.storeTotemFrameDefaults(frame)
	TotemFrameUtil.hookTotemFrame(frame)
	TotemFrameUtil._managed = true
	frame.ignoreFramePositionManager = true
	frame:ClearAllPoints()
	local anchor = tcfg.anchor or tdef.anchor
	local offsetX = (tcfg.offset and tcfg.offset.x)
	if offsetX == nil then offsetX = (tdef.offset and tdef.offset.x) end
	if offsetX == nil then offsetX = 0 end
	local offsetY = (tcfg.offset and tcfg.offset.y)
	if offsetY == nil then offsetY = (tdef.offset and tdef.offset.y) end
	if offsetY == nil then offsetY = 0 end
	if anchor then
		local info = TotemFrameUtil._originalLayout
		local selfPoint = (info and info.points and info.points[1] and info.points[1].point) or anchor
		frame:SetPoint(selfPoint, st.frame, anchor, offsetX, offsetY + UF.GetVirtualUnitFramePointOffsetY(st.frame, anchor))
	else
		local info = TotemFrameUtil._originalLayout
		if info and info.points and #info.points > 0 then
			for _, pt in ipairs(info.points) do
				local rel = pt.relativeTo
				if rel == info.parent or rel == _G.PlayerFrame then rel = st.frame end
				local pointOffsetY = rel == st.frame and UF.GetVirtualUnitFramePointOffsetY(st.frame, pt.relativePoint or pt.point) or 0
				frame:SetPoint(pt.point, rel, pt.relativePoint, pt.x or 0, (pt.y or 0) + pointOffsetY)
			end
		else
			frame:SetPoint("TOPRIGHT", st.frame, "BOTTOMRIGHT", offsetX, offsetY + UF.GetVirtualUnitFramePointOffsetY(st.frame, "BOTTOMRIGHT"))
		end
	end
	frame:SetParent(st.frame)
	local scale = tcfg.scale
	if scale == nil then scale = tdef.scale end
	if scale == nil then scale = (TotemFrameUtil._originalLayout and TotemFrameUtil._originalLayout.scale) end
	if scale == nil then scale = 1 end
	if frame.SetScale then frame:SetScale(scale) end
	if frame.SetFrameStrata and st.frame.GetFrameStrata then frame:SetFrameStrata(st.frame:GetFrameStrata()) end
	if frame.SetFrameLevel and st.frame.GetFrameLevel then frame:SetFrameLevel((st.frame:GetFrameLevel() or 0) + 5) end
	local inEditMode = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	local showSample = tcfg.showSample
	if showSample == nil then showSample = tdef.showSample end
	showSample = inEditMode and showSample == true
	if frame._eqolSampleButton then frame._eqolSampleButton:Hide() end
	if showSample then
		local sampleFrame = TotemFrameUtil.ensureSampleFrame(st.frame)
		TotemFrameUtil.syncSampleFrame(sampleFrame, frame, st.frame)
		TotemFrameUtil.updateSample(sampleFrame, true, frame)
	else
		TotemFrameUtil.hideSampleFrame()
	end
end

local function resolveProfileDB(profileName)
	if UFProfileManager and UFProfileManager.MaybeInitialize then UFProfileManager.MaybeInitialize() end
	if type(profileName) == "string" and profileName ~= "" then
		local profiles = EnhanceQoLDB and EnhanceQoLDB.profiles
		if type(profiles) ~= "table" then return nil, true end
		return profiles[profileName], true
	end
	addon.db = addon.db or {}
	return addon.db, false
end

local UF_EDITMODE_FRAME_IDS = {
	player = "EQOL_UF_Player",
	target = "EQOL_UF_Target",
	targettarget = "EQOL_UF_ToT",
	focus = "EQOL_UF_Focus",
	pet = "EQOL_UF_Pet",
	boss = "EQOL_UF_Boss",
}

function UF.SyncEditModeLayoutAnchors(units)
	if type(units) ~= "table" or #units == 0 then return end
	local editMode = addon and addon.EditMode
	if not (editMode and editMode.EnsureLayoutData) then return end

	for _, unit in ipairs(units) do
		local frameId = UF_EDITMODE_FRAME_IDS[unit]
		if frameId then
			local cfg = ensureDB(unit)
			local anchor = cfg and cfg.anchor
			if anchor then
				local def = defaultsFor(unit)
				local showStatus = unit ~= "boss" and UF.ShouldShowStatusLayout and UF.ShouldShowStatusLayout(cfg, unit, def)
				local statusHeightDelta = unit ~= "boss" and UF.GetStatusHeightDelta and UF.GetStatusHeightDelta(showStatus) or 0
				local relativeName = anchor.relativeTo or anchor.relativeFrame
				local rel = resolveRelativeAnchorFrame(relativeName, RelativeAnchor.GetFrameNameForKey(unit))
				local point = anchor.point or "CENTER"
				local relativePoint = anchor.relativePoint or point
				local data = editMode:EnsureLayoutData(frameId)
				if type(data) == "table" then
					data.point = point
					data.relativePoint = relativePoint
					data.x = anchor.x or 0
					data.y = UF.ResolvePhysicalUnitFrameAnchorY(point, relativePoint, anchor.y, rel, statusHeightDelta)
				end
			end
		end
	end
end

function UF.ExportProfile(scopeKey, profileName)
	local function normalize(key)
		if not key or key == "" then return "ALL" end
		if key == "ALL" then return "ALL" end
		if isBossUnit(key) then return "boss" end
		return key
	end
	local function isGroupScopeKey(key) return key == "party" or key == "raid" or key == "mt" or key == "ma" end
	local function hasExportableEntries(tbl)
		if type(tbl) ~= "table" then return false end
		for _, value in pairs(tbl) do
			if type(value) == "table" then return true end
		end
		return false
	end
	scopeKey = normalize(scopeKey)
	local db, externalProfile = resolveProfileDB(profileName)
	if type(db) ~= "table" then return nil, "NO_DATA" end
	local frameCfg = db.ufFrames
	if not frameCfg and not externalProfile then
		db.ufFrames = {}
		frameCfg = db.ufFrames
	end
	local groupCfg = db.ufGroupFrames

	local payload = {
		kind = UF_PROFILE_SHARE_KIND,
		version = 3,
		frames = {},
		groupFrames = {},
	}

	if scopeKey == "ALL" then
		local hasUnitFrames = hasExportableEntries(frameCfg)
		local hasGroupFrames = hasExportableEntries(groupCfg)
		if not hasUnitFrames and not hasGroupFrames then return nil, "EMPTY" end
		if hasUnitFrames then payload.frames = CopyTable(frameCfg) end
		if hasGroupFrames then payload.groupFrames = CopyTable(groupCfg) end
		local guid = UFProfileManager and UFProfileManager._getCurrentPlayerGUID and UFProfileManager._getCurrentPlayerGUID()
		local specMappings = guid and db.ufProfileSpecKeys and db.ufProfileSpecKeys[guid]
		if type(specMappings) == "table" then
			local exportedMappings = {}
			for specKey, mappedProfile in pairs(specMappings) do
				local specID = tonumber(specKey)
				if specID and specID > 0 and type(mappedProfile) == "string" and mappedProfile ~= "" then exportedMappings[specID] = mappedProfile end
			end
			if next(exportedMappings) then payload.specMappings = exportedMappings end
		end
	elseif isGroupScopeKey(scopeKey) then
		local src = type(groupCfg) == "table" and groupCfg[scopeKey] or nil
		if type(src) ~= "table" then return nil, "SCOPE_EMPTY" end
		payload.groupFrames[scopeKey] = CopyTable(src)
	else
		local src = type(frameCfg) == "table" and frameCfg[scopeKey] or nil
		if type(frameCfg) ~= "table" and externalProfile then return nil, "NO_DATA" end
		if type(src) ~= "table" then return nil, "SCOPE_EMPTY" end
		payload.frames[scopeKey] = CopyTable(src)
	end

	local serializer = LibStub("AceSerializer-3.0")
	local deflate = LibStub("LibDeflate")
	local serialized = serializer:Serialize(payload)
	local compressed = deflate:CompressDeflate(serialized)
	return deflate:EncodeForPrint(compressed)
end

function UF.ImportProfile(encoded, scopeKey)
	local function normalize(key)
		if not key or key == "" then return "ALL" end
		if key == "ALL" then return "ALL" end
		if isBossUnit(key) then return "boss" end
		return key
	end
	local function isGroupScopeKey(key) return key == "party" or key == "raid" or key == "mt" or key == "ma" end
	scopeKey = normalize(scopeKey)
	encoded = UFHelper.trim(encoded or "")
	if not encoded or encoded == "" then return false, "NO_INPUT" end

	local deflate = LibStub("LibDeflate")
	local serializer = LibStub("AceSerializer-3.0")
	local decoded = deflate:DecodeForPrint(encoded) or deflate:DecodeForWoWChatChannel(encoded) or deflate:DecodeForWoWAddonChannel(encoded)
	if not decoded then return false, "DECODE" end
	local decompressed = deflate:DecompressDeflate(decoded)
	if not decompressed then return false, "DECOMPRESS" end
	local ok, data = serializer:Deserialize(decompressed)
	if not ok or type(data) ~= "table" then return false, "DESERIALIZE" end

	if data.kind ~= UF_PROFILE_SHARE_KIND then return false, "WRONG_KIND" end
	local sourceFrames = type(data.frames) == "table" and data.frames or nil
	local sourceGroupFrames = type(data.groupFrames) == "table" and data.groupFrames or nil
	local sourceSpecMappings = type(data.specMappings) == "table" and data.specMappings or nil
	if not sourceFrames and not sourceGroupFrames then return false, "NO_FRAMES" end

	addon.db = addon.db or {}
	addon.db.ufFrames = addon.db.ufFrames or {}
	addon.db.ufGroupFrames = addon.db.ufGroupFrames or {}
	local targetFrames = addon.db.ufFrames
	local targetGroupFrames = addon.db.ufGroupFrames
	local applied = {}
	local appliedSet = {}
	local function markApplied(key)
		if not appliedSet[key] then
			appliedSet[key] = true
			applied[#applied + 1] = key
		end
	end
	local function applyFrameConfig(key, frameCfg)
		if isGroupScopeKey(key) then
			targetGroupFrames[key] = CopyTable(frameCfg)
		else
			targetFrames[key] = CopyTable(frameCfg)
		end
		markApplied(key)
	end

	if scopeKey == "ALL" then
		for unit, frameCfg in pairs(sourceFrames or {}) do
			if type(frameCfg) == "table" then
				local key = normalize(unit)
				applyFrameConfig(key, frameCfg)
			end
		end
		for unit, frameCfg in pairs(sourceGroupFrames or {}) do
			if type(frameCfg) == "table" then
				local key = normalize(unit)
				applyFrameConfig(key, frameCfg)
			end
		end
		if #applied == 0 then return false, "NO_FRAMES" end
		if sourceSpecMappings and UFProfileManager and UFProfileManager.SetSpecMapping then
			for specKey, mappedProfile in pairs(sourceSpecMappings) do
				local specID = tonumber(specKey)
				if specID and specID > 0 and type(mappedProfile) == "string" and mappedProfile ~= "" then UFProfileManager.SetSpecMapping(specID, mappedProfile) end
			end
		end
	else
		local key = scopeKey
		local source
		if isGroupScopeKey(key) then
			source = (sourceGroupFrames and sourceGroupFrames[key]) or (sourceFrames and (sourceFrames[key] or sourceFrames[normalize(key)]))
		else
			source = sourceFrames and (sourceFrames[key] or sourceFrames[normalize(key)])
			if not source and isBossUnit(key) and sourceFrames then source = sourceFrames["boss1"] or sourceFrames["boss"] end
		end
		if type(source) ~= "table" then return false, "SCOPE_MISSING" end
		applyFrameConfig(key, source)
	end

	table.sort(applied, function(a, b) return tostring(a) < tostring(b) end)
	if UFProfileManager and UFProfileManager._markUFProfilesDirty then UFProfileManager._markUFProfilesDirty() end
	UF.SyncEditModeLayoutAnchors(applied)
	addon.variables.requireReload = true
	return true, applied
end

function UF.ExportErrorMessage(reason)
	if reason == "NO_DATA" or reason == "EMPTY" then return L["UFExportProfileEmpty"] or "No unit frame settings to export." end
	if reason == "SCOPE_EMPTY" then return L["UFExportProfileScopeEmpty"] or "No saved settings for that frame yet." end
	return L["UFExportProfileFailed"] or "Could not create a Unit Frame export code."
end

function UF.ImportErrorMessage(reason)
	if reason == "NO_INPUT" then return L["Please enter a code to import."] or "Please enter a code to import." end
	if reason == "DECODE" or reason == "DECOMPRESS" or reason == "DESERIALIZE" or reason == "WRONG_KIND" then return L["The code could not be read."] or "The code could not be read." end
	if reason == "NO_FRAMES" then return L["UFImportProfileNoFrames"] or "The code does not contain any Unit Frame settings." end
	if reason == "SCOPE_MISSING" then return L["UFImportProfileMissingScope"] or "The code does not contain settings for that frame." end
	return L["UFImportProfileFailed"] or "Could not import the Unit Frame profile."
end

local function anchorBossContainer(cfg)
	if not bossContainer then return end
	if InCombatLockdown() then
		bossLayoutDirty = true
		return
	end
	cfg = cfg or ensureDB("boss")
	local def = defaultsFor("boss")
	local anchor = (cfg and cfg.anchor) or (def and def.anchor) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
	local dynamicWinner = UF.GetDynamicAnchorWinner("boss", bossContainer)
	local placement = dynamicWinner and dynamicWinner.placement or anchor
	local point = placement.point or "CENTER"
	local relativePoint = placement.relativePoint or point
	local relativeFrame = dynamicWinner and dynamicWinner.frame or resolveRelativeAnchorFrame(anchor.relativeTo or anchor.relativeFrame, RelativeAnchor.bossFrameName)
	bossContainer:ClearAllPoints()
	bossContainer:SetPoint(
		point,
		relativeFrame,
		relativePoint,
		placement.x or 0,
		dynamicWinner and (placement.y or 0) or UF.ResolvePhysicalUnitFrameAnchorY(point, relativePoint, anchor.y, relativeFrame, 0)
	)
	bossContainer._eqolDynamicAnchorWinner = dynamicWinner and dynamicWinner.targetId or nil
end

local function ensureBossContainer()
	if bossContainer then return bossContainer end
	bossContainer = CreateFrame("Frame", "EQOLUFBossContainer", UIParent, "BackdropTemplate")
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	if tonumber((select(4, GetBuildInfo()))) >= 120100 and type(bossContainer.SetRolesets) == "function" then bossContainer:SetRolesets("unitFrames") end
	bossContainer:SetSize(220, 200)
	bossContainer:SetClampedToScreen(true)
	bossContainer:SetMovable(true)
	bossContainer:RegisterForDrag("LeftButton")
	bossContainer:Hide()
	anchorBossContainer()
	return bossContainer
end

function AuraUtil.cacheTargetAura(aura, unit, kind)
	if not aura or not aura.auraInstanceID then return end
	local id = aura.auraInstanceID
	local cache = AuraUtil.getAuraKindCache(unit, kind)
	local auras = cache and cache.auras
	if not (cache and auras) then return end
	local t = auras[id]
	if not t then
		t = {}
		auras[id] = t
	end
	t.auraInstanceID = id
	t.spellId = aura.spellId
	t.name = aura.name
	t.icon = aura.icon
	t.isHelpful = aura.isHelpful
	t.isHarmful = aura.isHarmful
	t.isSample = aura.isSample == true
	t.isStealable = t.isSample and aura.isStealable == true or nil
	t.applications = aura.applications
	t.duration = aura.duration
	t.expirationTime = aura.expirationTime
	t.sourceUnit = aura.sourceUnit
	local dispelName = aura.dispelName
	local canActivePlayerDispel = aura.canActivePlayerDispel
	if issecretvalue and issecretvalue(dispelName) then dispelName = nil end
	if issecretvalue and issecretvalue(canActivePlayerDispel) then canActivePlayerDispel = nil end
	t.dispelName = dispelName
	t.canActivePlayerDispel = canActivePlayerDispel
	local idx = AuraUtil.addAuraToOrder(cache, id)
	return t, idx
end

function AuraUtil.addAuraToOrder(cache, auraInstanceID)
	if not (cache and auraInstanceID) then return nil end
	local order = cache.order
	local indexById = cache.indexById
	if not (order and indexById) then return nil end
	if indexById[auraInstanceID] then return indexById[auraInstanceID] end
	local idx = #order + 1
	order[idx] = auraInstanceID
	indexById[auraInstanceID] = idx
	return idx
end

function AuraUtil.markAuraRemovedFromOrder(cache, auraInstanceID)
	if not (cache and auraInstanceID) then return nil end
	local order = cache.order
	local indexById = cache.indexById
	if not (order and indexById) then return nil end
	local idx = indexById[auraInstanceID]
	if not idx then return nil end
	order[idx] = false
	indexById[auraInstanceID] = nil
	return idx
end

function AuraUtil.removeTargetAuraFromKindCache(unit, kind, auraInstanceID)
	local cache = AuraUtil.getAuraKindCache(unit, kind)
	if not (cache and auraInstanceID and cache.auras and cache.auras[auraInstanceID]) then return nil end
	cache.auras[auraInstanceID] = nil
	local idx = AuraUtil.markAuraRemovedFromOrder(cache, auraInstanceID)
	if idx then cache._orderDirty = true end
	return idx
end

function AuraUtil.removeTargetAuraFromCaches(unit, auraInstanceID)
	if not auraInstanceID then return nil, nil end
	local buffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "buff", auraInstanceID)
	local debuffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "debuff", auraInstanceID)
	return buffIdx, debuffIdx
end

function AuraUtil.compactAuraOrderInPlace(order, indexById, auras)
	if not (order and indexById and auras) then return false end
	local write = 1
	local changed = false
	for read = 1, #order do
		local auraId = order[read]
		if auraId and auras[auraId] then
			if write ~= read then
				order[write] = auraId
				changed = true
			end
			if indexById[auraId] ~= write then indexById[auraId] = write end
			write = write + 1
		else
			if auraId and indexById[auraId] ~= nil then indexById[auraId] = nil end
			changed = true
		end
	end
	for i = write, #order do
		order[i] = nil
	end
	return changed
end

function AuraUtil.compactAuraCache(cache)
	if not (cache and cache._orderDirty and cache.order and cache.indexById and cache.auras) then return false end
	local changed = AuraUtil.compactAuraOrderInPlace(cache.order, cache.indexById, cache.auras)
	cache._orderDirty = nil
	return changed
end

function AuraUtil.isPermanentAura(aura, unitToken)
	if not aura then return false end
	if not AuraUtil.canReadAuraData() then return false end
	local duration = aura.duration
	local expiration = aura.expirationTime
	unitToken = unitToken or "target"

	if C_UnitAuras.DoesAuraHaveExpirationTime then
		local tmpDurRes = C_UnitAuras.DoesAuraHaveExpirationTime(unitToken, aura.auraInstanceID)
		if issecretvalue(tmpDurRes) then return false end
		return not tmpDurRes
	end
	if issecretvalue and (issecretvalue(duration) or issecretvalue(expiration)) then return false end
	if duration and duration > 0 then return false end
	if expiration and expiration > 0 then return false end
	return true
end

function AuraUtil.ensureAuraButton(container, icons, index, ac)
	if not container then return nil end
	icons = icons or {}
	local btn = icons[index]
	local layerParent = container._eqolAuraLayerParent or container
	local ensureSize = ac and ac.size
	local ensureStrata = ac and ac.strata
	local ensureLevelOffset = ac and ac.frameLevelOffset
	if not btn then
		btn = CreateFrame("Button", nil, container, "BackdropTemplate")
		btn:SetSize(ac.size, ac.size)
		btn._eqolAuraButtonSize = ac.size
		btn.icon = btn:CreateTexture(nil, "ARTWORK")
		btn.icon:SetAllPoints(btn)
		btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
		btn.cd:SetAllPoints(btn)
		-- Keep the count on a sibling overlay so it is not hidden by the cooldown frame
		btn.overlay = CreateFrame("Frame", nil, btn)
		btn.overlay:SetAllPoints(btn)
		btn.overlay:SetFrameStrata(btn.cd:GetFrameStrata())
		btn.overlay:SetFrameLevel(btn.cd:GetFrameLevel() + 5)
		btn.foreground = CreateFrame("Frame", nil, btn)
		btn.foreground:EnableMouse(false)
		btn.foreground:SetAllPoints(btn)
		btn.foreground:SetFrameStrata(btn.overlay:GetFrameStrata())
		btn.foreground:SetFrameLevel(btn.overlay:GetFrameLevel() + 2)

		btn.count = btn.foreground:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		btn.count:SetPoint("BOTTOMRIGHT", btn.foreground, "BOTTOMRIGHT", -2, 2)
		btn.count:SetDrawLayer("OVERLAY", 2)
		btn.drText = btn.foreground:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		btn.drText:SetPoint("TOPLEFT", btn.foreground, "TOPLEFT", 2, -2)
		btn.drText:SetDrawLayer("OVERLAY", 2)
		btn.drText:Hide()
		btn.border = btn.overlay:CreateTexture(nil, "OVERLAY")
		btn.border:SetAllPoints(btn)
		btn.border:SetDrawLayer("OVERLAY", 1)
		btn.dispelIcon = btn.foreground:CreateTexture(nil, "OVERLAY")
		btn.dispelIcon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
		btn.dispelIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		btn.dispelIcon:SetDrawLayer("OVERLAY", 1)
		btn.dispelIcon:Hide()
		btn.cd:SetReverse(true)
		btn.cd:SetDrawEdge(true)
		btn.cd:SetDrawSwipe(true)
		btn:SetScript("OnEnter", function(self)
			if not self._showTooltip then return end
			local tooltip = GameTooltip
			if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
			local unitToken = self.unitToken
			local auraInstanceID = self.auraInstanceID
			if not unitToken or not auraInstanceID then return end
			if type(auraInstanceID) ~= "number" or auraInstanceID <= 0 then return end
			if self._tooltipUseEditMode == true and GameTooltip_SetDefaultAnchor then
				GameTooltip_SetDefaultAnchor(tooltip, self)
			else
				tooltip:SetOwner(self, self._tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
			end
			if self.isDebuff then
				if tooltip.SetUnitDebuffByAuraInstanceID then
					tooltip:SetUnitDebuffByAuraInstanceID(unitToken, auraInstanceID)
					tooltip:Show()
				end
			else
				if tooltip.SetUnitBuffByAuraInstanceID then
					tooltip:SetUnitBuffByAuraInstanceID(unitToken, auraInstanceID)
					tooltip:Show()
				end
			end
		end)
		btn:SetScript("OnLeave", function()
			if GameTooltip then GameTooltip:Hide() end
		end)
		icons[index] = btn
	else
		if
			btn._eqolAuraEnsureContainer == container
			and btn._eqolAuraEnsureLayerParent == layerParent
			and btn._eqolAuraEnsureSize == ensureSize
			and btn._eqolAuraEnsureStrata == ensureStrata
			and btn._eqolAuraEnsureLevelOffset == ensureLevelOffset
		then
			return btn, icons
		end
		if AuraUtil.setAuraButtonSize then
			AuraUtil.setAuraButtonSize(btn, ac and ac.size)
		elseif ac and ac.size and btn.SetSize then
			btn:SetSize(ac.size, ac.size)
			btn._eqolAuraButtonSize = ac.size
		end
		if btn.overlay and btn.cd then
			btn.overlay:SetFrameStrata(btn.cd:GetFrameStrata())
			btn.overlay:SetFrameLevel(btn.cd:GetFrameLevel() + 5)
		end
		if not btn.foreground then
			btn.foreground = CreateFrame("Frame", nil, btn)
			btn.foreground:EnableMouse(false)
			btn.foreground:SetAllPoints(btn)
		end
		if btn.foreground and btn.overlay then
			btn.foreground:SetFrameStrata(btn.overlay:GetFrameStrata())
			btn.foreground:SetFrameLevel(btn.overlay:GetFrameLevel() + 2)
		end
		if btn.foreground and btn.count and btn.count:GetParent() ~= btn.foreground then
			btn.count:SetParent(btn.foreground)
			btn.count:SetDrawLayer("OVERLAY", 2)
			btn._countStyleAnchor, btn._countStyleOx, btn._countStyleOy = nil, nil, nil
			btn._countStyleFontKey, btn._countStyleSize, btn._countStyleFlags = nil, nil, nil
		end
		if btn.overlay and btn.border and btn.border:GetParent() ~= btn.overlay then
			btn.border:SetParent(btn.overlay)
			btn.border:SetDrawLayer("OVERLAY", 1)
		end
		if not btn.drText then
			local parent = btn.foreground or btn.overlay or btn
			btn.drText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			btn.drText:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
			btn.drText:SetDrawLayer("OVERLAY", 2)
			btn.drText:Hide()
		elseif btn.foreground and btn.drText:GetParent() ~= btn.foreground then
			btn.drText:SetParent(btn.foreground)
			btn.drText:SetDrawLayer("OVERLAY", 2)
			btn._drStyleAnchor, btn._drStyleOx, btn._drStyleOy = nil, nil, nil
			btn._drStyleFontKey, btn._drStyleSize, btn._drStyleFlags = nil, nil, nil
		end
		if btn.foreground and btn.dispelIcon and btn.dispelIcon:GetParent() ~= btn.foreground then
			btn.dispelIcon:SetParent(btn.foreground)
			btn.dispelIcon:SetDrawLayer("OVERLAY", 1)
		end
	end

	if AuraUtil.syncAuraButtonLayer then AuraUtil.syncAuraButtonLayer(btn, container, ac) end
	btn._eqolAuraEnsureContainer = container
	btn._eqolAuraEnsureLayerParent = layerParent
	btn._eqolAuraEnsureSize = ensureSize
	btn._eqolAuraEnsureStrata = ensureStrata
	btn._eqolAuraEnsureLevelOffset = ensureLevelOffset

	return btn, icons
end

function AuraUtil.styleAuraCount(btn, ac, countFontSizeOverride)
	if not btn or not btn.count then return end
	ac = ac or {}
	local anchor = ac.countAnchor or "BOTTOMRIGHT"
	local off = ac.countOffset
	local ox, oy
	if off then
		ox = off.x or 0
		oy = off.y or 0
	else
		ox = -2
		oy = 2
	end
	local size = countFontSizeOverride
	if size == nil then size = ac.countFontSize end
	local flags = ac.countFontOutline
	local fontKey = ac.countFont or (addon.variables and addon.variables.defaultFont) or (LSM and LSM.DefaultMedia and LSM.DefaultMedia.font) or STANDARD_TEXT_FONT
	local globalFontStateVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	if
		btn._countStyleAnchor == anchor
		and btn._countStyleOx == ox
		and btn._countStyleOy == oy
		and btn._countStyleFontKey == fontKey
		and btn._countStyleSize == size
		and btn._countStyleFlags == flags
		and btn._countStyleFontStateVersion == globalFontStateVersion
	then
		return
	end
	btn._countStyleAnchor = anchor
	btn._countStyleOx = ox
	btn._countStyleOy = oy
	btn._countStyleFontKey = fontKey
	btn._countStyleSize = size
	btn._countStyleFlags = flags
	btn._countStyleFontStateVersion = globalFontStateVersion
	btn.count:ClearAllPoints()
	btn.count:SetPoint(anchor, btn.foreground or btn.overlay or btn, anchor, ox, oy)
	if size == nil or flags == nil then
		local _, curSize, curFlags = btn.count:GetFont()
		if size == nil then size = curSize or 14 end
		if flags == nil then flags = curFlags end
	end
	if UFHelper and UFHelper.applyFont then
		UFHelper.applyFont(btn.count, ac.countFont, size, flags)
	else
		local fallbackFlags = flags == "__EQOL_GLOBAL_FONT_STYLE__" and "OUTLINE" or flags
		btn.count:SetFont(UFHelper.getFont(ac.countFont), size, fallbackFlags)
	end
end

function AuraUtil.styleAuraCooldownText(btn, ac, cooldownFontSizeOverride)
	if not btn or not btn.cd then return end
	ac = ac or {}
	local fs = btn._cooldownText or (btn.cd.GetCountdownFontString and btn.cd:GetCountdownFontString())
	if not fs then return end
	btn._cooldownText = fs
	local anchor = ac.cooldownAnchor or "CENTER"
	local off = ac.cooldownOffset
	local ox = (off and off.x) or 0
	local oy = (off and off.y) or 0
	local size = cooldownFontSizeOverride
	if size == nil then size = ac.cooldownFontSize end
	local fontKey = ac.cooldownFont
	local outline = ac.cooldownFontOutline
	local globalFontStateVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	local curFont, curSize, curFlags = fs:GetFont()
	if size == nil then size = curSize or 12 end
	if outline == nil then outline = curFlags end
	if fontKey == nil then fontKey = curFont end
	if
		btn._cooldownStyleAnchor == anchor
		and btn._cooldownStyleOx == ox
		and btn._cooldownStyleOy == oy
		and btn._cooldownStyleFontKey == fontKey
		and btn._cooldownStyleSize == size
		and btn._cooldownStyleOutline == outline
		and btn._cooldownStyleFontStateVersion == globalFontStateVersion
	then
		return
	end
	btn._cooldownStyleAnchor = anchor
	btn._cooldownStyleOx = ox
	btn._cooldownStyleOy = oy
	btn._cooldownStyleFontKey = fontKey
	btn._cooldownStyleSize = size
	btn._cooldownStyleOutline = outline
	btn._cooldownStyleFontStateVersion = globalFontStateVersion
	fs:ClearAllPoints()
	fs:SetPoint(anchor, btn.overlay or btn, anchor, ox, oy)
	if UFHelper and UFHelper.applyFont then
		UFHelper.applyFont(fs, fontKey, size, outline)
	elseif UFHelper and UFHelper.applyCooldownTextStyle then
		UFHelper.applyCooldownTextStyle(btn.cd, size)
	end
end

function AuraUtil.styleAuraDRText(btn, ac, drFontSizeOverride)
	if not btn or not btn.drText then return end
	ac = ac or {}
	local anchor = ac.drAnchor or "TOPLEFT"
	local off = ac.drOffset
	local ox = (off and off.x) or 2
	local oy = (off and off.y) or -2
	local size = drFontSizeOverride
	if size == nil then size = ac.drFontSize end
	local flags = ac.drFontOutline
	local fontKey = ac.drFont or (addon.variables and addon.variables.defaultFont) or (LSM and LSM.DefaultMedia and LSM.DefaultMedia.font) or STANDARD_TEXT_FONT
	if btn._drStyleAnchor == anchor and btn._drStyleOx == ox and btn._drStyleOy == oy and btn._drStyleFontKey == fontKey and btn._drStyleSize == size and btn._drStyleFlags == flags then return end
	btn._drStyleAnchor = anchor
	btn._drStyleOx = ox
	btn._drStyleOy = oy
	btn._drStyleFontKey = fontKey
	btn._drStyleSize = size
	btn._drStyleFlags = flags
	btn.drText:ClearAllPoints()
	btn.drText:SetPoint(anchor, btn.foreground or btn.overlay or btn, anchor, ox, oy)
	if size == nil or flags == nil then
		local _, curSize, curFlags = btn.drText:GetFont()
		if size == nil then size = curSize or 12 end
		if flags == nil then flags = curFlags end
	end
	if UFHelper and UFHelper.applyFont then
		UFHelper.applyFont(btn.drText, ac.drFont, size, flags)
	else
		local fallbackFlags = flags == "__EQOL_GLOBAL_FONT_STYLE__" and "OUTLINE" or flags
		btn.drText:SetFont(UFHelper.getFont(ac.drFont), size, fallbackFlags)
	end
end

function AuraUtil.NormalizeIconShape(value, fallback)
	if addon.IconShape and addon.IconShape.Normalize then return addon.IconShape.Normalize(value, fallback) end
	local normalized = type(value) == "string" and value:upper() or nil
	if normalized == "HEXAGON" or normalized == "HEX" then return "HEXAGON" end
	if normalized == "ROUND_STAR" or normalized == "ROUNDSTAR" or normalized == "ROUND-STAR" then return "ROUND_STAR" end
	if normalized == "ROUND" or normalized == "CIRCLE" then return "ROUND" end
	if normalized == "SQUARE" then return "SQUARE" end
	if normalized == "DIAMOND" then return "DIAMOND" end
	local normalizedFallback = type(fallback) == "string" and fallback:upper() or nil
	if normalizedFallback == "HEXAGON" or normalizedFallback == "HEX" then return "HEXAGON" end
	if normalizedFallback == "ROUND_STAR" or normalizedFallback == "ROUNDSTAR" or normalizedFallback == "ROUND-STAR" then return "ROUND_STAR" end
	if normalizedFallback == "ROUND" or normalizedFallback == "CIRCLE" then return "ROUND" end
	if normalizedFallback == "SQUARE" then return "SQUARE" end
	if normalizedFallback == "DIAMOND" then return "DIAMOND" end
	return "DEFAULT"
end

function AuraUtil.IsIconShapeBackdropBorderCompatible(shape)
	if addon.IconShape and addon.IconShape.IsBackdropBorderCompatible then return addon.IconShape.IsBackdropBorderCompatible(shape) end
	shape = AuraUtil.NormalizeIconShape(shape, "DEFAULT")
	return shape == "DEFAULT" or shape == "SQUARE"
end

function AuraUtil.HideIconShapeBorderTextures(btn)
	if not btn then return end
	local stores = { btn._eqolAuraShapeBorderTextures, btn._eqolNativeAuraShapeBorderTextures }
	for _, textures in ipairs(stores) do
		if textures then
			for i = 1, #textures do
				if textures[i] then textures[i]:Hide() end
			end
		end
	end
end

function AuraUtil.EnsureIconShapeBorderTexture(btn, index)
	if not btn then return nil end
	btn._eqolAuraShapeBorderTextures = btn._eqolAuraShapeBorderTextures or {}
	local texture = btn._eqolAuraShapeBorderTextures[index]
	if not texture and index == 1 and btn.border then
		texture = btn.border
		btn._eqolAuraShapeBorderTextures[index] = texture
	end
	if not texture then
		local parent = btn.overlay or btn
		texture = parent:CreateTexture(nil, "OVERLAY")
		texture:SetDrawLayer("OVERLAY", 1)
		btn._eqolAuraShapeBorderTextures[index] = texture
	end
	return texture
end

function AuraUtil.GetIconShapeBorderLayerOffset(index)
	if index <= 1 then return 0, 0 end
	local remaining = index - 2
	local radius = 1
	while remaining >= radius * 8 do
		remaining = remaining - (radius * 8)
		radius = radius + 1
	end
	local side = math.floor(remaining / (radius * 2))
	local step = remaining % (radius * 2)
	if side == 0 then return -radius + step, -radius end
	if side == 1 then return radius, -radius + step end
	if side == 2 then return radius - step, radius end
	return -radius, radius - step
end

function AuraUtil.ApplyIconShape(btn, shape, iconZoom)
	if not btn then return end
	shape = AuraUtil.NormalizeIconShape(shape, "DEFAULT")
	if addon.IconShape and addon.IconShape.ApplyFrameShape then
		addon.IconShape.ApplyFrameShape(btn, shape, {
			textures = { btn.icon },
			cooldown = btn.cd,
			maskKey = "_eqolAuraIconShapeMask",
			textureMaskKey = "_eqolAuraIconShapeRegionMask",
			textureTexCoordKey = "_eqolAuraIconTexCoord",
			iconZoom = iconZoom,
			refreshSwipe = function(button)
				if addon.IconShape and addon.IconShape.ApplyCooldownSwipeVisual then
					addon.IconShape.ApplyCooldownSwipeVisual(button.cd, button, nil, nil, { customColor = false })
				end
			end,
		})
	end
end

function AuraUtil.ApplyIconShapeBorder(btn, ac, r, g, b, a)
	if not (btn and btn.border) then return false end
	local shape = AuraUtil.NormalizeIconShape(ac and ac.iconShape, "DEFAULT")
	local borderKey = ac and ac.borderTexture
	if addon.IconShape and addon.IconShape.NormalizeBorder then borderKey = addon.IconShape.NormalizeBorder(borderKey, nil, shape, { allowNone = true }) end
	if not (addon.IconShape and addon.IconShape.GetBorderInfo and addon.IconShape.GetBorderInfo(borderKey)) then return false end
	local borderSize = (UFHelper and UFHelper.calcAuraBorderSize and UFHelper.calcAuraBorderSize(btn, ac)) or 1
	local borderOffset = tonumber(ac and ac.borderOffset) or 0
	if UFHelper and UFHelper.hideAuraBorderFrame then UFHelper.hideAuraBorderFrame(btn) end
	btn._eqolAuraBorderFrame = nil
	btn._eqolAuraBorderRenderAsEdge = nil
	return addon.IconShape.ApplyBorder(btn, borderKey, shape, {
		borderSize = borderSize,
		borderOffset = borderOffset,
		color = { r or 1, g or 1, b or 1, a or 1 },
		pointFrame = btn,
		parent = btn.overlay or btn,
		primaryTexture = btn.border,
		texturesKey = "_eqolAuraShapeBorderTextures",
		allowNone = true,
	})
end

function AuraUtil.ShouldHideNativeAuraTooltipInCombat(style)
	local explicitHideInCombat = type(style) == "table" and style.hideTooltipInCombat == true
	if addon.AuraCompat and addon.AuraCompat.ShouldHideAuraButtonTooltipInCombat then
		return addon.AuraCompat:ShouldHideAuraButtonTooltipInCombat(explicitHideInCombat)
	end
	return explicitHideInCombat
end

function AuraUtil.getAuraButtonStyleKey(ac)
	if type(ac) ~= "table" then return "" end
	local fontVersion = addon.functions and addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	local hideTooltipInCombat = AuraUtil.ShouldHideNativeAuraTooltipInCombat(ac)
	if ac._eqolAuraButtonStyleFontVersion == fontVersion and ac._eqolAuraButtonStyleHideTooltipInCombat == hideTooltipInCombat and ac._eqolAuraButtonStyleKey then
		return ac._eqolAuraButtonStyleKey
	end
	local countOffset = ac.countOffset
	local cooldownOffset = ac.cooldownOffset
	local drOffset = ac.drOffset
	local tooltipOffset = ac.tooltipOffset
	local borderColor = ac.borderColor
	local externalGlowColor = ac.externalGlowColor
	local key = table.concat({
		tostring(fontVersion),
		tostring(ac.size),
		tostring(ac.showTooltip),
		tostring(ac.tooltipAnchor),
		tostring(tooltipOffset and tooltipOffset.x),
		tostring(tooltipOffset and tooltipOffset.y),
		tostring(hideTooltipInCombat),
		tostring(ac.showCooldown),
		tostring(ac.showCooldownText),
		tostring(ac.showCooldownEdge),
		tostring(ac.showCooldownSwipe),
		tostring(ac.showCooldownBling),
		tostring(ac.showStacks),
		tostring(ac.countAnchor),
		tostring(countOffset and countOffset.x),
		tostring(countOffset and countOffset.y),
		tostring(ac.countFont),
		tostring(ac.countFontSize),
		tostring(ac.countFontOutline),
		tostring(ac.cooldownAnchor),
		tostring(cooldownOffset and cooldownOffset.x),
		tostring(cooldownOffset and cooldownOffset.y),
		tostring(ac.cooldownFont),
		tostring(ac.cooldownFontSize),
		tostring(ac.cooldownFontOutline),
		tostring(ac.durationTextProfile),
		tostring(addon.DurationText and addon.DurationText.version or 0),
		tostring(ac.iconShape),
		tostring(ac.iconZoom),
		tostring(ac.strata),
		tostring(ac.frameLevelOffset),
		tostring(ac.borderTexture),
		tostring(ac.borderRenderMode),
		tostring(ac.borderSize),
		tostring(ac.borderOffset),
		tostring(borderColor and (borderColor[1] or borderColor.r)),
		tostring(borderColor and (borderColor[2] or borderColor.g)),
		tostring(borderColor and (borderColor[3] or borderColor.b)),
		tostring(borderColor and (borderColor[4] or borderColor.a)),
		tostring(ac.blizzardDispelBorder),
		tostring(ac.blizzardDispelBorderAlpha),
		tostring(ac.blizzardDispelBorderAlphaNot),
		tostring(ac.blizzardStealableBorder),
		tostring(ac.blizzardStealableGlowStyle),
		tostring(ac.blizzardStealableGlowInset),
		tostring(ac.externalGlowEnabled),
		tostring(ac.externalGlowStyle),
		tostring(ac.externalGlowInset),
		tostring(externalGlowColor and (externalGlowColor[1] or externalGlowColor.r)),
		tostring(externalGlowColor and (externalGlowColor[2] or externalGlowColor.g)),
		tostring(externalGlowColor and (externalGlowColor[3] or externalGlowColor.b)),
		tostring(externalGlowColor and (externalGlowColor[4] or externalGlowColor.a)),
		tostring(ac.showDR),
		tostring(ac.drAnchor),
		tostring(drOffset and drOffset.x),
		tostring(drOffset and drOffset.y),
		tostring(ac.drFont),
		tostring(ac.drFontSize),
		tostring(ac.drFontOutline),
		tostring(ac.drColor),
	}, "\031")
	ac._eqolAuraButtonStyleFontVersion = fontVersion
	ac._eqolAuraButtonStyleHideTooltipInCombat = hideTooltipInCombat
	ac._eqolAuraButtonStyleKey = key
	return key
end

AuraUtil.STEALABLE_GLOW_STYLES = {
	DEFAULT = true,
	BLIZZARD = true,
	FLASH = true,
	MARCHING_ANTS = true,
	PIXEL = true,
	PULSING = true,
	SOLID = true,
}

function AuraUtil.NormalizeStealableGlowStyle(value)
	local style = type(value) == "string" and value:upper() or "DEFAULT"
	return AuraUtil.STEALABLE_GLOW_STYLES[style] and style or "DEFAULT"
end

function AuraUtil.NormalizeStealableGlowInset(value)
	local inset = tonumber(value) or 0
	if inset < -100 then inset = -100 end
	if inset > 100 then inset = 100 end
	if inset < 0 then return math.ceil(inset - 0.5) end
	return math.floor(inset + 0.5)
end

function AuraUtil.ApplySampleStealableGlow(button, aura, style, isDebuff)
	if not button then return end
	style = style or {}
	local glowTarget = button.foreground or button
	local show = not isDebuff and aura and aura.isSample == true and aura.isStealable == true and style.blizzardStealableBorder ~= false
	if not show then
		if button.stealablePreviewBorder then button.stealablePreviewBorder:Hide() end
		if addon.Glow and addon.Glow.Stop then addon.Glow.Stop(glowTarget, "EQOL_STEALABLE", true) end
		return
	end

	local glowStyle = AuraUtil.NormalizeStealableGlowStyle(style.blizzardStealableGlowStyle)
	local inset = AuraUtil.NormalizeStealableGlowInset(style.blizzardStealableGlowInset)
	if glowStyle == "DEFAULT" then
		if addon.Glow and addon.Glow.Stop then addon.Glow.Stop(glowTarget, "EQOL_STEALABLE", true) end
		if not button.stealablePreviewBorder then
			button.stealablePreviewBorder = glowTarget:CreateTexture(nil, "OVERLAY", nil, 5)
			button.stealablePreviewBorder:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
			button.stealablePreviewBorder:SetBlendMode("ADD")
		end
		button.stealablePreviewBorder:ClearAllPoints()
		button.stealablePreviewBorder:SetPoint("TOPLEFT", button, "TOPLEFT", -inset, inset)
		button.stealablePreviewBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", inset, -inset)
		button.stealablePreviewBorder:Show()
		return
	end

	if button.stealablePreviewBorder then button.stealablePreviewBorder:Hide() end
	if addon.Glow and addon.Glow.Start then
		addon.Glow.Start(glowTarget, "EQOL_STEALABLE", glowStyle, {
			color = { 1, 0.82, 0.2, 1 },
			count = 8,
			frequency = 0.25,
			thickness = 2,
			inset = inset,
			shape = style.iconShape,
			hostFrameLevelOffset = 1,
			frameLevel = 1,
		})
	end
end

function AuraUtil.setAuraTooltipState(btn, style)
	if not (btn and style) then return end
	local show = style.showTooltip == true
	btn._tooltipUseEditMode = style.tooltipUseEditMode == true
	btn._tooltipAnchor = style.tooltipAnchor or "ANCHOR_BOTTOMRIGHT"
	if btn._showTooltip ~= show then btn._showTooltip = show end
	if btn.SetMouseMotionEnabled and btn._eqolAuraMouseMotionEnabled ~= show then
		btn:SetMouseMotionEnabled(show)
		btn._eqolAuraMouseMotionEnabled = show
	end
	if btn.EnableMouse then
		if btn._eqolAuraMouseEnabled ~= show then
			btn:EnableMouse(show)
			btn._eqolAuraMouseEnabled = show
			if btn.SetMouseClickEnabled then btn:SetMouseClickEnabled(false) end
		end
	end
	if not show and GameTooltip and GameTooltip.IsOwned and GameTooltip.Hide and GameTooltip:IsOwned(btn) then GameTooltip:Hide() end
end

function AuraUtil.applyAuraToButton(btn, aura, ac, isDebuff, unitToken, harmfulFilter, canShowPlayerDispel)
	if not btn or not aura then return end
	unitToken = unitToken or "target"
	local auraDataReadable = aura.isSample == true or AuraUtil.canReadAuraData()
	if not auraDataReadable then return end
	if issecretvalue and issecretvalue(isDebuff) then
		harmfulFilter = harmfulFilter or select(2, AuraUtil.getAuraFilters(unitToken, ac))
		isDebuff = AuraUtil.isAuraFilteredIn(unitToken, aura, harmfulFilter)
	end
	local styleKey = AuraUtil.getAuraButtonStyleKey(ac)
	local showCooldown = ac.showCooldown ~= false
	local showCooldownText = ac.showCooldownText
	if showCooldownText == nil then showCooldownText = showCooldown end
	local needsCooldown = showCooldown or showCooldownText == true
	local showStacks = ac.showStacks
	if showStacks == nil then showStacks = true end
	local borderKey = ac and ac.borderTexture
	local showBorder = isDebuff == true
	local borderKeyName = borderKey and tostring(borderKey):upper() or "DEFAULT"
	if borderKeyName == "NONE" then showBorder = false end
	if not showBorder then
		showBorder = borderKeyName ~= "" and borderKeyName ~= "DEFAULT" and borderKeyName ~= "NONE"
	end
	AuraUtil.setAuraTooltipState(btn, ac)
	if canShowPlayerDispel == nil then canShowPlayerDispel = AuraUtil.CanUnitShowPlayerDispel(unitToken, aura.isSample) end
	local canUseStaticSignature = not needsCooldown and not showStacks and not showBorder and not (ac and ac.blizzardDispelBorder == true) and not (ac and ac.showDR == true)
	if
		canUseStaticSignature
		and aura.auraInstanceID
		and btn:IsShown()
		and btn._eqolAuraStyleKey == styleKey
		and btn._eqolAuraSigUnitToken == unitToken
		and btn._eqolAuraSigInstanceID == aura.auraInstanceID
		and btn._eqolAuraSigSample == aura.isSample
		and btn._eqolAuraSigIsHelpful == aura.isHelpful
		and btn._eqolAuraSigIsHarmful == aura.isHarmful
		and btn._eqolAuraSigFromPlayerPet == aura.isFromPlayerOrPlayerPet
		and btn._eqolAuraSigNameplateOnly == aura.isNameplateOnly
		and btn._eqolAuraSigRaid == aura.isRaid
	then
		return
	end
	btn.spellId = aura.spellId
	btn.auraInstanceID = aura.auraInstanceID
	btn.unitToken = unitToken
	btn.isDebuff = isDebuff
	btn.icon:SetTexture(aura.icon or "")
	AuraUtil.ApplyIconShape(btn, ac and ac.iconShape, ac and ac.iconZoom)
	btn.cd:Clear()
	AuraUtil.ApplyDurationTextProfileToCooldownFrame(btn.cd, ac and ac.durationTextProfile)
	local drawCooldownEdge = ac.showCooldownEdge ~= false
	local drawCooldownSwipe = ac.showCooldownSwipe ~= false
	local drawCooldownBling = ac.showCooldownBling ~= false
	if not AuraUtil.IsIconShapeBackdropBorderCompatible(ac and ac.iconShape) then drawCooldownEdge = false end
	local hasCooldown = false
	if btn.cd.SetDrawEdge then btn.cd:SetDrawEdge(false) end
	if btn.cd.SetDrawSwipe then btn.cd:SetDrawSwipe(false) end
	if btn.cd.SetDrawBling then btn.cd:SetDrawBling(false) end
	if auraDataReadable and needsCooldown and aura.auraInstanceID and aura.auraInstanceID > 0 then
		local durObj = C_UnitAuras.GetAuraDuration(unitToken, aura.auraInstanceID)
		if durObj then
			btn.cd:SetCooldownFromDurationObject(durObj)
			hasCooldown = true
		end
	elseif needsCooldown and aura.isSample and aura.duration and aura.expirationTime and aura.duration > 0 and aura.expirationTime > 0 then
		local startTime = aura.expirationTime - aura.duration
		if btn.cd.SetCooldown then
			btn.cd:SetCooldown(startTime, aura.duration)
			hasCooldown = true
		elseif CooldownFrame_Set then
			CooldownFrame_Set(btn.cd, startTime, aura.duration, true)
			hasCooldown = true
		end
	end
	if btn.cd.SetDrawEdge then btn.cd:SetDrawEdge(hasCooldown and showCooldown and drawCooldownEdge) end
	if btn.cd.SetDrawSwipe then btn.cd:SetDrawSwipe(hasCooldown and showCooldown and drawCooldownSwipe) end
	if btn.cd.SetDrawBling then btn.cd:SetDrawBling(hasCooldown and showCooldown and drawCooldownBling) end
	AuraUtil.ApplyIconShape(btn, ac and ac.iconShape, ac and ac.iconZoom)
	local cooldownFontSize = ac.cooldownFontSize
	if cooldownFontSize ~= nil and cooldownFontSize < 1 then cooldownFontSize = nil end
	local countFontSize = ac.countFontSize
	btn.cd:SetHideCountdownNumbers(not hasCooldown or showCooldownText == false)
	if btn._eqolAuraTextStyleKey ~= styleKey then
		AuraUtil.styleAuraCount(btn, ac, countFontSize)
		AuraUtil.styleAuraCooldownText(btn, ac, cooldownFontSize)
		btn._eqolAuraTextStyleKey = styleKey
	end
	if showStacks and (issecretvalue and issecretvalue(aura.applications) or aura.applications and aura.applications > 1) then
		local appStacks = aura.applications
		if auraDataReadable and not aura.isSample and aura.auraInstanceID and aura.auraInstanceID > 0 and C_UnitAuras.GetAuraApplicationDisplayCount then
			appStacks = C_UnitAuras.GetAuraApplicationDisplayCount(unitToken, aura.auraInstanceID, 2, 1000) -- ? actual 4th param is required because otherwise it's always "*" this always get's the right stack shown
		end

		btn.count:SetText(appStacks)
		btn.count:Show()
	else
		btn.count:SetText("")
		btn.count:Hide()
	end
	local dispelR, dispelG, dispelB
	if btn.border then
		if showBorder then
			local r, g, b = 1, 0.25, 0.25
			local a = 1
			local usedApiColor
			if auraDataReadable and not aura.isSample and aura.auraInstanceID and aura.auraInstanceID > 0 and C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor and UFHelper and UFHelper.debuffColorCurve then
				local color = C_UnitAuras.GetAuraDispelTypeColor(unitToken, aura.auraInstanceID, UFHelper.debuffColorCurve)
				if color then
					usedApiColor = true
					if color.GetRGBA then
						r, g, b = color:GetRGBA()
					elseif color.r then
						r, g, b = color.r, color.g, color.b
					end
				end
			end
			if not usedApiColor then
				local fr, fg, fb
				if UFHelper and UFHelper.getDebuffColorFromName then
					local dispelName = aura.dispelName
					local canActivePlayerDispel = aura.canActivePlayerDispel
					if issecretvalue and issecretvalue(dispelName) then dispelName = nil end
					if issecretvalue and issecretvalue(canActivePlayerDispel) then canActivePlayerDispel = nil end
					if canShowPlayerDispel and (not dispelName or dispelName == "") and canActivePlayerDispel == true then dispelName = "Magic" end
					fr, fg, fb = UFHelper.getDebuffColorFromName(dispelName or "None")
				end
				if fr then
					r, g, b = fr, fg, fb
				end
			end
			if isDebuff then
				dispelR, dispelG, dispelB = r, g, b
			end
			local customBorderColor = ac and ac.borderColor
			if type(customBorderColor) == "table" then
				r = customBorderColor[1] or customBorderColor.r or r
				g = customBorderColor[2] or customBorderColor.g or g
				b = customBorderColor[3] or customBorderColor.b or b
				a = customBorderColor[4] or customBorderColor.a or a
			end
			if
				btn._eqolAuraBorderStyleKey ~= styleKey
				or btn._eqolAuraBorderKey ~= borderKey
				or btn._eqolAuraBorderButtonSize ~= btn._eqolAuraButtonSize
			then
				local borderMode = tostring((ac and ac.borderRenderMode) or "EDGE"):upper()
				local useOverlayBorderMode = borderMode == "OVERLAY"
				local borderTex, borderCoords, borderIsEdge
				if UFHelper and UFHelper.resolveAuraBorderTexture then
					borderTex, borderCoords, borderIsEdge = UFHelper.resolveAuraBorderTexture(borderKey)
				else
					borderTex = "Interface\\Buttons\\UI-Debuff-Overlays"
					borderCoords = { 0.296875, 0.5703125, 0, 0.515625 }
					borderIsEdge = false
				end
				local renderAsEdge = borderIsEdge and not useOverlayBorderMode
				btn._eqolAuraBorderRenderAsEdge = renderAsEdge
				btn._eqolAuraBorderStyleKey = styleKey
				btn._eqolAuraBorderKey = borderKey
				btn._eqolAuraBorderButtonSize = btn._eqolAuraButtonSize
				if not AuraUtil.IsIconShapeBackdropBorderCompatible(ac and ac.iconShape) then
					if AuraUtil.ApplyIconShapeBorder(btn, ac, r, g, b, a) then
						btn._eqolAuraBorderShape = ac and ac.iconShape
					else
						if UFHelper and UFHelper.hideAuraBorderFrame then UFHelper.hideAuraBorderFrame(btn) end
						AuraUtil.HideIconShapeBorderTextures(btn)
						btn._eqolAuraBorderFrame = nil
						btn._eqolAuraBorderRenderAsEdge = nil
					end
				elseif renderAsEdge and borderTex and borderTex ~= "" then
					AuraUtil.HideIconShapeBorderTextures(btn)
					local borderFrame = UFHelper and UFHelper.ensureAuraBorderFrame and UFHelper.ensureAuraBorderFrame(btn)
					btn._eqolAuraBorderFrame = borderFrame
					if borderFrame then
						local edgeSize = (UFHelper and UFHelper.calcAuraBorderSize and UFHelper.calcAuraBorderSize(btn, ac)) or 1
						local borderOffset = tonumber(ac and ac.borderOffset) or 0
						local edgeInset = (edgeSize or 1) * 0.5
						local anchorInset = edgeInset - borderOffset
						local insetVal = edgeSize
						if borderFrame._eqolAuraBorderTex ~= borderTex or borderFrame._eqolAuraBorderEdgeSize ~= edgeSize then
							borderFrame:SetBackdrop({
								bgFile = "Interface\\Buttons\\WHITE8x8",
								edgeFile = borderTex,
								edgeSize = edgeSize,
								insets = { left = insetVal, right = insetVal, top = insetVal, bottom = insetVal },
							})
							borderFrame:SetBackdropColor(0, 0, 0, 0)
							borderFrame._eqolAuraBorderTex = borderTex
							borderFrame._eqolAuraBorderEdgeSize = edgeSize
						end
						borderFrame:ClearAllPoints()
						borderFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", anchorInset, -anchorInset)
						borderFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -anchorInset, anchorInset)
						borderFrame._eqolAuraBorderInset = anchorInset
					end
					btn.border:Hide()
				else
					AuraUtil.HideIconShapeBorderTextures(btn)
					if UFHelper and UFHelper.hideAuraBorderFrame then UFHelper.hideAuraBorderFrame(btn) end
					btn._eqolAuraBorderFrame = nil
					btn.border:SetTexture(borderTex or "")
					local useOverlayBorderGeometry = useOverlayBorderMode and not borderCoords
					if borderCoords then
						btn.border:SetTexCoord(borderCoords[1], borderCoords[2], borderCoords[3], borderCoords[4])
					else
						btn.border:SetTexCoord(0, 1, 0, 1)
					end
					if useOverlayBorderGeometry then
						local bw = btn:GetWidth()
						local bh = btn:GetHeight()
						if not bw or bw <= 0 then bw = (ac and ac.size) or 24 end
						if not bh or bh <= 0 then bh = bw end
						btn.border:ClearAllPoints()
						btn.border:SetPoint("CENTER", btn, "CENTER", 0, 0)
						btn.border:SetSize((bw or 24) + 1, (bh or 24) + 1)
					else
						btn.border:SetAllPoints(btn)
					end
				end
			end
			if not AuraUtil.IsIconShapeBackdropBorderCompatible(ac and ac.iconShape) then
				if AuraUtil.ApplyIconShapeBorder(btn, ac, r, g, b, a) then
					btn._eqolAuraBorderShape = ac and ac.iconShape
				else
					if UFHelper and UFHelper.hideAuraBorderFrame then UFHelper.hideAuraBorderFrame(btn) end
					AuraUtil.HideIconShapeBorderTextures(btn)
				end
			elseif btn._eqolAuraBorderRenderAsEdge then
				AuraUtil.HideIconShapeBorderTextures(btn)
				local borderFrame = btn._eqolAuraBorderFrame
				if borderFrame then
					borderFrame:SetBackdropBorderColor(r, g, b, a)
					borderFrame:Show()
				end
				btn.border:Hide()
			else
				AuraUtil.HideIconShapeBorderTextures(btn)
				btn.border:SetVertexColor(r, g, b, a)
				btn.border:Show()
			end
		else
			if UFHelper and UFHelper.hideAuraBorderFrame then UFHelper.hideAuraBorderFrame(btn) end
			btn._eqolAuraBorderStyleKey = nil
			btn._eqolAuraBorderKey = nil
			btn._eqolAuraBorderButtonSize = nil
			btn._eqolAuraBorderRenderAsEdge = nil
			btn._eqolAuraBorderFrame = nil
			AuraUtil.HideIconShapeBorderTextures(btn)
			btn.border:SetTexture(nil)
			btn.border:Hide()
		end
	end
	if btn.dispelIcon then
		local showIcon = isDebuff and ac and ac.blizzardDispelBorder == true and canShowPlayerDispel
		if showIcon then
			if btn._eqolAuraDispelIconStyleKey ~= styleKey or btn._eqolAuraDispelIconButtonSize ~= btn._eqolAuraButtonSize then
				local baseSize = btn:GetWidth()
				if not baseSize or baseSize <= 0 then baseSize = (ac and ac.size) or 0 end
				local iconSize = baseSize and baseSize > 0 and (baseSize * 0.4) or 12
				btn.dispelIcon:ClearAllPoints()
				btn.dispelIcon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
				btn.dispelIcon:SetSize(iconSize, iconSize)
				btn._eqolAuraDispelIconStyleKey = styleKey
				btn._eqolAuraDispelIconButtonSize = btn._eqolAuraButtonSize
			end
			if dispelR then
				btn.dispelIcon:SetVertexColor(dispelR, dispelG, dispelB, 1)
			else
				btn.dispelIcon:SetVertexColor(1, 1, 1, 1)
			end
			local alphaOn = (ac and ac.blizzardDispelBorderAlpha) or 1
			local alphaOff = (ac and ac.blizzardDispelBorderAlphaNot) or 0
			local canActivePlayerDispel = aura.canActivePlayerDispel
			if issecretvalue and issecretvalue(canActivePlayerDispel) then canActivePlayerDispel = nil end
			if canActivePlayerDispel == nil then canActivePlayerDispel = false end
			btn.dispelIcon:SetAlphaFromBoolean(canActivePlayerDispel, alphaOn, alphaOff)
			btn.dispelIcon:Show()
		else
			btn._eqolAuraDispelIconStyleKey = nil
			btn._eqolAuraDispelIconButtonSize = nil
			btn.dispelIcon:Hide()
		end
	end
	if btn.drText then
		local showDR = ac and ac.showDR == true
		if showDR then
			local points = aura.points
			if issecretvalue and issecretvalue(points) then points = nil end
			local drValue
			if type(points) == "table" then
				local v = points[1]
				if issecretvalue and issecretvalue(v) then v = nil end
				if type(v) == "number" then drValue = v end
			end
			if drValue ~= nil then
				local text = tostring(math.floor(drValue + 0.5)) .. "%"
				if btn._lastDRText ~= text then
					btn._lastDRText = text
					btn.drText:SetText(text)
				end
				if btn._eqolAuraDRStyleKey ~= styleKey then
					AuraUtil.styleAuraDRText(btn, ac)
					btn._eqolAuraDRStyleKey = styleKey
				end
				local col = ac.drColor or { 1, 1, 1, 1 }
				btn.drText:SetTextColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
				btn.drText:Show()
			else
				if btn._lastDRText ~= "" then
					btn._lastDRText = ""
					btn.drText:SetText("")
				end
				btn.drText:Hide()
			end
		else
			if btn._lastDRText ~= "" then
				btn._lastDRText = ""
				btn.drText:SetText("")
			end
			btn.drText:Hide()
		end
	end
	btn:Show()
	AuraUtil.ApplySampleStealableGlow(btn, aura, ac, isDebuff)
	btn._eqolAuraStyleKey = styleKey
	btn._eqolAuraSigUnitToken = unitToken
	btn._eqolAuraSigInstanceID = aura.auraInstanceID
	btn._eqolAuraSigSample = aura.isSample
	btn._eqolAuraSigIsHelpful = aura.isHelpful
	btn._eqolAuraSigIsHarmful = aura.isHarmful
	btn._eqolAuraSigFromPlayerPet = aura.isFromPlayerOrPlayerPet
	btn._eqolAuraSigNameplateOnly = aura.isNameplateOnly
	btn._eqolAuraSigRaid = aura.isRaid
end

UF._auraLayout = UF._auraLayout or {}
local GROW_DIRS = { "UP", "DOWN", "LEFT", "RIGHT" }

function UF._auraLayout.parseGrowth(growth)
	if not growth or growth == "" then return end
	local raw = tostring(growth):upper()
	local first, second = raw:match("^(%a+)[_%s]+(%a+)$")
	if not first then
		for i = 1, #GROW_DIRS do
			local dir = GROW_DIRS[i]
			if raw:sub(1, #dir) == dir then
				local rest = raw:sub(#dir + 1)
				if rest == "UP" or rest == "DOWN" or rest == "LEFT" or rest == "RIGHT" then
					first, second = dir, rest
					break
				end
			end
		end
	end
	if not first or not second then return end
	local firstVertical = first == "UP" or first == "DOWN"
	local secondVertical = second == "UP" or second == "DOWN"
	if firstVertical == secondVertical then return end
	return first, second
end

function UF._auraLayout.resolveGrowth(ac, fallbackAnchor, growthOverride)
	local anchor = fallbackAnchor or (ac and ac.anchor) or "BOTTOM"
	local fallback
	if anchor == "TOP" then
		fallback = "RIGHTUP"
	elseif anchor == "LEFT" then
		fallback = "LEFTDOWN"
	else
		fallback = "RIGHTDOWN"
	end
	local primary, secondary = UF._auraLayout.parseGrowth(growthOverride or (ac and ac.growth))
	if not primary then
		primary, secondary = UF._auraLayout.parseGrowth(fallback)
	end
	return primary, secondary
end

function UF._auraLayout.defaultOffset(anchor)
	if anchor == "TOP" then return 0, 5 end
	if anchor == "LEFT" then return -5, 0 end
	if anchor == "RIGHT" then return 5, 0 end
	return 0, -5
end

function UF._auraLayout.positionContainer(container, anchor, barGroup, ax, ay, barAreaOffsetLeft, barAreaOffsetRight)
	if not container or not barGroup then return end
	if anchor == "TOP" then
		container:SetPoint("BOTTOMLEFT", barGroup, "TOPLEFT", (ax or 0) + (barAreaOffsetLeft or 0), ay or 0)
	elseif anchor == "LEFT" then
		container:SetPoint("TOPRIGHT", barGroup, "TOPLEFT", (ax or 0) + (barAreaOffsetLeft or 0), ay or 0)
	elseif anchor == "RIGHT" then
		container:SetPoint("TOPLEFT", barGroup, "TOPRIGHT", (ax or 0) - (barAreaOffsetRight or 0), ay or 0)
	else
		container:SetPoint("TOPLEFT", barGroup, "BOTTOMLEFT", (ax or 0) + (barAreaOffsetLeft or 0), ay or 0)
	end
end

function AuraUtil.anchorAuraButton(btn, container, index, ac, perRow, primary, secondary)
	if not btn or not container then return end
	perRow = perRow or 1
	if perRow < 1 then perRow = 1 end
	local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
	local row, col
	if primaryHorizontal then
		row = math.floor((index - 1) / perRow)
		col = (index - 1) % perRow
	else
		row = (index - 1) % perRow
		col = math.floor((index - 1) / perRow)
	end
	local horizontalDir = primaryHorizontal and primary or secondary
	local verticalDir = primaryHorizontal and secondary or primary
	local xSign = horizontalDir == "RIGHT" and 1 or -1
	local ySign = verticalDir == "UP" and 1 or -1
	local basePoint = (ySign == 1 and "BOTTOM" or "TOP") .. (xSign == 1 and "LEFT" or "RIGHT")
	local x = col * (ac.size + ac.padding) * xSign
	local y = row * (ac.size + ac.padding) * ySign
	if btn._eqolAuraAnchorContainer == container and btn._eqolAuraAnchorPoint == basePoint and btn._eqolAuraAnchorX == x and btn._eqolAuraAnchorY == y then return end
	btn._eqolAuraAnchorContainer = container
	btn._eqolAuraAnchorPoint = basePoint
	btn._eqolAuraAnchorX = x
	btn._eqolAuraAnchorY = y
	btn:ClearAllPoints()
	btn:SetPoint(basePoint, container, basePoint, x, y)
end

function AuraUtil.updateAuraContainerSize(container, shown, ac, perRow, primary)
	if not container then return end
	perRow = perRow or 1
	if perRow < 1 then perRow = 1 end
	local primaryVertical = primary == "UP" or primary == "DOWN"
	local rows
	if primaryVertical then
		rows = math.min(shown, perRow)
	else
		rows = math.ceil(shown / perRow)
	end
	local height = rows > 0 and (rows * (ac.size + ac.padding) - ac.padding) or 0.001
	if container._eqolAuraHeight ~= height then
		container:SetHeight(height)
		container._eqolAuraHeight = height
	end
	local shownFlag = shown > 0
	if container._eqolAuraShown ~= shownFlag then
		container:SetShown(shownFlag)
		container._eqolAuraShown = shownFlag
	end
end

function UF._auraLayout.calcPerRow(st, ac, width, primary)
	local size = (ac.size or 24) + (ac.padding or 0)
	if size <= 0 then return 1 end
	local override = ac and tonumber(ac.perRow)
	if override and override > 0 then return math.max(1, math.floor(override + 0.5)) end
	local available = width or 0
	if primary == "UP" or primary == "DOWN" then
		local height = (st and st.barGroup and st.barGroup:GetHeight()) or (st and st.frame and st.frame:GetHeight()) or 0
		if height and height > 0 then available = height end
	end
	if available <= 0 then return 1 end
	return math.max(1, math.floor((available + (ac.padding or 0)) / size))
end

function AuraUtil.hideAuraContainers(st)
	st = st or states.target
	if not st then return end
	if AuraUtil.HideNativeAuraContainers then AuraUtil.HideNativeAuraContainers(st) end
	if st.auraButtons then
		for i = 1, #st.auraButtons do
			local btn = st.auraButtons[i]
			if btn then btn:Hide() end
		end
	end
	if st.debuffButtons then
		for i = 1, #st.debuffButtons do
			local btn = st.debuffButtons[i]
			if btn then btn:Hide() end
		end
	end
	if st.auraContainer then
		st.auraContainer:SetHeight(0.001)
		st.auraContainer:SetShown(false)
	end
	if st.debuffContainer then
		st.debuffContainer:SetHeight(0.001)
		st.debuffContainer:SetShown(false)
	end
end

function AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, allowSample)
	if allowSample then return false end
	if addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() then return false end
	if not (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)) then return false end
	if not (auraRuntime and auraRuntime.enabled) then return false end
	return addon.AuraCompat and addon.AuraCompat:ShouldUseAuraContainer() == true or false
end

function AuraUtil.UnitUsesNativeAuraContainers(unit, allowSample)
	local cfg = ensureDB(unit)
	if not cfg or cfg.enabled == false then return false end
	local def = defaultsFor(unit)
	local ac = cfg.auraIcons or (def and def.auraIcons) or defaults.target.auraIcons or {}
	local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, def and def.auraIcons)
	return AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, allowSample)
end

function AuraUtil.CallNativeAuraMethod(object, method, ...)
	if not (object and method and object[method]) then return false end
	object[method](object, ...)
	return true
end

function AuraUtil.RegisterNativeStealableGlowTextures(button, glow, dispelTextureStyles, stealableFilters)
	if not (button and glow and glow.GetRegions and dispelTextureStyles and dispelTextureStyles.PreserveAsset and stealableFilters and stealableFilters.Stealable) then return false end
	local registered = 0
	local regions = { glow:GetRegions() }
	for i = 1, #regions do
		local region = regions[i]
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then
			local colorMap
			if CreateColor and region.GetVertexColor then
				local r, g, b, a = region:GetVertexColor()
				local color = CreateColor(r or 1, g or 0.82, b or 0.2, a or 1)
				colorMap = {
					None = color,
					Magic = color,
					Curse = color,
					Disease = color,
					Poison = color,
					Bleed = color,
				}
			end
			if
				AuraUtil.CallNativeAuraMethod(button, "AddDispelTypeTexture", region, {
					style = dispelTextureStyles.PreserveAsset,
					showWhenHarmful = false,
					showWhenHelpful = true,
					showWithoutDispelType = true,
					stealableFilter = stealableFilters.Stealable,
					customDispelColorMap = colorMap,
				})
			then
				registered = registered + 1
			end
		end
	end
	return registered > 0
end

function AuraUtil.RegisterNativeStealableBorder(button, inset, dispelTextureStyles, stealableFilters)
	if not (button and dispelTextureStyles and stealableFilters) then return false end
	if button.stealableGlow then button.stealableGlow:Hide() end
	if not button.stealableBorder then
		local borderParent = button.nativeBorderLayer or button
		button.stealableBorder = borderParent:CreateTexture(nil, "OVERLAY")
		button.stealableBorder:SetBlendMode("ADD")
	end
	inset = AuraUtil.NormalizeStealableGlowInset(inset)
	button.stealableBorder:ClearAllPoints()
	button.stealableBorder:SetPoint("TOPLEFT", button, "TOPLEFT", -inset, inset)
	button.stealableBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", inset, -inset)
	button.stealableBorder:Show()
	return AuraUtil.CallNativeAuraMethod(button, "AddDispelTypeTexture", button.stealableBorder, {
		style = dispelTextureStyles.CustomAsset,
		showWhenHarmful = false,
		showWhenHelpful = true,
		showWithoutDispelType = true,
		stealableFilter = stealableFilters.Stealable,
		customDispelAssetMap = {
			None = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
			Magic = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
			Curse = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
			Disease = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
			Poison = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
			Bleed = { asset = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable" },
		},
	})
end

function AuraUtil.RegisterNativeDispelBorderTexture(button, texture, options)
	if not (button and texture and options) then return false end
	return AuraUtil.CallNativeAuraMethod(button, "AddDispelTypeTexture", texture, options)
end

function AuraUtil.RegisterNativeDispelBorderTextures(button, dispelTextureStyles, borderKind, textureCount)
	if not (button and dispelTextureStyles and dispelTextureStyles.PreserveAsset) then return false end
	local options = AuraUtil.nativeDispelBorderOptions
	if not options or options.style ~= dispelTextureStyles.PreserveAsset then
		options = {
			style = dispelTextureStyles.PreserveAsset,
			showWhenHarmful = true,
			showWhenHelpful = false,
			showWithoutDispelType = true,
		}
		AuraUtil.nativeDispelBorderOptions = options
	end
	local registered = false
	if borderKind == "OVERLAY" then
		registered = AuraUtil.RegisterNativeDispelBorderTexture(button, button.nativeStyleBorder, options)
	elseif borderKind == "SHAPE" then
		local shapeTextures = button._eqolNativeAuraShapeBorderTextures
		for i = 1, textureCount or 0 do
			if AuraUtil.RegisterNativeDispelBorderTexture(button, shapeTextures[i], options) then registered = true end
		end
	elseif borderKind == "EDGE" then
		local borderFrame = button.nativeStyleBorderFrame
		local borderState = borderFrame and borderFrame._eqolNativeAuraSafeBorder
		if borderState then
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.top, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.bottom, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.left, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.right, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.topLeft, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.topRight, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.bottomLeft, options) then registered = true end
			if AuraUtil.RegisterNativeDispelBorderTexture(button, borderState.bottomRight, options) then registered = true end
		end
	end
	return registered
end

function AuraUtil.GetNativeAuraLaneStore(st)
	if not st then return nil end
	st.nativeAuraContainers = st.nativeAuraContainers or {}
	return st.nativeAuraContainers
end

function AuraUtil.PrecreateNativeAuraContainers(st)
	if not (st and st.frame and addon.AuraCompat and addon.AuraCompat.CreateAuraContainer) then return end
	local store = AuraUtil.GetNativeAuraLaneStore(st)
	for _, key in ipairs({ "buff", "debuff", "combined" }) do
		local lane = store[key]
		if not (lane and lane.container) then
			store[key] = { container = addon.AuraCompat:CreateAuraContainer(st.frame), generation = 0 }
		end
	end
end

function AuraUtil.DisableNativeAuraLane(lane)
	if not (lane and lane.container) then return end
	if addon.AuraCompat and addon.AuraCompat.DisableAuraContainer then
		addon.AuraCompat:DisableAuraContainer(lane.container)
	else
		AuraUtil.CallNativeAuraMethod(lane.container, "SetEnabled", false)
		lane.container:Hide()
	end
	if lane.container.SetAlpha then lane.container:SetAlpha(0) end
end

function AuraUtil.HideNativeAuraContainers(st)
	local store = st and st.nativeAuraContainers
	if st then AuraUtil.ClearNativeAuraIdentityPlan(st) end
	if not store then return end
	for _, lane in pairs(store) do
		AuraUtil.DisableNativeAuraLane(lane)
	end
end

function AuraUtil.ClearNativeAuraIdentityPlan(st)
	if not st then return end
	st._nativeAuraIdentityRefreshEnabled = nil
	st._nativeAuraIdentityBuffContainer = nil
	st._nativeAuraIdentityDebuffContainer = nil
end

function AuraUtil.CacheNativeAuraIdentityPlan(st, unit, auraRuntime)
	AuraUtil.ClearNativeAuraIdentityPlan(st)
	if not (st and AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, false)) then return end
	local store = st.nativeAuraContainers
	if auraRuntime.combineLayout then
		local lane = store and store.combined
		if not (lane and lane.container and lane.groups) then return end
		if auraRuntime.showBuffs and not (lane.groups.buff and lane.groups.buff.key) then return end
		if auraRuntime.showDebuffs and not (lane.groups.debuff and lane.groups.debuff.key) then return end
		st._nativeAuraIdentityBuffContainer = auraRuntime.showBuffs and lane.container or nil
		st._nativeAuraIdentityDebuffContainer = auraRuntime.showDebuffs and lane.container or nil
		st._nativeAuraIdentityRefreshEnabled = st._nativeAuraIdentityBuffContainer ~= nil or st._nativeAuraIdentityDebuffContainer ~= nil
		return
	end
	local buffLane = auraRuntime.showBuffs and store and store.buff or nil
	local debuffLane = auraRuntime.showDebuffs and store and store.debuff or nil
	if auraRuntime.showBuffs and not (buffLane and buffLane.container and buffLane.groupKey) then return end
	if auraRuntime.showDebuffs and not (debuffLane and debuffLane.container and debuffLane.groupKey) then return end
	st._nativeAuraIdentityBuffContainer = buffLane and buffLane.container or nil
	st._nativeAuraIdentityDebuffContainer = debuffLane and debuffLane.container or nil
	st._nativeAuraIdentityRefreshEnabled = st._nativeAuraIdentityBuffContainer ~= nil or st._nativeAuraIdentityDebuffContainer ~= nil
end

function AuraUtil.RefreshCompiledNativeAuraContainers(st)
	if not (st and st._nativeAuraIdentityRefreshEnabled and addon.AuraCompat and addon.AuraCompat.UpdateAuraContainer) then return false end
	local refreshed = false
	if st._nativeAuraIdentityBuffContainer then
		if not addon.AuraCompat:UpdateAuraContainer(st._nativeAuraIdentityBuffContainer) then return false end
		refreshed = true
	end
	if st._nativeAuraIdentityDebuffContainer and st._nativeAuraIdentityDebuffContainer ~= st._nativeAuraIdentityBuffContainer then
		if not addon.AuraCompat:UpdateAuraContainer(st._nativeAuraIdentityDebuffContainer) then return false end
		refreshed = true
	end
	return refreshed
end

function AuraUtil.RefreshNativeAuraContainers(st, unit, auraRuntime)
	local store = st and st.nativeAuraContainers
	if not (store and unit and auraRuntime and addon.AuraCompat and addon.AuraCompat.UpdateAuraContainer) then return false end
	if auraRuntime.combineLayout then
		local lane = store.combined
		if not (lane and lane.container and lane.groups) then return false end
		if auraRuntime.showBuffs and not lane.groups.buff then return false end
		if auraRuntime.showDebuffs and not lane.groups.debuff then return false end
		if lane.unit ~= unit then
			if not AuraUtil.CallNativeAuraMethod(lane.container, "SetUnit", unit) then return false end
			lane.unit = unit
		end
		if not addon.AuraCompat:UpdateAuraContainer(lane.container) then return false end
		AuraUtil.CacheNativeAuraIdentityPlan(st, unit, auraRuntime)
		return true
	end
	local refreshed = false
	for index = 1, 2 do
		local key = index == 1 and "buff" or "debuff"
		local enabled = key == "buff" and auraRuntime.showBuffs or false
		if key == "debuff" then enabled = auraRuntime.showDebuffs end
		if enabled then
			local lane = store[key]
			if not (lane and lane.container and lane.groupKey) then return false end
			if lane.unit ~= unit then
				if not AuraUtil.CallNativeAuraMethod(lane.container, "SetUnit", unit) then return false end
				lane.unit = unit
			end
			if not addon.AuraCompat:UpdateAuraContainer(lane.container) then return false end
			refreshed = true
		end
	end
	if refreshed then AuraUtil.CacheNativeAuraIdentityPlan(st, unit, auraRuntime) end
	return refreshed
end

function AuraUtil.BuildNativeAuraCandidateFilters(unit, hidePermanentAuras, isDebuff)
	local candidateFilters = {}
	if hidePermanentAuras == true then candidateFilters.maxDuration = math.huge end
	local ignoredSpellIDs = UF.GlobalAuraIgnore and UF.GlobalAuraIgnore.GetIgnoredSpellIDs and UF.GlobalAuraIgnore.GetIgnoredSpellIDs(unit)
	local healerBuffSpellIDs = isDebuff ~= true and AuraUtil.GetHealerBuffPlacementExcludedSpellIDs and AuraUtil.GetHealerBuffPlacementExcludedSpellIDs(unit) or nil
	if ignoredSpellIDs and not healerBuffSpellIDs then
		candidateFilters.excludeSpellIDs = ignoredSpellIDs
	elseif healerBuffSpellIDs then
		local excludedSpellIDs = {}
		for spellID, enabled in pairs(ignoredSpellIDs or EMPTY) do
			if enabled == true then excludedSpellIDs[spellID] = true end
		end
		for spellID, enabled in pairs(healerBuffSpellIDs) do
			if enabled == true then excludedSpellIDs[spellID] = true end
		end
		if next(excludedSpellIDs) then candidateFilters.excludeSpellIDs = excludedSpellIDs end
	end
	return candidateFilters
end

function AuraUtil.RefreshNativeAuraIgnoreFilters(unit)
	local store = unit and states[unit] and states[unit].nativeAuraContainers
	if not (store and addon.AuraCompat and addon.AuraCompat.UpdateAuraGroup) then return false end
	local refreshed = false
	for _, lane in pairs(store) do
		if lane and lane.container and lane.groupKey then
			local candidateFilters = AuraUtil.BuildNativeAuraCandidateFilters(unit, lane.hidePermanentAuras, lane.isDebuff)
			if addon.AuraCompat:UpdateAuraGroup(lane.container, lane.groupKey, { candidateFilters = candidateFilters }) then
				lane.candidateFilters = candidateFilters
				refreshed = true
			end
		elseif lane and lane.container and lane.groups then
			for kind, group in pairs(lane.groups) do
				local candidateFilters = AuraUtil.BuildNativeAuraCandidateFilters(unit, group.hidePermanentAuras, kind == "debuff")
				if addon.AuraCompat:UpdateAuraGroup(lane.container, group.key, { candidateFilters = candidateFilters }) then
					group.candidateFilters = candidateFilters
					refreshed = true
				end
				lane.groups[kind] = group
			end
		end
	end
	return refreshed
end

local normalizeStrataToken

function AuraUtil.SyncNativePlayerAuraButtonLayer(button, parent, style, unit)
	if not (button and parent and unit == UNIT.PLAYER) then return end
	style = style or {}
	local targetStrata = normalizeStrataToken and normalizeStrataToken(style.strata) or nil
	if not targetStrata and parent.GetFrameStrata then targetStrata = parent:GetFrameStrata() end
	local levelOffset = tonumber(style.frameLevelOffset)
	if levelOffset == nil then levelOffset = 5 end
	local targetLevel = levelOffset
	if parent.GetFrameLevel then targetLevel = (parent:GetFrameLevel() or 0) + levelOffset end
	if targetLevel < 0 then targetLevel = 0 end

	local function applyLayer(frame, level)
		if not frame then return end
		if targetStrata and frame.SetFrameStrata then frame:SetFrameStrata(targetStrata) end
		if frame.SetFrameLevel then frame:SetFrameLevel(level) end
	end

	applyLayer(button, targetLevel)
	applyLayer(button.cd, targetLevel + 1)
	applyLayer(button.nativeBorderLayer, targetLevel + 6)
	applyLayer(button.nativeStyleBorderFrame, targetLevel + 7)
	applyLayer(button.nativeForeground, targetLevel + 11)
end

function AuraUtil.PrepareNativeAuraButton(button, style, isDebuff, unit, parent)
	if not button then return false end
	style = style or {}
	local styleKey = AuraUtil.getAuraButtonStyleKey(style)
	if button._eqolNativeAuraStyleKey == styleKey then return true end
	button._eqolNativeAuraStyleKey = styleKey
	local size = tonumber(style.size) or 24
	button:SetSize(size, size)

	if not button.icon then
		button.icon = button:CreateTexture(nil, "ARTWORK")
		button.icon:SetAllPoints(button)
	end
	AuraUtil.CallNativeAuraMethod(button, "SetIcon", button.icon)

	if style.showCooldown ~= false then
		if not button.cd then
			button.cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
			button.cd:SetAllPoints(button)
		end
		if button.cd.SetHideCountdownNumbers then button.cd:SetHideCountdownNumbers(true) end
		if button.cd.SetDrawEdge then button.cd:SetDrawEdge(style.showCooldownEdge ~= false and AuraUtil.IsIconShapeBackdropBorderCompatible(style.iconShape)) end
		if button.cd.SetDrawBling then button.cd:SetDrawBling(style.showCooldownBling ~= false) end
		if button.cd.SetDrawSwipe then button.cd:SetDrawSwipe(style.showCooldownSwipe ~= false) end
		if button.cd.SetReverse then button.cd:SetReverse(true) end
		button.cd:Show()
		AuraUtil.CallNativeAuraMethod(button, "SetDurationCooldown", button.cd)
	else
		AuraUtil.CallNativeAuraMethod(button, "ClearDurationCooldown")
		if button.cd then button.cd:Hide() end
	end
	if not button.nativeBorderLayer then
		button.nativeBorderLayer = CreateFrame("Frame", nil, button)
		button.nativeBorderLayer:EnableMouse(false)
		button.nativeBorderLayer:SetAllPoints(button)
	end
	if not button.nativeForeground then
		button.nativeForeground = CreateFrame("Frame", nil, button)
		button.nativeForeground:EnableMouse(false)
		button.nativeForeground:SetAllPoints(button)
	end
	if button.cd and button.nativeBorderLayer then
		button.nativeBorderLayer:SetFrameStrata(button.cd:GetFrameStrata())
		button.nativeBorderLayer:SetFrameLevel(button.cd:GetFrameLevel() + 5)
		button.nativeBorderLayer:Show()
	end
	if button.cd and button.nativeForeground then
		button.nativeForeground:SetFrameStrata(button.cd:GetFrameStrata())
		button.nativeForeground:SetFrameLevel(button.cd:GetFrameLevel() + 10)
		button.nativeForeground:Show()
	end

	if style.showCooldownText ~= false then
		if not button.durationText then
			button.durationText = (button.nativeForeground or button):CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		end
		button.durationText:ClearAllPoints()
		button.durationText:SetDrawLayer("OVERLAY", 3)
		button.durationText:SetPoint(style.cooldownAnchor or "CENTER", button.nativeForeground or button, style.cooldownAnchor or "CENTER", (style.cooldownOffset and style.cooldownOffset.x) or 0, (style.cooldownOffset and style.cooldownOffset.y) or 0)
		if UFHelper and UFHelper.applyFont then UFHelper.applyFont(button.durationText, style.cooldownFont, style.cooldownFontSize or 12, style.cooldownFontOutline) end
		button.durationText:Show()
		local durationOptions = addon.functions and addon.functions.GetAuraButtonDurationTextOptions and addon.functions.GetAuraButtonDurationTextOptions(style.durationTextProfile)
		AuraUtil.CallNativeAuraMethod(button, "SetDurationText", button.durationText, durationOptions)
	else
		AuraUtil.CallNativeAuraMethod(button, "ClearDurationText")
		if button.durationText then button.durationText:Hide() end
	end

	if style.showStacks ~= false then
		if not button.count then
			button.count = (button.nativeForeground or button):CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		end
		button.count:ClearAllPoints()
		button.count:SetDrawLayer("OVERLAY", 4)
		button.count:SetPoint(style.countAnchor or "BOTTOMRIGHT", button.nativeForeground or button, style.countAnchor or "BOTTOMRIGHT", (style.countOffset and style.countOffset.x) or -2, (style.countOffset and style.countOffset.y) or 2)
		if UFHelper and UFHelper.applyFont then UFHelper.applyFont(button.count, style.countFont, style.countFontSize or 14, style.countFontOutline) end
		button.count:Show()
		AuraUtil.CallNativeAuraMethod(button, "SetApplicationCount", button.count, {})
	else
		AuraUtil.CallNativeAuraMethod(button, "ClearApplicationCount")
		if button.count then button.count:Hide() end
	end

	AuraUtil.CallNativeAuraMethod(button, "ClearDispelTypeTextures")
	local dispelTextureStyles = Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
	local stealableFilters = Enum and Enum.CustomAuraButtonDispelTypeStealableFilter
	if isDebuff and style.blizzardDispelBorder == true and dispelTextureStyles then
		if not button.dispelIcon then
			button.dispelIcon = (button.nativeForeground or button):CreateTexture(nil, "OVERLAY")
		end
		button.dispelIcon:ClearAllPoints()
		button.dispelIcon:SetPoint("TOPLEFT", button.nativeForeground or button, "TOPLEFT", 1, -1)
		button.dispelIcon:SetSize(size * 0.4, size * 0.4)
		button.dispelIcon:SetDrawLayer("OVERLAY", 6)
		button.dispelIcon:Show()
		AuraUtil.CallNativeAuraMethod(button, "AddDispelTypeTexture", button.dispelIcon, {
			style = dispelTextureStyles.Icon,
			showWhenHarmful = true,
			showWhenHelpful = false,
		})
	else
		if button.dispelIcon then button.dispelIcon:Hide() end
	end
	if button.auraBorder then button.auraBorder:Hide() end
	if not isDebuff and style.blizzardStealableBorder ~= false and dispelTextureStyles and stealableFilters then
		local glowStyle = AuraUtil.NormalizeStealableGlowStyle(style.blizzardStealableGlowStyle)
		local glowInset = AuraUtil.NormalizeStealableGlowInset(style.blizzardStealableGlowInset)
		local registered
		if glowStyle ~= "DEFAULT" and addon.Glow and addon.Glow.CreateRestrictedAura then
			if button.stealableBorder then button.stealableBorder:Hide() end
			if button.stealableGlow then button.stealableGlow:Hide() end
			button.stealableGlow = addon.Glow.CreateRestrictedAura(button, button, {
				style = glowStyle,
				inset = glowInset,
				color = { 1, 0.82, 0.2, 1 },
				count = 8,
				frequency = 0.25,
				thickness = 2,
				shape = style.iconShape,
				width = size,
				height = size,
				frameLevelOffset = 15,
			})
			registered = AuraUtil.RegisterNativeStealableGlowTextures(button, button.stealableGlow, dispelTextureStyles, stealableFilters)
			if not registered and button.stealableGlow then button.stealableGlow:Hide() end
		end
		if not registered then AuraUtil.RegisterNativeStealableBorder(button, glowInset, dispelTextureStyles, stealableFilters) end
	else
		if button.stealableBorder then button.stealableBorder:Hide() end
		if button.stealableGlow then button.stealableGlow:Hide() end
	end

	if isDebuff and style.blizzardDispelBorder == true then
		if not button.auraSymbol then
			button.auraSymbol = (button.nativeForeground or button):CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		end
		button.auraSymbol:ClearAllPoints()
		button.auraSymbol:SetDrawLayer("OVERLAY", 5)
		button.auraSymbol:SetPoint("BOTTOMRIGHT", button.nativeForeground or button, "BOTTOMRIGHT", -1, 1)
		if UFHelper and UFHelper.applyFont then UFHelper.applyFont(button.auraSymbol, style.countFont, math.min(style.countFontSize or 14, 14), style.countFontOutline) end
		button.auraSymbol:Show()
		AuraUtil.CallNativeAuraMethod(button, "SetDispelTypeText", button.auraSymbol, {
			showWhenHarmful = true,
			showWhenHelpful = false,
		})
	else
		AuraUtil.CallNativeAuraMethod(button, "ClearDispelTypeText")
		if button.auraSymbol then button.auraSymbol:Hide() end
	end

	local showTooltip = style.showTooltip ~= false
	local canCancel = unit == UNIT.PLAYER and not isDebuff
	AuraUtil.CallNativeAuraMethod(button, "SetCancelAuraButtons", canCancel and "RightButtonUp" or nil)
	AuraUtil.CallNativeAuraMethod(button, "EnableMouse", showTooltip or canCancel)
	AuraUtil.CallNativeAuraMethod(button, "SetMouseClickEnabled", canCancel)
	AuraUtil.CallNativeAuraMethod(button, "SetMouseMotionEnabled", showTooltip)
	local tooltipOffset = style.tooltipOffset
	AuraUtil.CallNativeAuraMethod(
		button,
		"SetTooltipAnchorPoint",
		style.tooltipAnchor or "ANCHOR_BOTTOMRIGHT",
		(tooltipOffset and tooltipOffset.x) or 0,
		(tooltipOffset and tooltipOffset.y) or 0
	)
	if addon.AuraCompat and addon.AuraCompat.RegisterAuraButtonTooltipPolicy then
		addon.AuraCompat:RegisterAuraButtonTooltipPolicy(button, style.hideTooltipInCombat == true, showTooltip)
	else
		AuraUtil.CallNativeAuraMethod(button, "SetHideTooltipInCombat", AuraUtil.ShouldHideNativeAuraTooltipInCombat(style))
	end
	AuraUtil.ApplyIconShape(button, style.iconShape, style.iconZoom)
	local hasStyleBorder, borderKind, borderTextureCount = AuraUtil.PrepareNativeAuraStyleBorder(button, style, isDebuff)
	if isDebuff and hasStyleBorder then AuraUtil.RegisterNativeDispelBorderTextures(button, dispelTextureStyles, borderKind, borderTextureCount) end
	if button.externalGlow then button.externalGlow:Hide() end
	if style.externalGlowEnabled == true and addon.Glow and addon.Glow.CreateRestrictedAura then
		local color = style.externalGlowColor or {}
		button.externalGlow = addon.Glow.CreateRestrictedAura(button, button, {
			style = style.externalGlowStyle,
			inset = style.externalGlowInset,
			color = {
				color[1] or color.r or 1,
				color[2] or color.g or 0.25,
				color[3] or color.b or 0.25,
				color[4] or color.a or 1,
			},
			shape = style.iconShape,
			width = size,
			height = size,
			frameLevelOffset = 8,
		})
	end
	AuraUtil.SyncNativePlayerAuraButtonLayer(button, parent, style, unit)
	return true
end

function AuraUtil.PrepareNativeAuraStyleBorder(button, style, isDebuff)
	if not button then return false end
	style = style or {}
	local borderKey = style.borderTexture
	local borderKeyName = borderKey and tostring(borderKey):upper() or "DEFAULT"
	local customColor = type(style.borderColor) == "table"
	local showCustomBorder = borderKeyName ~= "" and borderKeyName ~= "DEFAULT" and borderKeyName ~= "NONE"
	local showStyleBorder = borderKeyName ~= "NONE" and (isDebuff == true or showCustomBorder or customColor)
	if not showStyleBorder then
		if button.nativeStyleBorder then button.nativeStyleBorder:Hide() end
		return false
	end
	local borderParent = button.nativeForeground or button
	if button.nativeStyleBorder and button.nativeStyleBorder.GetParent and button.nativeStyleBorder:GetParent() ~= borderParent then
		button.nativeStyleBorder:Hide()
		button.nativeStyleBorder = nil
	end
	if not button.nativeStyleBorder then
		button.nativeStyleBorder = borderParent:CreateTexture(nil, "OVERLAY")
	end
	button.nativeStyleBorder:SetDrawLayer("OVERLAY", 1)
	local borderTex, borderCoords, borderIsEdge
	if UFHelper and UFHelper.resolveAuraBorderTexture then
		borderTex, borderCoords, borderIsEdge = UFHelper.resolveAuraBorderTexture(borderKey)
	else
		borderTex = "Interface\\Buttons\\UI-Debuff-Overlays"
		borderCoords = { 0.296875, 0.5703125, 0, 0.515625 }
		borderIsEdge = false
	end
	if not borderTex or borderTex == "" then
		button.nativeStyleBorder:Hide()
		if button.nativeStyleBorderFrame and addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(button.nativeStyleBorderFrame, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolNativeAuraSafeBorder" })
		elseif button.nativeStyleBorderFrame then
			button.nativeStyleBorderFrame:Hide()
		end
		return false
	end
	local borderSize = (UFHelper and UFHelper.calcAuraBorderSize and UFHelper.calcAuraBorderSize(button, style)) or 1
	local borderOffset = tonumber(style.borderOffset) or 0
	local borderMode = tostring(style.borderRenderMode or "EDGE"):upper()
	local useEdgeBorder = borderIsEdge and borderMode ~= "OVERLAY"
	local color = style.borderColor
	local r, g, b, a
	if customColor then
		r, g, b, a = color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1
	elseif isDebuff then
		r, g, b, a = 1, 0.25, 0.25, 1
	else
		r, g, b, a = 1, 1, 1, 1
	end
	if not AuraUtil.IsIconShapeBackdropBorderCompatible(style.iconShape) and addon.IconShape and addon.IconShape.ApplyBorder then
		if button.nativeStyleBorder then button.nativeStyleBorder:Hide() end
		if button.nativeStyleBorderFrame and addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(button.nativeStyleBorderFrame, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolNativeAuraSafeBorder" })
		elseif button.nativeStyleBorderFrame then
			button.nativeStyleBorderFrame:Hide()
		end
		local shapeBorderParent = button.nativeBorderLayer or button
		local ok, _, borderInfo = addon.IconShape.ApplyBorder(button, borderKey, style.iconShape, {
			borderSize = borderSize,
			borderOffset = borderOffset,
			color = { r, g, b, a },
			pointFrame = shapeBorderParent,
			parent = shapeBorderParent,
			texturesKey = "_eqolNativeAuraShapeBorderTextures",
			allowNone = true,
		})
		if ok then
			local textureCount = borderInfo and borderInfo.thicknessMode == "layers" and math.min(math.floor(borderSize + 0.5), 24) or 1
			return true, "SHAPE", textureCount
		end
	end
	AuraUtil.HideIconShapeBorderTextures(button)
	if useEdgeBorder then
		if button.nativeStyleBorder then button.nativeStyleBorder:Hide() end
		local edgeParent = button.nativeBorderLayer or button
		if not button.nativeStyleBorderFrame then
			button.nativeStyleBorderFrame = CreateFrame("Frame", nil, edgeParent)
			button.nativeStyleBorderFrame:EnableMouse(false)
		end
		if button.nativeStyleBorderFrame.SetFrameStrata and edgeParent.GetFrameStrata then button.nativeStyleBorderFrame:SetFrameStrata(edgeParent:GetFrameStrata()) end
		if button.nativeStyleBorderFrame.SetFrameLevel and edgeParent.GetFrameLevel then button.nativeStyleBorderFrame:SetFrameLevel(edgeParent:GetFrameLevel() + 1) end
		local anchorInset = (borderSize * 0.5) - borderOffset
		button.nativeStyleBorderFrame:ClearAllPoints()
		button.nativeStyleBorderFrame:SetPoint("TOPLEFT", edgeParent, "TOPLEFT", anchorInset, -anchorInset)
		button.nativeStyleBorderFrame:SetPoint("BOTTOMRIGHT", edgeParent, "BOTTOMRIGHT", -anchorInset, anchorInset)
		if addon.functions and addon.functions.SetSafeBorder then
			addon.functions.SetSafeBorder(button.nativeStyleBorderFrame, true, borderTex, borderSize, r, g, b, a, {
				stateKey = "_eqolNativeAuraSafeBorder",
				defaultTexture = "Interface\\Buttons\\WHITE8x8",
				drawLayer = "OVERLAY",
			})
		else
			button.nativeStyleBorderFrame:Show()
		end
		return true, "EDGE"
	end
	if button.nativeStyleBorderFrame and addon.functions and addon.functions.SetSafeBorder then
		addon.functions.SetSafeBorder(button.nativeStyleBorderFrame, false, nil, nil, nil, nil, nil, nil, { stateKey = "_eqolNativeAuraSafeBorder" })
	elseif button.nativeStyleBorderFrame then
		button.nativeStyleBorderFrame:Hide()
	end
	local inset = borderOffset - (borderSize * 0.5)
	button.nativeStyleBorder:SetTexture(borderTex)
	if borderCoords then
		button.nativeStyleBorder:SetTexCoord(borderCoords[1], borderCoords[2], borderCoords[3], borderCoords[4])
	else
		button.nativeStyleBorder:SetTexCoord(0, 1, 0, 1)
	end
	button.nativeStyleBorder:ClearAllPoints()
	button.nativeStyleBorder:SetPoint("TOPLEFT", borderParent, "TOPLEFT", inset, -inset)
	button.nativeStyleBorder:SetPoint("BOTTOMRIGHT", borderParent, "BOTTOMRIGHT", -inset, inset)
	button.nativeStyleBorder:SetVertexColor(r, g, b, a)
	button.nativeStyleBorder:Show()
	return true, "OVERLAY"
end

function AuraUtil.EnsureNativeAuraLane(st, key, unit, style, filterString, isDebuff)
	if not (st and st.frame and addon.AuraCompat and addon.AuraCompat:HasAuraContainerSupport()) then return nil end
	local store = AuraUtil.GetNativeAuraLaneStore(st)
	if not store then return nil end
	local lane = store[key]
	local maxCount = AuraUtil.normalizeAuraQueryLimit(style and style.max) or 0
	if maxCount < 1 then return nil end
	local signature = table.concat({
		tostring(unit),
		tostring(filterString),
		tostring(isDebuff == true),
		tostring(maxCount),
		tostring(style and style.hidePermanentAuras == true),
		AuraUtil.getAuraButtonStyleKey(style),
		unit == UNIT.PLAYER and tostring(st.frame.GetFrameStrata and st.frame:GetFrameStrata() or "") or "",
		unit == UNIT.PLAYER and tostring(st.frame.GetFrameLevel and st.frame:GetFrameLevel() or "") or "",
	}, "\031")
	if lane and lane.signature == signature then
		return lane
	end
	local container = lane and lane.container
	local generation = (lane and lane.generation or 0) + 1
	if lane and lane.groupKey and container then
		addon.AuraCompat:UpdateAuraGroup(container, lane.groupKey, { maxFrameCount = 0 })
	end
	lane = {
		filterString = filterString,
		max = maxCount,
		signature = signature,
		isDebuff = isDebuff == true,
		hidePermanentAuras = style and style.hidePermanentAuras == true,
		unit = unit,
		container = container or addon.AuraCompat:CreateAuraContainer(st.frame),
		generation = generation,
	}
	if not lane.container then return nil end
	AuraUtil.CallNativeAuraMethod(lane.container, "SetUnit", unit)
	local candidateFilters = AuraUtil.BuildNativeAuraCandidateFilters(unit, lane.hidePermanentAuras, lane.isDebuff)
	lane.candidateFilters = candidateFilters
	lane.groupKey = key .. ":" .. tostring(generation)
	local initializedStyle = style
	local initializedIsDebuff = isDebuff == true
	local registered = addon.AuraCompat:RegisterAuraGroup(lane.container, lane.groupKey, filterString, {
		maxFrameCount = maxCount,
		candidateFilters = candidateFilters,
		initializeFrame = function(button) AuraUtil.PrepareNativeAuraButton(button, initializedStyle, initializedIsDebuff, unit, st.frame) end,
		layout = {
			elementSpacing = tonumber(style and style.padding) or 0,
			lineSpacing = tonumber(style and style.padding) or 0,
			elementWidth = tonumber(style and style.size) or 24,
			elementHeight = tonumber(style and style.size) or 24,
			layoutIndex = 1,
		},
	})
	if not registered then
		AuraUtil.CallNativeAuraMethod(lane.container, "SetEnabled", false)
		lane.container:Hide()
		return nil
	end
	lane.container:Show()
	store[key] = lane
	return lane
end

function AuraUtil.EnsureNativeCombinedAuraLane(st, unit, auraRuntime, helpfulFilter, harmfulFilter)
	if not (st and st.frame and auraRuntime and addon.AuraCompat and addon.AuraCompat:HasAuraContainerSupport()) then return nil end
	local store = AuraUtil.GetNativeAuraLaneStore(st)
	if not store then return nil end
	local lane = store.combined
	local buffStyle = auraRuntime.buff or {}
	local debuffStyle = auraRuntime.debuff or {}
	local signature = table.concat({
		tostring(unit),
		tostring(auraRuntime.showBuffs),
		tostring(auraRuntime.showDebuffs),
		tostring(helpfulFilter),
		tostring(harmfulFilter),
		tostring(buffStyle.hidePermanentAuras == true),
		tostring(debuffStyle.hidePermanentAuras == true),
		tostring(buffStyle.max),
		tostring(debuffStyle.max),
		AuraUtil.getAuraButtonStyleKey(buffStyle),
		AuraUtil.getAuraButtonStyleKey(debuffStyle),
		unit == UNIT.PLAYER and tostring(st.frame.GetFrameStrata and st.frame:GetFrameStrata() or "") or "",
		unit == UNIT.PLAYER and tostring(st.frame.GetFrameLevel and st.frame:GetFrameLevel() or "") or "",
	}, "\031")
	if lane and lane.signature == signature then return lane end

	local container = lane and lane.container
	if lane and lane.groups and container then
		for _, group in pairs(lane.groups) do
			if group.key then addon.AuraCompat:UpdateAuraGroup(container, group.key, { maxFrameCount = 0 }) end
		end
	end
	local generation = (lane and lane.generation or 0) + 1
	lane = {
		container = container or addon.AuraCompat:CreateAuraContainer(st.frame),
		generation = generation,
		groups = {},
		signature = signature,
		unit = unit,
	}
	if not lane.container then return nil end
	AuraUtil.CallNativeAuraMethod(lane.container, "SetUnit", unit)

	local function register(kind, style, filterString, isDebuff, layoutIndex)
		local maxCount = AuraUtil.normalizeAuraQueryLimit(style and style.max) or 0
		if maxCount < 1 then return false end
		local hidePermanentAuras = style and style.hidePermanentAuras == true
		local candidateFilters = AuraUtil.BuildNativeAuraCandidateFilters(unit, hidePermanentAuras, isDebuff)
		local groupKey = "combined-" .. kind .. ":" .. tostring(generation)
		local registered = addon.AuraCompat:RegisterAuraGroup(lane.container, groupKey, filterString, {
			maxFrameCount = maxCount,
			candidateFilters = candidateFilters,
			initializeFrame = function(button) AuraUtil.PrepareNativeAuraButton(button, style, isDebuff, unit, st.frame) end,
			layout = {
				elementSpacing = tonumber(style and style.padding) or 0,
				lineSpacing = tonumber(style and style.padding) or 0,
				elementWidth = tonumber(style and style.size) or 24,
				elementHeight = tonumber(style and style.size) or 24,
				layoutIndex = layoutIndex,
			},
		})
		if not registered then return false end
		lane.groups[kind] = {
			key = groupKey,
			max = maxCount,
			candidateFilters = candidateFilters,
			hidePermanentAuras = hidePermanentAuras,
			style = style,
			layoutIndex = layoutIndex,
		}
		return true
	end

	if auraRuntime.showBuffs and not register("buff", buffStyle, helpfulFilter, false, 1) then return nil end
	if auraRuntime.showDebuffs and not register("debuff", debuffStyle, harmfulFilter, true, 2) then return nil end
	store.combined = lane
	return lane
end

function AuraUtil.GetNativeAuraFlowLayout(st, style, width)
	style = style or {}
	local anchor = style.anchor or "BOTTOM"
	local primary, secondary = UF._auraLayout.resolveGrowth(style, anchor, style.growth)
	local horizontal = (primary == "LEFT" or primary == "RIGHT") and primary or secondary
	local vertical = (primary == "UP" or primary == "DOWN") and primary or secondary
	if horizontal ~= "LEFT" and horizontal ~= "RIGHT" then horizontal = "RIGHT" end
	if vertical ~= "UP" and vertical ~= "DOWN" then vertical = "DOWN" end

	local perRow = UF._auraLayout.calcPerRow(st, style, width, primary)
	local size = tonumber(style.size) or 24
	local spacing = tonumber(style.padding) or 0
	local maximumLineSize = math.max(size, (perRow * size) + (math.max(perRow - 1, 0) * spacing))
	local horizontalPoint = horizontal == "RIGHT" and "LEFT" or "RIGHT"
	local verticalPoint = vertical == "UP" and "BOTTOM" or "TOP"
	local flowAxes = AnchorUtil and AnchorUtil.FlowLayoutAxis
	if not flowAxes then return nil end
	return {
		anchor = anchor,
		primary = primary,
		secondary = secondary,
		horizontal = horizontal,
		vertical = vertical,
		axis = (primary == "UP" or primary == "DOWN") and flowAxes.Vertical or flowAxes.Horizontal,
		anchorPoint = verticalPoint .. horizontalPoint,
		horizontalGrowthDirection = horizontal == "RIGHT" and 1 or -1,
		verticalGrowthDirection = vertical == "UP" and 1 or -1,
		maximumLineSize = maximumLineSize,
		perRow = perRow,
		size = size,
		spacing = spacing,
	}
end

function AuraUtil.GetNativeCombinedAuraFlowLayout(st, auraRuntime, width)
	local primaryStyle = auraRuntime.showBuffs and auraRuntime.buff or auraRuntime.debuff
	if not primaryStyle then return nil end
	local flowStyle = CopyTable(primaryStyle)
	local buffSize = auraRuntime.showBuffs and tonumber(auraRuntime.buff and auraRuntime.buff.size) or 0
	local debuffSize = auraRuntime.showDebuffs and tonumber(auraRuntime.debuff and auraRuntime.debuff.size) or 0
	flowStyle.size = math.max(buffSize or 0, debuffSize or 0, 1)
	flowStyle.padding = tonumber(primaryStyle.padding) or 0
	return AuraUtil.GetNativeAuraFlowLayout(st, flowStyle, width), primaryStyle
end

function AuraUtil.PositionNativeAuraLane(st, container, style, flow)
	if not (st and container and style and flow and st.barGroup) then return false end
	local anchor = flow.anchor
	local defAx, defAy = UF._auraLayout.defaultOffset(anchor)
	local ax = style.offset and style.offset.x
	if ax == nil then ax = defAx end
	local ay = style.offset and style.offset.y
	if ay == nil then ay = defAy end
	local horizontalPoint = flow.horizontal == "RIGHT" and "LEFT" or "RIGHT"
	local verticalPoint = flow.vertical == "UP" and "BOTTOM" or "TOP"
	local point, relativePoint
	if anchor == "TOP" then
		point = "BOTTOM" .. horizontalPoint
		relativePoint = "TOP" .. horizontalPoint
	elseif anchor == "LEFT" then
		point = verticalPoint .. (flow.horizontal == "RIGHT" and "LEFT" or "RIGHT")
		relativePoint = verticalPoint .. "LEFT"
	elseif anchor == "RIGHT" then
		point = verticalPoint .. (flow.horizontal == "RIGHT" and "LEFT" or "RIGHT")
		relativePoint = verticalPoint .. "RIGHT"
	else
		point = "TOP" .. horizontalPoint
		relativePoint = "BOTTOM" .. horizontalPoint
	end
	container:ClearAllPoints()
	container:SetPoint(point, st.barGroup, relativePoint, ax or 0, ay or 0)
	return true
end

function AuraUtil.LayoutNativeAuraLane(st, lane, style, width)
	if not (st and lane and lane.container and style) then return false end
	local flow = AuraUtil.GetNativeAuraFlowLayout(st, style, width)
	if not flow then return false end
	AuraUtil.PositionNativeAuraLane(st, lane.container, style, flow)
	addon.AuraCompat:ConfigureAuraContainerLayout(lane.container, {
		axis = flow.axis,
		anchorPoint = flow.anchorPoint,
		horizontalGrowthDirection = flow.horizontalGrowthDirection,
		verticalGrowthDirection = flow.verticalGrowthDirection,
		maximumLineSize = flow.maximumLineSize,
	})
	addon.AuraCompat:UpdateAuraGroup(lane.container, lane.groupKey, {
		maxFrameCount = lane.max,
		candidateFilters = lane.candidateFilters,
		layout = {
			elementSpacing = flow.spacing,
			lineSpacing = flow.spacing,
			elementWidth = flow.size,
			elementHeight = flow.size,
			layoutIndex = 1,
		},
	})
	AuraUtil.syncAuraContainerLayer(lane.container, st.frame)
	lane.container:SetAlpha(1)
	lane.container:Show()
	AuraUtil.CallNativeAuraMethod(lane.container, "SetEnabled", true)
	return true
end

function AuraUtil.LayoutNativeCombinedAuraLane(st, lane, auraRuntime, width)
	if not (st and lane and lane.container and lane.groups and auraRuntime) then return false end
	local flow, primaryStyle = AuraUtil.GetNativeCombinedAuraFlowLayout(st, auraRuntime, width)
	if not (flow and primaryStyle) then return false end
	AuraUtil.PositionNativeAuraLane(st, lane.container, primaryStyle, flow)
	if not addon.AuraCompat:ConfigureAuraContainerLayout(lane.container, {
		axis = flow.axis,
		anchorPoint = flow.anchorPoint,
		horizontalGrowthDirection = flow.horizontalGrowthDirection,
		verticalGrowthDirection = flow.verticalGrowthDirection,
		maximumLineSize = flow.maximumLineSize,
	}) then
		return false
	end
	for _, group in pairs(lane.groups) do
		if not addon.AuraCompat:UpdateAuraGroup(lane.container, group.key, {
			maxFrameCount = group.max,
			candidateFilters = group.candidateFilters,
			layout = {
				elementSpacing = flow.spacing,
				lineSpacing = flow.spacing,
				groupSpacing = flow.spacing,
				groupLineSpacing = flow.spacing,
				elementWidth = flow.size,
				elementHeight = flow.size,
				layoutIndex = group.layoutIndex,
			},
		}) then
			return false
		end
	end
	AuraUtil.syncAuraContainerLayer(lane.container, st.frame)
	lane.container:SetAlpha(1)
	lane.container:Show()
	AuraUtil.CallNativeAuraMethod(lane.container, "SetEnabled", true)
	return true
end

function AuraUtil.ApplyNativeAuraContainers(unit, st, cfg, def, forceRefresh)
	if not (unit and st and st.frame) then return false end
	local allowSample = UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit)
	cfg = cfg or st.cfg or ensureDB(unit)
	def = def or defaultsFor(unit)
	local ac = cfg.auraIcons or (def and def.auraIcons) or defaults.target.auraIcons or {}
	local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, def and def.auraIcons)
	if not AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, allowSample) then
		AuraUtil.HideNativeAuraContainers(st)
		return false
	end
	if st.auraButtons then
		for i = 1, #st.auraButtons do
			if st.auraButtons[i] then st.auraButtons[i]:Hide() end
		end
	end
	if st.debuffButtons then
		for i = 1, #st.debuffButtons do
			if st.debuffButtons[i] then st.debuffButtons[i]:Hide() end
		end
	end
	if st.auraContainer then st.auraContainer:SetShown(false) end
	if st.debuffContainer then st.debuffContainer:SetShown(false) end
	local helpfulFilter, harmfulFilter = AuraUtil.getUnitAuraFilters(unit, auraRuntime)
	local width = (st.barGroup and st.barGroup:GetWidth()) or (st.frame and st.frame:GetWidth()) or 1
	local any = false
	local store = AuraUtil.GetNativeAuraLaneStore(st)
	if auraRuntime.combineLayout then
		AuraUtil.DisableNativeAuraLane(store and store.buff)
		AuraUtil.DisableNativeAuraLane(store and store.debuff)
		local lane = AuraUtil.EnsureNativeCombinedAuraLane(st, unit, auraRuntime, helpfulFilter, harmfulFilter)
		if lane and AuraUtil.LayoutNativeCombinedAuraLane(st, lane, auraRuntime, width) then
			if forceRefresh and addon.AuraCompat then addon.AuraCompat:UpdateAuraContainer(lane.container) end
			any = true
		end
	else
		AuraUtil.DisableNativeAuraLane(store and store.combined)
	end
	if not auraRuntime.combineLayout and auraRuntime.showBuffs then
		local lane = AuraUtil.EnsureNativeAuraLane(st, "buff", unit, auraRuntime.buff, helpfulFilter, false)
		if lane then
			AuraUtil.LayoutNativeAuraLane(st, lane, auraRuntime.buff, width)
			if forceRefresh and addon.AuraCompat then addon.AuraCompat:UpdateAuraContainer(lane.container) end
			any = true
		end
	end
	if not auraRuntime.combineLayout and auraRuntime.showDebuffs then
		local lane = AuraUtil.EnsureNativeAuraLane(st, "debuff", unit, auraRuntime.debuff, harmfulFilter, true)
		if lane then
			AuraUtil.LayoutNativeAuraLane(st, lane, auraRuntime.debuff, width)
			if forceRefresh and addon.AuraCompat then addon.AuraCompat:UpdateAuraContainer(lane.container) end
			any = true
		end
	end
	store = st.nativeAuraContainers
	if store then
		if not auraRuntime.combineLayout and not auraRuntime.showBuffs and store.buff and store.buff.container then
			AuraUtil.CallNativeAuraMethod(store.buff.container, "SetEnabled", false)
			store.buff.container:Hide()
		end
		if not auraRuntime.combineLayout and not auraRuntime.showDebuffs and store.debuff and store.debuff.container then
			AuraUtil.CallNativeAuraMethod(store.debuff.container, "SetEnabled", false)
			store.debuff.container:Hide()
		end
	end
	if any then
		AuraUtil.CacheNativeAuraIdentityPlan(st, unit, auraRuntime)
	else
		AuraUtil.ClearNativeAuraIdentityPlan(st)
	end
	return any
end

AuraUtil.HEALER_BUFF_PLACEMENT_UNIT_KINDS = {
	target = "target",
	focus = "focus",
}

function AuraUtil.GetHealerBuffPlacementUnitKind(unit)
	if isBossUnit(unit) then return "boss" end
	return AuraUtil.HEALER_BUFF_PLACEMENT_UNIT_KINDS[unit]
end

function AuraUtil.GetHealerBuffPlacementExcludedSpellIDs(unit)
	local kind = AuraUtil.GetHealerBuffPlacementUnitKind(unit)
	local groupFrames = UF.GroupFrames
	local healerBuffs = UF.GroupFramesHealerBuffs
	local groupCfg = kind and groupFrames and groupFrames.GetHealerBuffPlacementConfig and groupFrames:GetHealerBuffPlacementConfig("party") or nil
	local placement = groupCfg and healerBuffs and healerBuffs.EnsureConfig and healerBuffs.EnsureConfig(groupCfg) or nil
	if not (placement and placement.enabled == true) then return nil end
	if not (UnitExists and UnitExists(unit) and UnitCanAssist and UnitCanAssist("player", unit) == true) then return nil end
	local compiled = healerBuffs.GetCompiled and healerBuffs.GetCompiled(kind, groupCfg) or nil
	if not (compiled and compiled.enabled == true) then return nil end
	return healerBuffs.GetManagedSuppressedSpellIDs and healerBuffs.GetManagedSuppressedSpellIDs(compiled) or nil
end

function AuraUtil.RefreshHealerBuffPlacementUnit(unit)
	local st = unit and states[unit]
	local frame = st and st.frame
	local healerBuffs = UF.GroupFramesHealerBuffs
	if not (frame and healerBuffs) then return false end
	local kind = AuraUtil.GetHealerBuffPlacementUnitKind(unit)
	local groupFrames = UF.GroupFrames
	local groupCfg = kind and groupFrames and groupFrames.GetHealerBuffPlacementConfig and groupFrames:GetHealerBuffPlacementConfig("party") or nil
	local placement = groupCfg and healerBuffs.EnsureConfig and healerBuffs.EnsureConfig(groupCfg) or nil
	local unitCfg = st.cfg or ensureDB(unit)
	local compiled = kind and groupCfg and healerBuffs.GetCompiled and healerBuffs.GetCompiled(kind, groupCfg) or nil
	local enabled = kind ~= nil and unitCfg and unitCfg.enabled ~= false and placement and placement.enabled == true and compiled and compiled.enabled == true

	frame._eqolUFState = st
	frame._eqolCfg = groupCfg
	frame._eqolGroupKind = kind
	frame.unit = unit
	if not enabled then
		if healerBuffs.HideManagedAuraContainer then healerBuffs.HideManagedAuraContainer(frame) end
		if healerBuffs.ClearButton then healerBuffs.ClearButton(frame) end
		AuraUtil.RefreshNativeAuraIgnoreFilters(unit)
		return false
	end

	if healerBuffs.BuildButton then healerBuffs.BuildButton(frame) end
	if healerBuffs.LayoutButton then healerBuffs.LayoutButton(frame) end
	if healerBuffs.PrecreateManagedAuraContainer then healerBuffs.PrecreateManagedAuraContainer(frame) end
	local assistable = UnitExists and UnitExists(unit) and UnitCanAssist and UnitCanAssist("player", unit) == true
	if not assistable then
		if healerBuffs.HideManagedAuraContainer then healerBuffs.HideManagedAuraContainer(frame) end
		if healerBuffs.ClearButton then healerBuffs.ClearButton(frame) end
		AuraUtil.RefreshNativeAuraIgnoreFilters(unit)
		return false
	end
	local applied = healerBuffs.ApplyManagedAuraContainer and healerBuffs.ApplyManagedAuraContainer(frame) == true or false
	AuraUtil.RefreshNativeAuraIgnoreFilters(unit)
	return applied
end

function UF.RefreshHealerBuffPlacementUnits()
	AuraUtil.RefreshHealerBuffPlacementUnit(UNIT.TARGET)
	AuraUtil.RefreshHealerBuffPlacementUnit(UNIT.FOCUS)
	for i = 1, maxBossFrames do
		AuraUtil.RefreshHealerBuffPlacementUnit("boss" .. i)
	end
end

function AuraUtil.prepareSingleAuraSectionStyle(section)
	local style = CopyTable(section or {})
	style._eqolAuraButtonStyleFontVersion = nil
	style._eqolAuraButtonStyleKey = nil
	style.size = tonumber(style.size) or 24
	local padding = tonumber(style.spacing)
	if padding == nil then padding = tonumber(style.padding) end
	style.padding = padding or 0
	style.max = AuraUtil.normalizeAuraQueryLimit(style.max) or 16
	style.iconShape = AuraUtil.NormalizeIconShape(style.iconShape, "DEFAULT")
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then style.iconZoom = addon.IconShape.NormalizeIconZoom(style.iconZoom) end
	if addon.IconShape and addon.IconShape.NormalizeBorder then style.borderTexture = addon.IconShape.NormalizeBorder(style.borderTexture, "DEFAULT", style.iconShape, { allowNone = true }) end
	if style.showTooltip == nil then style.showTooltip = true end
	if style.cooldownFontSize == nil or style.cooldownFontSize < 1 then style.cooldownFontSize = 12 end
	return style
end

function AuraUtil.getSingleAuraRelayoutThreshold(ac, defAc)
	local resolved = AuraUtil.resolveSingleAuraConfig(ac, defAc)
	local buff = AuraUtil.prepareSingleAuraSectionStyle(resolved.buff)
	local debuff = AuraUtil.prepareSingleAuraSectionStyle(resolved.debuff)
	return math.max(buff.max or 0, debuff.max or 0) + 1
end

function AuraUtil.fillSampleAuras(unit, ac, hidePermanent)
	local resolved = AuraUtil.resolveSingleAuraConfig(ac)
	local buffCfg = AuraUtil.prepareSingleAuraSectionStyle(resolved.buff)
	local debuffCfg = AuraUtil.prepareSingleAuraSectionStyle(resolved.debuff)
	local showBuffs = buffCfg.enabled ~= false
	local showDebuffs = debuffCfg.enabled ~= false
	if not showBuffs and not showDebuffs then return end
	local buffCount = showBuffs and (buffCfg.max or 0) or 0
	local debuffCount = showDebuffs and (debuffCfg.max or 0) or 0
	local now = GetTime and GetTime() or 0
	local base = unit == UNIT.PLAYER and -100000 or (unit == UNIT.TARGET or unit == "target") and -200000 or -300000
	local supportsStealablePreview = tonumber((select(4, GetBuildInfo()))) >= 120100
		and (unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit))

	local function addSampleAura(isDebuff, idx, laneIndex)
		local duration
		if idx % 3 == 0 then
			duration = 120
		elseif idx % 3 == 1 then
			duration = 30
		else
			duration = 0
		end
		local forceFinite = hidePermanent
		if not forceFinite then
			if isDebuff then
				forceFinite = debuffCfg.hidePermanentAuras == true
			else
				forceFinite = buffCfg.hidePermanentAuras == true
			end
		end
		if forceFinite and duration <= 0 then duration = 45 end
		local expiration = duration > 0 and (now + duration) or nil
		local stacks
		if idx % 5 == 0 then
			stacks = 5
		elseif idx % 3 == 0 then
			stacks = 3
		end
		local iconList = isDebuff and SAMPLE_DEBUFF_ICONS or SAMPLE_BUFF_ICONS
		local icon = iconList[((idx - 1) % #iconList) + 1]
		local dispelName = isDebuff and SAMPLE_DISPEL_TYPES[((idx - 1) % #SAMPLE_DISPEL_TYPES) + 1] or nil
		local canActivePlayerDispel = dispelName == "Magic"
		local auraId = base - idx
		AuraUtil.cacheTargetAura({
			auraInstanceID = auraId,
			icon = icon,
			isHelpful = not isDebuff,
			isHarmful = isDebuff,
			applications = stacks,
			duration = duration,
			expirationTime = expiration,
			dispelName = dispelName,
			canActivePlayerDispel = canActivePlayerDispel,
			isSample = true,
			isStealable = supportsStealablePreview and not isDebuff and laneIndex == 1,
		}, unit, isDebuff and "debuff" or "buff")
	end

	local idx = 0
	for i = 1, debuffCount do
		idx = idx + 1
		addSampleAura(true, idx, i)
	end
	for i = 1, buffCount do
		idx = idx + 1
		addSampleAura(false, idx, i)
	end
end

function AuraUtil.updateTargetAuraIcons(startIndex, unit, refreshBuffs, refreshDebuffs)
	unit = unit or "target"
	local st = states[unit]
	if not st or not st.auraContainer or not st.frame then return end
	local allowSample = UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit)
	local cfg = st.cfg or ensureDB(unit)
	local def = defaultsFor(unit)
	local ac = cfg.auraIcons or (def and def.auraIcons) or defaults.target.auraIcons or { size = 24, padding = 2, max = 16, showCooldown = true }
	local nativeAuraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, def and def.auraIcons)
	if AuraUtil.ShouldUseNativeAuraContainers(unit, nativeAuraRuntime, allowSample) then
		AuraUtil.ApplyNativeAuraContainers(unit, st, cfg, def, startIndex == 1)
		return
	end
	AuraUtil.HideNativeAuraContainers(st)
	local auraRuntime = nativeAuraRuntime
	if not auraRuntime.enabled then
		AuraUtil.hideAuraContainers(st)
		AuraUtil.UpdateSingleDispelIndicator(unit, allowSample)
		return
	end
	local buffStyle = auraRuntime.buff
	local debuffStyle = auraRuntime.debuff
	local showBuffs = auraRuntime.showBuffs
	local showDebuffs = auraRuntime.showDebuffs
	if not showBuffs and not showDebuffs then
		AuraUtil.hideAuraContainers(st)
		AuraUtil.UpdateSingleDispelIndicator(unit, allowSample)
		return
	end
	local _, harmfulFilter = AuraUtil.getUnitAuraFilters(unit, auraRuntime)
	if refreshBuffs == nil and refreshDebuffs == nil then
		refreshBuffs = true
		refreshDebuffs = true
	end

	local width = (st.auraContainer and st.auraContainer:GetWidth()) or (st.barGroup and st.barGroup:GetWidth()) or (st.frame and st.frame:GetWidth()) or 0
	local auraLayout = UF._auraLayout
	local canShowPlayerDispel = AuraUtil.CanUnitShowPlayerDispel(unit, allowSample)
	local buffAnchor = buffStyle.anchor or "BOTTOM"
	local buffPrimary, buffSecondary = auraLayout.resolveGrowth(buffStyle, buffAnchor, buffStyle.growth)
	local perRow = auraLayout.calcPerRow(st, buffStyle, width, buffPrimary)
	local debAnchor = debuffStyle.anchor or "BOTTOM"
	local debPrimary, debSecondary = auraLayout.resolveGrowth(debuffStyle, debAnchor, debuffStyle.growth)
	local perRowDebuff = auraLayout.calcPerRow(st, debuffStyle, width, debPrimary)

	local function hideAuraList(container, buttons)
		if buttons then
			for idx = 1, #buttons do
				if buttons[idx] then buttons[idx]:Hide() end
			end
		end
		if container then
			container:SetHeight(0.001)
			container:SetShown(false)
		end
	end

	local function renderAuraList(kind, container, buttons, style, isDebuff, primary, secondary, perRow)
		local cache = AuraUtil.getAuraKindCache(unit, kind)
		if not (cache and container) then
			hideAuraList(container, buttons)
			return buttons or {}, 0
		end
		AuraUtil.compactAuraCache(cache)
		local auras, order = cache.auras, cache.order
		if not (auras and order) then
			hideAuraList(container, buttons)
			return buttons or {}, 0
		end
		buttons = buttons or {}
		local shown = 0
		local maxCount = style.max or 0
		local layoutChanged = container._eqolAuraLayoutSize ~= style.size
			or container._eqolAuraLayoutPadding ~= style.padding
			or container._eqolAuraLayoutPerRow ~= perRow
			or container._eqolAuraLayoutPrimary ~= primary
			or container._eqolAuraLayoutSecondary ~= secondary
		for i = 1, #order do
			if shown >= maxCount then break end
			local auraId = order[i]
			local aura = auraId and auras[auraId]
			if aura then
				shown = shown + 1
				local oldButton = buttons[shown]
				local btn
				btn, buttons = AuraUtil.ensureAuraButton(container, buttons, shown, style)
				AuraUtil.applyAuraToButton(btn, aura, style, isDebuff, unit, harmfulFilter, canShowPlayerDispel)
				if layoutChanged or oldButton ~= btn or btn._eqolAuraAnchorContainer ~= container then
					AuraUtil.anchorAuraButton(btn, container, shown, style, perRow, primary, secondary)
				end
			end
		end
		container._eqolAuraLayoutSize = style.size
		container._eqolAuraLayoutPadding = style.padding
		container._eqolAuraLayoutPerRow = perRow
		container._eqolAuraLayoutPrimary = primary
		container._eqolAuraLayoutSecondary = secondary
		for idx = shown + 1, #buttons do
			if buttons[idx] then buttons[idx]:Hide() end
		end
		AuraUtil.updateAuraContainerSize(container, shown, style, perRow, primary)
		return buttons, shown
	end

	if auraRuntime.combineLayout then
		local primaryStyle = showBuffs and buffStyle or debuffStyle
		local combinedStyle = CopyTable(primaryStyle)
		combinedStyle.size = math.max(showBuffs and (tonumber(buffStyle.size) or 0) or 0, showDebuffs and (tonumber(debuffStyle.size) or 0) or 0, 1)
		combinedStyle.padding = tonumber(primaryStyle.padding) or 0
		combinedStyle.max = (showBuffs and (tonumber(buffStyle.max) or 0) or 0) + (showDebuffs and (tonumber(debuffStyle.max) or 0) or 0)
		local combinedAnchor = primaryStyle.anchor or "BOTTOM"
		local combinedPrimary, combinedSecondary = auraLayout.resolveGrowth(primaryStyle, combinedAnchor, primaryStyle.growth)
		local combinedPerRow = auraLayout.calcPerRow(st, combinedStyle, width, combinedPrimary)
		local buttons = st.auraButtons or {}
		local shown = 0
		local function appendKind(kind, style, isDebuff)
			local cache = AuraUtil.getAuraKindCache(unit, kind)
			if not cache then return end
			AuraUtil.compactAuraCache(cache)
			local auras, order = cache.auras, cache.order
			if not (auras and order) then return end
			local kindShown = 0
			for i = 1, #order do
				if kindShown >= (style.max or 0) then break end
				local aura = order[i] and auras[order[i]]
				if aura then
					kindShown = kindShown + 1
					shown = shown + 1
					local button
					button, buttons = AuraUtil.ensureAuraButton(st.auraContainer, buttons, shown, style)
					AuraUtil.applyAuraToButton(button, aura, style, isDebuff, unit, harmfulFilter, canShowPlayerDispel)
					AuraUtil.anchorAuraButton(button, st.auraContainer, shown, combinedStyle, combinedPerRow, combinedPrimary, combinedSecondary)
				end
			end
		end
		if showBuffs then appendKind("buff", buffStyle, false) end
		if showDebuffs then appendKind("debuff", debuffStyle, true) end
		for idx = shown + 1, #buttons do
			if buttons[idx] then buttons[idx]:Hide() end
		end
		st.auraButtons = buttons
		hideAuraList(st.debuffContainer, st.debuffButtons)
		AuraUtil.updateAuraContainerSize(st.auraContainer, shown, combinedStyle, combinedPerRow, combinedPrimary)
		if refreshDebuffs ~= false or allowSample then AuraUtil.UpdateSingleDispelIndicator(unit, allowSample) end
		return
	end

	if showBuffs then
		if refreshBuffs then st.auraButtons = renderAuraList("buff", st.auraContainer, st.auraButtons, buffStyle, false, buffPrimary, buffSecondary, perRow) end
	else
		hideAuraList(st.auraContainer, st.auraButtons)
	end

	if showDebuffs and st.debuffContainer then
		if refreshDebuffs then st.debuffButtons = renderAuraList("debuff", st.debuffContainer, st.debuffButtons, debuffStyle, true, debPrimary, debSecondary, perRowDebuff) end
	else
		hideAuraList(st.debuffContainer, st.debuffButtons)
	end

	if refreshDebuffs ~= false or allowSample then AuraUtil.UpdateSingleDispelIndicator(unit, allowSample) end
end

function AuraUtil.normalizeAuraQueryLimit(value)
	value = math.floor(tonumber(value) or 0)
	if value < 1 then return nil end
	return value
end

function AuraUtil.getTargetAuraQueryLimits(ac, defAc)
	local resolved = AuraUtil.resolveSingleAuraConfig(ac, defAc)
	local buff = AuraUtil.prepareSingleAuraSectionStyle(resolved.buff)
	local debuff = AuraUtil.prepareSingleAuraSectionStyle(resolved.debuff)
	local showBuffs = buff.enabled ~= false
	local showDebuffs = debuff.enabled ~= false

	return showBuffs and AuraUtil.normalizeAuraQueryLimit((buff.max or 0) + 1) or nil, showDebuffs and AuraUtil.normalizeAuraQueryLimit((debuff.max or 0) + 1) or nil
end

function AuraUtil.scanTargetAuraSlots(unit, filter, queryLimit, hidePermanent, kind)
	if not AuraUtil.canReadAuraData() then return end
	if not (unit and filter and C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then return end
	local slots
	if queryLimit then
		slots = { C_UnitAuras.GetAuraSlots(unit, filter, queryLimit) }
	else
		slots = { C_UnitAuras.GetAuraSlots(unit, filter) }
	end
	for i = 2, #slots do
		local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
		if
			aura
			and (not hidePermanent or not AuraUtil.isPermanentAura(aura, unit))
			and not (UF.GlobalAuraIgnore and UF.GlobalAuraIgnore.ShouldIgnoreAura and UF.GlobalAuraIgnore.ShouldIgnoreAura(unit, aura))
		then
			AuraUtil.cacheTargetAura(aura, unit, kind)
		end
	end
end

function AuraUtil.fullScanTargetAuras(unit)
	unit = unit or "target"
	local st = states[unit]
	local cfg = (st and st.cfg) or ensureDB(unit)
	local def = defaultsFor(unit)
	local ac = cfg.auraIcons or (def and def.auraIcons) or defaults.target.auraIcons or {}
	local inEditMode = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() == true
	local allowSample = UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit)
	local usesNativeRuntime = unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)
	if inEditMode and usesNativeRuntime then
		AuraUtil.HideNativeAuraContainers(st)
		AuraUtil.resetTargetAuras(unit)
		if allowSample then
			if st then st._sampleAurasActive = true end
			AuraUtil.fillSampleAuras(unit, ac)
		elseif st then
			st._sampleAurasActive = nil
		end
		AuraUtil.updateTargetAuraIcons(nil, unit)
		return
	end

	local cachedAuraRuntime = st and st._singleAuraRuntimeConfig
	if AuraUtil.RefreshCompiledNativeAuraContainers(st) then
		st._sampleAurasActive = nil
		return
	end
	if cachedAuraRuntime and AuraUtil.ShouldUseNativeAuraContainers(unit, cachedAuraRuntime, false) and AuraUtil.RefreshNativeAuraContainers(st, unit, cachedAuraRuntime) then
		st._sampleAurasActive = nil
		return
	end
	AuraUtil.resetTargetAuras(unit)
	local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, def and def.auraIcons)
	if not auraRuntime.enabled then
		if st then st._sampleAurasActive = nil end
		AuraUtil.updateTargetAuraIcons(nil, unit)
		return
	end
	local buff = auraRuntime.buff
	local debuff = auraRuntime.debuff
	local showBuffs = auraRuntime.showBuffs
	local showDebuffs = auraRuntime.showDebuffs
	if not showBuffs and not showDebuffs then
		AuraUtil.updateTargetAuraIcons(nil, unit)
		return
	end
	if allowSample then
		if st then st._sampleAurasActive = true end
		AuraUtil.fillSampleAuras(unit, ac)
		AuraUtil.updateTargetAuraIcons(nil, unit)
		return
	end
	if AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, allowSample) then
		if not AuraUtil.RefreshNativeAuraContainers(st, unit, auraRuntime) then AuraUtil.ApplyNativeAuraContainers(unit, st, cfg, def, true) end
		return
	end
	if st then st._sampleAurasActive = nil end
	if not UnitExists or not UnitExists(unit) then
		AuraUtil.updateTargetAuraIcons(nil, unit)
		return
	end
	local helpfulFilter, harmfulFilter = AuraUtil.getUnitAuraFilters(unit, auraRuntime)
	local helpfulLimit = auraRuntime.helpfulLimit
	local harmfulLimit = auraRuntime.harmfulLimit
	if showBuffs then AuraUtil.scanTargetAuraSlots(unit, helpfulFilter, helpfulLimit, buff.hidePermanentAuras == true, "buff") end
	if showDebuffs then AuraUtil.scanTargetAuraSlots(unit, harmfulFilter, harmfulLimit, debuff.hidePermanentAuras == true, "debuff") end
	AuraUtil.updateTargetAuraIcons(nil, unit)
end

local function refreshMainPower(unit)
	unit = unit or UNIT.PLAYER
	local enumId, token = UnitPowerType(unit)
	if unit == UNIT.PLAYER then
		mainPowerEnum, mainPowerToken = enumId, token
	end
	return enumId, token
end
local function getMainPower(unit)
	if unit and unit ~= UNIT.PLAYER then return UnitPowerType(unit) end
	if not mainPowerEnum or not mainPowerToken then return refreshMainPower(UNIT.PLAYER) end
	return mainPowerEnum, mainPowerToken
end
local function getFrameInfo(frameName)
	if not addon.variables or not addon.variables.unitFrameNames then return nil end
	for _, info in ipairs(addon.variables.unitFrameNames) do
		if info.name == frameName then return info end
	end
	return nil
end

local function shouldHideInVehicle(cfg, def)
	local value = cfg and cfg.hideInVehicle
	if value == nil then value = def and def.hideInVehicle end
	return value == true
end

local function shouldHideInPetBattle(cfg, def)
	local value = cfg and cfg.hideInPetBattle
	if value == nil then value = def and def.hideInPetBattle end
	return value == true
end

UF._eqolVisibilityHandler = [[
local target = self:GetFrameRef("target")
if not target then return end
if newstate == "show" then
	target:Show()
	target:SetAlpha(1)
elseif newstate == "fade" then
	target:Show()
	target:SetAlpha(self:GetAttribute("eqol-fade-alpha") or 0)
elseif newstate == "hide" then
	target:SetAlpha(0)
	target:Hide()
end
]]

function UF.GetFrameVisibilityInactiveAlpha(unit)
	local cfg = unit and ensureDB(unit) or nil
	local strength = cfg and cfg.visibilityFadeStrength
	strength = tonumber(strength) or 1
	if strength < 0 then strength = 0 end
	if strength > 1 then strength = 1 end
	return 1 - strength
end

function UF.GetFrameVisibilityInactiveState(unit)
	local alpha = UF.GetFrameVisibilityInactiveAlpha(unit)
	if alpha <= 0 then return "hide", alpha end
	if alpha >= 1 then return "show", alpha end
	return "fade", alpha
end

function UF.EnsureEqolVisibilityController(st)
	if not st or not st.frame then return nil end
	local controller = st._eqolVisibilityController
	if not controller then
		controller = CreateFrame("Frame", nil, st.frame, "SecureHandlerStateTemplate")
		controller:SetFrameRef("target", st.frame)
		controller:SetAttribute("_onstate-eqolvisibility", UF._eqolVisibilityHandler)
		st._eqolVisibilityController = controller
	else
		controller:SetFrameRef("target", st.frame)
	end
	return controller
end

function UF.ClearEqolVisibilityDriver(st, showWhenCleared)
	if not st then return end
	local controller = st._eqolVisibilityController
	if controller then
		if _G.UnregisterAttributeDriver then pcall(_G.UnregisterAttributeDriver, controller, "state-eqolvisibility") end
		if controller.SetAttribute then controller:SetAttribute("state-eqolvisibility", nil) end
	end
	st._eqolVisibilityCond = nil
	if st.frame then
		if st.frame.SetAlpha then st.frame:SetAlpha(1) end
		if showWhenCleared and st.frame.Show then st.frame:Show() end
	end
end

function UF.ApplyEqolVisibilityDriver(st, cond, inactiveAlpha)
	if not st or not st.frame or not cond or not _G.RegisterAttributeDriver then return false end
	local controller = UF.EnsureEqolVisibilityController(st)
	if not controller then return false end
	controller:SetAttribute("eqol-fade-alpha", inactiveAlpha or 0)
	if st._eqolVisibilityCond == cond then
		local currentState = controller.GetAttribute and controller:GetAttribute("state-eqolvisibility")
		if currentState then
			controller:SetAttribute("state-eqolvisibility", nil)
			controller:SetAttribute("state-eqolvisibility", currentState)
		end
		return true
	end
	if _G.UnregisterAttributeDriver then pcall(_G.UnregisterAttributeDriver, controller, "state-eqolvisibility") end
	local ok = pcall(_G.RegisterAttributeDriver, controller, "state-eqolvisibility", cond)
	if ok then st._eqolVisibilityCond = cond end
	return ok
end

function UF.RefreshEqolVisibilityDriverAlphas()
	if InCombatLockdown and InCombatLockdown() then
		UF.ScheduleEqolVisibilityDriverAlphaRefresh()
		return
	end
	for unit, st in pairs(states) do
		local controller = st and st._eqolVisibilityController
		if controller and st._eqolVisibilityCond then
			local alpha = UF.GetFrameVisibilityInactiveAlpha(unit)
			controller:SetAttribute("eqol-fade-alpha", alpha)
			local currentState = controller.GetAttribute and controller:GetAttribute("state-eqolvisibility")
			if currentState then
				controller:SetAttribute("state-eqolvisibility", nil)
				controller:SetAttribute("state-eqolvisibility", currentState)
			end
		end
	end
end

function UF.ScheduleEqolVisibilityDriverAlphaRefresh()
	if InCombatLockdown and InCombatLockdown() then
		UF._eqolVisibilityAlphaRefreshPending = true
		if not UF._eqolVisibilityAlphaRefreshWatcher then
			UF._eqolVisibilityAlphaRefreshWatcher = CreateFrame("Frame")
			UF._eqolVisibilityAlphaRefreshWatcher:SetScript("OnEvent", function(self)
				if InCombatLockdown and InCombatLockdown() then return end
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				UF._eqolVisibilityAlphaRefreshWatcher = nil
				UF._eqolVisibilityAlphaRefreshPending = nil
				UF.ScheduleEqolVisibilityDriverAlphaRefresh()
			end)
			UF._eqolVisibilityAlphaRefreshWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end
	if UF._eqolVisibilityAlphaRefreshPending then return end
	UF._eqolVisibilityAlphaRefreshPending = true
	RunNextFrame(function()
		UF._eqolVisibilityAlphaRefreshPending = nil
		if UF.RefreshEqolVisibilityDrivers then
			UF.RefreshEqolVisibilityDrivers()
		else
			UF.RefreshEqolVisibilityDriverAlphas()
		end
	end)
end

function UF.ApplyBossUnitWatch(frame, unit, enabled, flagName)
	if not frame or not _G.RegisterUnitWatch or not _G.UnregisterUnitWatch then return end
	if frame.SetAttribute then frame:SetAttribute("unit", unit) end
	flagName = flagName or "EQOL_BossUnitWatchRegistered"
	local registered = (_G.UnitWatchRegistered and _G.UnitWatchRegistered(frame)) or frame[flagName] == true
	if enabled then
		if not registered then
			local ok = pcall(_G.RegisterUnitWatch, frame)
			if ok then frame[flagName] = true end
		end
		return
	end
	if registered then pcall(_G.UnregisterUnitWatch, frame) end
	frame[flagName] = nil
	if frame.Hide then frame:Hide() end
end

function UF.ClearBossUnitWatch(frame, flagName, showWhenCleared)
	if not frame or not _G.UnregisterUnitWatch then return end
	flagName = flagName or "EQOL_BossUnitWatchRegistered"
	local registered = (_G.UnitWatchRegistered and _G.UnitWatchRegistered(frame)) or frame[flagName] == true
	if registered then pcall(_G.UnregisterUnitWatch, frame) end
	frame[flagName] = nil
	if showWhenCleared and frame.Show then frame:Show() end
end

local function applyVisibilityDriver(unit, enabled)
	local st = states[unit]
	if not st or not st.frame then return end
	local cfg = ensureDB(unit)
	local def = defaultsFor(unit)
	local inEdit = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	local NormalizeVisibilityConfig = addon.functions and addon.functions.NormalizeUnitFrameVisibilityConfig
	local BuildVisibilityDriverExpression = addon.functions and addon.functions.BuildUnitFrameDriverExpression
	local visibilityConfig = nil
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	local useRolesets = tonumber((select(4, GetBuildInfo()))) >= 120100
	if enabled and not inEdit and NormalizeVisibilityConfig then visibilityConfig = NormalizeVisibilityConfig(nil, cfg and cfg.visibility, { skipSave = true, ignoreOverride = true }) end
	local visibilityNeedsManualHandling = visibilityConfig and (visibilityConfig.MOUSEOVER or visibilityConfig.PLAYER_CASTING or visibilityConfig.SHOW_IN_INSTANCE)
	if isBossUnit(unit) and _G.RegisterUnitWatch and _G.UnregisterUnitWatch then
		local hideInClientScene = UFHelper and UFHelper.shouldHideInClientScene and UFHelper.shouldHideInClientScene(cfg, def)
		local forceClientSceneHide = enabled and not useRolesets and not inEdit and hideInClientScene and UF._clientSceneActive == true
		if UFHelper and UFHelper.applyClientSceneAlphaOverride then UFHelper.applyClientSceneAlphaOverride(st, forceClientSceneHide) end
		if InCombatLockdown and InCombatLockdown() then
			if UF.ScheduleEqolVisibilityDriverAlphaRefresh then UF.ScheduleEqolVisibilityDriverAlphaRefresh() end
			return
		end
		local frame = st.frame
		if frame.EQOL_VisibilityStateDriver or st._visibilityCond or (frame.GetAttribute and frame:GetAttribute("state-visibility") ~= nil) then
			if UnregisterStateDriver then UnregisterStateDriver(frame, "visibility") end
			if frame.SetAttribute then frame:SetAttribute("state-visibility", nil) end
			frame.EQOL_VisibilityStateDriver = nil
			st._visibilityCond = nil
		end
		if inEdit then
			UF.ClearBossUnitWatch(frame, "EQOL_BossUnitWatchRegistered", true)
			UF.ClearBossUnitWatch(st.powerGroup, "EQOL_BossPowerUnitWatchRegistered", false)
			return
		end
		UF.ApplyBossUnitWatch(frame, unit, enabled, "EQOL_BossUnitWatchRegistered")
		UF.ApplyBossUnitWatch(st.powerGroup, unit, enabled, "EQOL_BossPowerUnitWatchRegistered")
		return
	end
	local hideInClientScene = UFHelper and UFHelper.shouldHideInClientScene and UFHelper.shouldHideInClientScene(cfg, def)
	local forceClientSceneHide = enabled and not useRolesets and not inEdit and hideInClientScene and UF._clientSceneActive == true
	if UFHelper and UFHelper.applyClientSceneAlphaOverride then UFHelper.applyClientSceneAlphaOverride(st, forceClientSceneHide) end
	if InCombatLockdown and InCombatLockdown() then
		if UF.ScheduleEqolVisibilityDriverAlphaRefresh then UF.ScheduleEqolVisibilityDriverAlphaRefresh() end
		return
	end
	if unit == UNIT.PET and _G.RegisterUnitWatch and _G.UnregisterUnitWatch then
		local frame = st.frame
		local registered = (_G.UnitWatchRegistered and _G.UnitWatchRegistered(frame)) or frame.EQOL_PetUnitWatchRegistered == true
		if registered then
			pcall(_G.UnregisterUnitWatch, frame)
			frame.EQOL_PetUnitWatchRegistered = nil
		end
	end
	if not RegisterStateDriver and not _G.RegisterAttributeDriver then return end
	local hideInVehicle = enabled and shouldHideInVehicle(cfg, def)
	local hideInPetBattle = enabled and not useRolesets and shouldHideInPetBattle(cfg, def)
	local cond
	local baseCond
	local showPrefix
	local prependHideClauses = nil
	local inactiveState, inactiveAlpha = UF.GetFrameVisibilityInactiveState(unit)
	local supportsEqolFadeDriver = true
	if not enabled then
		cond = "hide"
	elseif unit == UNIT.TARGET then
		baseCond = "[@target,exists] show; hide"
		showPrefix = "@target,exists"
	elseif unit == UNIT.TARGET_TARGET then
		baseCond = "[@targettarget,exists] show; hide"
		showPrefix = "@targettarget,exists"
	elseif unit == UNIT.FOCUS then
		baseCond = "[@focus,exists] show; hide"
		showPrefix = "@focus,exists"
	elseif unit == UNIT.PET then
		-- Keep pet frame configurable in Edit Mode even when no pet exists.
		baseCond = inEdit and "show" or "[@pet,exists] show; hide"
		if not inEdit then
			showPrefix = "@pet,exists"
			prependHideClauses = { "@pet,noexists" }
		end
	elseif isBossUnit(unit) then
		baseCond = ("[@%s,exists] show; hide"):format(unit)
	end
	if enabled then
		if visibilityConfig and not visibilityNeedsManualHandling and BuildVisibilityDriverExpression then
			if hideInPetBattle then
				prependHideClauses = prependHideClauses or {}
				prependHideClauses[#prependHideClauses + 1] = "petbattle"
			end
			if hideInVehicle then
				prependHideClauses = prependHideClauses or {}
				prependHideClauses[#prependHideClauses + 1] = "vehicleui"
			end
			cond = BuildVisibilityDriverExpression(visibilityConfig, { prependHideClauses = prependHideClauses, showPrefix = showPrefix, inactiveState = supportsEqolFadeDriver and inactiveState or nil })
		end
		if not cond and (hideInPetBattle or hideInVehicle or baseCond) then
			local clauses = {}
			if prependHideClauses then
				for _, clause in ipairs(prependHideClauses) do
					clauses[#clauses + 1] = ("[%s] hide"):format(clause)
				end
			end
			if hideInPetBattle then clauses[#clauses + 1] = "[petbattle] hide" end
			if hideInVehicle then clauses[#clauses + 1] = "[vehicleui] hide" end
			clauses[#clauses + 1] = baseCond or "show"
			cond = table.concat(clauses, "; ")
		end
	end
	local useEqolVisibilityDriver = supportsEqolFadeDriver and cond and cond:find("fade", 1, true) ~= nil
	if useEqolVisibilityDriver then
		if UnregisterStateDriver then UnregisterStateDriver(st.frame, "visibility") end
		if st.frame.SetAttribute then st.frame:SetAttribute("state-visibility", nil) end
		st._visibilityCond = nil
		UF.ApplyEqolVisibilityDriver(st, cond, inactiveAlpha)
		return
	end
	UF.ClearEqolVisibilityDriver(st, false)
	if cond == st._visibilityCond then return end
	if not cond then
		if UnregisterStateDriver then UnregisterStateDriver(st.frame, "visibility") end
		st._visibilityCond = nil
		return
	end
	if UnregisterStateDriver then UnregisterStateDriver(st.frame, "visibility") end
	st.frame:SetAttribute("state-visibility", nil)
	RegisterStateDriver(st.frame, "visibility", cond)
	st._visibilityCond = cond
end

local function applyFrameRuleOverride(frameName, enabled)
	if not frameName then return end
	local info = getFrameInfo(frameName)
	if not info then
		if frameName == UF_FRAME_NAMES.targettarget.frame then
			info = { name = UF_FRAME_NAMES.targettarget.frame, var = "unitframeSettingTargetTargetFrame", unitToken = UNIT.TARGET_TARGET }
		else
			return
		end
	end
	local function frameNameFor(unitToken)
		if unitToken == UNIT.PLAYER then return BLIZZ_FRAME_NAMES.player end
		if unitToken == UNIT.TARGET then return BLIZZ_FRAME_NAMES.target end
		if unitToken == UNIT.TARGET_TARGET then return BLIZZ_FRAME_NAMES.targettarget end
		if unitToken == UNIT.FOCUS then return BLIZZ_FRAME_NAMES.focus end
		if unitToken == UNIT.PET then return BLIZZ_FRAME_NAMES.pet end
	end
	local NormalizeUnitFrameVisibilityConfig = addon.functions and addon.functions.NormalizeUnitFrameVisibilityConfig
	local UpdateUnitFrameMouseover = addon.functions and addon.functions.UpdateUnitFrameMouseover
	if not NormalizeUnitFrameVisibilityConfig or not UpdateUnitFrameMouseover then return end
	addon.db = addon.db or {}
	local key = info.var
	if enabled then
		if originalFrameRules[key] == nil then
			local cur = addon.db[key]
			if cur == nil then
				originalFrameRules[key] = NIL_VISIBILITY_SENTINEL
			else
				originalFrameRules[key] = cur
			end
		end
		if SetFrameVisibilityOverride then
			SetFrameVisibilityOverride(key, { ALWAYS_HIDDEN = true })
		else
			NormalizeUnitFrameVisibilityConfig(key, { ALWAYS_HIDDEN = true })
		end
	else
		if SetFrameVisibilityOverride then SetFrameVisibilityOverride(key, nil) end
		if originalFrameRules[key] ~= nil then
			local prev = originalFrameRules[key]
			if prev == NIL_VISIBILITY_SENTINEL then
				addon.db[key] = nil
			else
				addon.db[key] = prev
			end
			originalFrameRules[key] = nil
		elseif not HasFrameVisibilityOverride or not HasFrameVisibilityOverride(key) then
			NormalizeUnitFrameVisibilityConfig(key, nil)
		end
	end
	UpdateUnitFrameMouseover(info.name, info)
	if enabled then hardHideBlizzFrame(info.name or frameNameFor(info.unitToken)) end
end

local function normalizeVisibilityConfig(config)
	if NormalizeUnitFrameVisibilityConfig then return NormalizeUnitFrameVisibilityConfig(nil, config, { skipSave = true, ignoreOverride = true }) end
	if type(config) == "table" then return config end
	return nil
end

local function applyVisibilityRules(unit)
	if not ApplyFrameVisibilityConfig then return end
	local cfg = ensureDB(unit)
	local def = defaultsFor(unit)
	local inEdit = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	local useConfig = (not inEdit and cfg and cfg.enabled) and normalizeVisibilityConfig(cfg.visibility) or nil
	local manualConfig = useConfig
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	local useRolesets = tonumber((select(4, GetBuildInfo()))) >= 120100
	local hideInClientScene = UFHelper and UFHelper.shouldHideInClientScene and UFHelper.shouldHideInClientScene(cfg, def)
	local forceClientSceneHide = not useRolesets and not inEdit and cfg and cfg.enabled and hideInClientScene and UF._clientSceneActive == true
	if unit ~= "boss" and manualConfig and not manualConfig.MOUSEOVER and not manualConfig.PLAYER_CASTING and not manualConfig.SHOW_IN_INSTANCE then
		manualConfig = nil
	end
	local opts = { noStateDriver = true }
	if unit == "boss" then
		local bossCount = UF.GetBossFrameCount(cfg)
		for i = 1, maxBossFrames do
			local info = UNITS["boss" .. i]
			local frameConfig = i <= bossCount and manualConfig or nil
			local st = states["boss" .. i]
			if info and info.frameName and (frameConfig or (st and st._eqolManualVisibilityActive)) then
				ApplyFrameVisibilityConfig(info.frameName, { unitToken = "boss" }, frameConfig, opts)
			end
			if st then st._eqolManualVisibilityActive = frameConfig ~= nil or nil end
			if UFHelper and UFHelper.applyClientSceneAlphaOverride then UFHelper.applyClientSceneAlphaOverride(states["boss" .. i], forceClientSceneHide) end
		end
		return
	end
	local info = UNITS[unit]
	local st = states[unit]
	if info and info.frameName and (manualConfig or (st and st._eqolManualVisibilityActive)) then
		ApplyFrameVisibilityConfig(info.frameName, { unitToken = info.unit }, manualConfig, opts)
	end
	if st then st._eqolManualVisibilityActive = manualConfig ~= nil or nil end
	if UFHelper and UFHelper.applyClientSceneAlphaOverride then UFHelper.applyClientSceneAlphaOverride(states[unit], forceClientSceneHide) end
end

local function applyVisibilityRulesAll()
	applyVisibilityRules("player")
	applyVisibilityRules("target")
	applyVisibilityRules(UNIT.TARGET_TARGET)
	applyVisibilityRules("focus")
	applyVisibilityRules("pet")
	applyVisibilityRules("boss")
end

function UF.RefreshClientSceneVisibility()
	applyVisibilityDriver(UNIT.PLAYER, ensureDB(UNIT.PLAYER).enabled)
	applyVisibilityDriver(UNIT.TARGET, ensureDB(UNIT.TARGET).enabled)
	applyVisibilityDriver(UNIT.TARGET_TARGET, ensureDB(UNIT.TARGET_TARGET).enabled)
	applyVisibilityDriver(UNIT.FOCUS, ensureDB(UNIT.FOCUS).enabled)
	applyVisibilityDriver(UNIT.PET, ensureDB(UNIT.PET).enabled)
	local bossEnabled = ensureDB("boss").enabled
	local bossCount = bossEnabled and UF.GetBossFrameCount() or 0
	for i = 1, maxBossFrames do
		applyVisibilityDriver("boss" .. i, bossEnabled and i <= bossCount)
	end
	applyVisibilityRulesAll()
end

function UF.RefreshEqolVisibilityDrivers()
	if InCombatLockdown and InCombatLockdown() then
		UF.ScheduleEqolVisibilityDriverAlphaRefresh()
		return
	end
	UF.RefreshClientSceneVisibility()
	UF.RefreshEqolVisibilityDriverAlphas()
end

local function hideBlizzardPlayerFrame()
	if not _G.PlayerFrame then return end
	if not InCombatLockdown() and ensureDB("player").enabled then _G.PlayerFrame:Hide() end
	if not blizzardPlayerHooked then
		_G.PlayerFrame:HookScript("OnShow", function(frame)
			if ensureDB("player").enabled then
				frame:Hide()
			else
				frame:Show()
			end
		end)
		blizzardPlayerHooked = true
	end
end

local function hideBlizzardTargetFrame()
	if not _G.TargetFrame then return end
	if not InCombatLockdown() and ensureDB("target").enabled then _G.TargetFrame:Hide() end
	if not blizzardTargetHooked then
		_G.TargetFrame:HookScript("OnShow", function(frame)
			if ensureDB("target").enabled then
				frame:Hide()
			else
				frame:Show()
			end
		end)
		blizzardTargetHooked = true
	end
end

local function mergeDefaults(base, override)
	local merged = CopyTable(base or {})
	if type(override) ~= "table" then return merged end
	for k, v in pairs(override) do
		if type(v) == "table" and type(merged[k]) == "table" then
			merged[k] = mergeDefaults(merged[k], v)
		elseif type(v) == "table" then
			merged[k] = CopyTable(v)
		else
			merged[k] = v
		end
	end
	return merged
end

do
	local targetDefaults = mergeDefaults(defaults.player, defaults.target)
	targetDefaults.enabled = false
	targetDefaults.anchor = targetDefaults.anchor and CopyTable(targetDefaults.anchor) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = -200 }
	targetDefaults.anchor.x = (targetDefaults.anchor.x or 0) + 260
	targetDefaults.auraIcons = {
		enabled = true,
		combineLayout = true,
		size = 24,
		debuffSize = nil,
		padding = 2,
		max = 16,
		perRow = 0,
		showCooldown = true,
		showCooldownBuffs = nil,
		showCooldownDebuffs = nil,
		enemyDebuffFilterMode = ENEMY_DEBUFF_FILTER_MODE_PLAYER,
		showTooltip = true,
		hidePermanentAuras = false,
		blizzardDispelBorder = false,
		blizzardDispelBorderAlpha = 1,
		blizzardDispelBorderAlphaNot = 0,
		blizzardStealableBorder = true,
		blizzardStealableGlowStyle = "DEFAULT",
		blizzardStealableGlowInset = 0,
		borderColor = nil,
		borderTexture = "DEFAULT",
		borderRenderMode = "EDGE",
		borderSize = nil,
		borderOffset = 0,
		anchor = "BOTTOM",
		offset = { x = 0, y = -5 },
		growth = nil,
		debuffAnchor = nil,
		debuffOffset = nil,
		debuffGrowth = nil,
		countAnchor = "BOTTOMRIGHT",
		countOffset = { x = -2, y = 2 },
		countFont = "__EQOL_GLOBAL_FONT__",
		countFontSize = nil,
		countFontSizeBuff = nil,
		countFontSizeDebuff = nil,
		countFontOutline = nil,
		cooldownFontSize = 12,
		cooldownFontSizeBuff = nil,
		cooldownFontSizeDebuff = nil,
	}
	defaults.target = targetDefaults

	local totDefaults = CopyTable(targetDefaults)
	totDefaults.enabled = false
	totDefaults.auraIcons = nil
	totDefaults.width = 180
	totDefaults.healthHeight = 20
	totDefaults.powerHeight = 12
	totDefaults.statusHeight = 16
	totDefaults.anchor = totDefaults.anchor and CopyTable(totDefaults.anchor) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = -200 }
	totDefaults.anchor.x = (totDefaults.anchor.x or 0) + 260
	defaults.targettarget = totDefaults

	local focusDefaults = CopyTable(targetDefaults)
	focusDefaults.enabled = false
	focusDefaults.anchor = focusDefaults.anchor and CopyTable(focusDefaults.anchor) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = -200 }
	focusDefaults.anchor.x = (focusDefaults.anchor.x or 0) - 260
	defaults.focus = focusDefaults

	local petDefaults = CopyTable(defaults.player)
	petDefaults.enabled = false
	petDefaults.anchor = petDefaults.anchor and CopyTable(petDefaults.anchor) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = -200 }
	petDefaults.anchor.x = (petDefaults.anchor.x or 0) - 260
	petDefaults.width = 200
	petDefaults.healthHeight = 20
	petDefaults.powerHeight = 12
	petDefaults.statusHeight = 16
	petDefaults.health.absorbUseCustomColor = false
	petDefaults.health.useAbsorbGlow = false
	petDefaults.health.showSampleAbsorb = false
	petDefaults.health.healAbsorbUseCustomColor = false
	petDefaults.health.showSampleHealAbsorb = false
	if petDefaults.status and petDefaults.status.combatIndicator then petDefaults.status.combatIndicator.enabled = false end
	defaults.pet = petDefaults

	local bossDefaults = CopyTable(defaults.target)
	bossDefaults.enabled = false
	bossDefaults.bossCount = MAX_BOSS_FRAMES or 5
	bossDefaults.anchor = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 400, y = 200 }
	bossDefaults.width = 220
	bossDefaults.healthHeight = 20
	bossDefaults.powerHeight = 10
	bossDefaults.statusHeight = 16
	bossDefaults.spacing = 4
	bossDefaults.growth = "DOWN"
	bossDefaults.health.useClassColor = false
	bossDefaults.health.useCustomColor = false
	bossDefaults.health.useAbsorbGlow = false
	bossDefaults.health.showSampleAbsorb = false
	bossDefaults.health.absorbUseCustomColor = false
	bossDefaults.health.healAbsorbUseCustomColor = false
	bossDefaults.health.showSampleHealAbsorb = false
	if bossDefaults.auraIcons then bossDefaults.auraIcons.enabled = false end
	if bossDefaults.status then bossDefaults.status.nameColorMode = "CUSTOM" end
	defaults.boss = bossDefaults
end

if not defaults.player.auraIcons and defaults.target and defaults.target.auraIcons then
	defaults.player.auraIcons = CopyTable(defaults.target.auraIcons)
	defaults.player.auraIcons.enabled = false
end

local function ensureBorderFrame(frame)
	if not frame then return nil end
	local border = frame._ufBorder
	if not border then
		border = CreateFrame("Frame", nil, frame)
		border:EnableMouse(false)
		frame._ufBorder = border
	end
	border:SetFrameStrata(frame:GetFrameStrata())
	local baseLevel = frame:GetFrameLevel() or 0
	border:SetFrameLevel(baseLevel + 3)
	return border
end

local function unpackColor(color, defaultR, defaultG, defaultB, defaultA)
	if type(color) ~= "table" then return defaultR, defaultG, defaultB, defaultA end
	return color[1] or color.r or defaultR, color[2] or color.g or defaultG, color[3] or color.b or defaultB, color[4] or color.a or defaultA
end

function AuraUtil.ShouldUseManagedDispelBorder()
	return addon.AuraCompat and addon.AuraCompat.ShouldUseAuraContainer and addon.AuraCompat:ShouldUseAuraContainer() == true or false
end

function AuraUtil.SetManagedDispelSlotFilterStrings(managed, filterString)
	if not (managed and managed.container and filterString) then return end
	if managed.backgroundSlotKey then addon.AuraCompat:UpdateAuraSlot(managed.container, managed.backgroundSlotKey, { filterString = filterString }) end
	for _, slotKey in pairs(managed.overlaySlotKeys or {}) do
		addon.AuraCompat:UpdateAuraSlot(managed.container, slotKey, { filterString = filterString })
	end
end

function AuraUtil.HideManagedDispelBorder(st)
	local managed = st and st.managedDispelBorder
	if not managed then return end
	managed.enabled = nil
	if managed.container then
		if managed.container.SetEnabled then managed.container:SetEnabled(false) end
		AuraUtil.SetManagedDispelSlotFilterStrings(managed, "HELPFUL|HARMFUL")
		managed.filtersReset = true
		managed.container:Hide()
	end
end

AuraUtil.ManagedDispelTypes = AuraUtil.ManagedDispelTypes
	or {
		{ key = "Magic", colorName = "Magic" },
		{ key = "Curse", colorName = "Curse" },
		{ key = "Disease", colorName = "Disease" },
		{ key = "Poison", colorName = "Poison" },
		{ key = "Bleed", colorName = "Bleed" },
	}

function AuraUtil.GetManagedDispelRootSize(root)
	local width = root and root.GetWidth and root:GetWidth() or nil
	local height = root and root.GetHeight and root:GetHeight() or nil
	if type(width) ~= "number" or width < 1 or type(height) ~= "number" or height < 1 then return nil, nil end
	return width, height
end

function AuraUtil.GetManagedDispelGlowSignature(dcfg, defDispel, width, height)
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	local color = dcfg.glowColor or defDispel.glowColor or {}
	local fillColor = dcfg.fillColor or defDispel.fillColor or {}
	return table.concat({
		tostring(dcfg.alpha or defDispel.alpha or 0.25),
		tostring(dcfg.enabled == nil and defDispel.enabled ~= false or dcfg.enabled == true),
		tostring(dcfg.glowEnabled == nil and defDispel.glowEnabled == true or dcfg.glowEnabled == true),
		tostring(dcfg.fillEnabled == nil and defDispel.fillEnabled ~= false or dcfg.fillEnabled == true),
		tostring(dcfg.fillAlpha or defDispel.fillAlpha or 0.2),
		tostring(fillColor[1] or fillColor.r or 0),
		tostring(fillColor[2] or fillColor.g or 0),
		tostring(fillColor[3] or fillColor.b or 0),
		tostring(fillColor[4] or fillColor.a or 1),
		tostring(dcfg.strata or defDispel.strata or ""),
		tostring(dcfg.frameLevelModel or defDispel.frameLevelModel or ""),
		tostring(dcfg.frameLevelOffset or defDispel.frameLevelOffset or ""),
		tostring(dcfg.glowColorMode or defDispel.glowColorMode or "DISPEL"),
		tostring(color[1] or color.r or 1),
		tostring(color[2] or color.g or 1),
		tostring(color[3] or color.b or 1),
		tostring(color[4] or color.a or 1),
		tostring(dcfg.glowEffect or defDispel.glowEffect or "PIXEL"),
		tostring(dcfg.glowFrequency or defDispel.glowFrequency or 0.25),
		tostring(dcfg.glowLines or defDispel.glowLines or 8),
		tostring(dcfg.glowThickness or defDispel.glowThickness or 3),
		tostring(dcfg.glowX or defDispel.glowX or 0),
		tostring(dcfg.glowY or defDispel.glowY or 0),
		tostring(dcfg.glowStrata or defDispel.glowStrata or ""),
		tostring(dcfg.glowFrameLevelOffset or defDispel.glowFrameLevelOffset or ""),
		tostring(width or ""),
		tostring(height or ""),
	}, "\031")
end

function AuraUtil.GetManagedDispelFilterString(dcfg, defDispel)
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	local mode = tostring(dcfg.filterMode or defDispel.filterMode or "MY"):upper()
	if mode == "ALL" or mode == "ANY" then return "HARMFUL|INCLUDE_NAME_PLATE_ONLY|DISPELLABLE" end
	if mode == "GROUP" or mode == "RAID_PLAYER_DISPELLABLE" then return "HARMFUL|INCLUDE_NAME_PLATE_ONLY|RAID_PLAYER_DISPELLABLE" end
	return "HARMFUL|INCLUDE_NAME_PLATE_ONLY|RAID"
end

function AuraUtil.GetManagedDispelGlowOptions(colorName, dcfg, defDispel)
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	local colorMode = dcfg.glowColorMode or defDispel.glowColorMode or "DISPEL"
	local r, g, b = UFHelper.getDebuffColorFromName(colorName)
	if colorMode == "CUSTOM" then
		r, g, b = unpackColor(dcfg.glowColor or defDispel.glowColor, 1, 1, 1, 1)
	end
	local thickness = UFHelper.ClampNumber(dcfg.glowThickness or defDispel.glowThickness or 3, 1, 10, 3)
	local explicitGlowLevel = tonumber(rawget(dcfg, "glowFrameLevelOffset"))
	local explicitGlowStrata = rawget(dcfg, "glowStrata")
	local glowLevel
	if rawget(dcfg, "glowFrameLevelModel") == 2 or explicitGlowLevel ~= nil or explicitGlowStrata ~= nil then
		glowLevel = UFHelper.ClampNumber(explicitGlowLevel, -20, 1000, tonumber(defDispel.glowFrameLevelOffset) or 21)
	elseif rawget(dcfg, "glowOverOverlay") == true then
		glowLevel = 30
	else
		glowLevel = UFHelper.ClampNumber(defDispel.glowFrameLevelOffset, -20, 1000, 21)
	end
	return {
		style = tostring(dcfg.glowEffect or defDispel.glowEffect or "PIXEL"):upper(),
		color = { r or 1, g or 1, b or 1, 1 },
		count = UFHelper.ClampNumber(dcfg.glowLines or defDispel.glowLines or 8, 1, 20, 8),
		frequency = UFHelper.ClampNumber(dcfg.glowFrequency or defDispel.glowFrequency or 0.25, -1.5, 1.5, 0.25),
		scale = math.max(0.5, math.min(4, thickness / 3)),
		thickness = thickness,
		xOffset = UFHelper.ClampNumber(dcfg.glowX or defDispel.glowX or 0, -10, 10, 0),
		yOffset = UFHelper.ClampNumber(dcfg.glowY or defDispel.glowY or 0, -10, 10, 0),
		strata = dcfg.glowStrata or defDispel.glowStrata,
		frameLevelOffset = glowLevel,
	}
end

function AuraUtil.GetManagedDispelTintLayer(dcfg, defDispel)
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	local level = tonumber(rawget(dcfg, "frameLevelOffset"))
	if rawget(dcfg, "frameLevelModel") == 2 then
		level = UFHelper.ClampNumber(level, -20, 1000, 20)
	elseif level ~= nil then
		level = UFHelper.ClampNumber(level + 12, -20, 1000, 20)
	else
		level = tonumber(defDispel.frameLevelOffset)
		if defDispel.frameLevelModel == 2 then
			level = UFHelper.ClampNumber(level, -20, 1000, 20)
		elseif level ~= nil then
			level = UFHelper.ClampNumber(level + 12, -20, 1000, 20)
		else
			level = 20
		end
	end
	return level, dcfg.strata or defDispel.strata
end

function AuraUtil.LayoutManagedDispelHost(host, root, strata, level)
	if not (host and root) then return false end
	host:ClearAllPoints()
	host:SetAllPoints(root)
	if type(strata) == "string" and strata ~= "" then
		host:SetFrameStrata(strata)
	elseif root.GetFrameStrata then
		host:SetFrameStrata(root:GetFrameStrata())
	end
	if root.GetFrameLevel then host:SetFrameLevel(UF.ClampFrameLevel((root:GetFrameLevel() or 0) + (tonumber(level) or 0))) end
	host:Show()
	return true
end

function AuraUtil.SyncManagedDispelButtonLayer(button, host)
	if not (button and host) then return false end
	if button.CanBeAccessedInContext and button:CanBeAccessedInContext() ~= true then return false end
	if host.GetFrameStrata then button:SetFrameStrata(host:GetFrameStrata()) end
	if host.GetFrameLevel then button:SetFrameLevel(UF.ClampFrameLevel((host:GetFrameLevel() or 0) + 1)) end
	return true
end

function AuraUtil.PrepareManagedDispelSensorButton(button)
	if not button then return false end
	button:EnableMouse(false)
	if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
	if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end
	AuraUtil.CallNativeAuraMethod(button, "SetCancelAuraButtons", nil)
	AuraUtil.CallNativeAuraMethod(button, "ClearIcon")
	AuraUtil.CallNativeAuraMethod(button, "ClearDurationCooldown")
	AuraUtil.CallNativeAuraMethod(button, "ClearDurationText")
	AuraUtil.CallNativeAuraMethod(button, "ClearDurationBar")
	AuraUtil.CallNativeAuraMethod(button, "ClearApplicationCount")
	AuraUtil.CallNativeAuraMethod(button, "ClearDispelTypeText")
	AuraUtil.CallNativeAuraMethod(button, "ClearDispelTypeTextures")
	return true
end

function AuraUtil.ConfigureManagedDispelBackground(button, dcfg, defDispel)
	if not button then return false end
	if button.CanBeAccessedInContext and button:CanBeAccessedInContext() ~= true then return false end
	dcfg = dcfg or {}
	defDispel = defDispel or {}

	if not button._eqolDispelBackground then
		button._eqolDispelBackground = button:CreateTexture(nil, "BACKGROUND")
		button._eqolDispelBackground:SetAllPoints(button)
	end
	local fillColor = dcfg.fillColor or defDispel.fillColor or { 0, 0, 0, 1 }
	local fr, fg, fb, fa = unpackColor(fillColor, 0, 0, 0, 1)
	local fillEnabled = dcfg.fillEnabled
	if fillEnabled == nil then fillEnabled = defDispel.fillEnabled ~= false end
	local fillAlpha = dcfg.fillAlpha
	if fillAlpha == nil then fillAlpha = defDispel.fillAlpha or 0.2 end
	button._eqolDispelBackground:SetColorTexture(fr, fg, fb, fa or 1)
	button._eqolDispelBackground:SetAlpha(fillEnabled and fillAlpha or 0)
	button._eqolDispelBackground:Show()
	return true
end

function AuraUtil.ConfigureManagedDispelOverlay(button, colorName, dcfg, defDispel)
	if not button then return false end
	if button.CanBeAccessedInContext and button:CanBeAccessedInContext() ~= true then return false end
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	if not button._eqolDispelOverlay then
		button._eqolDispelOverlay = UFHelper.CreateDispelOverlay(button)
		button._eqolDispelOverlay:SetAllPoints(button)
		button._eqolDispelOverlay.Background:Hide()
	end
	local r, g, b = UFHelper.getDebuffColorFromName(colorName)
	local alpha = dcfg.alpha
	if alpha == nil then alpha = defDispel.alpha or 0.25 end
	button._eqolDispelOverlay.Gradient:SetVertexColor(r or 1, g or 1, b or 1, alpha)
	button._eqolDispelOverlay.Border:SetVertexColor(r or 1, g or 1, b or 1, alpha)
	button._eqolDispelOverlay:Show()
	return true
end

function AuraUtil.GetManagedDispelChildGlowOptions(button, root, colorName, dcfg, defDispel)
	local options = AuraUtil.GetManagedDispelGlowOptions(colorName, dcfg, defDispel)
	if not options.strata and button and button.GetFrameStrata then options.strata = button:GetFrameStrata() end
	options.width, options.height = AuraUtil.GetManagedDispelRootSize(root)
	return options
end

function AuraUtil.InitializeManagedDispelGlow(button, root, colorName, dcfg, defDispel)
	if not (button and root) then return nil end
	AuraUtil.PrepareManagedDispelSensorButton(button)
	if addon.AuraCompat and addon.AuraCompat.CreateRestrictedAuraGlow then
		return addon.AuraCompat:CreateRestrictedAuraGlow(button, root, AuraUtil.GetManagedDispelChildGlowOptions(button, root, colorName, dcfg, defDispel))
	end
	return nil
end

function AuraUtil.DisableManagedDispelGeneration(managed)
	if not (managed and managed.container) then return end
	if managed.backgroundSlotKey then
		addon.AuraCompat:UpdateAuraSlot(managed.container, managed.backgroundSlotKey, { candidateFilters = { includeDispelTypes = {} } })
	end
	for _, slotKey in pairs(managed.overlaySlotKeys or {}) do
		addon.AuraCompat:UpdateAuraSlot(managed.container, slotKey, { candidateFilters = { includeDispelTypes = {} } })
	end
end

function AuraUtil.LayoutManagedDispelHosts(managed, root, dcfg, defDispel)
	if not (managed and root) then return end
	local tintLevel, tintStrata = AuraUtil.GetManagedDispelTintLayer(dcfg, defDispel)
	AuraUtil.LayoutManagedDispelHost(managed.container, root, tintStrata, tintLevel)
	AuraUtil.LayoutManagedDispelHost(managed.backgroundHost, root, tintStrata, tintLevel)
	AuraUtil.SyncManagedDispelButtonLayer(managed.backgroundButton, managed.backgroundHost)
	for i = 1, #AuraUtil.ManagedDispelTypes do
		local dispelType = AuraUtil.ManagedDispelTypes[i]
		local overlayHost = managed.overlayHostsByType and managed.overlayHostsByType[dispelType.key]
		AuraUtil.LayoutManagedDispelHost(overlayHost, root, tintStrata, tintLevel + i)
		AuraUtil.SyncManagedDispelButtonLayer(managed.overlayButtonsByType and managed.overlayButtonsByType[dispelType.key], overlayHost)
	end
end

function AuraUtil.CreateManagedDispelGeneration(managed, root, filterString, dcfg, defDispel)
	if not (managed and managed.container and root) then return false end
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	managed.generation = (managed.generation or 0) + 1
	local generation = managed.generation
	local overlayEnabled = dcfg.enabled
	if overlayEnabled == nil then overlayEnabled = defDispel.enabled ~= false end
	local glowEnabled = dcfg.glowEnabled
	if glowEnabled == nil then glowEnabled = defDispel.glowEnabled == true end
	managed.backgroundSlotKey = "eqol-dispel-background:" .. tostring(generation)
	managed.backgroundHost = CreateFrame("Frame", nil, managed.container)
	managed.backgroundHost:EnableMouse(false)
	local tintLevel, tintStrata = AuraUtil.GetManagedDispelTintLayer(dcfg, defDispel)
	AuraUtil.LayoutManagedDispelHost(managed.backgroundHost, root, tintStrata, tintLevel)
	managed.slot = addon.AuraCompat:RegisterAuraSlot(managed.container, managed.backgroundSlotKey, filterString, {
		anchorFrame = managed.backgroundHost,
		candidateFilters = { includeDispelTypes = {} },
		initializeFrame = function(button)
			AuraUtil.PrepareManagedDispelSensorButton(button)
			managed.backgroundButton = button
			AuraUtil.SyncManagedDispelButtonLayer(button, managed.backgroundHost)
			AuraUtil.ConfigureManagedDispelBackground(button, dcfg, defDispel)
		end,
	})
	managed.overlaySlotKeys = {}
	managed.overlayButtonsByType = {}
	managed.overlayHostsByType = {}
	managed.glowsByType = {}
	for i = 1, #AuraUtil.ManagedDispelTypes do
		local dispelType = AuraUtil.ManagedDispelTypes[i]
		local dispelTypeKey = dispelType.key
		local dispelColorName = dispelType.colorName
		local overlaySlotKey = "eqol-dispel-overlay-" .. dispelTypeKey .. ":" .. tostring(generation)
		local overlayHost = CreateFrame("Frame", nil, managed.container)
		overlayHost:EnableMouse(false)
		managed.overlayHostsByType[dispelTypeKey] = overlayHost
		AuraUtil.LayoutManagedDispelHost(overlayHost, root, tintStrata, tintLevel + i)
		local overlayRegistered = addon.AuraCompat:RegisterAuraSlot(managed.container, overlaySlotKey, filterString, {
			anchorFrame = overlayHost,
			candidateFilters = { includeDispelTypes = {} },
			initializeFrame = function(button)
				AuraUtil.PrepareManagedDispelSensorButton(button)
				managed.overlayButtonsByType[dispelTypeKey] = button
				AuraUtil.SyncManagedDispelButtonLayer(button, overlayHost)
				AuraUtil.ConfigureManagedDispelOverlay(button, dispelColorName, dcfg, defDispel)
				if not overlayEnabled and button._eqolDispelOverlay then button._eqolDispelOverlay:Hide() end
				if glowEnabled then managed.glowsByType[dispelTypeKey] = AuraUtil.InitializeManagedDispelGlow(button, root, dispelColorName, dcfg, defDispel) end
			end,
		})
		if overlayRegistered then managed.overlaySlotKeys[dispelTypeKey] = overlaySlotKey end
	end
	managed.borderEnabled = nil
	managed.glowEnabled = nil
	AuraUtil.LayoutManagedDispelHosts(managed, root, dcfg, defDispel)
	return managed.slot ~= nil
end

function AuraUtil.QueueManagedDispelGeometryRefresh(st, root, dcfg, defDispel)
	local managed = st and st.managedDispelBorder
	if not (managed and C_Timer and C_Timer.NewTimer) then return false end
	if managed.geometryRefreshTimer and managed.geometryRefreshTimer.Cancel then managed.geometryRefreshTimer:Cancel() end
	managed.geometryRefreshTimer = C_Timer.NewTimer(0.25, function()
		managed.geometryRefreshTimer = nil
		if st.managedDispelBorder ~= managed then return end
		local unit = managed.unit
		local shouldReapply = managed.enabled == true and unit ~= nil
		local refreshed = AuraUtil.PrecreateManagedDispelBorder(st, root, dcfg, defDispel, true)
		if refreshed and shouldReapply then AuraUtil.ApplyManagedDispelBorder(st, root, unit, dcfg, defDispel, true) end
	end)
	return true
end

function AuraUtil.PrecreateManagedDispelBorder(st, root, dcfg, defDispel, forceGeometryRefresh)
	if not (st and root and AuraUtil.ShouldUseManagedDispelBorder() and addon.AuraCompat.CreateAuraContainer and addon.AuraCompat.RegisterAuraSlot) then return nil end
	local managed = st.managedDispelBorder
	local rootWidth, rootHeight = AuraUtil.GetManagedDispelRootSize(root)
	if not (rootWidth and rootHeight) then return managed and managed.slot and managed or nil end
	local settingsSignature = AuraUtil.GetManagedDispelGlowSignature(dcfg, defDispel)
	local signature = AuraUtil.GetManagedDispelGlowSignature(dcfg, defDispel, rootWidth, rootHeight)
	local filterString = AuraUtil.GetManagedDispelFilterString(dcfg, defDispel)
	if managed and managed.container and managed.slot then
		if managed.signature ~= signature then
			if not forceGeometryRefresh and managed.settingsSignature == settingsSignature and AuraUtil.QueueManagedDispelGeometryRefresh(st, root, dcfg, defDispel) then
				return managed
			end
			if managed.geometryRefreshTimer and managed.geometryRefreshTimer.Cancel then
				managed.geometryRefreshTimer:Cancel()
				managed.geometryRefreshTimer = nil
			end
			AuraUtil.DisableManagedDispelGeneration(managed)
			if not AuraUtil.CreateManagedDispelGeneration(managed, root, filterString, dcfg, defDispel) then return nil end
			managed.signature = signature
			managed.settingsSignature = settingsSignature
			managed.filterString = filterString
			managed.filtersReset = nil
			return managed
		end
		if managed.filterString ~= filterString or managed.filtersReset then
			AuraUtil.SetManagedDispelSlotFilterStrings(managed, filterString)
			managed.filterString = filterString
			managed.filtersReset = nil
		end
		return managed
	end

	managed = managed or {}
	st.managedDispelBorder = managed
	managed.signature = signature
	managed.settingsSignature = settingsSignature
	managed.filterString = filterString
	managed.root = root
	managed.container = managed.container or addon.AuraCompat:CreateAuraContainer(root)
	if not managed.container then return nil end
	managed.container:ClearAllPoints()
	managed.container:SetAllPoints(root)
	managed.container:SetEnabled(false)
	managed.container:Hide()
	if not AuraUtil.CreateManagedDispelGeneration(managed, root, filterString, dcfg, defDispel) then return nil end
	return managed.slot and managed or nil
end

function AuraUtil.ApplyManagedDispelBorder(st, root, unit, dcfg, defDispel, forceRefresh)
	if not AuraUtil.ShouldUseManagedDispelBorder() then return false end
	if not unit then
		AuraUtil.HideManagedDispelBorder(st)
		return true
	end
	dcfg = dcfg or {}
	defDispel = defDispel or {}
	local enabled = dcfg.enabled
	if enabled == nil then enabled = defDispel.enabled ~= false end
	local glowEnabled = dcfg.glowEnabled
	if glowEnabled == nil then glowEnabled = defDispel.glowEnabled == true end
	if not enabled and not glowEnabled then
		AuraUtil.HideManagedDispelBorder(st)
		return true
	end

	local managed = AuraUtil.PrecreateManagedDispelBorder(st, root, dcfg, defDispel)
	if not (managed and unit) then return false end
	if managed.filtersReset then
		AuraUtil.SetManagedDispelSlotFilterStrings(managed, managed.filterString or AuraUtil.GetManagedDispelFilterString(dcfg, defDispel))
		managed.filtersReset = nil
	end
	if managed.borderEnabled ~= enabled or managed.glowEnabled ~= glowEnabled then
		addon.AuraCompat:UpdateAuraSlot(managed.container, managed.backgroundSlotKey, {
			candidateFilters = enabled and {} or { includeDispelTypes = {} },
		})
		for dispelType, slotKey in pairs(managed.overlaySlotKeys or {}) do
			addon.AuraCompat:UpdateAuraSlot(managed.container, slotKey, {
				candidateFilters = (enabled or glowEnabled) and { includeDispelTypes = { [dispelType] = true } } or { includeDispelTypes = {} },
			})
		end
		managed.borderEnabled = enabled
		managed.glowEnabled = glowEnabled
	end
	local unitChanged = managed.unit ~= unit
	if unitChanged then
		managed.unit = unit
		managed.container:SetUnit(unit)
	end
	managed.container:Show()
	managed.container:SetEnabled(true)
	if forceRefresh or unitChanged or not managed.enabled then addon.AuraCompat:UpdateAuraContainer(managed.container) end
	managed.enabled = true
	return true
end

function AuraUtil.HideSingleDispelIndicator(unit, keepManagedBorder)
	if unit ~= UNIT.PLAYER and unit ~= UNIT.TARGET and unit ~= UNIT.FOCUS then return end
	local st = states[unit]
	if not st then return end

	if st.dispelTint then
		st._dispelTintShown = false
		st.dispelTint:Hide()
	end
	if not keepManagedBorder then AuraUtil.HideManagedDispelBorder(st) end

	if not st._dispelGlowActive then return end
	local effect = st._dispelGlowEffect
	st._dispelGlowActive = nil
	st._dispelGlowEffect = nil

	local target = st.barGroup or st.frame
	if addon.Glow and addon.Glow.Stop and target then
		addon.Glow.Stop(target, "EQOL_DISPEL", true)
		return
	end

	local glowLib = LibStub and LibStub("LibCustomGlow-1.0", true)
	if not (glowLib and target) then return end
	if effect == "SHINE" then
		if glowLib.AutoCastGlow_Stop then glowLib.AutoCastGlow_Stop(target, "EQOL_DISPEL") end
	elseif effect == "PROC" then
		if glowLib.ProcGlow_Stop then glowLib.ProcGlow_Stop(target, "EQOL_DISPEL") end
	elseif effect == "BLIZZARD" then
		if glowLib.ButtonGlow_Stop then glowLib.ButtonGlow_Stop(target) end
	else
		if glowLib.PixelGlow_Stop then glowLib.PixelGlow_Stop(target, "EQOL_DISPEL") end
	end
end

function AuraUtil.CanUnitShowPlayerDispel(unit, allowSample)
	if allowSample then return true end
	if unit == UNIT.PLAYER or unit == "player" then return true end
	if unit ~= UNIT.TARGET and unit ~= UNIT.FOCUS then return false end
	return UnitExists and UnitExists(unit) and UnitIsFriend and UnitIsFriend("player", unit) == true
end

function AuraUtil.UpdateSingleDispelIndicator(unit, allowSample, forceRefresh)
	if unit ~= UNIT.PLAYER and unit ~= UNIT.TARGET and unit ~= UNIT.FOCUS then return end
	local st = states[unit]
	if not st then return end
	local cfg = st.cfg or defaultsFor(unit) or {}
	local def = st.def or defaultsFor(unit) or {}
	local scfg = cfg.status or {}
	local dcfg = scfg.dispelTint or {}
	local defDispel = (def.status and def.status.dispelTint) or {}
	if addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() then
		local showSample = dcfg.showSample
		if showSample == nil then showSample = defDispel.showSample == true end
		if not showSample then
			AuraUtil.HideSingleDispelIndicator(unit)
			return
		end
		allowSample = true
	end
	if not AuraUtil.CanUnitShowPlayerDispel(unit, allowSample) then
		AuraUtil.HideSingleDispelIndicator(unit)
		return
	end
	local visualRoot = st.healthContainer or st.health or st.frame
	if AuraUtil.ShouldUseManagedDispelBorder() and not allowSample then
		AuraUtil.HideSingleDispelIndicator(unit, true)
		AuraUtil.ApplyManagedDispelBorder(st, visualRoot, unit, cfg.status and cfg.status.dispelTint, def.status and def.status.dispelTint, forceRefresh)
		return
	end
	if AuraUtil.ShouldUseManagedDispelBorder() then AuraUtil.HideManagedDispelBorder(st) end
	if not st.dispelTint and visualRoot then st.dispelTint = UFHelper.CreateDispelOverlay(visualRoot) end
	if st.dispelTint and visualRoot then
		local tintLevel, tintStrata = AuraUtil.GetManagedDispelTintLayer(dcfg, defDispel)
		AuraUtil.LayoutManagedDispelHost(st.dispelTint, visualRoot, tintStrata, tintLevel)
	end

	local function clampNumber(value, minValue, maxValue, fallback)
		local v = tonumber(value)
		if v == nil then return fallback end
		if minValue ~= nil and v < minValue then v = minValue end
		if maxValue ~= nil and v > maxValue then v = maxValue end
		return v
	end

	local function hideTint()
		if not st.dispelTint then return end
		if st._dispelTintShown == false then return end
		st._dispelTintShown = false
		st.dispelTint:Hide()
	end

	local function applyTint(r, g, b, alpha, fr, fg, fb, bgAlpha)
		if not st.dispelTint then return end
		st._dispelTintShown = true
		local bg = st.dispelTint.Background
		if bg then
			if bg.SetColorTexture then
				bg:SetColorTexture(fr, fg, fb, 1)
			elseif bg.SetVertexColor then
				bg:SetVertexColor(fr, fg, fb, 1)
			end
			if bg.SetAlpha then bg:SetAlpha(bgAlpha) end
			if bg.SetShown then bg:SetShown(bgAlpha > 0) end
		end
		local grad = st.dispelTint.Gradient
		if grad then grad:SetVertexColor(r, g, b, alpha) end
		local border = st.dispelTint.Border
		if border then border:SetVertexColor(r, g, b, alpha) end
		if st.dispelTint.SetAlpha then st.dispelTint:SetAlpha(1) end
		st.dispelTint:Show()
	end

	local function stopGlow()
		if not st._dispelGlowActive then return end
		local effect = st._dispelGlowEffect
		st._dispelGlowActive = nil
		st._dispelGlowEffect = nil

		local target = st.barGroup or st.frame
		if addon.Glow and addon.Glow.Stop and target then
			addon.Glow.Stop(target, "EQOL_DISPEL", true)
			return
		end

		local glowLib = LibStub and LibStub("LibCustomGlow-1.0", true)
		if not (glowLib and target) then return end
		if effect == "SHINE" then
			if glowLib.AutoCastGlow_Stop then glowLib.AutoCastGlow_Stop(target, "EQOL_DISPEL") end
		elseif effect == "PROC" then
			if glowLib.ProcGlow_Stop then glowLib.ProcGlow_Stop(target, "EQOL_DISPEL") end
		elseif effect == "BLIZZARD" then
			if glowLib.ButtonGlow_Stop then glowLib.ButtonGlow_Stop(target) end
		else
			if glowLib.PixelGlow_Stop then glowLib.PixelGlow_Stop(target, "EQOL_DISPEL") end
		end
	end

	local function findDispelAura()
		if not AuraUtil.canReadAuraData() then return nil end
		if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) or not UnitExists or not UnitExists(unit) then return nil end

		local slots = { C_UnitAuras.GetAuraSlots(unit, AuraUtil.GetManagedDispelFilterString(dcfg, defDispel), 32) }
		for i = 2, #slots do
			local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
			if aura and not (UF.GlobalAuraIgnore and UF.GlobalAuraIgnore.ShouldIgnoreAura and UF.GlobalAuraIgnore.ShouldIgnoreAura(unit, aura)) then return aura end
		end
		return nil
	end

	local function resolveAuraColor(aura)
		if not aura then return nil end
		if AuraUtil.canReadAuraData() and not aura.isSample and aura.auraInstanceID and aura.auraInstanceID > 0 and C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor and UFHelper and UFHelper.debuffColorCurve then
			local color = C_UnitAuras.GetAuraDispelTypeColor(unit, aura.auraInstanceID, UFHelper.debuffColorCurve)
			if color then
				if color.GetRGBA then
					return color:GetRGBA()
				elseif color.r then
					return color.r, color.g, color.b
				end
			end
		end
		if UFHelper and UFHelper.getDebuffColorFromName then
			local dispelName = aura.dispelName
			local canActivePlayerDispel = aura.canActivePlayerDispel
			if issecretvalue and issecretvalue(dispelName) then dispelName = nil end
			if issecretvalue and issecretvalue(canActivePlayerDispel) then canActivePlayerDispel = nil end
			if (not dispelName or dispelName == "") and canActivePlayerDispel == true then dispelName = "Magic" end
			local r, g, b = UFHelper.getDebuffColorFromName(dispelName or "None")
			if r then return r, g, b end
		end
		return nil
	end

	local overlayEnabled = dcfg.enabled
	if overlayEnabled == nil then overlayEnabled = defDispel.enabled ~= false end
	local glowEnabled = dcfg.glowEnabled
	if glowEnabled == nil then glowEnabled = defDispel.glowEnabled == true end

	if not overlayEnabled and not glowEnabled then
		hideTint()
		stopGlow()
		return
	end

	if allowSample then
		local showSample = dcfg.showSample
		if showSample == nil then showSample = defDispel.showSample == true end
		if not showSample then
			hideTint()
			stopGlow()
			return
		end
	end

	local alpha = dcfg.alpha
	if alpha == nil then alpha = defDispel.alpha or 0.25 end
	local fillEnabled = dcfg.fillEnabled
	if fillEnabled == nil then fillEnabled = defDispel.fillEnabled ~= false end
	local fillAlpha = dcfg.fillAlpha
	if fillAlpha == nil then fillAlpha = defDispel.fillAlpha or 0.2 end
	local fillColor = dcfg.fillColor or defDispel.fillColor or { 0, 0, 0, 1 }
	local fr, fg, fb, fa = unpackColor(fillColor, 0, 0, 0, 1)
	if not fillEnabled then fillAlpha = 0 end
	local bgAlpha = fillAlpha * (fa or 1)

	local r, g, b
	if allowSample then
		if UFHelper and UFHelper.getDebuffColorFromName then
			r, g, b = UFHelper.getDebuffColorFromName("Magic")
		end
		if not r then
			r, g, b = 0.2, 0.6, 1
		end
	else
		local aura = findDispelAura()
		if aura then
			r, g, b = resolveAuraColor(aura)
		end
	end

	if overlayEnabled and r then
		applyTint(r, g or 0, b or 0, alpha, fr, fg, fb, bgAlpha)
	else
		hideTint()
	end

	if not glowEnabled then
		stopGlow()
		return
	end

	local target = st.barGroup or st.frame
	if not (target and r and g and b) then
		stopGlow()
		return
	end
	local glowLib = LibStub and LibStub("LibCustomGlow-1.0", true)
	local usingGlow = addon.Glow and addon.Glow.Start and addon.Glow.Stop
	local canPixel = glowLib and glowLib.PixelGlow_Start
	local canShine = glowLib and glowLib.AutoCastGlow_Start
	local canButton = glowLib and glowLib.ButtonGlow_Start

	local colorMode = dcfg.glowColorMode or defDispel.glowColorMode or "DISPEL"
	local cr, cg, cb = r, g, b
	if colorMode == "CUSTOM" then
		local glowColor = dcfg.glowColor or defDispel.glowColor or { 1, 1, 1, 1 }
		cr, cg, cb = unpackColor(glowColor, 1, 1, 1, 1)
	end

	local lines = clampNumber(dcfg.glowLines or defDispel.glowLines or 8, 1, 20, 8)
	local freq = clampNumber(dcfg.glowFrequency or defDispel.glowFrequency or 0.25, -1.5, 1.5, 0.25)
	local thickness = clampNumber(dcfg.glowThickness or defDispel.glowThickness or 3, 1, 10, 3)
	local xoff = clampNumber(dcfg.glowX or defDispel.glowX or 0, -10, 10, 0)
	local yoff = clampNumber(dcfg.glowY or defDispel.glowY or 0, -10, 10, 0)
	local effect = dcfg.glowEffect or defDispel.glowEffect or "PIXEL"
	if effect ~= "PIXEL" and effect ~= "SHINE" and effect ~= "BLIZZARD" then effect = "PIXEL" end

	local appliedEffect = effect
	if appliedEffect == "SHINE" and not canShine then
		appliedEffect = "PIXEL"
	elseif appliedEffect == "BLIZZARD" and not usingGlow and not canButton then
		appliedEffect = "PIXEL"
	end
	if appliedEffect == "PIXEL" and not canPixel then
		stopGlow()
		return
	end
	if st._dispelGlowActive and st._dispelGlowEffect ~= appliedEffect then stopGlow() end

	local glowColor = { cr, cg, cb, 1 }
	local scale = thickness / 3
	if scale < 0.5 then
		scale = 0.5
	elseif scale > 4 then
		scale = 4
	end

	if usingGlow then
		local glowOptions = AuraUtil.GetManagedDispelGlowOptions(nil, dcfg, defDispel)
		addon.Glow.Start(target, "EQOL_DISPEL", appliedEffect, {
			color = glowColor,
			count = lines,
			frequency = freq,
			scale = scale,
			thickness = thickness,
			xOffset = xoff,
			yOffset = yoff,
			strata = glowOptions.strata,
			hostFrameLevelOffset = glowOptions.frameLevelOffset,
			frameLevel = glowOptions.frameLevelOffset,
		})
	elseif appliedEffect == "SHINE" and canShine then
		glowLib.AutoCastGlow_Start(target, glowColor, lines, freq, scale, xoff, yoff, "EQOL_DISPEL")
	elseif appliedEffect == "BLIZZARD" and canButton then
		glowLib.ButtonGlow_Start(target, glowColor, freq)
	else
		glowLib.PixelGlow_Start(target, glowColor, lines, freq, nil, thickness, xoff, yoff, nil, "EQOL_DISPEL")
	end

	st._dispelGlowActive = true
	st._dispelGlowEffect = appliedEffect
end

function AuraUtil.GetSingleDispelOverlayOrientation()
	if AuraUtil._singleDispelOverlayOrientation == nil and EnumUtil and EnumUtil.MakeEnum then
		AuraUtil._singleDispelOverlayOrientation = EnumUtil.MakeEnum("VerticalTopToBottom", "VerticalBottomToTop", "HorizontalLeftToRight")
	end
	return AuraUtil._singleDispelOverlayOrientation
end

UF._isFrameBorderEnabled = UF._isFrameBorderEnabled
	or function(borderCfg, borderDef, fallback)
		if borderCfg == true then return true end
		if borderCfg == false then return false end

		local enabled
		if type(borderCfg) == "table" then enabled = borderCfg.enabled end

		if enabled == nil and type(borderDef) == "table" then enabled = borderDef.enabled end
		if enabled == nil then enabled = fallback end
		if enabled == nil then enabled = true end
		return enabled == true
	end

function UF.ResolveBorderLayoutOffset(region, offset)
	offset = max(0, tonumber(offset) or 0)
	if offset == 0 then return 0 end
	local pixelUtil = addon.PixelUtil
	if pixelUtil and pixelUtil.SizeFromPixels then return pixelUtil.SizeFromPixels(region, offset, 1) end
	return offset
end

function UF.ResolvePixelLayoutSize(region, size)
	size = max(0, tonumber(size) or 0)
	if size == 0 then return 0 end
	local pixelUtil = addon.PixelUtil
	if pixelUtil and pixelUtil.Snap then return pixelUtil.Snap(size, region) end
	return size
end

function UF.AlignBorderHostToPixelGrid(frame)
	if not (frame and frame.GetNumPoints and frame.GetLeft and frame.GetBottom) then return end
	local pixelUtil = addon.PixelUtil
	if not (pixelUtil and pixelUtil.Snap) then return end
	local left, bottom = frame:GetLeft(), frame:GetBottom()
	if left == nil or bottom == nil then return end
	local offsetX = pixelUtil.Snap(left, frame) - left
	local offsetY = pixelUtil.Snap(bottom, frame) - bottom
	local epsilon = ((pixelUtil.OnePixel and pixelUtil.OnePixel(frame)) or 1) * 0.001
	if math.abs(offsetX) < epsilon then offsetX = 0 end
	if math.abs(offsetY) < epsilon then offsetY = 0 end
	if offsetX == 0 and offsetY == 0 then return end

	local points = {}
	for index = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = frame:GetPoint(index)
		points[index] = { point, relativeTo, relativePoint, x or 0, y or 0 }
	end
	if #points == 0 then return end

	frame:ClearAllPoints()
	for _, pointData in ipairs(points) do
		frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4] + offsetX, pointData[5] + offsetY)
	end
end

local function setBackdrop(frame, borderCfg, borderDef, fallbackEnabled)
	if not frame then return end
	if frame.SetBackdrop and not frame._ufBackdropCleared then
		frame:SetBackdrop(nil)
		frame._ufBackdropCleared = true
	end
	if UF._isFrameBorderEnabled(borderCfg, borderDef, fallbackEnabled) then
		if type(borderCfg) ~= "table" then borderCfg = {} end
		local borderFrame = ensureBorderFrame(frame)
		if not borderFrame then return end
		local colorR, colorG, colorB, colorA = unpackColor(borderCfg.color or (borderDef and borderDef.color), 0, 0, 0, 0.8)
		local edgeSize = tonumber(borderCfg.edgeSize) or 1
		if edgeSize <= 0 and borderDef then edgeSize = tonumber(borderDef.edgeSize) or 1 end
		if edgeSize <= 0 then edgeSize = 1 end
		local insetVal = borderCfg.inset
		if insetVal == nil and borderDef then insetVal = borderDef.inset end
		if insetVal == nil then insetVal = edgeSize end
		insetVal = tonumber(insetVal) or edgeSize
		if insetVal < 0 then insetVal = 0 end
		local edgeFile = UFHelper.resolveBorderTexture(borderCfg.texture or (borderDef and borderDef.texture))
		local resolvedEdgeSize = addon.PixelUtil and addon.PixelUtil.SizeFromPixels and addon.PixelUtil.SizeFromPixels(borderFrame, edgeSize, 1) or edgeSize
		local resolvedInsetVal = addon.PixelUtil and addon.PixelUtil.Snap and addon.PixelUtil.Snap(insetVal, frame) or insetVal
		local cache = borderFrame._ufBorderCache
		local styleChanged = not cache
			or cache.enabled ~= true
			or cache.edgeFile ~= edgeFile
			or cache.edgeSize ~= edgeSize
			or cache.resolvedEdgeSize ~= resolvedEdgeSize
			or cache.insetVal ~= insetVal
			or cache.resolvedInsetVal ~= resolvedInsetVal
			or cache.colorR ~= colorR
			or cache.colorG ~= colorG
			or cache.colorB ~= colorB
			or cache.colorA ~= colorA
		if styleChanged then
			if borderFrame.SetBackdrop then borderFrame:SetBackdrop(nil) end
			if addon.PixelUtil and addon.PixelUtil.SetOutside then
				addon.PixelUtil.SetOutside(borderFrame, frame, insetVal, insetVal)
			else
				borderFrame:ClearAllPoints()
				borderFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -insetVal, insetVal)
				borderFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", insetVal, -insetVal)
			end
			if addon.functions and addon.functions.SetSafeBorder then
				addon.functions.SetSafeBorder(borderFrame, true, edgeFile, edgeSize, colorR, colorG, colorB, colorA, {
					stateKey = "_ufSafeBorder",
					defaultTexture = "Interface\\Buttons\\WHITE8x8",
					pixelPerfect = true,
				})
			end
			cache = cache or {}
			cache.enabled = true
			cache.edgeFile = edgeFile
			cache.edgeSize = edgeSize
			cache.resolvedEdgeSize = resolvedEdgeSize
			cache.insetVal = insetVal
			cache.resolvedInsetVal = resolvedInsetVal
			cache.colorR = colorR
			cache.colorG = colorG
			cache.colorB = colorB
			cache.colorA = colorA
			borderFrame._ufBorderCache = cache
		end
		borderFrame:Show()
	else
		local borderFrame = frame._ufBorder
		if borderFrame then
			local cache = borderFrame._ufBorderCache
			if not cache or cache.enabled ~= false then
				if addon.functions and addon.functions.SetSafeBorder then addon.functions.SetSafeBorder(borderFrame, false, nil, nil, nil, nil, nil, nil, { stateKey = "_ufSafeBorder" }) end
				if borderFrame.SetBackdrop then borderFrame:SetBackdrop(nil) end
				cache = cache or {}
				cache.enabled = false
				borderFrame._ufBorderCache = cache
			end
			borderFrame:Hide()
		end
	end
end

local function applyBarBackdrop(bar, cfg, overrideR, overrideG, overrideB, overrideA, options)
	if not bar then return end
	cfg = cfg or {}
	options = options or {}
	local bd = cfg.backdrop or {}
	local backdropTextureKey = bd.texture
	if backdropTextureKey == nil or backdropTextureKey == "" or backdropTextureKey == "DEFAULT" then backdropTextureKey = cfg.texture end
	local backdropTexture = UFHelper.resolveTexture(backdropTextureKey)
	local clampToFill = options.clampToFill == true
	local reverseFill = options.reverseFill == true
	local orientation = UFHelper.normalizeStatusBarOrientation(options.orientation)
	local axis = UFHelper.GetHealthAxis(orientation, reverseFill)
	local cache = bar._ufBackdropCache
	if bd.enabled == false then
		if cache and cache.enabled == false and cache.clampToFill == clampToFill and cache.reverseFill == reverseFill and cache.orientation == orientation then return end
		if bar.SetBackdrop then bar:SetBackdrop(nil) end
		if bar._ufBackdropTexture then bar._ufBackdropTexture:Hide() end
		cache = cache or {}
		cache.enabled = false
		cache.clampToFill = clampToFill
		cache.reverseFill = reverseFill
		cache.orientation = orientation
		cache.statusTex = nil
		cache.texture = nil
		bar._ufBackdropCache = cache
		return
	end
	local colorR, colorG, colorB, colorA
	if overrideR ~= nil and overrideG ~= nil and overrideB ~= nil then
		colorR, colorG, colorB = overrideR, overrideG, overrideB
		colorA = overrideA
		if colorA == nil then
			local _, _, _, fallbackA = unpackColor(bd.color, 0, 0, 0, 0.6)
			colorA = fallbackA
		end
	else
		colorR, colorG, colorB, colorA = unpackColor(bd.color, 0, 0, 0, 0.6)
	end
	local currentStatusTex = (clampToFill and bar.GetStatusBarTexture and bar:GetStatusBarTexture()) or nil
	local styleChanged = not cache
		or cache.enabled ~= true
		or cache.colorR ~= colorR
		or cache.colorG ~= colorG
		or cache.colorB ~= colorB
		or cache.colorA ~= colorA
		or cache.clampToFill ~= clampToFill
		or cache.reverseFill ~= reverseFill
		or cache.orientation ~= orientation
		or cache.statusTex ~= currentStatusTex
		or cache.texture ~= backdropTexture
	if not styleChanged then return end
	if clampToFill then
		if bar.SetBackdrop then bar:SetBackdrop(nil) end
		local tex = bar._ufBackdropTexture
		if not tex then
			tex = bar:CreateTexture(nil, "BACKGROUND")
			bar._ufBackdropTexture = tex
		end
		UFHelper.LayoutMissingHealthTexture(bar, tex, axis)
		tex:SetTexture(backdropTexture)
		if tex.SetHorizTile then tex:SetHorizTile(false) end
		if tex.SetVertTile then tex:SetVertTile(false) end
		if tex.SetVertexColor then tex:SetVertexColor(colorR, colorG, colorB, colorA) end
		tex:Show()
	else
		if bar._ufBackdropTexture then bar._ufBackdropTexture:Hide() end
		bar:SetBackdrop({
			bgFile = backdropTexture,
			edgeFile = nil,
			tile = false,
		})
		bar:SetBackdropColor(colorR, colorG, colorB, colorA)
	end
	cache = cache or {}
	cache.enabled = true
	cache.colorR = colorR
	cache.colorG = colorG
	cache.colorB = colorB
	cache.colorA = colorA
	cache.clampToFill = clampToFill
	cache.reverseFill = reverseFill
	cache.orientation = orientation
	cache.statusTex = currentStatusTex
	cache.texture = backdropTexture
	bar._ufBackdropCache = cache
end

local function ensureCastBorderFrame(st)
	if not st or not st.castBar then return nil end
	local border = st.castBorder
	if not border then
		border = CreateFrame("Frame", nil, st.castBar, "BackdropTemplate")
		border:EnableMouse(false)
		st.castBorder = border
	end
	border:SetFrameStrata(st.castBar:GetFrameStrata())
	local baseLevel = st.castBar:GetFrameLevel() or 0
	border:SetFrameLevel(baseLevel + 3)
	return border
end

local function applyCastBorder(st, ccfg, defc)
	if not st or not st.castBar then return end
	local borderCfg = (ccfg and ccfg.border) or (defc and defc.border) or {}
	if borderCfg.enabled == true then
		local border = ensureCastBorderFrame(st)
		if not border then return end
		local size = tonumber(borderCfg.edgeSize) or 1
		if size < 1 then size = 1 end
		local offset = borderCfg.offset
		if offset == nil then offset = size end
		offset = math.max(0, tonumber(offset) or 0)
		local colorR, colorG, colorB, colorA = unpackColor(borderCfg.color, 0, 0, 0, 0.8)
		local edgeFile = UFHelper.resolveBorderTexture(borderCfg.texture)
		local cache = border._ufCastBorderCache
		local styleChanged = not cache or cache.edgeFile ~= edgeFile or cache.edgeSize ~= size
		local colorChanged = not cache or cache.colorR ~= colorR or cache.colorG ~= colorG or cache.colorB ~= colorB or cache.colorA ~= colorA

		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", st.castBar, "TOPLEFT", -offset, offset)
		border:SetPoint("BOTTOMRIGHT", st.castBar, "BOTTOMRIGHT", offset, -offset)
		if styleChanged then
			local style = {
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = edgeFile,
				edgeSize = size,
				insets = { left = size, right = size, top = size, bottom = size },
			}
			border._ufCastBorderStyle = style
			border:SetBackdrop(style)
			border:SetBackdropColor(0, 0, 0, 0)
		end
		if styleChanged or colorChanged then border:SetBackdropBorderColor(colorR, colorG, colorB, colorA) end
		cache = cache or {}
		cache.edgeFile = edgeFile
		cache.edgeSize = size
		cache.colorR = colorR
		cache.colorG = colorG
		cache.colorB = colorB
		cache.colorA = colorA
		border._ufCastBorderCache = cache
		border:Show()
	else
		local border = st.castBorder
		if border then border:Hide() end
	end
end

function UF._getCastIconBorderMetrics(borderCfg, borderDef)
	local size = type(borderCfg) == "table" and tonumber(borderCfg.edgeSize) or nil
	if size == nil and type(borderDef) == "table" then size = tonumber(borderDef.edgeSize) end
	if size == nil then size = 1 end
	if size < 1 then size = 1 end

	local offset = type(borderCfg) == "table" and borderCfg.offset or nil
	if offset == nil and type(borderDef) == "table" then offset = borderDef.offset end
	if offset == nil then offset = size end
	offset = math.max(0, tonumber(offset) or 0)

	return size, offset
end

function UF._getCastIconBorderOutset(ccfg, defc)
	local borderCfg = ccfg and ccfg.iconBorder
	local borderDef = defc and defc.iconBorder
	local enabled = type(borderCfg) == "table" and borderCfg.enabled
	if enabled == nil and type(borderDef) == "table" then enabled = borderDef.enabled end
	if enabled ~= true then return 0 end
	local size, offset = UF._getCastIconBorderMetrics(borderCfg, borderDef)
	return size + offset
end

function UF._ensureCastIconBorderFrame(st)
	if not st or not st.castBar or not st.castIconHolder or not st.castIcon then return nil end
	local border = st.castIconBorder
	if not border then
		border = CreateFrame("Frame", nil, st.castIconHolder, "BackdropTemplate")
		border:EnableMouse(false)
		st.castIconBorder = border
	end
	border:SetFrameStrata(st.castBar:GetFrameStrata())
	local baseLevel = (st.castIconHolder.GetFrameLevel and st.castIconHolder:GetFrameLevel()) or (st.castBar:GetFrameLevel() or 0)
	border:SetFrameLevel(baseLevel + 1)
	return border
end

function UF._applyCastIconBorder(st, ccfg, defc)
	if not st then return end
	local iconAnchor = st.castIconHolder or st.castIcon
	if not iconAnchor then return end
	local borderCfg = ccfg and ccfg.iconBorder
	local borderDef = defc and defc.iconBorder
	local enabled = type(borderCfg) == "table" and borderCfg.enabled
	if enabled == nil and type(borderDef) == "table" then enabled = borderDef.enabled end

	if enabled == true then
		local border = UF._ensureCastIconBorderFrame(st)
		if not border then return end
		local size, offset = UF._getCastIconBorderMetrics(borderCfg, borderDef)
		local edgeFile = UFHelper.resolveBorderTexture((type(borderCfg) == "table" and borderCfg.texture) or (type(borderDef) == "table" and borderDef.texture))
		local color = (type(borderCfg) == "table" and borderCfg.color) or (type(borderDef) == "table" and borderDef.color) or { 0, 0, 0, 0.8 }
		local colorR, colorG, colorB, colorA = unpackColor(color, 0, 0, 0, 0.8)
		local cache = border._ufCastIconBorderCache
		local styleChanged = not cache or cache.edgeFile ~= edgeFile or cache.edgeSize ~= size
		local colorChanged = not cache or cache.colorR ~= colorR or cache.colorG ~= colorG or cache.colorB ~= colorB or cache.colorA ~= colorA

		border:ClearAllPoints()
		border:SetPoint("TOPLEFT", iconAnchor, "TOPLEFT", -offset, offset)
		border:SetPoint("BOTTOMRIGHT", iconAnchor, "BOTTOMRIGHT", offset, -offset)
		if styleChanged then
			local style = {
				bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = edgeFile,
				edgeSize = size,
				insets = { left = size, right = size, top = size, bottom = size },
			}
			border._ufCastIconBorderStyle = style
			border:SetBackdrop(style)
			border:SetBackdropColor(0, 0, 0, 0)
		end
		if styleChanged or colorChanged then border:SetBackdropBorderColor(colorR, colorG, colorB, colorA) end
		cache = cache or {}
		cache.edgeFile = edgeFile
		cache.edgeSize = size
		cache.colorR = colorR
		cache.colorG = colorG
		cache.colorB = colorB
		cache.colorA = colorA
		border._ufCastIconBorderCache = cache
		border:SetShown(iconAnchor:IsShown())
	else
		local border = st.castIconBorder
		if border then
			border:SetBackdrop(nil)
			border:Hide()
		end
	end
end

local function ensureHealPredictionCalculator(st)
	if not st or st._healPredictionCalcUnsupported then return nil end
	if st._healPredictionCalc then return st._healPredictionCalc end
	if not (CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction) then
		st._healPredictionCalcUnsupported = true
		return nil
	end

	local calc = CreateUnitHealPredictionCalculator()
	if not calc then
		st._healPredictionCalcUnsupported = true
		return nil
	end
	if calc.SetIncomingHealOverflowPercent then calc:SetIncomingHealOverflowPercent(1) end
	st._healPredictionCalc = calc
	return calc
end

function UF.RefreshHealPredictionCalculator(st, unit)
	local calc = ensureHealPredictionCalculator(st)
	if calc and UnitGetDetailedHealPrediction then UnitGetDetailedHealPrediction(unit, "player", calc) end
	return calc
end

local setFrameLevelAbove

local function shouldShowSampleAbsorb(unit)
	local samples = addon.variables.ufSampleAbsorb
	if not samples then return false end
	if samples[unit] == true then return true end
	if unit and unit:match("^boss%d+$") then return samples.boss == true end
	return false
end

function UF.HealthTextUsesAbsorbMode(leftMode, centerMode, rightMode)
	if not (UFHelper and UFHelper.textModeUsesAbsorb) then return false end
	return UFHelper.textModeUsesAbsorb(leftMode) or UFHelper.textModeUsesAbsorb(centerMode) or UFHelper.textModeUsesAbsorb(rightMode)
end

function UF.CacheHealthTextAbsorbAmount(st, unit, maxv, fallbackAbsorb, calc)
	local amount
	if calc and calc.GetTotalDamageAbsorbs then
		amount = calc:GetTotalDamageAbsorbs()
	elseif calc and calc.GetDamageAbsorbs then
		amount = calc:GetDamageAbsorbs()
	end
	if amount == nil then amount = fallbackAbsorb end
	if amount == nil then amount = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0 end

	local maxForValue
	if issecretvalue and issecretvalue(maxv) then
		maxForValue = maxv or 1
	else
		maxForValue = (maxv and maxv > 0) and maxv or 1
	end

	if shouldShowSampleAbsorb(unit) and (not issecretvalue or not issecretvalue(maxForValue)) then amount = (maxForValue or 1) * 0.6 end

	if st then st._healthTextAbsorbAmount = amount end
	return amount
end

local function applyIncomingHealBar(st, hc, healthAxis, regions, interpolation)
	if not (st and st.health and st.incomingHeal) then return end
	local incomingHealTextureKey = hc.incomingHealTexture or hc.texture
	st.incomingHeal:SetStatusBarTexture(UFHelper.resolveTexture(incomingHealTextureKey))
	if st.incomingHeal.SetStatusBarDesaturated then st.incomingHeal:SetStatusBarDesaturated(false) end
	UFHelper.configureSpecialTexture(st.incomingHeal, "HEALTH", incomingHealTextureKey, hc)
	UF.StabilizeStatusBarTexture(st.incomingHeal)
	UFHelper.LayoutHealthOverlayBar(st.health, st.incomingHeal, {
		axis = healthAxis,
		regions = regions,
		role = "MISSING_FROM_CURRENT",
		direction = "HEALTH_FORWARD",
	})
	setFrameLevelAbove(st.incomingHeal, st.health, 1)
	st.incomingHeal:SetMinMaxValues(0, 1)
	UF.SetStatusBarValue(st.incomingHeal, 0, false, true)
	st.incomingHeal:Hide()
end

local function updateIncomingHeal(st, unit, hc, defH, cur, maxv, interpolation, calc)
	local bar = st and st.incomingHeal
	if not bar then return end
	if hc.incomingHealEnabled ~= true then
		bar:Hide()
		return
	end

	calc = calc or UF.RefreshHealPredictionCalculator(st, unit)

	local incomingHeal = 0
	if calc and calc.GetIncomingHeals then
		incomingHeal = calc:GetIncomingHeals() or 0
	elseif UnitGetIncomingHeals then
		incomingHeal = UnitGetIncomingHeals(unit) or 0
	end
	if incomingHeal == nil then incomingHeal = 0 end

	local maxForValue
	if issecretvalue and issecretvalue(maxv) then
		maxForValue = maxv or 1
	else
		maxForValue = (maxv and maxv > 0) and maxv or 1
	end

	local incomingHealSecret = issecretvalue and issecretvalue(incomingHeal)
	local incomingHealValue = incomingHeal
	if hc.showSampleIncomingHeal == true then
		local useSample = false
		if incomingHealSecret then
			useSample = true
		else
			incomingHealValue = tonumber(incomingHeal) or 0
			if incomingHealValue <= 0 then useSample = true end
		end
		if useSample and not (issecretvalue and issecretvalue(maxForValue)) then
			incomingHealValue = (maxForValue or 1) * 0.25
			incomingHealSecret = false
		end
	elseif not incomingHealSecret then
		incomingHealValue = tonumber(incomingHeal) or 0
	end

	local curSecret = issecretvalue and issecretvalue(cur)
	if not incomingHealSecret and not curSecret then
		local missingHealth = (tonumber(maxForValue) or 0) - (tonumber(cur) or 0)
		if missingHealth < 0 then missingHealth = 0 end
		if incomingHealValue > missingHealth then incomingHealValue = missingHealth end
	end

	bar:SetMinMaxValues(0, maxForValue or 1)
	UF.SetStatusBarValue(bar, incomingHealValue or 0, false, true)

	local color = hc.incomingHealColor or defH.incomingHealColor or { 0.2, 0.85, 0.35, 0.45 }
	bar:SetStatusBarColor(color.r or color[1] or 0.2, color.g or color[2] or 0.85, color.b or color[3] or 0.35, color.a or color[4] or 0.45)

	if incomingHealSecret or (incomingHealValue and incomingHealValue > 0) then
		bar:Show()
	else
		bar:Hide()
	end
end

local function shouldShowSampleHealAbsorb(unit)
	local samples = addon.variables.ufSampleHealAbsorb
	if not samples then return false end
	if samples[unit] == true then return true end
	if unit and unit:match("^boss%d+$") then return samples.boss == true end
	return false
end

function UF.ClearCastInterruptState(st)
	if not st then return end
	if st.castInterruptAnim then st.castInterruptAnim:Stop() end
	if st.castInterruptGlowAnim then st.castInterruptGlowAnim:Stop() end
	if st.castInterruptGlow then st.castInterruptGlow:Hide() end
	UFHelper.hideCastSpark(st)
	if st.castBar then st.castBar:SetAlpha(1) end
	st.castInterruptActive = nil
	st.castInterruptToken = (st.castInterruptToken or 0) + 1
end

function UF._setAlphaFromBoolean(region, value, alphaOn, alphaOff)
	if not region then return end
	if value == nil then
		region:SetAlpha(alphaOff)
	elseif region.SetAlphaFromBoolean then
		region:SetAlphaFromBoolean(value, alphaOn, alphaOff)
	elseif type(value) == "boolean" then
		region:SetAlpha(value and alphaOn or alphaOff)
	else
		region:SetAlpha(alphaOff)
	end
end

function UF._hideDefaultCastUninterruptibleBar(st)
	if st and st.castDefaultUninterruptibleBar then st.castDefaultUninterruptibleBar:Hide() end
	local normalTexture = st and st.castBar and st.castBar.GetStatusBarTexture and st.castBar:GetStatusBarTexture()
	if normalTexture then normalTexture:SetAlpha(1) end
end

function UF._ensureDefaultCastUninterruptibleBar(st)
	if not st or not st.castBar then return nil end
	local overlay = st.castDefaultUninterruptibleBar
	if not overlay then
		overlay = st.castBar:CreateTexture(nil, "ARTWORK", nil, 0)
		st.castDefaultUninterruptibleBar = overlay
	end
	local normalTexture = st.castBar.GetStatusBarTexture and st.castBar:GetStatusBarTexture()
	overlay:ClearAllPoints()
	if normalTexture then
		overlay:SetAllPoints(normalTexture)
	else
		overlay:SetAllPoints(st.castBar)
	end
	local tex = (UFHelper.resolveCastUninterruptibleTexture and UFHelper.resolveCastUninterruptibleTexture()) or "ui-castingbar-uninterruptable"
	if overlay.SetAtlas then
		overlay:SetAtlas(tex, false)
	else
		overlay:SetTexture(tex)
	end
	if overlay.SetHorizTile then overlay:SetHorizTile(false) end
	if overlay.SetVertTile then overlay:SetVertTile(false) end
	if overlay.SetVertexColor then overlay:SetVertexColor(1, 1, 1, 1) end
	return overlay
end

function UF._syncDefaultCastUninterruptibleBar(st, notInterruptible)
	if not st or not st.castBar then return end
	if st.castUseDefaultArt ~= true then
		UF._hideDefaultCastUninterruptibleBar(st)
		return
	end
	local overlay = UF._ensureDefaultCastUninterruptibleBar(st)
	if not overlay then return end
	local normalTexture = st.castBar:GetStatusBarTexture()
	UF._setAlphaFromBoolean(normalTexture, notInterruptible, 0, 1)
	UF._setAlphaFromBoolean(overlay, notInterruptible, 1, 0)
	overlay:Show()
end

function UF._setCastBarMinMaxValues(st, minValue, maxValue)
	if not st or not st.castBar then return end
	st.castBar:SetMinMaxValues(minValue, maxValue)
end

function UF._setCastBarValue(st, value)
	if not st or not st.castBar then return end
	st.castBar:SetValue(value)
end

local function stopCast(unit)
	local st = states[unit]
	if not st or not st.castBar then return end
	UF.ClearCastInterruptState(st)
	UFHelper.clearEmpowerStages(st)
	UF._hideDefaultCastUninterruptibleBar(st)
	st.castBar:Hide()
	if st.castName then st.castName:SetText("") end
	if st.castDuration then st.castDuration:SetText("") end
	if st.castIconHolder then st.castIconHolder:Hide() end
	if st.castIcon then st.castIcon:Hide() end
	st.castIconTexture = nil
	st.castTarget = nil
	st.castInfo = nil
	st.castBarDuration = nil
	st.castDurationFormat = nil
	if castOnUpdateHandlers[unit] then
		st.castBar:SetScript("OnUpdate", nil)
		castOnUpdateHandlers[unit] = nil
	end
end

local function applyCastLayout(cfg, unit)
	local st = states[unit]
	if not st or not st.castBar then return end
	local def = defaultsFor(unit)
	local ccfg = (cfg and cfg.cast) or {}
	local defc = (def and def.cast) or {}
	local hc = (cfg and cfg.health) or {}
	local nameAnchor = type(ccfg.nameAnchor) == "string" and string.upper(ccfg.nameAnchor) or nil
	if nameAnchor ~= "LEFT" and nameAnchor ~= "CENTER" and nameAnchor ~= "RIGHT" then
		nameAnchor = type(defc.nameAnchor) == "string" and string.upper(defc.nameAnchor) or "LEFT"
		if nameAnchor ~= "LEFT" and nameAnchor ~= "CENTER" and nameAnchor ~= "RIGHT" then nameAnchor = "LEFT" end
	end
	local width = ccfg.width or (cfg and cfg.width) or defc.width or (def and def.width) or 220
	local height = ccfg.height or defc.height or 16
	local defaultBackdropInset = ((tonumber(height) or 0) <= 20) and 0 or 1
	st.castBar:SetSize(width, height)
	local anchor = (ccfg.anchor or defc.anchor or "BOTTOM")
	local off = ccfg.offset or defc.offset or { x = 0, y = -4 }
	local centerOffset = (st and st._portraitCenterOffset) or 0
	local anchorFrame = st.barGroup or st.frame
	local castStrata = normalizeStrataToken(ccfg.strata) or normalizeStrataToken(defc.strata) or ((st.frame and st.frame.GetFrameStrata and st.frame:GetFrameStrata()) or "MEDIUM")
	local castLevelOffset = tonumber(ccfg.frameLevelOffset)
	if castLevelOffset == nil then castLevelOffset = tonumber(defc.frameLevelOffset) end
	if castLevelOffset == nil then castLevelOffset = 1 end
	local baseFrameLevel = (st.frame and st.frame.GetFrameLevel and st.frame:GetFrameLevel()) or 0
	local castFrameLevel = math.max(0, baseFrameLevel + castLevelOffset)
	if st.castBar.GetFrameStrata and st.castBar.SetFrameStrata and st.castBar:GetFrameStrata() ~= castStrata then st.castBar:SetFrameStrata(castStrata) end
	if st.castBar.GetFrameLevel and st.castBar.SetFrameLevel and st.castBar:GetFrameLevel() ~= castFrameLevel then st.castBar:SetFrameLevel(castFrameLevel) end
	st.castBar:ClearAllPoints()
	if anchor == "TOP" then
		st.castBar:SetPoint("BOTTOM", anchorFrame, "TOP", (off.x or 0) + centerOffset, off.y or 0)
	else
		st.castBar:SetPoint("TOP", anchorFrame, "BOTTOM", (off.x or 0) + centerOffset, off.y or 0)
	end
	if st.castName then
		local nameOff = ccfg.nameOffset or defc.nameOffset or { x = 6, y = 0 }
		st.castName:ClearAllPoints()
		st.castName:SetPoint(nameAnchor, st.castBar, nameAnchor, nameOff.x or 0, nameOff.y or 0)
		st.castName:SetShown(ccfg.showName ~= false)
	end
	if st.castDuration then
		local durOff = ccfg.durationOffset or defc.durationOffset or { x = -6, y = 0 }
		st.castDuration:ClearAllPoints()
		st.castDuration:SetPoint("RIGHT", st.castBar, "RIGHT", durOff.x or 0, durOff.y or 0)
		st.castDuration:SetShown(ccfg.showDuration ~= false)
		if st.castDuration.SetWordWrap then st.castDuration:SetWordWrap(false) end
		if st.castDuration.SetJustifyH then st.castDuration:SetJustifyH("RIGHT") end
	end
	local showIcon = ccfg.showIcon
	if showIcon == nil then showIcon = defc.showIcon end
	if showIcon == nil then showIcon = true end
	showIcon = showIcon ~= false
	if st.castIconHolder then
		local size = ccfg.iconSize or defc.iconSize or height
		local iconOff = ccfg.iconOffset or defc.iconOffset or { x = -4, y = 0 }
		if type(iconOff) ~= "table" then iconOff = { x = iconOff, y = 0 } end
		st.castIconHolder:SetSize(size, size)
		st.castIconHolder:ClearAllPoints()
		st.castIconHolder:SetPoint("RIGHT", st.castBar, "LEFT", iconOff.x or -4, iconOff.y or 0)
		st.castIconHolder:SetShown(showIcon)
	end
	if st.castIcon then
		if not st.castIconHolder then
			local size = ccfg.iconSize or defc.iconSize or height
			local iconOff = ccfg.iconOffset or defc.iconOffset or { x = -4, y = 0 }
			if type(iconOff) ~= "table" then iconOff = { x = iconOff, y = 0 } end
			st.castIcon:SetSize(size, size)
			st.castIcon:ClearAllPoints()
			st.castIcon:SetPoint("RIGHT", st.castBar, "LEFT", iconOff.x or -4, iconOff.y or 0)
		end
		st.castIcon:SetShown(showIcon)
	end
	local texKey = ccfg.texture or defc.texture or "DEFAULT"
	local useDefaultArt = not texKey or texKey == "" or texKey == "DEFAULT"
	local castTexture = UFHelper.resolveCastTexture(texKey)
	st.castBar:SetStatusBarTexture(castTexture)
	st.castUseDefaultArt = useDefaultArt
	UF._syncDefaultCastUninterruptibleBar(st, unit ~= UNIT.PLAYER and st.castInfo and st.castInfo.notInterruptible)
	do -- Cast backdrop
		local bd = (ccfg and ccfg.backdrop) or (defc and defc.backdrop) or { enabled = true, color = { 0, 0, 0, 0.6 } }
		local backdropTexKey = bd.texture
		if backdropTexKey == nil or backdropTexKey == "" or backdropTexKey == "DEFAULT" then backdropTexKey = texKey end
		local useDefaultBackdropArt = not backdropTexKey or backdropTexKey == "" or backdropTexKey == "DEFAULT"
		local castBackdropTexture = UFHelper.resolveCastTexture(backdropTexKey)
		if st.castBar.SetBackdrop then st.castBar:SetBackdrop(nil) end
		local bg = st.castBar.backdropTexture
		if bd.enabled == false then
			if bg then bg:Hide() end
		else
			if not bg then
				bg = st.castBar:CreateTexture(nil, "BACKGROUND")
				st.castBar.backdropTexture = bg
			end
			local col = bd.color or { 0, 0, 0, 0.6 }
			bg:ClearAllPoints()
			if useDefaultBackdropArt and bg.SetAtlas then
				bg:SetAtlas("ui-castingbar-background", false)
				bg:SetPoint("TOPLEFT", st.castBar, "TOPLEFT", -defaultBackdropInset, defaultBackdropInset)
				bg:SetPoint("BOTTOMRIGHT", st.castBar, "BOTTOMRIGHT", defaultBackdropInset, -defaultBackdropInset)
			else
				bg:SetTexture(castBackdropTexture)
				bg:SetAllPoints(st.castBar)
			end
			bg:SetVertexColor(col[1] or 0, col[2] or 0, col[3] or 0, col[4] or 0.6)
			bg:Show()
		end
	end
	applyCastBorder(st, ccfg, defc)
	UF._applyCastIconBorder(st, ccfg, defc)
	-- Limit cast name width so long names don't overlap duration text
	if st.castName then
		local iconSize = (ccfg.iconSize or defc.iconSize or height) + 4
		if not showIcon then
			iconSize = 0
		else
			iconSize = iconSize + (UF._getCastIconBorderOutset(ccfg, defc) * 2)
		end
		local durationSpace = (ccfg.showDuration ~= false) and 60 or 0
		local available = (width or 0) - iconSize - durationSpace - 6
		if available < 0 then available = 0 end
		local maxChars = ccfg.nameMaxChars
		if maxChars == nil then maxChars = defc.nameMaxChars end
		maxChars = tonumber(maxChars) or 0
		if maxChars > 0 and UFHelper.getNameLimitWidth then
			local castFont = ccfg.font or defc.font or hc.font
			local castFontSize = ccfg.fontSize or defc.fontSize or hc.fontSize or 12
			local castOutline = ccfg.fontOutline or defc.fontOutline or hc.fontOutline or "OUTLINE"
			local maxWidth = UFHelper.getNameLimitWidth(castFont, castFontSize, castOutline, maxChars)
			if maxWidth and maxWidth > 0 then available = maxWidth end
		end
		st.castName:SetWidth(available)
		if st.castName.SetWordWrap then st.castName:SetWordWrap(false) end
		if st.castName.SetMaxLines then st.castName:SetMaxLines(1) end
		if st.castName.SetJustifyH then st.castName:SetJustifyH(nameAnchor) end
	end
	if st.castEmpower and st.castEmpower.stagePercents then UFHelper.layoutEmpowerStages(st) end
end

local function getClassColor(class)
	if issecretvalue and issecretvalue(class) then return nil end
	if not class then return nil end
	if addon.db and addon.db.ufUseCustomClassColors then
		local overrides = addon.db.ufClassColors
		local custom = overrides and overrides[class]
		if custom then
			if custom.r then return custom.r, custom.g, custom.b, custom.a or 1 end
			if custom[1] then return custom[1], custom[2], custom[3], custom[4] or 1 end
		end
	end
	local fallback = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
	if fallback then return fallback.r or fallback[1], fallback.g or fallback[2], fallback.b or fallback[3], fallback.a or fallback[4] or 1 end
	return nil
end

function UF.IsPartyAI(unit)
	local unitInPartyIsAI = _G.UnitInPartyIsAI
	return (unitInPartyIsAI and unitInPartyIsAI(unit)) or false
end

function UF.IsPlayerOrPartyAI(unit)
	return (UnitIsPlayer and UnitIsPlayer(unit)) or UF.IsPartyAI(unit)
end

function UF.ApplySecretUnitClassTextColor(fontString, unit)
	if not (fontString and UnitClass and C_ClassColor and C_ClassColor.GetClassColor) then return false end
	local isPartyAI = UF.IsPartyAI(unit)
	if not (isPartyAI or (UnitIsPlayer and UnitIsPlayer(unit))) then return false end
	local class = select(2, UnitClass(unit))
	if not isPartyAI and not (issecretvalue and issecretvalue(class)) then return false end
	fontString:SetTextColor(C_ClassColor.GetClassColor(class):GetRGBA())
	return true
end

function UF.ApplySecretUnitClassStatusBarColor(statusBar, unit)
	if not (statusBar and UnitClass and C_ClassColor and C_ClassColor.GetClassColor) then return false end
	local isPartyAI = UF.IsPartyAI(unit)
	if not (isPartyAI or (UnitIsPlayer and UnitIsPlayer(unit))) then return false end
	local class = select(2, UnitClass(unit))
	if not isPartyAI and not (issecretvalue and issecretvalue(class)) then return false end
	statusBar:SetStatusBarColor(C_ClassColor.GetClassColor(class):GetRGBA())
	return true
end

function UF.ApplyHealthBackdrop(st, unit, hc, defH, reverseHealth)
	if not (st and st.health) then return end
	hc = hc or {}
	defH = defH or {}
	local backdropCfg = hc.backdrop or {}
	local useBackdropClassColor = backdropCfg.useClassColor
	if useBackdropClassColor == nil and defH.backdrop then useBackdropClassColor = defH.backdrop.useClassColor end
	local healthBackdropClampToFill = backdropCfg.clampToFill
	if healthBackdropClampToFill == nil and defH.backdrop then healthBackdropClampToFill = defH.backdrop.clampToFill end
	if healthBackdropClampToFill == nil then healthBackdropClampToFill = false end

	local healthBackdropR, healthBackdropG, healthBackdropB, healthBackdropA
	if useBackdropClassColor == true then
		local class
		if UnitIsPlayer and UnitIsPlayer(unit) then
			class = select(2, UnitClass(unit))
		elseif unit == UNIT.PET then
			class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
		end
		local cr, cg, cb = getClassColor(class)
		if cr then
			local backdropColor = backdropCfg.color or (defH.backdrop and defH.backdrop.color) or { 0, 0, 0, 0.6 }
			healthBackdropR, healthBackdropG, healthBackdropB = cr, cg, cb
			healthBackdropA = backdropColor[4]
			if healthBackdropA == nil then healthBackdropA = 0.6 end
		end
	end

	local options = st._healthBackdropOptions
	if not options then
		options = {}
		st._healthBackdropOptions = options
	end
	options.clampToFill = healthBackdropClampToFill == true
	options.reverseFill = reverseHealth == true
	options.orientation = hc.orientation or defH.orientation
	applyBarBackdrop(st.health, hc, healthBackdropR, healthBackdropG, healthBackdropB, healthBackdropA, options)
end

local function configureCastStatic(unit, ccfg, defc)
	local st = states[unit]
	if not st or not st.castBar or not st.castInfo then return end
	ccfg = ccfg or st.castCfg or {}
	defc = defc or (defaultsFor(unit) and defaultsFor(unit).cast) or {}

	local showInterruptFeedback = ccfg.showInterruptFeedback
	if showInterruptFeedback == nil then showInterruptFeedback = defc.showInterruptFeedback end
	if showInterruptFeedback == nil then showInterruptFeedback = true end
	st.castInterruptFeedbackEnabled = showInterruptFeedback ~= false

	local showInterruptFeedbackGlow = ccfg.showInterruptFeedbackGlow
	if showInterruptFeedbackGlow == nil then showInterruptFeedbackGlow = defc.showInterruptFeedbackGlow end
	if showInterruptFeedbackGlow == nil then showInterruptFeedbackGlow = true end
	st.castInterruptFeedbackGlow = showInterruptFeedbackGlow ~= false

	local interruptColor = ccfg.interruptFeedbackColor
	if type(interruptColor) ~= "table" then interruptColor = defc.interruptFeedbackColor end
	local ir
	local ig
	local ib
	local ia
	if type(interruptColor) == "table" then
		ir = interruptColor.r or interruptColor[1]
		ig = interruptColor.g or interruptColor[2]
		ib = interruptColor.b or interruptColor[3]
		ia = interruptColor.a or interruptColor[4]
	end
	if ir == nil then ir = 0.85 end
	if ig == nil then ig = 0.12 end
	if ib == nil then ib = 0.12 end
	if ia == nil then ia = 1 end
	st.castInterruptFeedbackR = ir
	st.castInterruptFeedbackG = ig
	st.castInterruptFeedbackB = ib
	st.castInterruptFeedbackA = ia

	local gradientCfg = unit == UNIT.PLAYER and ccfg or nil
	local isEmpoweredDefault = st.castInfo.isEmpowered and st.castUseDefaultArt == true
	local useDefaultArt = st.castUseDefaultArt == true
	local clr = ccfg.color or defc.color or { 0.9, 0.7, 0.2, 1 }
	local useClassColor = ccfg.useClassColor
	if useClassColor == nil then useClassColor = defc.useClassColor end
	if useClassColor == true then
		local class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
		local cr, cg, cb, ca = getClassColor(class)
		if cr then clr = { cr, cg, cb, ca or 1 } end
	end
	if isEmpoweredDefault then
		st.castBar:SetStatusBarDesaturated(false)
		UFHelper.SetCastbarColorWithGradient(st.castBar, nil, 0, 0, 0, 0)
	elseif useDefaultArt then
		st.castBar:SetStatusBarDesaturated(false)
		UFHelper.SetCastbarColorWithGradient(st.castBar, nil, 1, 1, 1, 1)
	else
		local nclr = (unit == UNIT.PLAYER) and clr or (ccfg.notInterruptibleColor or defc.notInterruptibleColor or clr)
		st.castBar:SetStatusBarDesaturated(false)
		UFHelper.SetCastbarColorWithGradient(st.castBar, gradientCfg, clr[1] or 0.9, clr[2] or 0.7, clr[3] or 0.2, clr[4] or 1)
		local tex = st.castBar:GetStatusBarTexture()
		local showUninterruptible = unit ~= UNIT.PLAYER and st.castInfo.notInterruptible
		if tex and tex.SetVertexColorFromBoolean then
			tex:SetVertexColorFromBoolean(
				showUninterruptible,
				CreateColor(nclr[1] or 0.9, nclr[2] or 0.7, nclr[3] or 0.2, nclr[4] or 1),
				CreateColor(clr[1] or 0.9, clr[2] or 0.7, clr[3] or 0.2, clr[4] or 1)
			)
		end
	end
	UF._syncDefaultCastUninterruptibleBar(st, unit ~= UNIT.PLAYER and st.castInfo.notInterruptible)
	local duration = (st.castInfo.endTime or 0) - (st.castInfo.startTime or 0)
	local maxValue = duration and duration > 0 and duration / 1000 or 1
	st.castInfo.maxValue = maxValue
	-- UFHelper.applyStatusBarReverseFill(st.castBar, st.castInfo.isChannel == true and not st.castInfo.isEmpowered)
	UF._setCastBarMinMaxValues(st, 0, maxValue)
	UFHelper.RefreshCastbarGradient(st.castBar, useDefaultArt and nil or gradientCfg)
	UF._syncDefaultCastUninterruptibleBar(st, unit ~= UNIT.PLAYER and st.castInfo.notInterruptible)
	if st.castName then
		local showName = ccfg.showName ~= false
		st.castName:SetShown(showName)
		local nameText = showName and (st.castInfo.name or "") or ""
		if showName and UFHelper.formatCastName then
			local showTarget = ccfg.showCastTarget
			if showTarget == nil then showTarget = defc.showCastTarget end
			if unit ~= UNIT.PLAYER then showTarget = false end
			nameText = UFHelper.formatCastName(nameText, st.castTarget, showTarget == true)
		end
		st.castName:SetText(nameText)
	end
	if st.castIcon then
		local iconTexture = UFHelper.resolveCastIconTexture(st.castInfo.texture)
		local showIcon = ccfg.showIcon
		if showIcon == nil then showIcon = defc.showIcon end
		if showIcon == nil then showIcon = true end
		showIcon = showIcon ~= false
		if st.castIconHolder then st.castIconHolder:SetShown(showIcon) end
		st.castIcon:SetShown(showIcon)
		if showIcon then
			st.castIcon:SetTexture(iconTexture)
			st.castIconTexture = iconTexture
		end
	end
	UF._applyCastIconBorder(st, ccfg, defc)
	if st.castDuration then st.castDuration:SetShown(ccfg.showDuration ~= false) end
	st.castBar:Show()
end

local function updateCastBar(unit)
	local st = states[unit]
	local ccfg = st and st.castCfg
	if not st or not st.castBar or not st.castInfo or not ccfg then
		stopCast(unit)
		return
	end
	if st.castInfo.useTimer then
		if st.castInfo.isEmpowered then
			UFHelper.updateEmpowerStageFromBar(st)
			UFHelper.updateCastSpark(st, "empowered")
		else
			UFHelper.hideCastSpark(st)
		end
		return
	end
	if not st.castInfo.startTime or not st.castInfo.endTime then
		stopCast(unit)
		return
	end
	if issecretvalue and (issecretvalue(st.castInfo.startTime) or issecretvalue(st.castInfo.endTime)) then
		stopCast(unit)
		return
	end
	local nowMs = GetTime() * 1000
	local startMs = st.castInfo.startTime or 0
	local endMs = st.castInfo.endTime or 0
	local duration = endMs - startMs
	if not duration or duration <= 0 then
		stopCast(unit)
		return
	end
	if nowMs >= endMs then
		if UF.ShouldShowSampleCast(unit) then
			UF.SetSampleCast(unit)
		else
			stopCast(unit)
		end
		return
	end
	local elapsedMs
	if st.castInfo.isEmpowered then
		elapsedMs = nowMs - startMs
	else
		elapsedMs = st.castInfo.isChannel and (endMs - nowMs) or (nowMs - startMs)
	end
	if elapsedMs < 0 then elapsedMs = 0 end
	local value = elapsedMs / 1000
	UF._setCastBarValue(st, value)
	if
		unit == UNIT.PLAYER
		and not (st.castInfo.isEmpowered and st.castUseDefaultArt == true)
		and ccfg.useGradient == true
		and type(ccfg.gradientMode) == "string"
		and ccfg.gradientMode:upper() == "BAR_END"
	then
		local maxValue = st.castInfo.maxValue
		local progress
		if type(maxValue) == "number" and maxValue > 0 then progress = value / maxValue end
		UFHelper.RefreshCastbarGradient(st.castBar, ccfg, nil, nil, nil, nil, progress)
	end
	if st.castInfo.isEmpowered then
		local maxValue = st.castInfo.maxValue
		if not maxValue then
			local _, maxVal = st.castBar:GetMinMaxValues()
			maxValue = maxVal
		end
		if maxValue and maxValue > 0 and (not issecretvalue or (not issecretvalue(value) and not issecretvalue(maxValue))) then UFHelper.updateEmpowerStageFromProgress(st, value / maxValue) end
		UFHelper.updateCastSpark(st, "empowered")
	else
		UFHelper.hideCastSpark(st)
	end
	if st.castDuration then
		if ccfg.showDuration ~= false then
			local durationFormat = ccfg.durationFormat or "REMAINING"
			if durationFormat == "ELAPSED_TOTAL" then
				local total = duration / 1000
				local elapsed = (nowMs - startMs) / 1000
				if elapsed < 0 then elapsed = 0 end
				if elapsed > total then elapsed = total end
				local tenths = math.floor(elapsed * 10 + 0.5)
				if st.castInfo.durationTenths ~= tenths then
					st.castInfo.durationTenths = tenths
					st.castDuration:SetText(("%.1f / %.1f"):format(elapsed, total))
				end
			elseif durationFormat == "REMAINING_TOTAL" then
				local total = duration / 1000
				local remaining = (endMs - nowMs) / 1000
				if remaining < 0 then remaining = 0 end
				if remaining > total then remaining = total end
				local tenths = math.floor(remaining * 10 + 0.5)
				if st.castInfo.durationTenths ~= tenths then
					st.castInfo.durationTenths = tenths
					st.castDuration:SetText(("%.1f / %.1f"):format(remaining, total))
				end
			else
				local remaining = (endMs - nowMs) / 1000
				if remaining < 0 then remaining = 0 end
				local tenths = math.floor(remaining * 10 + 0.5)
				if st.castInfo.durationTenths ~= tenths then
					st.castInfo.durationTenths = tenths
					st.castDuration:SetText(("%.1f"):format(remaining))
				end
			end
			st.castDuration:Show()
		else
			st.castInfo.durationTenths = nil
			st.castDuration:SetText("")
			st.castDuration:Hide()
		end
	end
end

function UF.OnCastBarUpdate(self)
	local unit = self and self._eqolUFUnit
	if not unit then
		self:SetScript("OnUpdate", nil)
		return
	end
	updateCastBar(unit)
end

function UF.OnCastDurationTimerUpdate(self, elapsed)
	local unit = self and self._eqolUFUnit
	if not unit then
		self:SetScript("OnUpdate", nil)
		return
	end
	local st = states[unit]
	local timerObj = st and st.castBarDuration
	if not st or not timerObj then
		self:SetScript("OnUpdate", nil)
		castOnUpdateHandlers[unit] = nil
		return
	end

	self._eqolCastDurationElapsed = (self._eqolCastDurationElapsed or 0) + (elapsed or 0)
	if self._eqolCastDurationElapsed < 0.1 then return end
	self._eqolCastDurationElapsed = 0

	local totalDuration = timerObj:GetTotalDuration()
	if type(totalDuration) ~= "number" then totalDuration = 0 end
	if not st.castDuration then return end

	local durationFormat = st.castDurationFormat or "REMAINING"
	if durationFormat == "ELAPSED_TOTAL" then
		st.castDuration:SetText(("%.1f / %.1f"):format(timerObj:GetElapsedDuration(), totalDuration))
	elseif durationFormat == "REMAINING_TOTAL" then
		st.castDuration:SetText(("%.1f / %.1f"):format(timerObj:GetRemainingDuration(), totalDuration))
	else
		st.castDuration:SetText(("%.1f"):format(timerObj:GetRemainingDuration()))
	end
end

function UF.OnCastInterruptAnimFinished(self)
	local unit = self and self._eqolUFUnit
	local token = self and self._eqolCastInterruptToken
	local st = unit and states[unit]
	if not st or st.castInterruptToken ~= token then return end
	stopCast(unit)
	if UF.ShouldShowSampleCast(unit) then UF.SetSampleCast(unit) end
end

function UF.ShouldShowSampleCast(unit) return UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit) end

function UF.SetSampleCast(unit)
	local key = isBossUnit(unit) and "boss" or unit
	local st = states[unit]
	if not st or not st.castBar then return end
	UF.ClearCastInterruptState(st)
	UFHelper.clearEmpowerStages(st)
	local cfg = (st and st.cfg) or ensureDB(key or unit)
	local ccfg = (cfg or {}).cast or {}
	local def = defaultsFor(unit)
	local defc = (def and def.cast) or {}
	if ccfg.enabled == false then
		stopCast(unit)
		return
	end
	local resolvedCfg = ccfg or defc or {}
	st.castCfg = resolvedCfg
	local nowMs = GetTime() * 1000
	if st.castInfo and st.castInfo.isSample == true and type(st.castInfo.endTime) == "number" and st.castInfo.endTime > nowMs then
		applyCastLayout(cfg, unit)
		configureCastStatic(unit, resolvedCfg, defc)
		if not castOnUpdateHandlers[unit] then
			st.castBar._eqolUFUnit = unit
			st.castBar:SetScript("OnUpdate", UF.OnCastBarUpdate)
			castOnUpdateHandlers[unit] = true
		end
		updateCastBar(unit)
		return
	end
	st.castInfo = {
		name = L["Sample Cast"] or "Sample Cast",
		texture = 136235, -- lightning icon as placeholder
		startTime = nowMs,
		endTime = nowMs + 3000,
		notInterruptible = false,
		isChannel = false,
		isSample = true,
	}
	applyCastLayout(cfg, unit)
	configureCastStatic(unit, resolvedCfg, defc)
	if not castOnUpdateHandlers[unit] then
		st.castBar._eqolUFUnit = unit
		st.castBar:SetScript("OnUpdate", UF.OnCastBarUpdate)
		castOnUpdateHandlers[unit] = true
	end
	updateCastBar(unit)
end

local function shouldIgnoreCastFail(unit, castGUID, spellId, castBarID)
	if UnitChannelInfo then
		local channelName = UnitChannelInfo(unit)
		if channelName then return true end
	end
	local st = states[unit]
	if not st or not st.castInfo then return false end
	if st.castInfo.castBarID and castBarID and st.castInfo.castBarID ~= castBarID then return true end
	if st.castInfo.castGUID and castGUID then
		if not (issecretvalue and (issecretvalue(st.castInfo.castGUID) or issecretvalue(castGUID))) and st.castInfo.castGUID ~= castGUID then return true end
	end
	if st.castInfo.spellId and spellId and st.castInfo.castGUID then
		if not (issecretvalue and (issecretvalue(st.castInfo.spellId) or issecretvalue(spellId))) and st.castInfo.spellId ~= spellId then return true end
	end
	return false
end

function UF.ShowCastInterrupt(unit, event)
	local key = isBossUnit(unit) and "boss" or unit
	local st = states[unit]
	if not st or not st.castBar then return end
	local cfg = (st and st.cfg) or ensureDB(key or unit)
	if cfg and cfg.enabled == false then return end
	local ccfg = (cfg or {}).cast or {}
	local defc = (defaultsFor(unit) and defaultsFor(unit).cast) or {}
	if ccfg.enabled == false then return end
	if not st.castBar:IsShown() and not st.castInfo then return end
	local showInterruptFeedback = st.castInterruptFeedbackEnabled
	if showInterruptFeedback == nil then
		showInterruptFeedback = ccfg.showInterruptFeedback
		if showInterruptFeedback == nil then showInterruptFeedback = defc.showInterruptFeedback end
		if showInterruptFeedback == nil then showInterruptFeedback = true end
		showInterruptFeedback = showInterruptFeedback ~= false
		st.castInterruptFeedbackEnabled = showInterruptFeedback
	end
	if showInterruptFeedback == false then
		stopCast(unit)
		if UF.ShouldShowSampleCast(unit) then UF.SetSampleCast(unit) end
		return
	end

	UF.ClearCastInterruptState(st)
	UFHelper.clearEmpowerStages(st)
	st.castInterruptActive = true
	local token = st.castInterruptToken or 0

	if castOnUpdateHandlers[unit] then
		st.castBar:SetScript("OnUpdate", nil)
		castOnUpdateHandlers[unit] = nil
	end

	applyCastLayout(cfg, unit)

	local texKey = ccfg.texture or defc.texture or "DEFAULT"
	local useDefault = not texKey or texKey == "" or texKey == "DEFAULT"
	local interruptTex
	if useDefault then
		interruptTex = (UFHelper.resolveCastInterruptTexture and UFHelper.resolveCastInterruptTexture()) or UFHelper.resolveCastTexture(texKey)
	else
		interruptTex = UFHelper.resolveCastTexture(texKey)
	end
	if interruptTex then st.castBar:SetStatusBarTexture(interruptTex) end
	UF._hideDefaultCastUninterruptibleBar(st)
	if st.castBar.SetStatusBarDesaturated then st.castBar:SetStatusBarDesaturated(false) end
	local ir = st.castInterruptFeedbackR
	local ig = st.castInterruptFeedbackG
	local ib = st.castInterruptFeedbackB
	local ia = st.castInterruptFeedbackA
	if ir == nil then
		local interruptColor = ccfg.interruptFeedbackColor
		if type(interruptColor) ~= "table" then interruptColor = defc.interruptFeedbackColor end
		if type(interruptColor) == "table" then
			ir = interruptColor.r or interruptColor[1]
			ig = interruptColor.g or interruptColor[2]
			ib = interruptColor.b or interruptColor[3]
			ia = interruptColor.a or interruptColor[4]
		end
		if ir == nil then ir = 0.85 end
		if ig == nil then ig = 0.12 end
		if ib == nil then ib = 0.12 end
		if ia == nil then ia = 1 end
		st.castInterruptFeedbackR = ir
		st.castInterruptFeedbackG = ig
		st.castInterruptFeedbackB = ib
		st.castInterruptFeedbackA = ia
	end
	UFHelper.SetCastbarColorWithGradient(st.castBar, nil, ir, ig, ib, ia)
	UF._setCastBarMinMaxValues(st, 0, 1)
	UF._setCastBarValue(st, 1)
	if st.castDuration then
		st.castDuration:SetText("")
		st.castDuration:Hide()
	end
	if st.castName then
		local label = (event == "UNIT_SPELLCAST_FAILED") and FAILED or INTERRUPTED
		st.castName:SetText(label)
		st.castName:SetShown(ccfg.showName ~= false)
	end
	if st.castIcon then
		local iconTexture = UFHelper.resolveCastIconTexture((st.castInfo and st.castInfo.texture) or st.castIconTexture)
		local showIcon = ccfg.showIcon
		if showIcon == nil then showIcon = defc.showIcon end
		if showIcon == nil then showIcon = true end
		showIcon = showIcon ~= false
		if st.castIconHolder then st.castIconHolder:SetShown(showIcon) end
		st.castIcon:SetShown(showIcon)
		if showIcon then
			st.castIcon:SetTexture(iconTexture)
			st.castIconTexture = iconTexture
		end
	end
	UF._applyCastIconBorder(st, ccfg, defc)

	local showInterruptFeedbackGlow = st.castInterruptFeedbackGlow
	if showInterruptFeedbackGlow == nil then
		showInterruptFeedbackGlow = ccfg.showInterruptFeedbackGlow
		if showInterruptFeedbackGlow == nil then showInterruptFeedbackGlow = defc.showInterruptFeedbackGlow end
		if showInterruptFeedbackGlow == nil then showInterruptFeedbackGlow = true end
		showInterruptFeedbackGlow = showInterruptFeedbackGlow ~= false
		st.castInterruptFeedbackGlow = showInterruptFeedbackGlow
	end
	if showInterruptFeedbackGlow ~= false then
		local glowAlpha = (useDefault and 0.4 or 0.25) * (ia or 1)
		if glowAlpha < 0 then
			glowAlpha = 0
		elseif glowAlpha > 1 then
			glowAlpha = 1
		end
		if not st.castInterruptGlow then
			st.castInterruptGlow = st.castBar:CreateTexture(nil, "OVERLAY")
			if st.castInterruptGlow.SetAtlas then
				st.castInterruptGlow:SetAtlas("cast_interrupt_outerglow", true)
			else
				st.castInterruptGlow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
			end
			if st.castInterruptGlow.SetBlendMode then st.castInterruptGlow:SetBlendMode("ADD") end
			st.castInterruptGlow:SetPoint("CENTER", st.castBar, "CENTER", 0, 0)
			st.castInterruptGlow:SetAlpha(0)
		end
		if st.castInterruptGlow.SetVertexColor then st.castInterruptGlow:SetVertexColor(ir, ig, ib, 1) end
		do
			local w, h = st.castBar:GetSize()
			if w and h and w > 0 and h > 0 then
				st.castInterruptGlow:SetSize(w + (h * 0.5), h * 2.2)
				if st.castInterruptGlow.SetScale then st.castInterruptGlow:SetScale(1) end
			elseif st.castInterruptGlow.SetScale then
				st.castInterruptGlow:SetScale(0.5)
			end
		end
		if not st.castInterruptGlowAnim then
			st.castInterruptGlowAnim = st.castInterruptGlow:CreateAnimationGroup()
			local fade = st.castInterruptGlowAnim:CreateAnimation("Alpha")
			fade:SetFromAlpha(glowAlpha)
			fade:SetToAlpha(0)
			fade:SetDuration(1.0)
			st.castInterruptGlowAnim.fade = fade
			st.castInterruptGlowAnim:SetScript("OnFinished", function() st.castInterruptGlow:Hide() end)
		elseif st.castInterruptGlowAnim.fade and st.castInterruptGlowAnim.fade.SetFromAlpha then
			st.castInterruptGlowAnim.fade:SetFromAlpha(glowAlpha)
		end
		st.castInterruptGlow:SetAlpha(glowAlpha)
		st.castInterruptGlow:Show()
		st.castInterruptGlowAnim:Stop()
		st.castInterruptGlowAnim:Play()
	elseif st.castInterruptGlow then
		if st.castInterruptGlowAnim then st.castInterruptGlowAnim:Stop() end
		st.castInterruptGlow:Hide()
	end

	if not st.castInterruptAnim then
		st.castInterruptAnim = st.castBar:CreateAnimationGroup()
		local hold = st.castInterruptAnim:CreateAnimation("Alpha")
		hold:SetOrder(1)
		hold:SetFromAlpha(1)
		hold:SetToAlpha(1)
		hold:SetDuration(1.0)
		st.castInterruptAnim.hold = hold
		local fade = st.castInterruptAnim:CreateAnimation("Alpha")
		fade:SetOrder(2)
		fade:SetFromAlpha(1)
		fade:SetToAlpha(0)
		fade:SetDuration(0.3)
		st.castInterruptAnim.fade = fade
	end
	st.castBar:SetAlpha(1)
	st.castBar:Show()
	st.castInterruptAnim:Stop()
	st.castInterruptAnim._eqolUFUnit = unit
	st.castInterruptAnim._eqolCastInterruptToken = token
	st.castInterruptAnim:SetScript("OnFinished", UF.OnCastInterruptAnimFinished)
	st.castInterruptAnim:Play()
end

local function setCastInfoFromUnit(unit)
	local key = isBossUnit(unit) and "boss" or unit
	local st = states[unit]
	if not st or not st.castBar then return end
	local cfg = (st and st.cfg) or ensureDB(key or unit)
	if cfg and cfg.enabled == false then
		stopCast(unit)
		return
	end
	local ccfg = (cfg or {}).cast or {}
	local def = st.def or defaultsFor(unit) or {}
	local defc = def.cast or {}
	if ccfg.enabled == false then
		stopCast(unit)
		return
	end
	local name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellId, isEmpowered, numEmpowerStages, castBarID = UnitChannelInfo(unit)
	local isChannel = true
	local castGUID
	if not name then
		name, text, texture, startTimeMS, endTimeMS, _, castGUID, notInterruptible, spellId, castBarID = UnitCastingInfo(unit)
		isChannel = false
		isEmpowered = nil
		numEmpowerStages = nil
	end
	if not name then
		if UF.ShouldShowSampleCast(unit) then
			UF.SetSampleCast(unit)
		else
			stopCast(unit)
		end
		return
	end
	local isEmpoweredCast = isChannel and (issecretvalue and not issecretvalue(isEmpowered)) and isEmpowered and numEmpowerStages and numEmpowerStages > 0
	if isEmpoweredCast and startTimeMS and endTimeMS and (not issecretvalue or (not issecretvalue(startTimeMS) and not issecretvalue(endTimeMS))) then
		local totalMs = UFHelper.getEmpoweredChannelDurationMilliseconds and UFHelper.getEmpoweredChannelDurationMilliseconds(unit)
		if totalMs and totalMs > 0 and (not issecretvalue or not issecretvalue(totalMs)) then
			endTimeMS = startTimeMS + totalMs
		else
			local hold = UFHelper.getEmpowerHoldMilliseconds and UFHelper.getEmpowerHoldMilliseconds(unit)
			if hold and (not issecretvalue or not issecretvalue(hold)) then endTimeMS = endTimeMS + hold end
		end
	end

	if issecretvalue and ((startTimeMS and issecretvalue(startTimeMS)) or (endTimeMS and issecretvalue(endTimeMS))) then
		if type(startTimeMS) ~= "nil" and type(endTimeMS) ~= "nil" then
			local durObj, direction
			if _G.UnitEmpoweredChannelDuration then
				durObj = _G.UnitEmpoweredChannelDuration(unit, true)
				direction = Enum.StatusBarTimerDirection.ElapsedTime
				if not durObj then
					if isChannel then
						durObj = UnitChannelDuration(unit)
						direction = Enum.StatusBarTimerDirection.RemainingTime
					else
						durObj = UnitCastingDuration(unit)
						direction = Enum.StatusBarTimerDirection.ElapsedTime
					end
				end
			elseif isChannel then
				durObj = UnitChannelDuration(unit)
				direction = Enum.StatusBarTimerDirection.RemainingTime
			else
				durObj = UnitCastingDuration(unit)
				direction = Enum.StatusBarTimerDirection.ElapsedTime
			end
			if not durObj then
				stopCast(unit)
				return
			end
			UF.ClearCastInterruptState(st)
			applyCastLayout(cfg, unit)
			st.castBar:Show()
			st.castBar:SetTimerDuration(durObj, Enum.StatusBarInterpolation.Immediate, direction)
			st.castBarDuration = durObj
			if st.castName then
				local showName = ccfg.showName ~= false
				st.castName:SetShown(showName)
				local nameText = showName and (text or name or "") or ""
				if showName and UFHelper.formatCastName then
					local showTarget = ccfg.showCastTarget
					if showTarget == nil then showTarget = defc.showCastTarget end
					if unit ~= UNIT.PLAYER then showTarget = false end
					nameText = UFHelper.formatCastName(nameText, st.castTarget, showTarget == true)
				end
				st.castName:SetText(nameText)
			end
			if st.castIcon then
				local iconTexture = UFHelper.resolveCastIconTexture(texture)
				local showIcon = ccfg.showIcon ~= false
				if st.castIconHolder then st.castIconHolder:SetShown(showIcon) end
				st.castIcon:SetShown(showIcon)
				if showIcon then
					st.castIcon:SetTexture(iconTexture)
					st.castIconTexture = iconTexture
				end
			end
			local clr = ccfg.color or defc.color or { 0.9, 0.7, 0.2, 1 }
			local useClassColor = ccfg.useClassColor
			if useClassColor == nil then useClassColor = defc.useClassColor end
			if useClassColor == true then
				local class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
				local cr, cg, cb, ca = getClassColor(class)
				if cr then clr = { cr, cg, cb, ca or 1 } end
			end
			local tex = st.castBar:GetStatusBarTexture()
			if st.castUseDefaultArt == true then
				if tex and tex.SetVertexColor then tex:SetVertexColor(1, 1, 1, 1) end
			else
				local nclr = (unit == UNIT.PLAYER) and clr or (ccfg.notInterruptibleColor or defc.notInterruptibleColor or { 204 / 255, 204 / 255, 204 / 255, 1 })
				local showUninterruptible = unit ~= UNIT.PLAYER and notInterruptible
				if tex and tex.SetVertexColorFromBoolean then
					tex:SetVertexColorFromBoolean(
						showUninterruptible,
						CreateColor(nclr[1] or 0.9, nclr[2] or 0.7, nclr[3] or 0.2, nclr[4] or 1),
						CreateColor(clr[1] or 0.9, clr[2] or 0.7, clr[3] or 0.2, clr[4] or 1)
					)
				end
			end
			UF._syncDefaultCastUninterruptibleBar(st, unit ~= UNIT.PLAYER and notInterruptible)
			st.castBar:SetStatusBarDesaturated(false)
			local showDuration = ccfg.showDuration ~= false and st.castDuration ~= nil
			local needsOnUpdate = showDuration
			if not needsOnUpdate then
				if castOnUpdateHandlers[unit] then
					st.castBar:SetScript("OnUpdate", nil)
					castOnUpdateHandlers[unit] = nil
				end
				if st.castDuration then
					st.castDuration:SetText("")
					st.castDuration:Hide()
				end
			else
				if st.castDuration then
					if showDuration then
						st.castDuration:Show()
					else
						st.castDuration:SetText("")
						st.castDuration:Hide()
					end
				end
				st.castDurationFormat = ccfg.durationFormat or defc.durationFormat or "REMAINING"
				st.castBar._eqolCastDurationElapsed = 0
				st.castBar._eqolUFUnit = unit
				st.castBar:SetScript("OnUpdate", UF.OnCastDurationTimerUpdate)
				castOnUpdateHandlers[unit] = true
			end
		else
			stopCast(unit)
		end
		return
	end
	local duration = (endTimeMS or 0) - (startTimeMS or 0)
	if not duration or duration <= 0 then
		stopCast(unit)
		return
	end
	UF.ClearCastInterruptState(st)
	applyCastLayout(cfg, unit)
	local resolvedCfg = ccfg or defc or {}
	st.castCfg = resolvedCfg
	st.castInfo = {
		name = text or name,
		texture = UFHelper.resolveCastIconTexture(texture),
		startTime = startTimeMS,
		endTime = endTimeMS,
		notInterruptible = notInterruptible,
		isChannel = isChannel,
		isEmpowered = isEmpowered,
		numEmpowerStages = numEmpowerStages,
		castGUID = castGUID,
		castBarID = castBarID,
		spellId = spellId,
	}
	configureCastStatic(unit, resolvedCfg, defc)
	if isEmpowered then
		UFHelper.setupEmpowerStages(st, unit, numEmpowerStages)
	else
		UFHelper.clearEmpowerStages(st)
	end
	if not castOnUpdateHandlers[unit] then
		st.castBar._eqolUFUnit = unit
		st.castBar:SetScript("OnUpdate", UF.OnCastBarUpdate)
		castOnUpdateHandlers[unit] = true
	end
	updateCastBar(unit)
end

local function getHealthPercent(unit, cur, maxv, calc)
	if calc and calc.EvaluateCurrentHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then return calc:EvaluateCurrentHealthPercent(CurveConstants.ScaleTo100) end
	return nil
end

local function getPowerPercent(unit, powerEnum, cur, maxv)
	if addon.functions and addon.functions.GetPowerPercent then return addon.functions.GetPowerPercent(unit, powerEnum, cur, maxv, true) end
	if maxv and maxv > 0 then return (cur or 0) / maxv * 100 end
	return nil
end

local function ensureBossBarsVisible(unit, st)
	if not isBossUnit(unit) then return end
	if not UnitExists or not UnitExists(unit) then return end
	if st.barGroup and not st.barGroup:IsShown() then st.barGroup:Show() end
	if st.status and not st.status:IsShown() then st.status:Show() end
end

function UF.resolveHealthBaseColor(unit, hc, defH)
	local useCustom = hc.useCustomColor == true
	local isPlayerUnit = UnitIsPlayer and UnitIsPlayer(unit)
	local hr, hg, hb, ha = nil, nil, nil, nil

	if useCustom then
		if not isPlayerUnit then
			local nr, ng, nb, na
			if UFHelper and UFHelper.getNPCOverrideColor then
				nr, ng, nb, na = UFHelper.getNPCOverrideColor(unit)
			end
			if nr then
				hr, hg, hb, ha = nr, ng, nb, na
			elseif hc.color then
				hr, hg, hb, ha = hc.color[1], hc.color[2], hc.color[3], hc.color[4] or 1
			end
		elseif hc.color then
			hr, hg, hb, ha = hc.color[1], hc.color[2], hc.color[3], hc.color[4] or 1
		end
	elseif hc.useClassColor then
		local class
		if isPlayerUnit then
			class = select(2, UnitClass(unit))
		elseif unit == UNIT.PET then
			class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
		end
		local cr, cg, cb, ca = getClassColor(class)
		if cr then
			hr, hg, hb, ha = cr, cg, cb, ca
		end
	end

	if not hr and not useCustom then
		local nr, ng, nb, na
		if UFHelper and UFHelper.getNPCHealthColor then
			nr, ng, nb, na = UFHelper.getNPCHealthColor(unit)
		end
		if nr then
			hr, hg, hb, ha = nr, ng, nb, na
		end
	end

	if not hr then
		local color = defH.color or { 0, 0.8, 0, 1 }
		hr, hg, hb, ha = color[1] or 0, color[2] or 0.8, color[3] or 0, color[4] or 1
	end

	return hr, hg, hb, ha
end

function UF.resolveHealthColorCurveType(value)
	local curveType = Enum and Enum.LuaCurveType
	if not curveType then return nil end
	local token = type(value) == "string" and value:upper() or "COSINE"
	if token == "LINEAR" then return curveType.Linear or curveType.Cosine or curveType.Step end
	if token == "STEP" then return curveType.Step or curveType.Cosine or curveType.Linear end
	return curveType.Cosine or curveType.Linear or curveType.Step
end

local function extractCurveColorRGBA(color)
	if not color then return nil end
	if color.GetRGBA then return color:GetRGBA() end
	if color.r then return color.r, color.g, color.b, color.a end
	return color[1], color[2], color[3], color[4]
end

function UF.getHealthPercentCurveColor(st, unit, hc, defH, maxR, maxG, maxB, maxA)
	local useCurve = hc.usePercentColorCurve
	if useCurve == nil then useCurve = defH.usePercentColorCurve end
	if useCurve ~= true then return nil end
	if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor) then return nil end

	local hr, hg, hb, ha = maxR or 0, maxG or 0.8, maxB or 0, maxA or 1
	local curveTypeToken = type(hc.percentColorCurveType) == "string" and hc.percentColorCurveType or defH.percentColorCurveType or "COSINE"
	curveTypeToken = tostring(curveTypeToken):upper()
	local curve = st._healthPercentCurve
	if
		curve
		and st._healthPercentCurveDirty ~= true
		and st._healthPercentCurveTypeToken == curveTypeToken
		and st._healthPercentCurveMaxR == hr
		and st._healthPercentCurveMaxG == hg
		and st._healthPercentCurveMaxB == hb
		and st._healthPercentCurveMaxA == ha
	then
		local fastColor
		if UFHelper and UFHelper.getHealthCurveValue then
			fastColor = UFHelper.getHealthCurveValue(unit, curve)
		elseif UnitHealthPercent then
			fastColor = UnitHealthPercent(unit, true, curve)
		end
		if not fastColor then return nil end
		return extractCurveColorRGBA(fastColor)
	end

	local pointsSource = hc.percentColorCurvePoints
	if type(pointsSource) ~= "table" or next(pointsSource) == nil then pointsSource = defH.percentColorCurvePoints end

	local pointCount = tonumber(hc.percentColorCurvePointCount)
	if pointCount == nil then pointCount = tonumber(defH.percentColorCurvePointCount) end
	if pointCount == nil or pointCount <= 0 then
		if type(pointsSource) == "table" then
			for i = 1, 5 do
				if type(pointsSource[i]) == "table" then pointCount = i end
			end
		end
	end
	if pointCount == nil or pointCount <= 0 then pointCount = 2 end
	pointCount = math.floor(pointCount + 0.5)
	if pointCount < 1 then pointCount = 1 end
	if pointCount > 5 then pointCount = 5 end

	local legacyMidpoint = tonumber(hc.percentColorCurveMidpoint)
	if legacyMidpoint == nil then legacyMidpoint = tonumber(defH.percentColorCurveMidpoint) end
	if legacyMidpoint == nil then legacyMidpoint = 60 end
	if legacyMidpoint < 1 then legacyMidpoint = 1 end
	if legacyMidpoint > 99 then legacyMidpoint = 99 end
	local legacyLowColor = hc.percentColorCurveLowColor or defH.percentColorCurveLowColor or { 0.9, 0.0, 0.0, 1 }
	local legacyMidColor = hc.percentColorCurveMidColor or defH.percentColorCurveMidColor or { 0.9, 0.9, 0.0, 1 }
	local fallbackPoints = {
		{ percent = 0, color = legacyLowColor },
		{ percent = legacyMidpoint, color = legacyMidColor },
		{ percent = 80, color = { 0.6, 0.85, 0.0, 1 } },
		{ percent = 40, color = { 0.95, 0.6, 0.0, 1 } },
		{ percent = 20, color = { 0.95, 0.25, 0.0, 1 } },
	}

	local points = {}
	for i = 1, pointCount do
		local fallback = fallbackPoints[i] or fallbackPoints[#fallbackPoints]
		local src = type(pointsSource) == "table" and pointsSource[i] or nil
		local percent, pointColor
		if type(src) == "table" then
			percent = tonumber(src.percent or src[1])
			pointColor = src.color or src[2]
			if pointColor == nil and src.percent == nil and src[1] ~= nil and src[2] ~= nil and src[3] ~= nil then pointColor = src end
		end
		if percent == nil then percent = fallback.percent end
		if percent < 0 then percent = 0 end
		if percent > 99 then percent = 99 end
		local pr, pg, pb, pa = unpackColor(pointColor, fallback.color[1] or 1, fallback.color[2] or 1, fallback.color[3] or 1, fallback.color[4] or 1)
		points[#points + 1] = { percent = percent, r = pr, g = pg, b = pb, a = pa }
	end
	if #points == 0 then return nil end
	table.sort(points, function(a, b) return (a.percent or 0) > (b.percent or 0) end)

	local uniquePoints = {}
	local lastPercent
	for i = 1, #points do
		local point = points[i]
		if point.percent ~= lastPercent then
			uniquePoints[#uniquePoints + 1] = point
			lastPercent = point.percent
		end
	end
	points = uniquePoints

	local signatureParts = {
		curveTypeToken,
		string.format("MAX:%.4f,%.4f,%.4f,%.4f", hr, hg, hb, ha),
	}
	for i = 1, #points do
		local point = points[i]
		signatureParts[#signatureParts + 1] = string.format("%d:%.4f,%.4f,%.4f,%.4f,%.4f", i, (point.percent or 0) / 100, point.r or 1, point.g or 1, point.b or 1, point.a or 1)
	end
	local signature = table.concat(signatureParts, "|")

	if st._healthPercentCurveSig ~= signature then
		curve = C_CurveUtil.CreateColorCurve()
		if not curve then return nil end
		local curveType = UF.resolveHealthColorCurveType(curveTypeToken)
		if curveType then curve:SetType(curveType) end
		curve:AddPoint(1.0, CreateColor(hr, hg, hb, ha))
		for i = 1, #points do
			local point = points[i]
			curve:AddPoint((point.percent or 0) / 100, CreateColor(point.r or 1, point.g or 1, point.b or 1, point.a or 1))
		end
		st._healthPercentCurve = curve
		st._healthPercentCurveSig = signature
	else
		curve = st._healthPercentCurve
	end

	st._healthPercentCurveTypeToken = curveTypeToken
	st._healthPercentCurveMaxR, st._healthPercentCurveMaxG, st._healthPercentCurveMaxB, st._healthPercentCurveMaxA = hr, hg, hb, ha
	st._healthPercentCurveDirty = nil

	if not curve then return nil end
	local color
	if UFHelper and UFHelper.getHealthCurveValue then
		color = UFHelper.getHealthCurveValue(unit, curve)
	elseif UnitHealthPercent then
		color = UnitHealthPercent(unit, true, curve)
	end
	if not color then return nil end

	return extractCurveColorRGBA(color)
end

UF.DataBar = UF.DataBar or {}

function UF.DataBar.IsEnabled(cfg, def)
	local dcfg = (cfg and cfg.dataBar) or {}
	local ddef = (def and def.dataBar) or {}
	local enabled = dcfg.enabled
	if enabled == nil then enabled = ddef.enabled == true end
	return enabled == true
end

function UF.DataBar.GetPosition(cfg, def)
	local dcfg = (cfg and cfg.dataBar) or {}
	local ddef = (def and def.dataBar) or {}
	local position = tostring(dcfg.position or ddef.position or "BELOW"):upper()
	if position ~= "ABOVE" and position ~= "CENTER" then position = "BELOW" end
	return position
end

function UF.DataBar.ClearTexts(st)
	if not st then return end
	if st.dataBarTextLeft then st.dataBarTextLeft:SetText("") end
	if st.dataBarTextCenter then st.dataBarTextCenter:SetText("") end
	if st.dataBarTextRight then st.dataBarTextRight:SetText("") end
end

function UF.DataBar.Hide(st)
	if not st then return end
	if st.dataBar then
		st.dataBar:SetValue(0)
		st.dataBar:Hide()
	end
	UF.DataBar.ClearTexts(st)
	st._dataBarTextDirty = nil
end

function UF.DataBar.GetFallbackName(unit)
	if unit == UNIT.PLAYER then return PLAYER or "Player" end
	if unit == UNIT.TARGET then return TARGET or "Target" end
	if unit == UNIT.TARGET_TARGET then return L["Target of Target"] or "Target of Target" end
	if unit == UNIT.FOCUS then return L["Focus"] or "Focus" end
	if unit == UNIT.PET then return PET or "Pet" end
	if isBossUnit(unit) then return L["UFBossFrame"] or "Boss Frame" end
	return tostring(unit or "")
end

function UF.DataBar.GetText(mode, unit, cfg, def, cur, maxv, percentVal)
	mode = tostring(mode or "NONE"):upper()
	if mode == "NONE" then return "" end
	local dcfg = (cfg and cfg.dataBar) or {}
	local ddef = (def and def.dataBar) or {}
	if mode == "NAME" then
		if not UnitName then return UF.DataBar.GetFallbackName(unit) end
		local name = UnitName(unit)
		if issecretvalue and issecretvalue(name) then return name end
		return name or UF.DataBar.GetFallbackName(unit)
	end
	if mode == "LEVEL" then return (UFHelper and UFHelper.getUnitLevelText and UFHelper.getUnitLevelText(unit, nil, UF.ShouldHideClassificationText(cfg, unit))) or "" end
	local delimiter, delimiter2, delimiter3 = UFHelper.getTextDelimiter(dcfg, ddef), UFHelper.getTextDelimiterSecondary(dcfg, ddef), UFHelper.getTextDelimiterTertiary(dcfg, ddef)
	if UFHelper.resolveTextDelimiters then delimiter, delimiter2, delimiter3 = UFHelper.resolveTextDelimiters(delimiter, delimiter2, delimiter3) end
	local levelText
	if UFHelper.textModeUsesLevel and UFHelper.textModeUsesLevel(mode) then levelText = UFHelper.getUnitLevelText(unit, nil, UF.ShouldHideClassificationText(cfg, unit)) end
	return UFHelper.formatText(
		mode,
		cur or 0,
		maxv or 0,
		dcfg.useShortNumbers ~= false,
		percentVal,
		delimiter,
		delimiter2,
		delimiter3,
		dcfg.hidePercentSymbol == true,
		levelText,
		nil,
		dcfg.roundPercent == true,
		true
	)
end

function UF.DataBar.ApplyTextColor(st, unit, cfg, def)
	if not st then return end
	local dcfg = (cfg and cfg.dataBar) or {}
	local ddef = (def and def.dataBar) or {}
	local textColor = dcfg.textColor or ddef.textColor or { 1, 1, 1, 1 }
	local tr, tg, tb, ta = textColor[1] or 1, textColor[2] or 1, textColor[3] or 1, textColor[4] or 1
	local useTextClassColor = dcfg.useTextClassColor
	if useTextClassColor == nil then useTextClassColor = ddef.useTextClassColor end
	if useTextClassColor == true then
		local class
		if UnitIsPlayer and UnitIsPlayer(unit) then
			class = select(2, UnitClass(unit))
		elseif unit == UNIT.PET then
			class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
		end
		local cr, cg, cb, ca = getClassColor(class)
		if cr then tr, tg, tb, ta = cr, cg, cb, ca or ta end
	end
	if st.dataBarTextLeft then st.dataBarTextLeft:SetTextColor(tr, tg, tb, ta) end
	if st.dataBarTextCenter then st.dataBarTextCenter:SetTextColor(tr, tg, tb, ta) end
	if st.dataBarTextRight then st.dataBarTextRight:SetTextColor(tr, tg, tb, ta) end
end

function UF.DataBar.Update(cfg, unit, deferTextUpdate)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	local st = states[unit]
	if not st or not st.dataBar then return end
	local def = defaultsFor(unit) or {}
	if not cfg or cfg.enabled == false or not UF.DataBar.IsEnabled(cfg, def) then
		UF.DataBar.Hide(st)
		return
	end
	local inEdit = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	local exists = UnitExists and UnitExists(unit)
	if not exists and not inEdit then
		UF.DataBar.Hide(st)
		return
	end
	local dcfg = cfg.dataBar or {}
	local ddef = def.dataBar or {}
	st.dataBar:SetMinMaxValues(0, 1)
	UF.SetStatusBarValue(st.dataBar, 1, false, true)
	local color = dcfg.color or ddef.color or { 0.18, 0.18, 0.22, 1 }
	local r, g, b, a = color[1] or 0.18, color[2] or 0.18, color[3] or 0.22, color[4] or 1
	if dcfg.useClassColor == true then
		local class
		if UnitIsPlayer and UnitIsPlayer(unit) then
			class = select(2, UnitClass(unit))
		elseif unit == UNIT.PET then
			class = (addon.variables and addon.variables.unitClass) or select(2, UnitClass(UNIT.PLAYER))
		end
		local cr, cg, cb, ca = getClassColor(class)
		if cr then r, g, b, a = cr, cg, cb, ca or a end
	end
	st.dataBar:SetStatusBarColor(r, g, b, a)
	st.dataBar:Show()
	UF.DataBar.ApplyTextColor(st, unit, cfg, def)
	st._dataBarTextDirty = true
	if not deferTextUpdate and UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
end

local applyBossEditSample

function UF.InvalidateHealthIdentityState(st)
	if not st then return end
	st._healthColorDirty = true
	st._healthPercentCurveDirty = true
	st._absorbAmount = nil
	st._healAbsorbAmount = nil
	st._healthTextAbsorbAmount = nil
end

local function updateHealth(cfg, unit, deferAuxiliaryUpdates)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	if cfg and cfg.enabled == false then return end
	local st = states[unit]
	if not st or not st.health or not st.frame then return end
	if addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() and isBossUnit(unit) then
		local idx = tonumber(type(unit) == "string" and unit:match("^boss(%d+)$") or nil)
		if idx then
			applyBossEditSample(idx, cfg)
			st._healthTextDirty = nil
			return
		end
	end
	ensureBossBarsVisible(unit, st)
	local info = UNITS[unit]
	local allowAbsorb = not (info and info.disableAbsorb)
	local def = st.def or defaultsFor(unit) or {}
	local defH = def.health or {}
	local interpolation = getSmoothInterpolation(cfg, def)
	local cur = UnitHealth(unit)
	local maxv = UnitHealthMax(unit)
	st._healthTextCurrent = cur
	st._healthTextMaximum = maxv
	st._healthTextValuesReady = true
	if issecretvalue and issecretvalue(maxv) then
		st.health:SetMinMaxValues(0, maxv or 1)
	else
		st.health:SetMinMaxValues(0, maxv > 0 and maxv or 1)
	end
	st.health:SetValue(cur or 0, interpolation)
	local hc = cfg.health or {}
	local reverseHealth = hc.reverseFill
	if reverseHealth == nil then reverseHealth = defH.reverseFill == true end
	local backdropCfg = hc.backdrop or {}
	local useBackdropClassColor = backdropCfg.useClassColor
	if useBackdropClassColor == nil and defH.backdrop then useBackdropClassColor = defH.backdrop.useClassColor end
	if st._healthBackdropDirty or useBackdropClassColor == true then
		UF.ApplyHealthBackdrop(st, unit, hc, defH, reverseHealth)
		st._healthBackdropDirty = nil
	end
	if st.tempMaxHealthLoss then
		local showTempLoss = hc.tempMaxHealthLossEnabled
		if showTempLoss == nil then showTempLoss = defH.tempMaxHealthLossEnabled ~= false end
		if showTempLoss then
			local loss = GetUnitTotalModifiedMaxHealthPercent(unit) or 0
			st.tempMaxHealthLoss:SetMinMaxValues(0, 1)
			st.tempMaxHealthLoss:SetValue(loss, interpolation)
			if st.tempMaxHealthLoss.SetAlpha then st.tempMaxHealthLoss:SetAlpha(1) end
			st.tempMaxHealthLoss:Show()
		else
			st.tempMaxHealthLoss:SetValue(0, interpolation)
			if st.tempMaxHealthLoss.SetAlpha then st.tempMaxHealthLoss:SetAlpha(0) end
			st.tempMaxHealthLoss:Hide()
		end
	end
	local usePercentColorCurve = hc.usePercentColorCurve
	if usePercentColorCurve == nil then usePercentColorCurve = defH.usePercentColorCurve end
	local appliedSecretClassColor = hc.useCustomColor ~= true
		and hc.useClassColor == true
		and usePercentColorCurve ~= true
		and UF.ApplySecretUnitClassStatusBarColor(st.health, unit)
	if appliedSecretClassColor then
		st._healthColorR, st._healthColorG, st._healthColorB, st._healthColorA = nil, nil, nil, nil
		st._healthColorDirty = true
		st._healthPercentCurveDirty = true
	else
		local hr, hg, hb, ha = st._healthColorR, st._healthColorG, st._healthColorB, st._healthColorA
		if st._healthColorDirty or hr == nil then
			hr, hg, hb, ha = UF.resolveHealthBaseColor(unit, hc, defH)

			st._healthColorR, st._healthColorG, st._healthColorB, st._healthColorA = hr, hg, hb, ha
			st._healthPercentCurveDirty = true
			st._healthColorDirty = nil
		end

		local finalR, finalG, finalB, finalA = hr, hg, hb, ha
		local cr, cg, cb, ca = UF.getHealthPercentCurveColor(st, unit, hc, defH, hr, hg, hb, ha)
		if cr then
			finalR, finalG, finalB, finalA = cr, cg, cb, ca
		end

		local useTapDenied = hc.useTapDeniedColor
		if useTapDenied == nil then useTapDenied = defH.useTapDeniedColor end
		if useTapDenied ~= false and UnitIsTapDenied and UnitPlayerControlled and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
			local tc = hc.tapDeniedColor or defH.tapDeniedColor or { 0.5, 0.5, 0.5, 1 }
			finalR, finalG, finalB, finalA = tc[1] or 0.5, tc[2] or 0.5, tc[3] or 0.5, tc[4] or 1
		end

		st.health:SetStatusBarColor(finalR or 0, finalG or 0.8, finalB or 0, finalA or 1)
	end

	local needsHealthAbsorbText = st._healthTextUsesAbsorb
	if needsHealthAbsorbText == nil then
		local healthLeftMode = hc.textLeft or defH.textLeft or "PERCENT"
		local healthCenterMode = hc.textCenter or defH.textCenter or "NONE"
		local healthRightMode = hc.textRight or defH.textRight or "CURMAX"
		needsHealthAbsorbText = UF.HealthTextUsesAbsorbMode(healthLeftMode, healthCenterMode, healthRightMode)
	end
	local reverseAbsorb = hc.absorbReverseFill
	if reverseAbsorb == nil then reverseAbsorb = defH.absorbReverseFill == true end
	local absorbDontOverflow = hc.absorbDontOverflowHealthBar
	if absorbDontOverflow == nil then absorbDontOverflow = defH.absorbDontOverflowHealthBar == true end
	absorbDontOverflow = absorbDontOverflow == true and reverseAbsorb == true
	local healPredictionCalc
	if hc.incomingHealEnabled == true or needsHealthAbsorbText or (allowAbsorb and st.absorb) then
		healPredictionCalc = ensureHealPredictionCalculator(st)
		if healPredictionCalc and healPredictionCalc.SetDamageAbsorbClampMode and Enum and Enum.UnitDamageAbsorbClampMode then
			local modes = Enum.UnitDamageAbsorbClampMode
			local mode = absorbDontOverflow and modes.MissingHealthWithoutIncomingHeals or modes.MaximumHealth
			if mode ~= nil and st._lastDamageAbsorbClampMode ~= mode then
				st._lastDamageAbsorbClampMode = mode
				healPredictionCalc:SetDamageAbsorbClampMode(mode)
			end
		end
		if healPredictionCalc and UnitGetDetailedHealPrediction then UnitGetDetailedHealPrediction(unit, "player", healPredictionCalc) end
	end

	updateIncomingHeal(st, unit, hc, defH, cur, maxv, interpolation, healPredictionCalc)
	if st._absorbAmount == nil and (needsHealthAbsorbText or (allowAbsorb and st.absorb)) then
		st._absorbAmount = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
	end
	if allowAbsorb and st.healAbsorb and st._healAbsorbAmount == nil then
		st._healAbsorbAmount = UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit) or 0
	end
	if needsHealthAbsorbText then
		UF.CacheHealthTextAbsorbAmount(st, unit, maxv, st._absorbAmount, healPredictionCalc)
	else
		st._healthTextAbsorbAmount = nil
	end
	if allowAbsorb and st.absorb then
		local abs
		if absorbDontOverflow and healPredictionCalc and healPredictionCalc.GetDamageAbsorbs then
			abs = healPredictionCalc:GetDamageAbsorbs()
		elseif healPredictionCalc and healPredictionCalc.GetTotalDamageAbsorbs then
			abs = healPredictionCalc:GetTotalDamageAbsorbs()
		else
			abs = st._absorbAmount
		end
		if abs == nil then
			abs = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
			st._absorbAmount = abs
		end
		local maxForValue
		if issecretvalue and issecretvalue(maxv) then
			maxForValue = maxv or 1
		else
			maxForValue = (maxv and maxv > 0) and maxv or 1
		end
		st.absorb:SetMinMaxValues(0, maxForValue or 1)
		if shouldShowSampleAbsorb(unit) and (not issecretvalue or not issecretvalue(maxForValue)) then abs = (maxForValue or 1) * 0.6 end
		st.absorb:SetValue(abs or 0, interpolation)
		local absorbValueForGlow = abs
		if reverseAbsorb and st.absorb2 then
			st.absorb2:SetMinMaxValues(0, maxForValue or 1)
			st.absorb2:SetValue(abs or 0, interpolation)
		end
		if reverseAbsorb and st.absorb2 then
			st.absorb2:Show()
			if st.absorb then
				if absorbDontOverflow then
					st.absorb:SetAlpha(0)
					st.absorb:Hide()
				else
					st.absorb:SetAlpha(1)
					st.absorb:Show()
				end
			end
		elseif st.absorb then
			st.absorb:SetAlpha(1)
			st.absorb:Show()
			if st.absorb2 then
				st.absorb2:SetAlpha(0)
				st.absorb2:Show()
			end
		end
		local ar, ag, ab, aa = UFHelper.getAbsorbColor(hc, defH)
		st.absorb:SetStatusBarColor(ar or 0.85, ag or 0.95, ab or 1, aa or 0.7)
		if reverseAbsorb and st.absorb2 then st.absorb2:SetStatusBarColor(ar or 0.85, ag or 0.95, ab or 1, aa or 0.7) end
		if st.overAbsorbGlow then
			local glowAbsorb = absorbValueForGlow
			if glowAbsorb == nil then glowAbsorb = abs end
			local verticalHealth = UFHelper.normalizeStatusBarOrientation(hc.orientation or defH.orientation) == "VERTICAL"
			if hc.useAbsorbGlow ~= false and not verticalHealth then
				st.overAbsorbGlow:SetAlpha(glowAbsorb or 0)
				st.overAbsorbGlow:Show()
			else
				st.overAbsorbGlow:SetAlpha(0)
				st.overAbsorbGlow:Hide()
			end
		end
	end
	if allowAbsorb and st.healAbsorb then
		local healAbs = st._healAbsorbAmount
		if healAbs == nil then
			healAbs = UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit) or 0
			st._healAbsorbAmount = healAbs
		end
		local maxForValue
		if issecretvalue and issecretvalue(maxv) then
			maxForValue = maxv or 1
		else
			maxForValue = (maxv and maxv > 0) and maxv or 1
		end
		st.healAbsorb:SetMinMaxValues(0, maxForValue or 1)
		local hasVisibleHealAbsorb = healAbs and (not issecretvalue or not issecretvalue(healAbs)) and healAbs > 0
		if shouldShowSampleHealAbsorb(unit) and not hasVisibleHealAbsorb and (not issecretvalue or not issecretvalue(maxForValue)) then healAbs = (maxForValue or 1) * 0.6 end
		if not issecretvalue or (not issecretvalue(cur) and not issecretvalue(healAbs)) then
			if (cur or 0) < (healAbs or 0) then healAbs = cur or 0 end
		end
		st.healAbsorb:SetValue(healAbs or 0, interpolation)
		local har, hag, hab, haa = UFHelper.getHealAbsorbColor(hc, defH)
		st.healAbsorb:SetStatusBarColor(har or 1, hag or 0.3, hab or 0.3, haa or 0.7)
	end
	st._healthTextDirty = true
	if not deferAuxiliaryUpdates then
		UF.DataBar.Update(cfg, unit)
		if UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
	end
end

local function updatePower(cfg, unit, allowVisibilityChanges, deferAuxiliaryUpdates, knownPowerEnum, knownPowerToken)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	if cfg and cfg.enabled == false then return end
	local st = states[unit]
	if not st then return end
	if allowVisibilityChanges == nil then allowVisibilityChanges = true end
	if addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() and isBossUnit(unit) then
		local idx = tonumber(type(unit) == "string" and unit:match("^boss(%d+)$") or nil)
		if idx then
			applyBossEditSample(idx, cfg)
			st._powerTextDirty = nil
			return
		end
	end
	local bar = st.power
	local secondaryBar = st.secondaryPower
	if not bar and not secondaryBar then return end
	local def = st.def or defaultsFor(unit) or {}
	local interpolation = getSmoothInterpolation(cfg, def)
	local pcfg = cfg.power or {}
	local powerDef = def.power or {}
	local powerEnabled = pcfg.enabled ~= false
	local powerEnum, powerToken = knownPowerEnum, knownPowerToken
	if powerEnabled then
		if powerEnum == nil then
			if unit == UNIT.PLAYER then refreshMainPower(unit) end
			powerEnum, powerToken = getMainPower(unit)
		end
		st._lastPowerEnum, st._lastPowerToken = powerEnum, powerToken
		if unit == UNIT.PLAYER and UFHelper and UFHelper.IsPrimaryPowerAllowed then powerEnabled = UFHelper.IsPrimaryPowerAllowed(pcfg, powerDef, powerToken, powerEnum, unit) ~= false end
	end
	local powerDetached = powerEnabled and pcfg.detached == true
	if bar then
		if not powerEnabled then
			if allowVisibilityChanges then bar:Hide() end
			bar:SetValue(0, interpolation)
			st._powerTextValuesReady = nil
			if st.powerTextLeft then st.powerTextLeft:SetText("") end
			if st.powerTextCenter then st.powerTextCenter:SetText("") end
			if st.powerTextRight then st.powerTextRight:SetText("") end
			st._powerTextDirty = nil
		else
			if allowVisibilityChanges then bar:Show() end
			powerEnum = powerEnum or 0
			local cur = UnitPower(unit, powerEnum)
			local maxv = UnitPowerMax(unit, powerEnum)
			st._powerTextCurrent = cur
			st._powerTextMaximum = maxv
			st._powerTextEnum = powerEnum
			st._powerTextValuesReady = true
			if issecretvalue and issecretvalue(maxv) then
				bar:SetMinMaxValues(0, maxv or 1)
			else
				bar:SetMinMaxValues(0, maxv > 0 and maxv or 1)
			end
			bar:SetValue(cur or 0, interpolation)
			local powerColorDirty = st._powerColorDirty
			if not powerColorDirty and st._powerColorEnum ~= powerEnum then powerColorDirty = true end
			if not powerColorDirty and st._powerColorToken ~= powerToken then powerColorDirty = true end
			if powerColorDirty or st._powerColorR == nil then
				local cr, cg, cb, ca = UFHelper.getPowerColor(powerEnum, powerToken)
				st._powerColorR, st._powerColorG, st._powerColorB, st._powerColorA = cr, cg, cb, ca
				st._powerColorDesaturated = UFHelper.isPowerDesaturated(powerEnum, powerToken)
				st._powerColorEnum = powerEnum
				st._powerColorToken = powerToken
				st._powerColorDirty = nil
			end
			bar:SetStatusBarColor(st._powerColorR or 0.1, st._powerColorG or 0.45, st._powerColorB or 1, st._powerColorA or 1)
			if bar.SetStatusBarDesaturated then bar:SetStatusBarDesaturated(st._powerColorDesaturated == true) end
			local emptyFallback = pcfg.emptyMaxFallback == true
			if emptyFallback then
				if powerDetached then
					if bar.SetAlpha then bar:SetAlpha(maxv) end
					if st.powerGroup and st.powerGroup.SetAlpha then st.powerGroup:SetAlpha(maxv) end
				end
			elseif powerDetached then
				if bar.SetAlpha then bar:SetAlpha(1) end
				if st.powerGroup and st.powerGroup.SetAlpha then st.powerGroup:SetAlpha(1) end
			end
			st._powerTextDirty = true
			if not deferAuxiliaryUpdates then
				if UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
				UF.DataBar.Update(cfg, unit)
			end
		end
	end
	if secondaryBar then
		local secondaryCfg = cfg.secondaryPower or {}
		local secondaryDef = def.secondaryPower or {}
		local secondaryToken
		if unit == UNIT.PLAYER and UFHelper and UFHelper.ResolveSecondaryPowerToken then
			secondaryToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
		end
		local secondaryEnabled = unit == UNIT.PLAYER and secondaryCfg.enabled ~= false and secondaryToken ~= nil
		local secondaryDetached = secondaryEnabled and secondaryCfg.detached == true
		if not secondaryEnabled then
			if allowVisibilityChanges then secondaryBar:Hide() end
			secondaryBar:SetValue(0, interpolation)
			if st.secondaryPowerTextLeft then st.secondaryPowerTextLeft:SetText("") end
			if st.secondaryPowerTextCenter then st.secondaryPowerTextCenter:SetText("") end
			if st.secondaryPowerTextRight then st.secondaryPowerTextRight:SetText("") end
			st._secondaryPowerEnum = nil
			st._secondaryPowerToken = nil
			st._secondaryPowerTextValuesReady = nil
			st._secondaryPowerTextDirty = nil
		else
			if allowVisibilityChanges then secondaryBar:Show() end
			local cur, maxv, enumId, resolvedToken
			if UFHelper and UFHelper.GetPowerValuesForToken then
				cur, maxv, enumId, resolvedToken = UFHelper.GetPowerValuesForToken(unit, secondaryToken)
			end
			resolvedToken = resolvedToken or secondaryToken
			cur = cur or 0
			maxv = maxv or 0
			st._secondaryPowerTextCurrent = cur
			st._secondaryPowerTextMaximum = maxv
			st._secondaryPowerTextEnum = enumId
			st._secondaryPowerTextResolvedToken = resolvedToken
			st._secondaryPowerTextValuesReady = true
			if issecretvalue and issecretvalue(maxv) then
				secondaryBar:SetMinMaxValues(0, maxv or 1)
			else
				secondaryBar:SetMinMaxValues(0, maxv > 0 and maxv or 1)
			end
			secondaryBar:SetValue(cur, interpolation)
			local secondaryColorDirty = st._secondaryPowerColorDirty
			if not secondaryColorDirty and st._secondaryPowerColorEnum ~= enumId then secondaryColorDirty = true end
			if not secondaryColorDirty and st._secondaryPowerColorToken ~= resolvedToken then secondaryColorDirty = true end
			if not secondaryColorDirty and resolvedToken == "STAGGER" then secondaryColorDirty = true end
			if secondaryColorDirty or st._secondaryPowerColorR == nil then
				local cr, cg, cb, ca = UFHelper.getPowerColor(enumId, resolvedToken, secondaryCfg, unit)
				st._secondaryPowerColorR, st._secondaryPowerColorG, st._secondaryPowerColorB, st._secondaryPowerColorA = cr, cg, cb, ca
				st._secondaryPowerColorDesaturated = UFHelper.isPowerDesaturated(enumId, resolvedToken)
				st._secondaryPowerColorEnum = enumId
				st._secondaryPowerColorToken = resolvedToken
				st._secondaryPowerColorDirty = nil
			end
			secondaryBar:SetStatusBarColor(st._secondaryPowerColorR or 0.1, st._secondaryPowerColorG or 0.45, st._secondaryPowerColorB or 1, st._secondaryPowerColorA or 1)
			if secondaryBar.SetStatusBarDesaturated then secondaryBar:SetStatusBarDesaturated(st._secondaryPowerColorDesaturated == true) end
			local emptyFallback = secondaryCfg.emptyMaxFallback == true
			if emptyFallback then
				if secondaryDetached then
					if secondaryBar.SetAlpha then secondaryBar:SetAlpha(maxv) end
					if st.secondaryPowerGroup and st.secondaryPowerGroup.SetAlpha then st.secondaryPowerGroup:SetAlpha(maxv) end
				end
			elseif secondaryDetached then
				if secondaryBar.SetAlpha then secondaryBar:SetAlpha(1) end
				if st.secondaryPowerGroup and st.secondaryPowerGroup.SetAlpha then st.secondaryPowerGroup:SetAlpha(1) end
			end
			st._secondaryPowerEnum = enumId
			st._secondaryPowerToken = resolvedToken
			st._secondaryPowerTextDirty = true
			if UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
		end
	end
	if not (bar and powerEnabled) then UF.DataBar.Update(cfg, unit) end
end

local function layoutTexts(bar, leftFS, centerFS, rightFS, cfg, width)
	if not bar then return end
	local leftCfg = (cfg and cfg.offsetLeft) or { x = 6, y = 0 }
	local centerCfg = (cfg and cfg.offsetCenter) or { x = 0, y = 0 }
	local rightCfg = (cfg and cfg.offsetRight) or { x = -6, y = 0 }
	if leftFS then
		leftFS:ClearAllPoints()
		leftFS:SetPoint("LEFT", bar, "LEFT", leftCfg.x or 0, leftCfg.y or 0)
		leftFS:SetJustifyH("LEFT")
	end
	if centerFS then
		centerFS:ClearAllPoints()
		centerFS:SetPoint("CENTER", bar, "CENTER", centerCfg.x or 0, centerCfg.y or 0)
		centerFS:SetJustifyH("CENTER")
	end
	if rightFS then
		rightFS:ClearAllPoints()
		rightFS:SetPoint("RIGHT", bar, "RIGHT", rightCfg.x or 0, rightCfg.y or 0)
		rightFS:SetJustifyH("RIGHT")
	end
end

function UF.ApplyDataBarNameCharLimit(st, cfg, def)
	if not st then return end
	local maxChars = tonumber(cfg and cfg.nameMaxChars)
	if maxChars == nil then maxChars = tonumber(def and def.nameMaxChars) end
	maxChars = maxChars or 0
	local width
	if maxChars > 0 and UFHelper and UFHelper.getNameLimitWidth then
		width = UFHelper.getNameLimitWidth(cfg and cfg.font or def and def.font, cfg and cfg.fontSize or def and def.fontSize or 12, cfg and cfg.fontOutline or def and def.fontOutline or "OUTLINE", maxChars)
	end
	local function apply(fontString, mode)
		if not fontString then return end
		if fontString.SetMaxLines then fontString:SetMaxLines(1) end
		if fontString.SetWordWrap then fontString:SetWordWrap(false) end
		if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(false) end
		if tostring(mode or "NONE"):upper() == "NAME" and width and width > 0 then
			fontString:SetWidth(width)
		else
			fontString:SetWidth(0)
		end
	end
	apply(st.dataBarTextLeft, cfg and cfg.textLeft or def and def.textLeft or "NAME")
	apply(st.dataBarTextCenter, cfg and cfg.textCenter or def and def.textCenter or "CURMAX")
	apply(st.dataBarTextRight, cfg and cfg.textRight or def and def.textRight or "PERCENT")
end

setFrameLevelAbove = function(child, parent, offset)
	if not child or not parent then return end
	child:SetFrameStrata(parent:GetFrameStrata())
	local level = (parent:GetFrameLevel() or 0) + (offset or 1)
	if level < 0 then level = 0 end
	child:SetFrameLevel(level)
end

function UF.syncAbsorbFrameLevels(st)
	if not st or not st.health then return end
	local health = st.health
	local healthLevel = (health.GetFrameLevel and health:GetFrameLevel()) or 0
	local tempLossLevel = max(0, healthLevel)
	local overlayClipLevel = max(0, healthLevel + 1)
	local absorbAboveIncoming = UFHelper.NormalizeAbsorbLayerOrder(st.cfg and st.cfg.health and st.cfg.health.absorbLayerOrder) == "ABSORB_ABOVE"
	local absorbLevel = max(0, healthLevel + (absorbAboveIncoming and 2 or 1))
	local incomingHealLevel = max(0, healthLevel + (absorbAboveIncoming and 1 or 2))
	local healAbsorbLevel = max(0, healthLevel + 3)
	local healthStrata = health.GetFrameStrata and health:GetFrameStrata()
	local borderFrame = st.barGroup and st.barGroup._ufBorder
	local function apply(frame, level)
		if not frame then return end
		if healthStrata and frame.SetFrameStrata and frame:GetFrameStrata() ~= healthStrata then frame:SetFrameStrata(healthStrata) end
		if frame.SetFrameLevel and frame:GetFrameLevel() ~= level then frame:SetFrameLevel(level) end
	end
	apply(health.absorbClip, overlayClipLevel)
	apply(health._healthFillClip, overlayClipLevel)
	apply(st.tempMaxHealthLoss, tempLossLevel)
	apply(st.absorb, absorbLevel)
	apply(st.absorb2, absorbLevel)
	apply(st.incomingHeal, incomingHealLevel)
	apply(st.healAbsorb, healAbsorbLevel)
	if borderFrame and st.barGroup and borderFrame.SetFrameStrata and st.barGroup.GetFrameStrata then
		local borderStrata = st.barGroup:GetFrameStrata()
		if borderStrata and borderFrame:GetFrameStrata() ~= borderStrata then borderFrame:SetFrameStrata(borderStrata) end
	end
	if borderFrame and borderFrame.SetFrameLevel then
		local desiredBorderLevel = max(tempLossLevel, absorbLevel, incomingHealLevel, healAbsorbLevel) + 1
		if borderFrame:GetFrameLevel() < desiredBorderLevel then borderFrame:SetFrameLevel(desiredBorderLevel) end
	end
end

local function getHealthTextAnchor(st, includeStatus)
	if not st or not st.health then return nil end
	local anchor = st.health
	local maxLevel = (anchor.GetFrameLevel and anchor:GetFrameLevel()) or 0
	local function consider(frame)
		if not frame or not frame.GetFrameLevel then return end
		local level = frame:GetFrameLevel() or 0
		if level > maxLevel then
			maxLevel = level
			anchor = frame
		end
	end
	consider(st.health.absorbClip)
	consider(st.health._healthFillClip)
	if includeStatus then consider(st.status) end
	return anchor
end

local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local STRATA_INDEX = {}
for i = 1, #STRATA_ORDER do
	STRATA_INDEX[STRATA_ORDER[i]] = i
end

normalizeStrataToken = function(value)
	if type(value) ~= "string" or value == "" then return nil end
	local token = string.upper(value)
	if STRATA_INDEX[token] then return token end
	return nil
end

function AuraUtil.getRaisedStrataToken(baseStrata)
	local token = normalizeStrataToken(baseStrata) or "LOW"
	local index = STRATA_INDEX[token] or STRATA_INDEX.LOW
	return STRATA_ORDER[index + 1] or STRATA_ORDER[index] or "MEDIUM"
end

function AuraUtil.syncAuraContainerLayer(container, parent)
	if not (container and parent) then return end
	container._eqolAuraLayerParent = parent
	local targetStrata = parent.GetFrameStrata and parent:GetFrameStrata()
	-- AuraContainer frame aspects can become secret once the container owns
	-- restricted aura data. Never read them back for Lua comparisons; only pass
	-- our non-secret parent layout values into the setters.
	if targetStrata and container.SetFrameStrata then container:SetFrameStrata(targetStrata) end
	if container.SetFrameLevel and parent.GetFrameLevel then
		local targetLevel = (parent:GetFrameLevel() or 0) + 1
		if targetLevel < 0 then targetLevel = 0 end
		container:SetFrameLevel(targetLevel)
	end
end

function AuraUtil.syncAuraButtonLayer(btn, container, ac)
	if not (btn and container) then return end
	local explicitParent = container._eqolAuraLayerParent
	local parent = explicitParent or container
	local targetStrata = normalizeStrataToken(ac and ac.strata)
	if not targetStrata and parent.GetFrameStrata then targetStrata = parent:GetFrameStrata() end
	local levelOffset = tonumber(ac and ac.frameLevelOffset)
	if levelOffset == nil then levelOffset = explicitParent and 5 or 1 end
	local targetLevel = levelOffset
	if parent.GetFrameLevel then targetLevel = (parent:GetFrameLevel() or 0) + levelOffset end
	if targetLevel < 0 then targetLevel = 0 end
	if targetStrata and btn.SetFrameStrata then btn:SetFrameStrata(targetStrata) end
	if btn.SetFrameLevel then btn:SetFrameLevel(targetLevel) end

	local cdLevel = targetLevel + 1
	if btn.cd then
		if targetStrata and btn.cd.SetFrameStrata then btn.cd:SetFrameStrata(targetStrata) end
		if btn.cd.SetFrameLevel then btn.cd:SetFrameLevel(cdLevel) end
	end

	local overlayLevel = cdLevel + 5
	if btn.overlay then
		if targetStrata and btn.overlay.SetFrameStrata then btn.overlay:SetFrameStrata(targetStrata) end
		if btn.overlay.SetFrameLevel then btn.overlay:SetFrameLevel(overlayLevel) end
	end

	local foregroundLevel = overlayLevel + 2
	if btn.foreground then
		if targetStrata and btn.foreground.SetFrameStrata then btn.foreground:SetFrameStrata(targetStrata) end
		if btn.foreground.SetFrameLevel then btn.foreground:SetFrameLevel(foregroundLevel) end
	end

	if UFHelper and UFHelper.syncAuraBorderFrameLayer then UFHelper.syncAuraBorderFrameLayer(btn) end
end

function AuraUtil.getFrameZOrder(frame)
	if not frame then return 0, 0 end
	local strataToken = frame.GetFrameStrata and frame:GetFrameStrata() or "MEDIUM"
	local strata = STRATA_INDEX[strataToken] or STRATA_INDEX.MEDIUM or 3
	local level = frame.GetFrameLevel and frame:GetFrameLevel() or 0
	return strata, level
end

function AuraUtil.getTopTextAnchor(...)
	local topFrame
	local topStrata = -1
	local topLevel = -1
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		if frame and (not frame.IsShown or frame:IsShown()) then
			local strata, level = AuraUtil.getFrameZOrder(frame)
			if strata > topStrata or (strata == topStrata and level > topLevel) then
				topFrame = frame
				topStrata = strata
				topLevel = level
			end
		end
	end
	return topFrame
end

local function syncTextFrameLevels(st)
	if not st then return end
	local scfg = (st.cfg and st.cfg.status) or {}
	local healthAnchor = getHealthTextAnchor(st) or st.health
	local statusAnchor = getHealthTextAnchor(st, true) or st.status or healthAnchor
	local textAnchor = AuraUtil.getTopTextAnchor(healthAnchor, statusAnchor, st.power, st.powerGroup, st.secondaryPower, st.secondaryPowerGroup, st.dataBar) or statusAnchor or healthAnchor
	setFrameLevelAbove(st.healthTextLayer, textAnchor, 5)
	setFrameLevelAbove(st.powerTextLayer, st.power, 5)
	if st.secondaryPowerTextLayer and st.secondaryPower then setFrameLevelAbove(st.secondaryPowerTextLayer, st.secondaryPower, 5) end
	if st.dataBarTextLayer and st.dataBar then setFrameLevelAbove(st.dataBarTextLayer, st.dataBar, 5) end
	setFrameLevelAbove(st.statusTextLayer, textAnchor, 5)
	local nameLayer = st.nameTextLayer or st.statusTextLayer
	local nameLevelOffset = tonumber(scfg.nameFrameLevelOffset)
	if nameLevelOffset == nil then nameLevelOffset = 5 end
	setFrameLevelAbove(nameLayer, textAnchor, nameLevelOffset)
	if nameLayer and nameLayer.SetFrameStrata then
		local nameStrata = normalizeStrataToken(scfg.nameStrata)
		local fallbackStrata
		if textAnchor and textAnchor.GetFrameStrata then fallbackStrata = textAnchor:GetFrameStrata() end
		if not fallbackStrata and st.status and st.status.GetFrameStrata then fallbackStrata = st.status:GetFrameStrata() end
		if nameStrata or fallbackStrata then nameLayer:SetFrameStrata(nameStrata or fallbackStrata) end
	end
	local levelLayer = st.levelTextLayer or st.statusTextLayer
	local levelOffset = tonumber(scfg.levelFrameLevelOffset)
	if levelOffset == nil then levelOffset = 5 end
	setFrameLevelAbove(levelLayer, textAnchor, levelOffset)
	if levelLayer and levelLayer.SetFrameStrata then
		local levelStrata = normalizeStrataToken(scfg.levelStrata)
		local fallbackStrata
		if textAnchor and textAnchor.GetFrameStrata then fallbackStrata = textAnchor:GetFrameStrata() end
		if not fallbackStrata and st.status and st.status.GetFrameStrata then fallbackStrata = st.status:GetFrameStrata() end
		if levelStrata or fallbackStrata then levelLayer:SetFrameStrata(levelStrata or fallbackStrata) end
	end
	if st.dispelTint then
		local dispelParent = st.healthTextLayer or st.health
		if st.dispelTint.GetParent and dispelParent and st.dispelTint:GetParent() ~= dispelParent then st.dispelTint:SetParent(dispelParent) end
		setFrameLevelAbove(st.dispelTint, dispelParent or healthAnchor, 0)
	end
	if st.restLoop and st.statusTextLayer then setFrameLevelAbove(st.restLoop, st.statusTextLayer, 3) end
	if st.castTextLayer then setFrameLevelAbove(st.castTextLayer, st.castBar, 5) end
	if st.castIconLayer then setFrameLevelAbove(st.castIconLayer, st.castBar, 4) end
	if st.castIconHolder and st.castIconLayer then setFrameLevelAbove(st.castIconHolder, st.castIconLayer, 0) end
	if st.castIconBorder and st.castIconHolder then setFrameLevelAbove(st.castIconBorder, st.castIconHolder, 1) end
	if UFHelper and UFHelper.syncCombatFeedbackLayer then UFHelper.syncCombatFeedbackLayer(st) end
end

local function hookTextFrameLevels(st)
	if not st then return end
	st._textLevelHooks = st._textLevelHooks or {}
	local function hookFrame(frame)
		if not frame or st._textLevelHooks[frame] then return end
		st._textLevelHooks[frame] = true
		if hooksecurefunc then
			hooksecurefunc(frame, "SetFrameLevel", function() syncTextFrameLevels(st) end)
			hooksecurefunc(frame, "SetFrameStrata", function() syncTextFrameLevels(st) end)
		end
	end
	hookFrame(st.frame)
	hookFrame(st.barGroup)
	hookFrame(st.health)
	hookFrame(st.power)
	hookFrame(st.dataBar)
	hookFrame(st.secondaryPower)
	hookFrame(st.status)
	hookFrame(st.castBar)
	syncTextFrameLevels(st)
end

local function getUnitSubGroup(unit)
	if not IsInRaid then return nil end
	if not IsInRaid() then return nil end
	local idx = UnitInRaid and UnitInRaid(unit or UNIT.PLAYER)
	if issecretvalue and issecretvalue(idx) then return nil end
	if not idx then return nil end
	local _, _, subgroup = GetRaidRosterInfo(idx)
	if issecretvalue and issecretvalue(subgroup) then return nil end
	return subgroup
end

local function formatGroupNumber(subgroup, format)
	local num = tonumber(subgroup)
	if not num then return nil end
	local fmt = format or "GROUP"
	if fmt == "NUMBER" then return tostring(num) end
	if fmt == "PARENS" then return "(" .. num .. ")" end
	if fmt == "BRACKETS" then return "[" .. num .. "]" end
	if fmt == "BRACES" then return "{" .. num .. "}" end
	if fmt == "PIPE" then return "|| " .. num .. " ||" end
	if fmt == "ANGLE" then return "<" .. num .. ">" end
	if fmt == "G" then return "G" .. num end
	if fmt == "G_SPACE" then return "G " .. num end
	if fmt == "HASH" then return "#" .. num end
	return string.format(GROUP_NUMBER or "Group %d", num)
end

local function shouldUseUnitStatusText(cfg, unit, st, def)
	if not st or not st.unitStatusText then return false end
	if not cfg or cfg.enabled == false then return false end
	def = def or defaultsFor(unit) or {}
	local scfg = cfg.status or {}
	local defStatus = def.status or {}
	local usDef = defStatus.unitStatus or {}
	local usCfg = scfg.unitStatus or usDef or {}
	return usCfg.enabled == true
end

local function updateUnitStatusIndicator(cfg, unit)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	local st = states[unit]
	if not st or (not st.unitStatusText and not st.unitGroupText) then return end
	if cfg.enabled == false then
		if st.unitStatusText then
			st.unitStatusText:SetText("")
			st.unitStatusText:Hide()
		end
		if st.unitGroupText then
			st.unitGroupText:SetText("")
			st.unitGroupText:Hide()
		end
		return
	end
	local def = defaultsFor(unit) or {}
	local defStatus = def.status or {}
	local scfg = cfg.status or {}
	local usDef = defStatus.unitStatus or {}
	local usCfg = scfg.unitStatus or usDef or {}
	if usCfg.enabled ~= true then
		if st.unitStatusText then
			st.unitStatusText:SetText("")
			st.unitStatusText:Hide()
		end
		if st.unitGroupText then
			st.unitGroupText:SetText("")
			st.unitGroupText:Hide()
		end
		return
	end
	local inEditMode = addon.EditModeLib and addon.EditModeLib:IsInEditMode()
	local allowSample = inEditMode and not isBossUnit(unit)
	if UnitExists and not UnitExists(unit) and not allowSample then
		if st.unitStatusText then
			st.unitStatusText:SetText("")
			st.unitStatusText:Hide()
		end
		if st.unitGroupText then
			st.unitGroupText:SetText("")
			st.unitGroupText:Hide()
		end
		return
	end
	local statusTag
	local lifeStatusTag
	local isDead = UnitIsDead and UnitIsDead(unit)
	if issecretvalue and issecretvalue(isDead) then isDead = nil end
	if isDead then
		lifeStatusTag = DEAD or "Dead"
	else
		local isGhost = UnitIsGhost and UnitIsGhost(unit)
		if issecretvalue and issecretvalue(isGhost) then isGhost = nil end
		if isGhost then lifeStatusTag = GHOST or "Ghost" end
	end
	local connected = UnitIsConnected and UnitIsConnected(unit)
	if issecretvalue and issecretvalue(connected) then connected = nil end
	local isAFK = UnitIsAFK and UnitIsAFK(unit)
	if issecretvalue and issecretvalue(isAFK) then isAFK = nil end
	local isDND = UnitIsDND and UnitIsDND(unit)
	if issecretvalue and issecretvalue(isDND) then isDND = nil end
	if lifeStatusTag then
		statusTag = lifeStatusTag
	elseif connected == false then
		statusTag = PLAYER_OFFLINE or "Offline"
	elseif isAFK == true then
		statusTag = DEFAULT_AFK_MESSAGE or "AFK"
	elseif isDND == true then
		statusTag = DEFAULT_DND_MESSAGE or "DND"
	end
	if not statusTag and allowSample then statusTag = DEFAULT_AFK_MESSAGE or "AFK" end
	if st.unitStatusText then
		st.unitStatusText:SetText(statusTag or "")
		st.unitStatusText:SetShown(statusTag ~= nil)
	end

	local groupTag
	if (unit == UNIT.PLAYER or unit == UNIT.TARGET) and usCfg.showGroup == true then
		local subgroup = getUnitSubGroup(unit)
		local groupFormat = usCfg.groupFormat or usDef.groupFormat or "GROUP"
		if subgroup then
			groupTag = formatGroupNumber(subgroup, groupFormat)
		elseif addon.EditModeLib and addon.EditModeLib:IsInEditMode() then
			groupTag = formatGroupNumber(1, groupFormat)
		end
	end
	if st.unitGroupText then
		st.unitGroupText:SetText(groupTag or "")
		st.unitGroupText:SetShown(groupTag ~= nil)
	end
end

local function shouldShowLevel(scfg, unit)
	if not scfg or scfg.levelEnabled == false then return false end
	if scfg.hideLevelAtMax and addon.variables and addon.variables.isMaxLevel then
		local level = UnitLevel(unit) or 0
		if addon.variables.isMaxLevel[level] then return false end
	end
	return true
end

function UF.ResolveStatusHeight(cfg, def, showStatus)
	if not showStatus then return 0 end
	return UF.STATUS_PHYSICAL_HEIGHT
end

function UF.ResolveStatusLayoutHeight(showStatus)
	if not showStatus then return 0 end
	return UF.STATUS_LAYOUT_HEIGHT
end

function UF.GetStatusVisualOffsetY(anchor, physicalHeight, layoutHeight)
	local delta = (tonumber(layoutHeight) or UF.STATUS_LAYOUT_HEIGHT) - (tonumber(physicalHeight) or UF.STATUS_PHYSICAL_HEIGHT)
	if delta <= 0 then return 0 end
	local point = type(anchor) == "string" and string.upper(anchor) or "CENTER"
	if string.find(point, "BOTTOM", 1, true) then return 0 end
	if string.find(point, "TOP", 1, true) then return delta end
	return delta / 2
end

function UF.GetStatusHeightDelta(showStatus)
	return UF.ResolveStatusLayoutHeight(showStatus) - UF.ResolveStatusHeight(nil, nil, showStatus)
end

function UF.GetAnchorVerticalFactor(point)
	point = type(point) == "string" and string.upper(point) or "CENTER"
	if string.find(point, "BOTTOM", 1, true) then return 0 end
	if string.find(point, "TOP", 1, true) then return 1 end
	return 0.5
end

function UF.GetUnitFrameStatusHeightDelta(frame)
	local unit = frame and frame._eqolUFUnit
	if unit then
		local cfg = ensureDB(unit)
		local def = defaultsFor(unit)
		return UF.GetStatusHeightDelta(UF.ShouldShowStatusLayout(cfg, unit, def))
	end
	return tonumber(frame and frame._eqolUFStatusHeightDelta) or 0
end

function UF.ResolvePhysicalUnitFrameAnchorY(point, relativePoint, storedY, relativeFrame, statusHeightDelta)
	local ownShift = -UF.GetAnchorVerticalFactor(point) * (tonumber(statusHeightDelta) or 0)
	local relativeDelta = UF.GetUnitFrameStatusHeightDelta(relativeFrame)
	local relativeShift = -UF.GetAnchorVerticalFactor(relativePoint or point) * relativeDelta
	return (tonumber(storedY) or 0) + ownShift - relativeShift
end

function UF.ResolveStoredUnitFrameAnchorY(point, relativePoint, physicalY, relativeFrame, statusHeightDelta)
	local ownShift = -UF.GetAnchorVerticalFactor(point) * (tonumber(statusHeightDelta) or 0)
	local relativeDelta = UF.GetUnitFrameStatusHeightDelta(relativeFrame)
	local relativeShift = -UF.GetAnchorVerticalFactor(relativePoint or point) * relativeDelta
	return (tonumber(physicalY) or 0) - ownShift + relativeShift
end

function UF.GetVirtualUnitFramePointOffsetY(frame, point)
	local delta = UF.GetUnitFrameStatusHeightDelta(frame)
	return UF.GetAnchorVerticalFactor(point) * delta
end

function UF.ShouldShowStatusLayout(cfg, unit, def)
	cfg = cfg or {}
	def = def or defaultsFor(unit) or {}
	local scfg = cfg.status or {}
	local defStatus = def.status or {}
	local ciCfg = scfg.combatIndicator or defStatus.combatIndicator or {}
	local usCfg = scfg.unitStatus or defStatus.unitStatus or {}
	local ttCfg = scfg.targetTargetName or defStatus.targetTargetName or {}
	return scfg.enabled ~= false
		or shouldShowLevel(scfg, unit)
		or usCfg.enabled == true
		or (UF.SupportsCombatIndicator(unit) and ciCfg.enabled ~= false)
		or (unit == UNIT.TARGET and (ttCfg.enabled == true or scfg.showTargetTargetName == true))
end

function UF.ShouldHideClassificationText(cfg, unit)
	if unit == UNIT.PLAYER or not cfg then return false end
	local scfg = cfg.status or {}
	local icfg = scfg.classificationIcon or {}
	return icfg.enabled == true and icfg.hideText == true
end

local function updateStatus(cfg, unit)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	local st = states[unit]
	if not st or not st.status then return end
	local scfg = cfg.status or {}
	local def = defaultsFor(unit)
	local defStatus = def.status or {}
	local usDef = defStatus.unitStatus or {}
	local usCfg = scfg.unitStatus or usDef or {}
	local showName = scfg.enabled ~= false
	local showLevel = shouldShowLevel(scfg, unit)
	local ttDef = defStatus.targetTargetName or {}
	local ttCfg = scfg.targetTargetName or ttDef
	local showTargetTargetName = unit == UNIT.TARGET and (ttCfg.enabled == true or scfg.showTargetTargetName == true)
	local showStatus = UF.ShouldShowStatusLayout(cfg, unit, def)
	local leaderCfg = cfg.leaderIcon or (def and def.leaderIcon) or {}
	local showLeaderIndicator = (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS) and leaderCfg.enabled == true
	local raidCfg = cfg.raidIcon or (def and def.raidIcon) or {}
	local showRaidIndicator = raidCfg.enabled ~= false
	local supportsIdentityIndicators = unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS
	local pvpCfg = cfg.pvpIndicator or (def and def.pvpIndicator) or {}
	local roleCfg = cfg.roleIndicator or (def and def.roleIndicator) or {}
	local classificationCfg = scfg.classificationIcon or defStatus.classificationIcon or {}
	local showStatusFrame = showStatus
		or showRaidIndicator
		or showLeaderIndicator
		or (supportsIdentityIndicators and pvpCfg.enabled == true)
		or (supportsIdentityIndicators and roleCfg.enabled == true)
		or (unit ~= UNIT.PLAYER and classificationCfg.enabled == true)
	local statusHeight = UF.ResolveStatusHeight(cfg, def, showStatus)
	local statusLayoutHeight = UF.ResolveStatusLayoutHeight(showStatus)
	st._statusLayoutHeight = statusLayoutHeight
	if statusHeight <= 0 then statusHeight = 0.001 end
	st.status:SetHeight(statusHeight)
	st.status:SetShown(showStatusFrame)
	local nameFontSize = scfg.nameFontSize or scfg.fontSize or 14
	local levelFontSize = scfg.levelFontSize or scfg.fontSize or 14
	local statusFontSize = scfg.fontSize or nameFontSize or levelFontSize or 14
	if st.nameText then
		UFHelper.applyFont(st.nameText, scfg.font, nameFontSize, scfg.fontOutline)
		local nameAnchor = scfg.nameAnchor or "LEFT"
		local nameOffset = scfg.nameOffset or {}
		st.nameText:ClearAllPoints()
		st.nameText:SetPoint(nameAnchor, st.status, nameAnchor, nameOffset.x or 0, (nameOffset.y or 0) + UF.GetStatusVisualOffsetY(nameAnchor, statusHeight, statusLayoutHeight))
		if st.nameText.SetJustifyH then st.nameText:SetJustifyH(nameAnchor) end
		st.nameText:SetShown(showName)
		local maxChars = scfg.nameMaxChars
		if maxChars == nil then maxChars = defStatus.nameMaxChars end
		maxChars = tonumber(maxChars) or 0
		if maxChars > 0 then
			UFHelper.applyNameCharLimit(st, scfg, defStatus)
		else
			if st.nameText.SetMaxLines then st.nameText:SetMaxLines(1) end
			if st.nameText.SetWordWrap then st.nameText:SetWordWrap(false) end
			if st.nameText.SetNonSpaceWrap then st.nameText:SetNonSpaceWrap(false) end

			local nameWidth = (st.status and st.status.GetWidth and st.status:GetWidth()) or 0
			if not nameWidth or nameWidth <= 1 then nameWidth = (st.frame and st.frame.GetWidth and st.frame:GetWidth()) or 0 end
			if not nameWidth or nameWidth <= 1 then nameWidth = max(MIN_WIDTH, tonumber(cfg.width or def.width) or 220) end
			st.nameText:SetWidth(max(1, nameWidth))
			st._eqolNameTextWidth = nil
		end
	end
	if st.targetTargetText then
		UFHelper.applyFont(st.targetTargetText, scfg.font, ttCfg.fontSize or nameFontSize, scfg.fontOutline)
		local ttAnchor = ttCfg.anchor or "RIGHT"
		local ttOffset = ttCfg.offset or {}
		st.targetTargetText:ClearAllPoints()
		st.targetTargetText:SetPoint(ttAnchor, st.status, ttAnchor, ttOffset.x or 0, (ttOffset.y or 0) + UF.GetStatusVisualOffsetY(ttAnchor, statusHeight, statusLayoutHeight))
		if st.targetTargetText.SetJustifyH then st.targetTargetText:SetJustifyH(ttAnchor) end
		st.targetTargetText:SetShown(showTargetTargetName)
	end
	if st.levelText then
		UFHelper.applyFont(st.levelText, scfg.font, levelFontSize, scfg.fontOutline)
		local levelAnchor = scfg.levelAnchor or "RIGHT"
		local levelOffset = scfg.levelOffset or {}
		st.levelText:ClearAllPoints()
		st.levelText:SetPoint(levelAnchor, st.status, levelAnchor, levelOffset.x or 0, (levelOffset.y or 0) + UF.GetStatusVisualOffsetY(levelAnchor, statusHeight, statusLayoutHeight))
		st.levelText:SetShown(showStatus and showLevel)
	end
	if st.unitStatusText then
		local unitStatusFont = usCfg.font or scfg.font
		local unitStatusFontSize = usCfg.fontSize or statusFontSize
		local unitStatusFontOutline = usCfg.fontOutline or scfg.fontOutline
		UFHelper.applyFont(st.unitStatusText, unitStatusFont, unitStatusFontSize, unitStatusFontOutline)
		local off = usCfg.offset or usDef.offset or {}
		st.unitStatusText:ClearAllPoints()
		st.unitStatusText:SetPoint("CENTER", st.status, "CENTER", off.x or 0, (off.y or 0) + UF.GetStatusVisualOffsetY("CENTER", statusHeight, statusLayoutHeight))
		if st.unitStatusText.SetJustifyH then st.unitStatusText:SetJustifyH("CENTER") end
		if st.unitStatusText.SetWordWrap then st.unitStatusText:SetWordWrap(false) end
		if st.unitStatusText.SetMaxLines then st.unitStatusText:SetMaxLines(1) end
	end
	if st.unitGroupText then
		local groupFont = usCfg.groupFont or usCfg.font or scfg.font
		local groupFontOutline = usCfg.groupFontOutline or usCfg.fontOutline or scfg.fontOutline
		local groupFontSize = usCfg.groupFontSize or usCfg.fontSize or statusFontSize
		local groupOff = usCfg.groupOffset or usDef.groupOffset or {}
		UFHelper.applyFont(st.unitGroupText, groupFont, groupFontSize, groupFontOutline)
		st.unitGroupText:ClearAllPoints()
		st.unitGroupText:SetPoint("CENTER", st.status, "CENTER", groupOff.x or 0, (groupOff.y or 0) + UF.GetStatusVisualOffsetY("CENTER", statusHeight, statusLayoutHeight))
		if st.unitGroupText.SetJustifyH then st.unitGroupText:SetJustifyH("CENTER") end
		if st.unitGroupText.SetWordWrap then st.unitGroupText:SetWordWrap(false) end
		if st.unitGroupText.SetMaxLines then st.unitGroupText:SetMaxLines(1) end
	end
	updateUnitStatusIndicator(cfg, unit)
end

local function updateCombatIndicator(cfg, unit)
	unit = unit or UNIT.PLAYER
	if not UF.SupportsCombatIndicator(unit) then return end
	local st = states[unit]
	if not st or not st.combatIcon or not st.status then return end
	local def = defaultsFor(unit)
	local defStatus = (def and def.status) or {}
	local scfg = (cfg and cfg.status) or defStatus
	local ccfg = scfg.combatIndicator or defStatus.combatIndicator or {}
	if ccfg.enabled == false then
		st.combatIcon:Hide()
		return
	end
	local option = UF.GetCombatIndicatorIconDefinition((ccfg and ccfg.icon) or UF.COMBAT_INDICATOR_DEFAULT_ICON)
	local atlas = option and option.atlas
	local appliedAtlas = false
	if atlas and st.combatIcon.SetAtlas then
		if C_Texture and C_Texture.GetAtlasInfo and not C_Texture.GetAtlasInfo(atlas) then
			appliedAtlas = false
		else
			st.combatIcon:SetTexture(nil)
			local ok, result = pcall(st.combatIcon.SetAtlas, st.combatIcon, atlas, false)
			appliedAtlas = ok and result ~= false
		end
	end
	if not appliedAtlas then
		if st.combatIcon.SetAtlas then pcall(st.combatIcon.SetAtlas, st.combatIcon, nil) end
		st.combatIcon:SetTexture((option and option.texture) or UF.COMBAT_INDICATOR_DEFAULT_TEXTURE)
		st.combatIcon:SetTexCoord(0, 1, 0, 1)
	end
	st.combatIcon:SetSize(ccfg.size or 18, ccfg.size or 18)
	st.combatIcon:ClearAllPoints()
	st.combatIcon:SetPoint(
		"TOP",
		st.status,
		"TOP",
		(ccfg.offset and ccfg.offset.x) or -8,
		((ccfg.offset and ccfg.offset.y) or 0) + UF.GetStatusVisualOffsetY("TOP", st.status:GetHeight(), st._statusLayoutHeight)
	)
	local inEditMode = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	if inEditMode or (UnitExists and UnitExists(unit) and UnitAffectingCombat and UnitAffectingCombat(unit)) then
		st.combatIcon:Show()
	else
		st.combatIcon:Hide()
	end
end

local function ensureRestLoop(st)
	if not st or st.restLoop or not st.frame then return end
	local loop = CreateFrame("Frame", nil, st.frame)
	loop:Hide()
	local tex = loop:CreateTexture(nil, "OVERLAY")
	if tex.SetAtlas then
		tex:SetAtlas("UI-HUD-UnitFrame-Player-Rest-Flipbook", true)
	else
		tex:SetTexture("Interface\\PlayerFrame\\UI-Player-Status")
	end
	tex:SetPoint("CENTER")
	loop.restTexture = tex
	local anim = loop:CreateAnimationGroup()
	anim:SetLooping("REPEAT")
	anim:SetToFinalAlpha(true)
	local flip = anim:CreateAnimation("FlipBook")
	flip:SetTarget(tex)
	flip:SetDuration(1.5)
	flip:SetOrder(1)
	if flip.SetSmoothing then flip:SetSmoothing("NONE") end
	if flip.SetFlipBookRows then flip:SetFlipBookRows(7) end
	if flip.SetFlipBookColumns then flip:SetFlipBookColumns(6) end
	if flip.SetFlipBookFrames then flip:SetFlipBookFrames(42) end
	if flip.SetFlipBookFrameWidth then flip:SetFlipBookFrameWidth(0) end
	if flip.SetFlipBookFrameHeight then flip:SetFlipBookFrameHeight(0) end
	st.restLoop = loop
	st.restLoopAnim = anim
end

local function applyRestLoopLayout(cfg)
	local st = states[UNIT.PLAYER]
	if not st or not st.restLoop then return end
	local def = defaultsFor(UNIT.PLAYER)
	local rdef = def and def.resting or {}
	local rcfg = (cfg and cfg.resting) or rdef
	local size = max(10, rcfg.size or rdef.size or 20)
	local ox = (rcfg.offset and rcfg.offset.x) or (rdef.offset and rdef.offset.x) or 0
	local oy = (rcfg.offset and rcfg.offset.y) or (rdef.offset and rdef.offset.y) or 0
	local texSize = max(1, size * 1.5)
	st.restLoop:ClearAllPoints()
	local centerOffset = (st and st._portraitCenterOffset) or 0
	st.restLoop:SetPoint("CENTER", st.barGroup or st.frame, "CENTER", (ox or 0) + centerOffset, oy)
	st.restLoop:SetSize(size, size)
	if st.restLoop.restTexture then st.restLoop.restTexture:SetSize(texSize, texSize) end
	if st.statusTextLayer then setFrameLevelAbove(st.restLoop, st.statusTextLayer, 3) end
end

local function updateRestingIndicator(cfg)
	local st = states[UNIT.PLAYER]
	if not st or not st.restLoop then return end
	local def = defaultsFor(UNIT.PLAYER)
	local rdef = def and def.resting or {}
	local rcfg = (cfg and cfg.resting) or rdef
	if not cfg or cfg.enabled == false or rcfg.enabled == false then
		if st.restLoopAnim and st.restLoopAnim:IsPlaying() then st.restLoopAnim:Stop() end
		st.restLoop:Hide()
		return
	end
	applyRestLoopLayout(cfg)
	local resting = (IsResting and IsResting()) or (UnitIsResting and UnitIsResting(UNIT.PLAYER))
	if resting then
		st.restLoop:Show()
		if st.restLoopAnim and not st.restLoopAnim:IsPlaying() then st.restLoopAnim:Play() end
	else
		if st.restLoopAnim and st.restLoopAnim:IsPlaying() then st.restLoopAnim:Stop() end
		st.restLoop:Hide()
	end
end

local function getPortraitConfig(cfg, unit)
	local def = defaultsFor(unit)
	local pdef = def and def.portrait or {}
	local pcfg = (cfg and cfg.portrait) or {}
	local enabled = pcfg.enabled
	if enabled == nil then enabled = pdef.enabled end
	local side = (pcfg.side or pdef.side or "LEFT"):upper()
	if side ~= "RIGHT" then side = "LEFT" end
	local squareBackground = pcfg.squareBackground
	if squareBackground == nil then squareBackground = pdef.squareBackground end
	local mode = tostring(pcfg.mode or pdef.mode or "PORTRAIT"):upper()
	if mode ~= "CLASS_ICON" then mode = "PORTRAIT" end
	local shape = UF.NormalizePortraitShape(pcfg.shape or pdef.shape)
	return enabled == true, side, squareBackground == true, mode, shape
end

function UF.ResolvePortraitDetachedConfig(cfg, unit)
	local def = defaultsFor(unit)
	local pdef = def and def.portrait or {}
	local pcfg = (cfg and cfg.portrait) or {}
	local detached = pcfg.detached
	if detached == nil then detached = pdef.detached end
	local offset = pcfg.detachedOffset
	local size = tonumber(pcfg.detachedSize)
	if size == nil then size = tonumber(pdef.detachedSize) end
	return detached == true, tonumber(offset and offset.x), tonumber(offset and offset.y), size
end

function UF.GetDefaultDetachedPortraitSize(cfg, unit)
	local st = unit and states[unit]
	local runtimeSize = st and tonumber(st._portraitSize)
	if runtimeSize and runtimeSize > 0 then return runtimeSize end

	local def = defaultsFor(unit)
	local powerCfg = (cfg and cfg.power) or {}
	local powerDef = (def and def.power) or {}
	local secondaryCfg = (cfg and cfg.secondaryPower) or {}
	local secondaryDef = (def and def.secondaryPower) or {}
	local size = tonumber(cfg and cfg.healthHeight) or tonumber(def and def.healthHeight) or 1
	local powerEnabled = powerCfg.enabled
	if powerEnabled == nil then powerEnabled = powerDef.enabled end
	local powerDetached = powerCfg.detached
	if powerDetached == nil then powerDetached = powerDef.detached end
	if powerEnabled ~= false and powerDetached ~= true then size = size + (tonumber(cfg and cfg.powerHeight) or tonumber(def and def.powerHeight) or 0) end
	if unit == UNIT.PLAYER then
		local secondaryEnabled = secondaryCfg.enabled
		if secondaryEnabled == nil then secondaryEnabled = secondaryDef.enabled end
		local secondaryDetached = secondaryCfg.detached
		if secondaryDetached == nil then secondaryDetached = secondaryDef.detached end
		if secondaryEnabled == true and secondaryDetached ~= true then
			size = size + (tonumber(cfg and cfg.secondaryPowerHeight) or tonumber(def and def.secondaryPowerHeight) or 0)
		end
	end
	return max(1, size)
end

function UF.GetDefaultDetachedPortraitOffset(cfg, unit, frameWidth, portraitSize)
	local st = unit and states[unit]
	local def = defaultsFor(unit)
	local width = tonumber(frameWidth)
	local detached = select(1, UF.ResolvePortraitDetachedConfig(cfg, unit))
	if width == nil and detached and st and st.barGroup and st.barGroup.GetWidth then width = tonumber(st.barGroup:GetWidth()) end
	if width == nil then width = tonumber(cfg and cfg.width) or tonumber(def and def.width) or 0 end
	local size = tonumber(portraitSize) or UF.GetDefaultDetachedPortraitSize(cfg, unit)
	local side = tostring((cfg and cfg.portrait and cfg.portrait.side) or (def.portrait and def.portrait.side) or "LEFT"):upper()
	local x = (width * 0.5) + (size * 0.5)
	if side ~= "RIGHT" then x = -x end
	return x, 0
end

function UF.ClampFrameLevel(level)
	level = tonumber(level) or 0
	level = math.floor(level + (level >= 0 and 0.5 or -0.5))
	if level < 0 then return 0 end
	if level > 65535 then return 65535 end
	return level
end

function UF.ApplyPortraitTexture(texture, unit, mode)
	if not texture then return false end
	if mode == "CLASS_ICON" and UnitIsPlayer and UnitIsPlayer(unit) then
		local classFile = select(2, UnitClass(unit))
		if issecretvalue and issecretvalue(classFile) then classFile = nil end
		local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
		if coords then
			texture:SetTexture(CLASS_ICON_TEXTURE)
			texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			return true
		end
	end
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	SetPortraitTexture(texture, unit)
	return true
end

function UF.NormalizePortraitShape(value)
	local iconShape = addon.IconShape
	local shape = iconShape and iconShape.Normalize and iconShape.Normalize(value, iconShape.SQUARE or "SQUARE") or tostring(value or "SQUARE"):upper()
	if shape == "DEFAULT" then shape = "SQUARE" end
	return shape
end

function UF.GetPortraitShapeOptions()
	local options
	if addon.IconShape and addon.IconShape.GetOptions then
		options = addon.IconShape.GetOptions(L, { exclude = { DEFAULT = true } })
	else
		options = {
			{ value = "SQUARE", label = L["settingsIconShapeSquare"] or "Square" },
			{ value = "ROUND", label = L["settingsIconShapeRound"] or "Round" },
			{ value = "ROUND_STAR", label = L["settingsIconShapeRoundStar"] or "Round star" },
			{ value = "STAR", label = L["settingsIconShapeStar"] or "Star" },
			{ value = "HEXAGON", label = L["settingsIconShapeHexagon"] or "Hexagon" },
			{ value = "DIAMOND", label = L["settingsIconShapeDiamond"] or "Diamond" },
		}
	end
	for _, option in ipairs(options) do
		if option.text == nil then option.text = option.label or tostring(option.value or "") end
	end
	return options
end

function UF.ApplyPortraitShape(st, shape)
	if not (st and st.portraitHolder) then return end
	local iconShape = addon.IconShape
	if not (iconShape and iconShape.EnsureMask and iconShape.ApplyTextureMask and iconShape.ClearTextureMask) then return end

	shape = UF.NormalizePortraitShape(shape)
	local mask = iconShape.EnsureMask(st.portraitHolder, shape, "_eqolPortraitShapeMask")
	local textures = { st.portrait, st.portraitBg }
	for _, texture in ipairs(textures) do
		if mask then
			iconShape.ApplyTextureMask(texture, mask, "_eqolPortraitShapeTextureMask")
		else
			iconShape.ClearTextureMask(texture, "_eqolPortraitShapeTextureMask")
		end
	end
	st._portraitShape = shape
end

local function getPortraitSeparatorConfig(cfg, unit, portraitEnabled)
	if not portraitEnabled or not cfg or cfg.enabled == false then return false, 0, "SOLID" end
	local def = defaultsFor(unit)
	local borderDef = def and def.border or {}
	local borderCfg = cfg.border or {}
	if not UF._isFrameBorderEnabled(borderCfg, borderDef, true) then return false, 0, "SOLID" end
	local pdef = def and def.portrait or {}
	local pcfg = (cfg and cfg.portrait) or {}
	local sdef = pdef.separator or {}
	local scfg = pcfg.separator or {}
	local enabled = scfg.enabled
	if enabled == nil then enabled = sdef.enabled end
	if enabled == nil then enabled = true end
	if enabled ~= true then return false, 0, "SOLID" end
	local size = scfg.size
	if size == nil then size = sdef.size end
	if not size or size <= 0 then size = borderCfg.edgeSize or 1 end
	size = max(1, size or 1)
	local texture = scfg.texture
	if not texture or texture == "" then texture = sdef.texture end
	if not texture or texture == "" then texture = "SOLID" end
	local useCustomColor = scfg.useCustomColor
	if useCustomColor == nil then useCustomColor = sdef.useCustomColor end
	local color
	if useCustomColor == true then
		color = scfg.color
		if color == nil then color = sdef.color end
	end
	if not color then color = borderCfg.color or borderDef.color or { 0, 0, 0, 0.8 } end
	return true, size, texture, color
end

local function applyPortraitSeparator(cfg, unit, st, portraitEnabled)
	if not st or not st.portraitSeparator or not st.portraitHolder then return end
	if UnitExists and not UnitExists(unit) then
		st.portraitSeparator:Hide()
		return
	end
	local separatorEnabled, separatorSize, separatorTexture, separatorColor = getPortraitSeparatorConfig(cfg, unit, portraitEnabled)
	if not separatorEnabled or not separatorSize or separatorSize <= 0 then
		st.portraitSeparator:Hide()
		return
	end
	separatorSize = UF.ResolvePixelLayoutSize(st.portraitHolder, separatorSize)
	local color = separatorColor or { 0, 0, 0, 0.8 }
	st.portraitSeparator:SetTexture(UFHelper.resolveSeparatorTexture(separatorTexture))
	st.portraitSeparator:SetVertexColor(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1)
	st.portraitSeparator:ClearAllPoints()
	local side = st._portraitSide or "LEFT"
	if side == "RIGHT" then
		st.portraitSeparator:SetPoint("TOP", st.portraitHolder, "TOP", 0, 0)
		st.portraitSeparator:SetPoint("BOTTOM", st.portraitHolder, "BOTTOM", 0, 0)
		st.portraitSeparator:SetPoint("RIGHT", st.portraitHolder, "LEFT", 0, 0)
	else
		st.portraitSeparator:SetPoint("TOP", st.portraitHolder, "TOP", 0, 0)
		st.portraitSeparator:SetPoint("BOTTOM", st.portraitHolder, "BOTTOM", 0, 0)
		st.portraitSeparator:SetPoint("LEFT", st.portraitHolder, "RIGHT", 0, 0)
	end
	st.portraitSeparator:SetWidth(separatorSize)
	st.portraitSeparator:Show()
end

local function updatePortrait(cfg, unit)
	cfg = cfg or (states[unit] and states[unit].cfg) or ensureDB(unit)
	local st = states[unit]
	if not st or not st.portrait then return end
	local enabled, _, squareBackground, mode, shape = getPortraitConfig(cfg, unit)
	local detached = select(1, UF.ResolvePortraitDetachedConfig(cfg, unit))
	st._portraitEnabled = enabled and cfg.enabled ~= false or false
	if not enabled or cfg.enabled == false then
		st.portrait:Hide()
		st.portrait:SetTexture(nil)
		if st.portraitBg then st.portraitBg:Hide() end
		if st.portraitHolder then st.portraitHolder:Hide() end
		applyPortraitSeparator(cfg, unit, st, false)
		return
	end
	if UnitExists and not UnitExists(unit) then
		st.portrait:Hide()
		st.portrait:SetTexture(nil)
		if st.portraitBg then st.portraitBg:Hide() end
		if st.portraitHolder then st.portraitHolder:Hide() end
		applyPortraitSeparator(cfg, unit, st, false)
		return
	end
	UF.ApplyPortraitTexture(st.portrait, unit, mode)
	UF.ApplyPortraitShape(st, shape)
	st.portrait:Show()
	if st.portraitHolder then st.portraitHolder:Show() end
	if st.portraitBg then
		if squareBackground == true then
			st.portraitBg:Show()
		else
			st.portraitBg:Hide()
		end
	end
	applyPortraitSeparator(cfg, unit, st, not detached)
end

local function layoutFrame(cfg, unit)
	local st = states[unit]
	if not st or not st.frame then return end
	local def = defaultsFor(unit)
	local dynamicAnchorOwner = isBossUnit(unit) and bossContainer or st.frame
	local dynamicWinner = UF.GetDynamicAnchorWinner(unit, dynamicAnchorOwner)
	local showStatus = UF.ShouldShowStatusLayout(cfg, unit, def)
	local pcfg = cfg.power or {}
	local hcfg = cfg.health or {}
	local hdef = def.health or {}
	local powerDef = def.power or {}
	local secondaryCfg = cfg.secondaryPower or {}
	local secondaryDef = def.secondaryPower or {}
	local secondaryPowerToken
	if unit == UNIT.PLAYER and UFHelper and UFHelper.ResolveSecondaryPowerToken then
		secondaryPowerToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
	end
	local powerEnabled = pcfg.enabled ~= false
	if unit == UNIT.PLAYER and powerEnabled and UFHelper and UFHelper.IsPrimaryPowerAllowed then
		refreshMainPower(unit)
		local powerEnum, powerToken = getMainPower(unit)
		powerEnabled = UFHelper.IsPrimaryPowerAllowed(pcfg, powerDef, powerToken, powerEnum, unit) ~= false
	end
	local powerDetached = powerEnabled and pcfg.detached == true
	local secondaryPowerEnabled = unit == UNIT.PLAYER and st.secondaryPower and secondaryCfg.enabled ~= false and secondaryPowerToken ~= nil
	local secondaryPowerDetached = secondaryPowerEnabled and secondaryCfg.detached == true
	local width = UF.ResolvePixelLayoutSize(st.barGroup or st.frame, max(MIN_WIDTH, cfg.width or def.width))
	local statusHeight = UF.ResolveStatusHeight(cfg, def, showStatus)
	local statusLayoutHeight = UF.ResolveStatusLayoutHeight(showStatus)
	local statusHeightDelta = statusLayoutHeight - statusHeight
	st._statusLayoutHeight = statusLayoutHeight
	st.frame._eqolUFStatusHeightDelta = statusHeightDelta
	local healthHeight = UF.ResolvePixelLayoutSize(st.barGroup or st.frame, cfg.healthHeight or def.healthHeight)
	local powerHeight = powerEnabled and UF.ResolvePixelLayoutSize(st.barGroup or st.frame, cfg.powerHeight or def.powerHeight) or 0
	local secondaryPowerHeight = secondaryPowerEnabled
			and UF.ResolvePixelLayoutSize(st.barGroup or st.frame, cfg.secondaryPowerHeight or def.secondaryPowerHeight or cfg.powerHeight or def.powerHeight)
		or 0
	local healthOrientation = UFHelper.normalizeStatusBarOrientation(hcfg.orientation or hdef.orientation)
	local powerOrientation = UFHelper.normalizeStatusBarOrientation(pcfg.orientation or powerDef.orientation)
	local secondaryPowerOrientation = UFHelper.normalizeStatusBarOrientation(secondaryCfg.orientation or secondaryDef.orientation)
	UFHelper.applyStatusBarOrientation(st.health, healthOrientation)
	UFHelper.applyStatusBarOrientation(st.tempMaxHealthLoss, healthOrientation)
	UFHelper.applyStatusBarOrientation(st.power, powerOrientation)
	UFHelper.applyStatusBarOrientation(st.secondaryPower, secondaryPowerOrientation)
	local dataBarEnabled = UF.DataBar.IsEnabled(cfg, def)
	local dataBarCfg = cfg.dataBar or {}
	local dataBarDef = def.dataBar or {}
	local dataBarHeight = dataBarEnabled and max(1, tonumber(dataBarCfg.height or dataBarDef.height or 16) or 16) or 0
	local dataBarGap = dataBarEnabled and (tonumber(dataBarCfg.gap or dataBarDef.gap or 0) or 0) or 0
	if dataBarEnabled then
		if dataBarGap < -dataBarHeight then dataBarGap = -dataBarHeight end
		if dataBarGap > 40 then dataBarGap = 40 end
	end
	local dataBarPosition = UF.DataBar.GetPosition(cfg, def)
	local dataBarOuterHeight = dataBarEnabled and (dataBarHeight + dataBarGap) or 0
	local dataBarCanDetach = unit == UNIT.TARGET or unit == UNIT.TARGET_TARGET
	local dataBarDetached = dataBarCanDetach and dataBarCfg.detached == true
	local stackHeight = healthHeight + (powerDetached and 0 or powerHeight) + (secondaryPowerDetached and 0 or secondaryPowerHeight)
	local borderCfg = cfg.border or {}
	local borderDef = def.border or {}
	local borderEnabled = UF._isFrameBorderEnabled(borderCfg, borderDef, true)
	local borderOffset = 0
	if borderEnabled then
		borderOffset = borderCfg.offset
		if borderOffset == nil then borderOffset = borderCfg.edgeSize or borderDef.edgeSize or 1 end
		borderOffset = UF.ResolveBorderLayoutOffset(st.barGroup or st.frame, borderOffset)
	end
	local detachedPowerBorder = powerDetached and powerEnabled and borderCfg.detachedPower == true
	local detachedPowerOffset = 0
	if detachedPowerBorder then
		detachedPowerOffset = borderCfg.detachedPowerOffset
		if detachedPowerOffset == nil then detachedPowerOffset = borderCfg.offset end
		if detachedPowerOffset == nil then detachedPowerOffset = borderCfg.edgeSize or borderDef.edgeSize or 1 end
		detachedPowerOffset = UF.ResolveBorderLayoutOffset(st.powerGroup or st.power, detachedPowerOffset)
	end
	local detachedSecondaryPowerBorder = secondaryPowerDetached and secondaryPowerEnabled and borderCfg.detachedSecondaryPower == true
	local detachedSecondaryPowerOffset = 0
	if detachedSecondaryPowerBorder then
		detachedSecondaryPowerOffset = borderCfg.detachedSecondaryPowerOffset
		if detachedSecondaryPowerOffset == nil then detachedSecondaryPowerOffset = borderCfg.offset end
		if detachedSecondaryPowerOffset == nil then detachedSecondaryPowerOffset = borderCfg.edgeSize or borderDef.edgeSize or 1 end
		detachedSecondaryPowerOffset = UF.ResolveBorderLayoutOffset(st.secondaryPowerGroup or st.secondaryPower, detachedSecondaryPowerOffset)
	end
	local portraitEnabled, portraitSide, portraitSquareBackground, _, portraitShape = getPortraitConfig(cfg, unit)
	local portraitDetached, portraitDetachedX, portraitDetachedY, portraitDetachedSize = UF.ResolvePortraitDetachedConfig(cfg, unit)
	portraitDetached = portraitEnabled and portraitDetached == true
	local portraitInnerHeight = stackHeight
	local portraitBaseSize = portraitDetached and (portraitDetachedSize or portraitInnerHeight) or portraitInnerHeight
	local portraitSize = portraitEnabled and UF.ResolvePixelLayoutSize(st.portraitHolder or st.barGroup or st.frame, max(1, portraitBaseSize)) or 0
	local separatorEnabled, separatorSize = getPortraitSeparatorConfig(cfg, unit, portraitEnabled)
	if separatorEnabled then separatorSize = UF.ResolvePixelLayoutSize(st.barGroup or st.frame, separatorSize) end
	local separatorSpace = separatorEnabled and separatorSize or 0
	local portraitSpace = (portraitEnabled and not portraitDetached) and (portraitSize + separatorSpace) or 0
	local barAreaOffsetLeft = (portraitEnabled and portraitSide == "LEFT") and portraitSpace or 0
	local barAreaOffsetRight = (portraitEnabled and portraitSide == "RIGHT") and portraitSpace or 0
	local barCenterOffset = 0
	if portraitEnabled and portraitSpace > 0 then barCenterOffset = (portraitSide == "LEFT") and (portraitSpace / 2) or -(portraitSpace / 2) end
	local statusOffsetLeft = barAreaOffsetLeft
	local statusOffsetRight = -barAreaOffsetRight
	st._portraitSpace = portraitSpace
	st._portraitCenterOffset = barCenterOffset
	local matchedFrameWidth
	if dynamicWinner and dynamicWinner.matchRelativeWidth == true and dynamicWinner.frame ~= UIParent and dynamicWinner.frame.GetWidth then
		local relativeWidth = dynamicWinner.frame:GetWidth()
		if issecretvalue and issecretvalue(relativeWidth) then relativeWidth = nil end
		relativeWidth = tonumber(relativeWidth) or 0
		if relativeWidth > 0 then
			local relativeScale = dynamicWinner.frame.GetEffectiveScale and dynamicWinner.frame:GetEffectiveScale() or 1
			local ownerScale = st.frame.GetEffectiveScale and st.frame:GetEffectiveScale() or 1
			if issecretvalue and issecretvalue(relativeScale) then relativeScale = 1 end
			if issecretvalue and issecretvalue(ownerScale) then ownerScale = 1 end
			relativeScale = tonumber(relativeScale) or 1
			ownerScale = tonumber(ownerScale) or 1
			if ownerScale <= 0 then ownerScale = 1 end
			matchedFrameWidth = max(MIN_WIDTH, (relativeWidth * relativeScale) / ownerScale + (tonumber(dynamicWinner.matchRelativeWidthOffset) or 0))
			width = UF.ResolvePixelLayoutSize(st.barGroup or st.frame, max(MIN_WIDTH, matchedFrameWidth - borderOffset * 2 - portraitSpace))
		end
	end
	local frameWidth = UF.ResolvePixelLayoutSize(st.frame, matchedFrameWidth or (width + borderOffset * 2 + portraitSpace))
	if portraitDetached and (portraitDetachedX == nil or portraitDetachedY == nil) then
		local defaultPortraitX, defaultPortraitY = UF.GetDefaultDetachedPortraitOffset(cfg, unit, frameWidth, portraitSize)
		if portraitDetachedX == nil then portraitDetachedX = defaultPortraitX end
		if portraitDetachedY == nil then portraitDetachedY = defaultPortraitY end
	end
	portraitDetachedX = portraitDetachedX or 0
	portraitDetachedY = portraitDetachedY or 0
	st.frame:SetWidth(frameWidth)
	local frameStrata = normalizeStrataToken(cfg.strata) or normalizeStrataToken(def.strata) or "LOW"
	if st.frame.GetFrameStrata and st.frame:GetFrameStrata() ~= frameStrata then st.frame:SetFrameStrata(frameStrata) end
	local selection = st.frame.Selection
	if selection and selection.SetFrameStrata then
		if not st._selectionBaseStrata then
			local baseStrata = (selection.GetFrameStrata and selection:GetFrameStrata()) or "MEDIUM"
			st._selectionBaseStrata = baseStrata
			st._selectionBaseStrataIndex = STRATA_INDEX[baseStrata] or STRATA_INDEX.MEDIUM
		end
		local baseIndex = st._selectionBaseStrataIndex or STRATA_INDEX.MEDIUM
		local targetIndex = cfg.strata and STRATA_INDEX[cfg.strata]
		local targetStrata = (targetIndex and targetIndex > baseIndex) and cfg.strata or st._selectionBaseStrata
		if targetStrata and selection.GetFrameStrata and selection:GetFrameStrata() ~= targetStrata then selection:SetFrameStrata(targetStrata) end
	end
	if cfg.frameLevel then
		st.frame:SetFrameLevel(cfg.frameLevel)
	else
		local pf = _G.PlayerFrame
		if pf and pf.GetFrameLevel then st.frame:SetFrameLevel(pf:GetFrameLevel()) end
	end
	local frameLevel = (st.frame and st.frame.GetFrameLevel and st.frame:GetFrameLevel()) or 0
	if st.status.SetFrameStrata and st.status:GetFrameStrata() ~= frameStrata then st.status:SetFrameStrata(frameStrata) end
	if st.barGroup and st.barGroup.SetFrameStrata and st.barGroup:GetFrameStrata() ~= frameStrata then st.barGroup:SetFrameStrata(frameStrata) end
	if st.healthContainer and st.healthContainer.SetFrameStrata and st.healthContainer:GetFrameStrata() ~= frameStrata then st.healthContainer:SetFrameStrata(frameStrata) end
	if st.health.SetFrameStrata and st.health:GetFrameStrata() ~= frameStrata then st.health:SetFrameStrata(frameStrata) end
	if st.dataBar and st.dataBar.SetFrameStrata and st.dataBar:GetFrameStrata() ~= frameStrata then st.dataBar:SetFrameStrata(frameStrata) end
	if st.status.SetFrameLevel then st.status:SetFrameLevel(frameLevel + 1) end
	if st.barGroup and st.barGroup.SetFrameLevel then st.barGroup:SetFrameLevel(frameLevel + 1) end
	if st.healthContainer and st.healthContainer.SetFrameLevel then st.healthContainer:SetFrameLevel(frameLevel + 2) end
	if st.health.SetFrameLevel then st.health:SetFrameLevel(frameLevel + 2) end
	if st.dataBar and st.dataBar.SetFrameLevel then st.dataBar:SetFrameLevel(frameLevel + 1) end
	st.status:SetHeight(statusHeight)
	if st.healthContainer then st.healthContainer:SetSize(width, healthHeight) end
	st.health:SetSize(width, healthHeight)
	local detachedGrowFromCenter = powerDetached and pcfg.detachedGrowFromCenter == true
	local detachedMatchHealthWidth = powerDetached and pcfg.detachedMatchHealthWidth == true
	local powerWidth = width
	if powerDetached and not detachedMatchHealthWidth and pcfg.width and pcfg.width > 0 then powerWidth = UF.ResolvePixelLayoutSize(st.powerGroup or st.power, pcfg.width) end
	st.power:SetSize(powerWidth, powerHeight)
	st.power:SetShown(powerEnabled)
	local secondaryDetachedGrowFromCenter = secondaryPowerDetached and secondaryCfg.detachedGrowFromCenter == true
	local secondaryDetachedMatchHealthWidth = secondaryPowerDetached and secondaryCfg.detachedMatchHealthWidth == true
	local secondaryPowerWidth = width
	if secondaryPowerDetached and not secondaryDetachedMatchHealthWidth and secondaryCfg.width and secondaryCfg.width > 0 then
		secondaryPowerWidth = UF.ResolvePixelLayoutSize(st.secondaryPowerGroup or st.secondaryPower, secondaryCfg.width)
	end
	if st.secondaryPower then
		st.secondaryPower:SetSize(secondaryPowerWidth, secondaryPowerHeight)
		st.secondaryPower:SetShown(secondaryPowerEnabled)
	end

	st.status:ClearAllPoints()
	if st.barGroup then st.barGroup:ClearAllPoints() end
	if st.healthContainer then st.healthContainer:ClearAllPoints() end
	st.health:ClearAllPoints()
	st.power:ClearAllPoints()
	if st.powerGroup then st.powerGroup:ClearAllPoints() end
	if st.secondaryPower then st.secondaryPower:ClearAllPoints() end
	if st.secondaryPowerGroup then st.secondaryPowerGroup:ClearAllPoints() end
	if st.dataBar then st.dataBar:ClearAllPoints() end

	local anchor = cfg.anchor or def.anchor or defaults.player.anchor
	if isBossUnit(unit) then
		local container = ensureBossContainer() or UIParent
		if st.frame.SetParent then st.frame:SetParent(container) end
		if st.frame:GetNumPoints() == 0 then st.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0) end
	else
		local placement = dynamicWinner and dynamicWinner.placement or anchor
		local rel = dynamicWinner and dynamicWinner.frame or resolveRelativeAnchorFrame(anchor and (anchor.relativeTo or anchor.relativeFrame), st.frame and st.frame:GetName())
		local anchorPoint = placement.point or "CENTER"
		local relativePoint = placement.relativePoint or anchorPoint
		local anchorY = dynamicWinner and (placement.y or 0) or UF.ResolvePhysicalUnitFrameAnchorY(anchorPoint, relativePoint, anchor.y, rel, statusHeightDelta)
		st.frame:ClearAllPoints()
		st.frame:SetPoint(anchorPoint, rel or UIParent, relativePoint, placement.x or 0, anchorY)
		st.frame._eqolDynamicAnchorWinner = dynamicWinner and dynamicWinner.targetId or nil
		if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.ReapplyTrackerAnchorsForTarget and st.frame.GetName then
			addon.MythicPlus.functions.ReapplyTrackerAnchorsForTarget(st.frame:GetName())
		end
	end

	local y = 0
	if st.dataBar then
		if dataBarEnabled then
			if st.dataBar.GetParent and st.dataBar:GetParent() ~= st.frame then st.dataBar:SetParent(st.frame) end
			if dataBarDetached then
				local detachedOffset = dataBarCfg.detachedOffset or dataBarDef.detachedOffset or {}
				local detachedX = tonumber(detachedOffset.x) or 0
				local detachedY = tonumber(detachedOffset.y) or 0
				local detachedWidth = math.min(1000, max(10, tonumber(dataBarCfg.detachedWidth or dataBarDef.detachedWidth or frameWidth) or frameWidth))
				local detachedHeight = math.min(1000, max(4, tonumber(dataBarCfg.detachedHeight or dataBarDef.detachedHeight or dataBarHeight) or dataBarHeight))
				st.dataBar:SetSize(detachedWidth, detachedHeight)
				if dataBarPosition == "ABOVE" then
					st.dataBar:SetPoint("BOTTOMLEFT", st.frame, "TOPLEFT", detachedX, dataBarGap + detachedY)
				elseif dataBarPosition == "CENTER" then
					st.dataBar:SetPoint("CENTER", st.frame, "CENTER", detachedX, detachedY)
				else
					st.dataBar:SetPoint("TOPLEFT", st.frame, "BOTTOMLEFT", detachedX, -dataBarGap + detachedY)
				end
			else
				st.dataBar:SetHeight(dataBarHeight)
				if dataBarPosition == "CENTER" then
					st.dataBar:SetPoint("LEFT", st.frame, "LEFT", 0, 0)
					st.dataBar:SetPoint("RIGHT", st.frame, "RIGHT", 0, 0)
				else
					local dataBarAnchorY = -(statusHeight + stackHeight + borderOffset * 2 + dataBarGap)
					if dataBarPosition == "ABOVE" then dataBarAnchorY = statusHeightDelta end
					st.dataBar:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, dataBarAnchorY)
					st.dataBar:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", 0, dataBarAnchorY)
					if dataBarPosition == "ABOVE" then y = -dataBarOuterHeight end
				end
			end
			st.dataBar:Show()
		else
			UF.DataBar.Hide(st)
		end
	end
	local contentTopY = y
	if statusHeight > 0 then
		st.status:SetPoint("TOPLEFT", st.frame, "TOPLEFT", statusOffsetLeft, contentTopY)
		st.status:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", statusOffsetRight, contentTopY)
		y = contentTopY - statusHeight
	else
		st.status:SetPoint("TOPLEFT", st.frame, "TOPLEFT", statusOffsetLeft, contentTopY)
		st.status:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", statusOffsetRight, contentTopY)
	end
	-- Bars container sits below status; border applied here, not on status
	local barsHeight = UF.ResolvePixelLayoutSize(st.barGroup or st.frame, stackHeight + borderOffset * 2)
	if st.barGroup then
		st.barGroup:SetWidth(frameWidth)
		st.barGroup:SetHeight(barsHeight)
		st.barGroup:SetPoint("TOPLEFT", st.frame, "TOPLEFT", 0, y)
		st.barGroup:SetPoint("TOPRIGHT", st.frame, "TOPRIGHT", 0, y)
	end

	local barInsetLeft = borderOffset + barAreaOffsetLeft
	local barInsetRight = borderOffset + barAreaOffsetRight
	local healthSlot = st.healthContainer or st.health
	healthSlot:SetPoint("TOPLEFT", st.barGroup or st.frame, "TOPLEFT", barInsetLeft, -borderOffset)
	healthSlot:SetPoint("TOPRIGHT", st.barGroup or st.frame, "TOPRIGHT", -barInsetRight, -borderOffset)
	if st.healthTextLayer then
		if st.healthTextLayer.GetParent and st.healthTextLayer:GetParent() ~= healthSlot then st.healthTextLayer:SetParent(healthSlot) end
		st.healthTextLayer:ClearAllPoints()
		st.healthTextLayer:SetAllPoints(healthSlot)
	end
	st.health:ClearAllPoints()
	if st.tempMaxHealthLoss then
		st.tempMaxHealthLoss:ClearAllPoints()
		st.tempMaxHealthLoss:SetAllPoints(healthSlot)
	end
	local showTempLoss = hcfg.tempMaxHealthLossEnabled
	if showTempLoss == nil then showTempLoss = hdef.tempMaxHealthLossEnabled ~= false end
	if showTempLoss and st.tempMaxHealthLoss and st.tempMaxHealthLoss.GetStatusBarTexture then
		local reverseHealth = hcfg.reverseFill
		if reverseHealth == nil then reverseHealth = hdef.reverseFill == true end
		UFHelper.LayoutTemporaryMaxHealthLoss(healthSlot, st.health, st.tempMaxHealthLoss, {
			axis = UFHelper.GetHealthAxis(healthOrientation, reverseHealth),
			reserveHealthSpace = true,
		})
	else
		st.health:SetAllPoints(healthSlot)
	end
	if powerDetached then
		local off = pcfg.offset or {}
		local ox = off.x or 0
		local oy = off.y or 0
		local centerOx = detachedGrowFromCenter and (ox - (st._portraitCenterOffset or 0)) or ox
		if detachedPowerBorder and st.powerGroup then
			if st.power.GetParent and st.power:GetParent() ~= st.powerGroup then st.power:SetParent(st.powerGroup) end
			st.powerGroup:Show()
			st.powerGroup:SetSize(
				UF.ResolvePixelLayoutSize(st.powerGroup, powerWidth + detachedPowerOffset * 2),
				UF.ResolvePixelLayoutSize(st.powerGroup, powerHeight + detachedPowerOffset * 2)
			)
			if detachedGrowFromCenter then
				st.powerGroup:SetPoint("TOP", healthSlot, "BOTTOM", centerOx, oy + detachedPowerOffset)
				st.power:SetPoint("TOP", st.powerGroup, "TOP", 0, -detachedPowerOffset)
			else
				st.powerGroup:SetPoint("TOPLEFT", healthSlot, "BOTTOMLEFT", ox - detachedPowerOffset, oy + detachedPowerOffset)
				st.power:SetPoint("TOPLEFT", st.powerGroup, "TOPLEFT", detachedPowerOffset, -detachedPowerOffset)
			end
		else
			if st.powerGroup then st.powerGroup:Hide() end
			if st.power.GetParent and st.power:GetParent() ~= st.barGroup then st.power:SetParent(st.barGroup) end
			if detachedGrowFromCenter then
				st.power:SetPoint("TOP", healthSlot, "BOTTOM", centerOx, oy)
			else
				st.power:SetPoint("TOPLEFT", healthSlot, "BOTTOMLEFT", ox, oy)
			end
		end
	else
		if st.powerGroup then st.powerGroup:Hide() end
		if st.power.GetParent and st.power:GetParent() ~= st.barGroup then st.power:SetParent(st.barGroup) end
		st.power:SetPoint("TOPLEFT", healthSlot, "BOTTOMLEFT", 0, 0)
		st.power:SetPoint("TOPRIGHT", healthSlot, "BOTTOMRIGHT", 0, 0)
	end
	if st.secondaryPower then
		if secondaryPowerDetached then
			local soff = secondaryCfg.offset or {}
			local sox = soff.x or 0
			local soy = soff.y or 0
			local secondaryCenterOx = secondaryDetachedGrowFromCenter and (sox - (st._portraitCenterOffset or 0)) or sox
			if detachedSecondaryPowerBorder and st.secondaryPowerGroup then
				if st.secondaryPower.GetParent and st.secondaryPower:GetParent() ~= st.secondaryPowerGroup then st.secondaryPower:SetParent(st.secondaryPowerGroup) end
				st.secondaryPowerGroup:Show()
				st.secondaryPowerGroup:SetSize(
					UF.ResolvePixelLayoutSize(st.secondaryPowerGroup, secondaryPowerWidth + detachedSecondaryPowerOffset * 2),
					UF.ResolvePixelLayoutSize(st.secondaryPowerGroup, secondaryPowerHeight + detachedSecondaryPowerOffset * 2)
				)
				if secondaryDetachedGrowFromCenter then
					st.secondaryPowerGroup:SetPoint("TOP", healthSlot, "BOTTOM", secondaryCenterOx, soy + detachedSecondaryPowerOffset)
					st.secondaryPower:SetPoint("TOP", st.secondaryPowerGroup, "TOP", 0, -detachedSecondaryPowerOffset)
				else
					st.secondaryPowerGroup:SetPoint("TOPLEFT", healthSlot, "BOTTOMLEFT", sox - detachedSecondaryPowerOffset, soy + detachedSecondaryPowerOffset)
					st.secondaryPower:SetPoint("TOPLEFT", st.secondaryPowerGroup, "TOPLEFT", detachedSecondaryPowerOffset, -detachedSecondaryPowerOffset)
				end
			else
				if st.secondaryPowerGroup then st.secondaryPowerGroup:Hide() end
				if st.secondaryPower.GetParent and st.secondaryPower:GetParent() ~= st.barGroup then st.secondaryPower:SetParent(st.barGroup) end
				if secondaryDetachedGrowFromCenter then
					st.secondaryPower:SetPoint("TOP", healthSlot, "BOTTOM", secondaryCenterOx, soy)
				else
					st.secondaryPower:SetPoint("TOPLEFT", healthSlot, "BOTTOMLEFT", sox, soy)
				end
			end
		else
			if st.secondaryPowerGroup then st.secondaryPowerGroup:Hide() end
			if st.secondaryPower.GetParent and st.secondaryPower:GetParent() ~= st.barGroup then st.secondaryPower:SetParent(st.barGroup) end
			local secondaryAnchor = healthSlot
			if powerEnabled and not powerDetached then secondaryAnchor = st.power end
			st.secondaryPower:SetPoint("TOPLEFT", secondaryAnchor, "BOTTOMLEFT", 0, 0)
			st.secondaryPower:SetPoint("TOPRIGHT", secondaryAnchor, "BOTTOMRIGHT", 0, 0)
		end
	end
	local powerStrata = frameStrata
	if powerDetached then
		local detachedStrata = pcfg.detachedStrata
		if detachedStrata == nil then detachedStrata = powerDef.detachedStrata end
		detachedStrata = normalizeStrataToken(detachedStrata)
		powerStrata = detachedStrata or AuraUtil.getRaisedStrataToken(frameStrata)
	end
	if st.power.SetFrameStrata and st.power:GetFrameStrata() ~= powerStrata then st.power:SetFrameStrata(powerStrata) end
	if st.powerGroup and st.powerGroup.SetFrameStrata and st.powerGroup:GetFrameStrata() ~= powerStrata then st.powerGroup:SetFrameStrata(powerStrata) end
	local secondaryPowerStrata = frameStrata
	if secondaryPowerDetached then
		local detachedStrata = secondaryCfg.detachedStrata
		if detachedStrata == nil then detachedStrata = secondaryDef.detachedStrata end
		detachedStrata = normalizeStrataToken(detachedStrata)
		secondaryPowerStrata = detachedStrata or AuraUtil.getRaisedStrataToken(frameStrata)
	end
	if st.secondaryPower and st.secondaryPower.SetFrameStrata and st.secondaryPower:GetFrameStrata() ~= secondaryPowerStrata then st.secondaryPower:SetFrameStrata(secondaryPowerStrata) end
	if st.secondaryPowerGroup and st.secondaryPowerGroup.SetFrameStrata and st.secondaryPowerGroup:GetFrameStrata() ~= secondaryPowerStrata then
		st.secondaryPowerGroup:SetFrameStrata(secondaryPowerStrata)
	end
	local healthLevel = (st.health and st.health.GetFrameLevel and st.health:GetFrameLevel()) or (frameLevel + 2)
	local powerLevel = healthLevel
	if powerDetached then
		local levelOffset = pcfg.detachedFrameLevelOffset
		if levelOffset == nil then levelOffset = powerDef.detachedFrameLevelOffset end
		levelOffset = levelOffset or 0
		powerLevel = max(0, frameLevel + levelOffset)
		if powerLevel <= healthLevel then powerLevel = healthLevel + 1 end
	end
	if st.power.SetFrameLevel then st.power:SetFrameLevel(powerLevel) end
	if st.powerGroup and st.powerGroup.SetFrameLevel then
		local groupLevel = powerLevel
		if powerDetached then groupLevel = max(0, powerLevel - 1) end
		st.powerGroup:SetFrameLevel(groupLevel)
	end
	local secondaryPowerLevel = healthLevel
	if secondaryPowerDetached then
		local levelOffset = secondaryCfg.detachedFrameLevelOffset
		if levelOffset == nil then levelOffset = secondaryDef.detachedFrameLevelOffset end
		levelOffset = levelOffset or 0
		secondaryPowerLevel = max(0, frameLevel + levelOffset)
		if secondaryPowerLevel <= healthLevel then secondaryPowerLevel = healthLevel + 1 end
	else
		secondaryPowerLevel = powerEnabled and not powerDetached and (powerLevel + 1) or (healthLevel + 1)
	end
	if st.secondaryPower and st.secondaryPower.SetFrameLevel then st.secondaryPower:SetFrameLevel(secondaryPowerLevel) end
	if st.secondaryPowerGroup and st.secondaryPowerGroup.SetFrameLevel then
		local groupLevel = secondaryPowerLevel
		if secondaryPowerDetached then groupLevel = max(0, secondaryPowerLevel - 1) end
		st.secondaryPowerGroup:SetFrameLevel(groupLevel)
	end

	st._portraitSide = portraitSide
	st._portraitSize = portraitSize
	if st.portraitHolder then
		if portraitEnabled then
			local holderParent = st.barGroup or st.frame
			local holderOffset = borderOffset + (portraitSize / 2)
			st.portraitHolder:SetSize(portraitSize, portraitSize)
			st.portraitHolder:ClearAllPoints()
			if portraitDetached then
				st.portraitHolder:SetPoint("CENTER", holderParent, "CENTER", portraitDetachedX, portraitDetachedY)
			elseif portraitSide == "RIGHT" then
				st.portraitHolder:SetPoint("CENTER", holderParent, "RIGHT", -holderOffset, 0)
			else
				st.portraitHolder:SetPoint("CENTER", holderParent, "LEFT", holderOffset, 0)
			end
			if holderParent and holderParent.GetFrameStrata then
				local portraitStrata = portraitDetached and normalizeStrataToken(cfg.portrait and cfg.portrait.detachedStrata) or nil
				st.portraitHolder:SetFrameStrata(portraitStrata or holderParent:GetFrameStrata())
				local portraitLevelOffset = portraitDetached and tonumber(cfg.portrait and cfg.portrait.detachedFrameLevelOffset) or 1
				portraitLevelOffset = max(-20, math.min(1000, portraitLevelOffset or 1))
				st.portraitHolder:SetFrameLevel(UF.ClampFrameLevel((holderParent:GetFrameLevel() or 0) + portraitLevelOffset))
			end
			if st.portrait then
				st.portrait:SetSize(portraitSize, portraitSize)
				st.portrait:ClearAllPoints()
				st.portrait:SetPoint("CENTER", st.portraitHolder, "CENTER", 0, 0)
			end
			if st.portraitBg then
				if portraitSquareBackground == true then
					st.portraitBg:ClearAllPoints()
					st.portraitBg:SetAllPoints(st.portrait)
					st.portraitBg:Show()
				else
					st.portraitBg:Hide()
				end
			end
			UF.ApplyPortraitShape(st, portraitShape)
		else
			if st.portrait then st.portrait:Hide() end
			if st.portraitBg then st.portraitBg:Hide() end
			st.portraitHolder:Hide()
		end
		setBackdrop(st.portraitHolder, false, nil, false)
		if addon.IconShape and addon.IconShape.HideBorderTextures then
			addon.IconShape.HideBorderTextures(st.portraitHolder, { texturesKey = "_eqolPortraitShapeBorderTextures" })
		end
	end
	applyPortraitSeparator(cfg, unit, st, portraitEnabled and not portraitDetached)
	if st.dispelTint then
		if st.dispelTint.GetParent and st.healthTextLayer and st.dispelTint:GetParent() ~= st.healthTextLayer then st.dispelTint:SetParent(st.healthTextLayer) end
		if st.dispelTint.SetFrameLevel and st.healthTextLayer then st.dispelTint:SetFrameLevel(st.healthTextLayer:GetFrameLevel() or 0) end
		st.dispelTint:SetAllPoints(st.health)
		local dispelOrientation = AuraUtil.GetSingleDispelOverlayOrientation()
		if st.dispelTint.SetOrientation and dispelOrientation then st.dispelTint:SetOrientation(dispelOrientation.VerticalTopToBottom, 0, 0) end
	end

	local dataBarLayoutHeight = dataBarEnabled and not dataBarDetached and dataBarPosition ~= "CENTER" and dataBarOuterHeight or 0
	local totalHeight = statusHeight + barsHeight + dataBarLayoutHeight
	st.frame:SetHeight(totalHeight)
	if borderEnabled then UF.AlignBorderHostToPixelGrid(st.barGroup) end
	if detachedPowerBorder then UF.AlignBorderHostToPixelGrid(st.powerGroup) end
	if detachedSecondaryPowerBorder then UF.AlignBorderHostToPixelGrid(st.secondaryPowerGroup) end
	if st.raidIcon then
		st.raidIcon:ClearAllPoints()
		st.raidIcon:SetPoint("TOP", st.barGroup or st.frame, "TOP", barCenterOffset or 0, -2)
	end

	layoutTexts(healthSlot, st.healthTextLeft, st.healthTextCenter, st.healthTextRight, cfg.health, width)
	layoutTexts(st.power, st.powerTextLeft, st.powerTextCenter, st.powerTextRight, cfg.power, width)
	if st.secondaryPower then layoutTexts(st.secondaryPower, st.secondaryPowerTextLeft, st.secondaryPowerTextCenter, st.secondaryPowerTextRight, cfg.secondaryPower, width) end
	if st.dataBar then
		layoutTexts(st.dataBar, st.dataBarTextLeft, st.dataBarTextCenter, st.dataBarTextRight, cfg.dataBar, frameWidth)
		UF.ApplyDataBarNameCharLimit(st, cfg.dataBar, (def and def.dataBar) or {})
	end
	if st.castBar and unit == UNIT.TARGET then applyCastLayout(cfg, unit) end

	-- Apply border only around the bar region wrapper
	if st.barGroup then setBackdrop(st.barGroup, cfg.border, borderDef, true) end
	if st.powerGroup then
		local showPowerBorder = detachedPowerBorder and powerEnabled
		local powerBorderCfg
		if showPowerBorder then
			local borderTexture = borderCfg.detachedPowerTexture or borderCfg.texture or borderDef.texture or "DEFAULT"
			local borderSize = borderCfg.detachedPowerSize
			if borderSize == nil then borderSize = borderCfg.edgeSize or borderDef.edgeSize or 1 end
			powerBorderCfg = {
				enabled = true,
				texture = borderTexture,
				edgeSize = borderSize,
				color = borderCfg.color or borderDef.color,
				inset = borderCfg.inset or borderDef.inset,
			}
		end
		setBackdrop(st.powerGroup, powerBorderCfg, nil, false)
	end
	if st.secondaryPowerGroup then
		local showSecondaryBorder = detachedSecondaryPowerBorder and secondaryPowerEnabled
		local secondaryBorderCfg
		if showSecondaryBorder then
			local borderTexture = borderCfg.detachedSecondaryPowerTexture or borderCfg.texture or borderDef.texture or "DEFAULT"
			local borderSize = borderCfg.detachedSecondaryPowerSize
			if borderSize == nil then borderSize = borderCfg.edgeSize or borderDef.edgeSize or 1 end
			secondaryBorderCfg = {
				enabled = true,
				texture = borderTexture,
				edgeSize = borderSize,
				color = borderCfg.color or borderDef.color,
				inset = borderCfg.inset or borderDef.inset,
			}
		end
		setBackdrop(st.secondaryPowerGroup, secondaryBorderCfg, nil, false)
	end
	UF.syncAbsorbFrameLevels(st)
	UFHelper.applyHighlightStyle(st, st._highlightCfg)

	if (unit == UNIT.PLAYER or unit == "target" or unit == UNIT.FOCUS or isBossUnit(unit)) and st.auraContainer then
		st.auraContainer:ClearAllPoints()
		local acfg = cfg.auraIcons or def.auraIcons or defaults.target.auraIcons or {}
		local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, acfg, def and def.auraIcons)
		local buffAura = auraRuntime.buff
		local debuffAura = auraRuntime.debuff
		local anchor = buffAura.anchor or "BOTTOM"
		local defAx, defAy = UF._auraLayout.defaultOffset(anchor)
		local baseAx = (buffAura.offset and buffAura.offset.x)
		if baseAx == nil then baseAx = defAx end
		local baseAy = (buffAura.offset and buffAura.offset.y)
		if baseAy == nil then baseAy = defAy end
		UF._auraLayout.positionContainer(st.auraContainer, anchor, st.barGroup, baseAx, baseAy, barAreaOffsetLeft, barAreaOffsetRight)
		st.auraContainer:SetWidth(width + borderOffset * 2)
		AuraUtil.syncAuraContainerLayer(st.auraContainer, st.frame)

		if st.debuffContainer then
			st.debuffContainer:ClearAllPoints()
			if auraRuntime.combineLayout then
				st.debuffContainer:SetPoint("TOPLEFT", st.auraContainer, "TOPLEFT", 0, 0)
				st.debuffContainer:SetSize(0.001, 0.001)
				st.debuffContainer:Hide()
			else
				local danchor = debuffAura.anchor or anchor
				local defDax, defDay = UF._auraLayout.defaultOffset(danchor)
				local baseDax = (debuffAura.offset and debuffAura.offset.x)
				if baseDax == nil then baseDax = defDax end
				local baseDay = (debuffAura.offset and debuffAura.offset.y)
				if baseDay == nil then baseDay = defDay end
				UF._auraLayout.positionContainer(st.debuffContainer, danchor, st.barGroup, baseDax, baseDay, barAreaOffsetLeft, barAreaOffsetRight)
				st.debuffContainer:SetWidth(width + borderOffset * 2)
			end
			AuraUtil.syncAuraContainerLayer(st.debuffContainer, st.frame)
		end

		if st.auraButtons then
			for i = 1, #st.auraButtons do
				local btn = st.auraButtons[i]
				if btn then AuraUtil.syncAuraButtonLayer(btn, st.auraContainer, auraRuntime.combineLayout and btn.isDebuff and debuffAura or buffAura) end
			end
		end
		if st.debuffButtons and st.debuffContainer then
			for i = 1, #st.debuffButtons do
				local btn = st.debuffButtons[i]
				if btn then AuraUtil.syncAuraButtonLayer(btn, st.debuffContainer, debuffAura) end
			end
		end
		if AuraUtil.ShouldUseNativeAuraContainers(unit, auraRuntime, UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit)) then
			AuraUtil.ApplyNativeAuraContainers(unit, st, cfg, def, false)
		end
	end
	if unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit) then AuraUtil.RefreshHealerBuffPlacementUnit(unit) end
	if unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS then
		local dispelCfg = cfg.status and cfg.status.dispelTint
		local dispelDef = def.status and def.status.dispelTint
		AuraUtil.PrecreateManagedDispelBorder(st, st.healthContainer or st.health or st.frame, dispelCfg, dispelDef)
	end
	syncTextFrameLevels(st)
end

local refreshNameAndLevelSoon

function UF.ShouldDesaturateHealthTexture(hc)
	hc = hc or {}
	local textureKey = hc.texture
	return hc.useClassColor == true or textureKey == nil or textureKey == "" or textureKey == "DEFAULT"
end

function UF.IsPlayerPingPortraitMouseOver(frame)
	local portrait = frame and frame.portraitHolder
	return portrait and portrait:IsShown() and portrait:IsMouseOver() or false
end

function UF.PlayerFramePingGetAllowRadialWheel(self) return UF.IsPlayerPingPortraitMouseOver(self) end

function UF.PlayerFramePingGetTargetInfo(self)
	return {
		guid = UnitGUID(UNIT.PLAYER),
		isPlayerResource = not UF.IsPlayerPingPortraitMouseOver(self),
	}
end

local function ensureFrames(unit)
	local info = UNITS[unit]
	if not info then return end
	states[unit] = states[unit] or {}
	local st = states[unit]
	addon.variables.states = states
	if st.frame then return end
	local parent = UIParent
	if isBossUnit(unit) then parent = ensureBossContainer() or UIParent end
	-- TODO: Remove this 12.1 PTR gate after 12.1 is the supported baseline.
	local is121OrNewer = tonumber((select(4, GetBuildInfo()))) >= 120100
	local template = "BackdropTemplate,SecureUnitButtonTemplate,PingableUnitFrameTemplate"
	st.frame = _G[info.frameName] or CreateFrame("Button", info.frameName, parent, template)
	st.frame._eqolUFUnit = unit
	if is121OrNewer and unit == UNIT.PLAYER then
		st.frame.GetAllowRadialWheel = UF.PlayerFramePingGetAllowRadialWheel
		st.frame.GetTargetInfo = UF.PlayerFramePingGetTargetInfo
	end
	if is121OrNewer and (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)) then AuraUtil.PrecreateNativeAuraContainers(st) end
	_G.ClickCastFrames = _G.ClickCastFrames or {}
	_G.ClickCastFrames[st.frame] = true
	if st.frame.SetParent then st.frame:SetParent(parent) end
	st.frame:SetAttribute("unit", info.unit)
	st.frame:SetAttribute("*type1", "target")
	st.frame:SetAttribute("*type2", "togglemenu")
	if is121OrNewer then
		if type(st.frame.SetRolesets) == "function" then st.frame:SetRolesets("unitFrames") end
	end
	st.frame:HookScript("OnEnter", function(self)
		st._hovered = true
		UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
		local cfg = ensureDB(unit)
		if not (cfg and cfg.showTooltip) then return end
		if not GameTooltip or GameTooltip:IsForbidden() then return end
		if info and info.unit then
			if cfg.tooltipUseEditMode and GameTooltip_SetDefaultAnchor then
				GameTooltip_SetDefaultAnchor(GameTooltip, self)
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			end
			GameTooltip:SetUnit(info.unit)
			GameTooltip:Show()
		end
	end)
	st.frame:HookScript("OnLeave", function()
		st._hovered = false
		UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
		if GameTooltip and not GameTooltip:IsForbidden() then GameTooltip:Hide() end
	end)
	st.frame:HookScript("OnHide", function()
		st._hovered = false
		UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
		AuraUtil.HideSingleDispelIndicator(unit)
		if unit == UNIT.TARGET then
			local targetLoose = IsTargetLoose and IsTargetLoose()
			if not targetLoose and UnitExists and not UnitExists(UNIT.TARGET) then
				if PlaySound and SOUNDKIT and SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT then PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT, nil, true) end
			end
		end
	end)
	st.frame:HookScript("OnShow", function()
		if refreshNameAndLevelSoon then refreshNameAndLevelSoon(unit) end
	end)
	st.frame:RegisterForClicks("AnyUp")
	st.frame:Hide()
	hideSettingsReset(st.frame)

	if info.dropdown then st.frame.menu = info.dropdown end
	st.frame:SetClampedToScreen(true)
	st.status = _G[info.statusName] or CreateFrame("Frame", info.statusName, st.frame)
	st.status:EnableMouse(false)
	if st.status.SetMouseClickEnabled then st.status:SetMouseClickEnabled(false) end
	if st.status.SetMouseMotionEnabled then st.status:SetMouseMotionEnabled(false) end
	st.barGroup = st.barGroup or CreateFrame("Frame", nil, st.frame, "BackdropTemplate")
	st.healthContainer = st.healthContainer or CreateFrame("Frame", nil, st.barGroup, "BackdropTemplate")
	st.health = _G[info.healthName] or CreateFrame("StatusBar", info.healthName, st.barGroup, "BackdropTemplate")
	if st.health.GetParent and st.health:GetParent() ~= st.healthContainer then st.health:SetParent(st.healthContainer) end
	local initialCfg = ensureDB(unit)
	if st.health.SetStatusBarDesaturated then st.health:SetStatusBarDesaturated(UF.ShouldDesaturateHealthTexture(initialCfg and initialCfg.health)) end
	st.tempMaxHealthLoss = st.tempMaxHealthLoss or CreateFrame("StatusBar", info.healthName .. "TempMaxHealthLoss", st.healthContainer, "BackdropTemplate")
	if st.tempMaxHealthLoss.SetStatusBarDesaturated then st.tempMaxHealthLoss:SetStatusBarDesaturated(false) end
	st.power = _G[info.powerName] or CreateFrame("StatusBar", info.powerName, st.barGroup, "BackdropTemplate")
	st.powerGroup = st.powerGroup or CreateFrame("Frame", nil, st.frame, "BackdropTemplate")
	st.powerGroup:Hide()
	st.dataBar = st.dataBar or CreateFrame("StatusBar", info.healthName .. "DataBar", st.frame, "BackdropTemplate")
	if st.dataBar.GetParent and st.dataBar:GetParent() ~= st.frame then st.dataBar:SetParent(st.frame) end
	st.dataBar:EnableMouse(false)
	st.dataBar:SetMinMaxValues(0, 1)
	st.dataBar:SetValue(0)
	st.dataBar:Hide()
	if info.secondaryPowerName then
		st.secondaryPower = _G[info.secondaryPowerName] or CreateFrame("StatusBar", info.secondaryPowerName, st.barGroup, "BackdropTemplate")
		st.secondaryPowerGroup = st.secondaryPowerGroup or CreateFrame("Frame", nil, st.frame, "BackdropTemplate")
		st.secondaryPowerGroup:Hide()
	else
		if st.secondaryPower then st.secondaryPower:Hide() end
		if st.secondaryPowerGroup then st.secondaryPowerGroup:Hide() end
		st.secondaryPower = nil
		st.secondaryPowerGroup = nil
	end
	local powerEnum, powerToken = getMainPower(unit)
	if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(powerEnum, powerToken)) end
	if st.secondaryPower and st.secondaryPower.SetStatusBarDesaturated then st.secondaryPower:SetStatusBarDesaturated(false) end
	if not st.portraitHolder then
		st.portraitHolder = CreateFrame("Frame", nil, st.barGroup or st.frame, "BackdropTemplate")
		st.portraitHolder:EnableMouse(false)
		st.portraitHolder:Hide()
	end
	if not st.portrait then
		st.portrait = st.portraitHolder:CreateTexture(nil, "ARTWORK")
		st.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		st.portrait:Hide()
	end
	if not st.portraitBg then
		st.portraitBg = st.portraitHolder:CreateTexture(nil, "BACKGROUND")
		st.portraitBg:SetColorTexture(0, 0, 0, 1)
		st.portraitBg:Hide()
	end
	if not st.portraitSeparator then
		st.portraitSeparator = (st.barGroup or st.frame):CreateTexture(nil, "ARTWORK")
		st.portraitSeparator:SetColorTexture(0, 0, 0, 1)
		st.portraitSeparator:Hide()
	end
	if st.portrait and st.portrait:GetParent() ~= st.portraitHolder then st.portrait:SetParent(st.portraitHolder) end
	if st.portraitBg and st.portraitBg:GetParent() ~= st.portraitHolder then st.portraitBg:SetParent(st.portraitHolder) end
	if st.portraitHolder and st.barGroup and st.portraitHolder:GetParent() ~= st.barGroup then st.portraitHolder:SetParent(st.barGroup) end
	if st.portraitSeparator and st.barGroup and st.portraitSeparator:GetParent() ~= st.barGroup then st.portraitSeparator:SetParent(st.barGroup) end
	if st.portrait and st.portraitHolder then
		st.frame.portrait = st.portrait
		st.frame.portraitHolder = st.portraitHolder
	end

	local allowAbsorb = not (info and info.disableAbsorb)
	if allowAbsorb then
		st.incomingHeal = st.incomingHeal or CreateFrame("StatusBar", info.healthName .. "IncomingHeal", st.health, "BackdropTemplate")
		if st.incomingHeal.SetStatusBarDesaturated then st.incomingHeal:SetStatusBarDesaturated(false) end
		st.absorb = st.absorb or CreateFrame("StatusBar", info.healthName .. "Absorb", st.health, "BackdropTemplate")
		if st.absorb.SetStatusBarDesaturated then st.absorb:SetStatusBarDesaturated(false) end
		st.overAbsorbGlow = st.overAbsorbGlow or st.health:CreateTexture(nil, "ARTWORK", "OverAbsorbGlowTemplate")
		if st.absorb then st.absorb.overAbsorbGlow = st.overAbsorbGlow end
		if not st.overAbsorbGlow then st.overAbsorbGlow = st.health:CreateTexture(nil, "ARTWORK") end
		if st.overAbsorbGlow then
			st.overAbsorbGlow:SetTexture(798066)
			st.overAbsorbGlow:SetBlendMode("ADD")
			if st.overAbsorbGlow.SetDrawLayer then st.overAbsorbGlow:SetDrawLayer("OVERLAY", 7) end
			st.overAbsorbGlow:SetAlpha(0.8)
			st.overAbsorbGlow:Hide()
		end
		st.healAbsorb = st.healAbsorb or CreateFrame("StatusBar", info.healthName .. "HealAbsorb", st.health, "BackdropTemplate")
		if st.healAbsorb.SetStatusBarDesaturated then st.healAbsorb:SetStatusBarDesaturated(false) end
	else
		if st.incomingHeal then st.incomingHeal:Hide() end
		st.incomingHeal = nil
		if st.absorb then st.absorb:Hide() end
		st.absorb = nil
		if st.absorb2 then st.absorb2:Hide() end
		st.absorb2 = nil
		if st.overAbsorbGlow then st.overAbsorbGlow:Hide() end
		if st.healAbsorb then st.healAbsorb:Hide() end
		st.healAbsorb = nil
	end
	if (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)) and not st.castBar then
		st.castBar = CreateFrame("StatusBar", info.healthName .. "Cast", st.frame, "BackdropTemplate")
		st.castBar:SetStatusBarDesaturated(true)
		st.castTextLayer = CreateFrame("Frame", nil, st.castBar)
		st.castTextLayer:SetAllPoints(st.castBar)
		st.castIconLayer = CreateFrame("Frame", nil, st.castBar)
		st.castIconLayer:SetAllPoints(st.castBar)
		st.castIconLayer:EnableMouse(false)
		st.castIconHolder = CreateFrame("Frame", nil, st.castIconLayer)
		st.castIconHolder:EnableMouse(false)
		st.castIconHolder:Hide()
		st.castName = st.castTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		st.castDuration = st.castTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		st.castIcon = st.castIconHolder:CreateTexture(nil, "ARTWORK")
		st.castIcon:SetAllPoints(st.castIconHolder)
		st.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		UF._setCastBarMinMaxValues(st, 0, 1)
		UF._setCastBarValue(st, 0)
		st.castBar:Hide()
	end

	local healthTextParent = st.healthContainer or st.health
	st.healthTextLayer = st.healthTextLayer or CreateFrame("Frame", nil, healthTextParent)
	if st.healthTextLayer.GetParent and st.healthTextLayer:GetParent() ~= healthTextParent then st.healthTextLayer:SetParent(healthTextParent) end
	st.healthTextLayer:SetAllPoints(healthTextParent)
	st.powerTextLayer = st.powerTextLayer or CreateFrame("Frame", nil, st.power)
	st.powerTextLayer:SetAllPoints(st.power)
	st.dataBarTextLayer = st.dataBarTextLayer or CreateFrame("Frame", nil, st.dataBar)
	st.dataBarTextLayer:SetAllPoints(st.dataBar)
	st.dataBarTextLayer:EnableMouse(false)
	if st.secondaryPower then
		st.secondaryPowerTextLayer = st.secondaryPowerTextLayer or CreateFrame("Frame", nil, st.secondaryPower)
		st.secondaryPowerTextLayer:SetAllPoints(st.secondaryPower)
	elseif st.secondaryPowerTextLayer then
		st.secondaryPowerTextLayer:Hide()
	end
	st.statusTextLayer = st.statusTextLayer or CreateFrame("Frame", nil, st.status)
	st.statusTextLayer:SetAllPoints(st.status)
	st.statusTextLayer:EnableMouse(false)
	st.nameTextLayer = st.nameTextLayer or CreateFrame("Frame", nil, st.status)
	st.nameTextLayer:SetAllPoints(st.status)
	st.nameTextLayer:EnableMouse(false)
	st.levelTextLayer = st.levelTextLayer or CreateFrame("Frame", nil, st.status)
	st.levelTextLayer:SetAllPoints(st.status)
	st.levelTextLayer:EnableMouse(false)
	if (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS) and not st.dispelTint and not AuraUtil.ShouldUseManagedDispelBorder() then
		st.dispelTint = UFHelper.CreateDispelOverlay(st.healthTextLayer or st.health)
		st.dispelTint:SetAllPoints(st.health)
		st.dispelTint:Hide()
	end
	st.healthTextLeft = st.healthTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.healthTextCenter = st.healthTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.healthTextRight = st.healthTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.powerTextLeft = st.powerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.powerTextCenter = st.powerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.powerTextRight = st.powerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.dataBarTextLeft = st.dataBarTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.dataBarTextCenter = st.dataBarTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.dataBarTextRight = st.dataBarTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	if st.secondaryPowerTextLayer then
		st.secondaryPowerTextLeft = st.secondaryPowerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		st.secondaryPowerTextCenter = st.secondaryPowerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		st.secondaryPowerTextRight = st.secondaryPowerTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	end
	st.nameText = st.nameText or st.nameTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	if st.nameText.GetParent and st.nameText:GetParent() ~= st.nameTextLayer then st.nameText:SetParent(st.nameTextLayer) end
	if unit == UNIT.TARGET then
		st.targetTargetText = st.targetTargetText or st.nameTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		if st.targetTargetText.GetParent and st.targetTargetText:GetParent() ~= st.nameTextLayer then st.targetTargetText:SetParent(st.nameTextLayer) end
	end
	st.levelText = st.levelText or st.levelTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	if st.levelText.GetParent and st.levelText:GetParent() ~= st.levelTextLayer then st.levelText:SetParent(st.levelTextLayer) end
	st.unitStatusText = st.statusTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.unitGroupText = st.statusTextLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	st.raidIcon = st.statusTextLayer:CreateTexture(nil, "OVERLAY", nil, 7)
	st.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	st.raidIcon:SetSize(18, 18)
	st.raidIcon:SetPoint("TOP", st.frame, "TOP", 0, -2)
	st.raidIcon:Hide()
	if unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS then
		st.leaderIcon = st.statusTextLayer:CreateTexture(nil, "OVERLAY", nil, 7)
		st.leaderIcon:SetSize(12, 12)
		st.leaderIcon:SetPoint("TOPLEFT", st.health, "TOPLEFT", 0, 0)
		st.leaderIcon:Hide()
		st.pvpIcon = st.statusTextLayer:CreateTexture(nil, "OVERLAY", nil, 7)
		st.pvpIcon:SetSize(20, 20)
		st.pvpIcon:SetPoint("TOP", st.frame, "TOP", -24, -2)
		st.pvpIcon:Hide()
		st.roleIcon = st.statusTextLayer:CreateTexture(nil, "OVERLAY", nil, 7)
		st.roleIcon:SetSize(18, 18)
		st.roleIcon:SetPoint("TOP", st.frame, "TOP", 24, -2)
		st.roleIcon:Hide()
	end
	if unit ~= UNIT.PLAYER then
		st.classificationIcon = st.classificationIcon or st.statusTextLayer:CreateTexture(nil, "OVERLAY", nil, 7)
		st.classificationIcon:SetSize(16, 16)
		st.classificationIcon:Hide()
	end
	if UF.SupportsCombatIndicator(unit) then
		st.combatIcon = st.combatIcon or st.statusTextLayer:CreateTexture(nil, "OVERLAY")
		if st.combatIcon.GetParent and st.combatIcon:GetParent() ~= st.statusTextLayer then st.combatIcon:SetParent(st.statusTextLayer) end
	end
	if unit == UNIT.PLAYER then ensureRestLoop(st) end

	if unit == UNIT.PLAYER or unit == "target" or unit == UNIT.FOCUS or isBossUnit(unit) then
		st.auraContainer = CreateFrame("Frame", nil, st.frame)
		st.debuffContainer = CreateFrame("Frame", nil, st.frame)
		st.auraButtons = {}
		st.debuffButtons = {}
	end

	st.frame:SetMovable(true)
	st.frame:EnableMouse(true)
	st.frame:RegisterForDrag("LeftButton")
	hookTextFrameLevels(st)
end

local function applyBars(cfg, unit)
	local st = states[unit]
	if not st or not st.health or not st.power then return end
	local info = UNITS[unit]
	local allowAbsorb = not (info and info.disableAbsorb)
	local hc = cfg.health or {}
	local def = defaultsFor(unit) or {}
	local defH = def.health or {}
	local defP = def.power or {}
	local defSP = def.secondaryPower or {}
	local interpolation = getSmoothInterpolation(cfg, def)
	local pcfg = cfg.power or {}
	local secondaryCfg = cfg.secondaryPower or {}
	local powerEnabled = pcfg.enabled ~= false
	local powerEnum, powerToken
	if powerEnabled then
		if unit == UNIT.PLAYER then refreshMainPower(unit) end
		powerEnum, powerToken = getMainPower(unit)
		if unit == UNIT.PLAYER and UFHelper and UFHelper.IsPrimaryPowerAllowed then powerEnabled = UFHelper.IsPrimaryPowerAllowed(pcfg, defP, powerToken, powerEnum, unit) ~= false end
	end
	local healthOrientation = UFHelper.normalizeStatusBarOrientation(hc.orientation or defH.orientation)
	UFHelper.applyStatusBarOrientation(st.health, healthOrientation)
	UFHelper.applyStatusBarOrientation(st.tempMaxHealthLoss, healthOrientation)
	st.health:SetStatusBarTexture(UFHelper.resolveTexture(hc.texture))
	if st.health.SetStatusBarDesaturated then st.health:SetStatusBarDesaturated(UF.ShouldDesaturateHealthTexture(hc)) end
	UFHelper.configureSpecialTexture(st.health, "HEALTH", hc.texture, hc)
	UF.StabilizeStatusBarTexture(st.health)
	local reverseHealth = hc.reverseFill
	if reverseHealth == nil then reverseHealth = defH.reverseFill == true end
	UFHelper.applyStatusBarReverseFill(st.health, reverseHealth)
	local healthAxis = UFHelper.GetHealthAxis(healthOrientation, reverseHealth)
	local overlayRegions = UFHelper.LayoutHealthOverlayRegions(st.health, healthAxis)
	if st.tempMaxHealthLoss then
		st.tempMaxHealthLoss:SetStatusBarTexture("UI-HUD-UnitFrame-Target-PortraitOn-Bar-TempHPLoss")
		if st.tempMaxHealthLoss.SetStatusBarDesaturated then st.tempMaxHealthLoss:SetStatusBarDesaturated(false) end
		UFHelper.applyStatusBarReverseFill(st.tempMaxHealthLoss, not reverseHealth)
		st.tempMaxHealthLoss:SetMinMaxValues(0, 1)
		st.tempMaxHealthLoss:SetValue(0, interpolation)
		if st.tempMaxHealthLoss.SetAlpha then st.tempMaxHealthLoss:SetAlpha(0) end
		st.tempMaxHealthLoss:SetShown(hc.tempMaxHealthLossEnabled ~= false)
	end
	UF.ApplyHealthBackdrop(st, unit, hc, defH, reverseHealth)
	if allowAbsorb and st.incomingHeal then applyIncomingHealBar(st, hc, healthAxis, overlayRegions, interpolation) end
	if powerEnabled then
		UFHelper.applyStatusBarOrientation(st.power, pcfg.orientation or defP.orientation)
		st.power:SetStatusBarTexture(UFHelper.resolveTexture(pcfg.texture))
		if not powerEnum then
			powerEnum, powerToken = getMainPower(unit)
		end
		if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(powerEnum, powerToken)) end
		UFHelper.configureSpecialTexture(st.power, powerToken, pcfg.texture, pcfg, powerEnum)
		local reversePower = pcfg.reverseFill
		if reversePower == nil then reversePower = defP.reverseFill == true end
		UFHelper.applyStatusBarReverseFill(st.power, reversePower)
		applyBarBackdrop(st.power, pcfg)
		st.power:Show()
	else
		st.power:Hide()
		if st.powerTextLeft then st.powerTextLeft:SetText("") end
		if st.powerTextCenter then st.powerTextCenter:SetText("") end
		if st.powerTextRight then st.powerTextRight:SetText("") end
	end

	if st.secondaryPower then
		local secondaryToken
		if unit == UNIT.PLAYER and UFHelper and UFHelper.ResolveSecondaryPowerToken then
			secondaryToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, defSP, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
		end
		local secondaryEnabled = unit == UNIT.PLAYER and secondaryCfg.enabled ~= false and secondaryToken ~= nil
		if secondaryEnabled then
			UFHelper.applyStatusBarOrientation(st.secondaryPower, secondaryCfg.orientation or defSP.orientation)
			st.secondaryPower:SetStatusBarTexture(UFHelper.resolveTexture(secondaryCfg.texture))
			local secEnum, secResolved = nil, secondaryToken
			if UFHelper and UFHelper.GetPowerValuesForToken then
				local _, _, enumId, tokenId = UFHelper.GetPowerValuesForToken(unit, secondaryToken)
				secEnum, secResolved = enumId, tokenId
			end
			secResolved = secResolved or secondaryToken
			if st.secondaryPower.SetStatusBarDesaturated then st.secondaryPower:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(secEnum, secResolved)) end
			UFHelper.configureSpecialTexture(st.secondaryPower, secResolved, secondaryCfg.texture, secondaryCfg, secEnum)
			local reverseSecondary = secondaryCfg.reverseFill
			if reverseSecondary == nil then reverseSecondary = defSP.reverseFill == true end
			UFHelper.applyStatusBarReverseFill(st.secondaryPower, reverseSecondary)
			applyBarBackdrop(st.secondaryPower, secondaryCfg)
			st.secondaryPower:Show()
			st._secondaryPowerToken = secResolved
			st._secondaryPowerEnum = secEnum
		else
			st.secondaryPower:Hide()
			if st.secondaryPowerTextLeft then st.secondaryPowerTextLeft:SetText("") end
			if st.secondaryPowerTextCenter then st.secondaryPowerTextCenter:SetText("") end
			if st.secondaryPowerTextRight then st.secondaryPowerTextRight:SetText("") end
			st._secondaryPowerToken = nil
			st._secondaryPowerEnum = nil
		end
	end
	if allowAbsorb and st.absorb then
		local absorbTextureKey = hc.absorbTexture or hc.texture
		st.absorb:SetStatusBarTexture(UFHelper.resolveTexture(absorbTextureKey))
		if st.absorb.SetStatusBarDesaturated then st.absorb:SetStatusBarDesaturated(false) end
		UFHelper.configureSpecialTexture(st.absorb, "HEALTH", absorbTextureKey, hc)
		UF.StabilizeStatusBarTexture(st.absorb)
		local reverseAbsorb = hc.absorbReverseFill
		if reverseAbsorb == nil then reverseAbsorb = defH.absorbReverseFill == true end
		local absorbDontOverflow = hc.absorbDontOverflowHealthBar
		if absorbDontOverflow == nil then absorbDontOverflow = defH.absorbDontOverflowHealthBar == true end
		if reverseAbsorb then
			st.absorb2 = st.absorb2 or CreateFrame("StatusBar", info.healthName .. "Absorb2", st.health, "BackdropTemplate")
			if st.absorb2.SetStatusBarDesaturated then st.absorb2:SetStatusBarDesaturated(false) end
			st.absorb2:Hide()
		elseif st.absorb2 then
			st.absorb2:Hide()
		end
		local absorbHeight = hc.absorbOverlayHeight
		if absorbHeight == nil then absorbHeight = defH.absorbOverlayHeight end
		local absorbAnchorTop = hc.absorbOverlayAnchorTop
		if absorbAnchorTop == nil then absorbAnchorTop = defH.absorbOverlayAnchorTop == true end
		UFHelper.LayoutDamageAbsorb(st.health, st.absorb, st.absorb2, {
			axis = healthAxis,
			regions = overlayRegions,
			reverseAbsorb = reverseAbsorb,
			dontOverflow = absorbDontOverflow,
			thickness = absorbHeight,
			crossAlign = absorbAnchorTop and "MAX" or "MIN",
		})
		if reverseAbsorb and st.absorb2 then
			st.absorb2:SetStatusBarTexture(UFHelper.resolveTexture(absorbTextureKey))
			if st.absorb2.SetStatusBarDesaturated then st.absorb2:SetStatusBarDesaturated(false) end
			UFHelper.configureSpecialTexture(st.absorb2, "HEALTH", absorbTextureKey, hc)
			UF.StabilizeStatusBarTexture(st.absorb2)
			syncTextFrameLevels(st)
			setFrameLevelAbove(st.absorb2, st.health, 1)
		end
		setFrameLevelAbove(st.absorb, st.health, 1)
		if st.overAbsorbGlow then
			if st.overAbsorbGlow.GetParent and st.overAbsorbGlow:GetParent() ~= st.health then st.overAbsorbGlow:SetParent(st.health) end
			UFHelper.LayoutHealthEndGlow(st.health, st.overAbsorbGlow, healthAxis, 7)
		end
		if st.overAbsorbGlow then st.overAbsorbGlow:Hide() end
	elseif st.overAbsorbGlow then
		st.overAbsorbGlow:Hide()
	end
	local absorbAboveIncoming = UFHelper.NormalizeAbsorbLayerOrder(hc.absorbLayerOrder) == "ABSORB_ABOVE"
	local absorbLayer = st.absorb2 or st.absorb or st.health
	local topHealthOverlay
	if absorbAboveIncoming then
		if st.incomingHeal then setFrameLevelAbove(st.incomingHeal, st.health, 1) end
		setFrameLevelAbove(st.absorb, st.incomingHeal or st.health, 1)
		if st.absorb2 then setFrameLevelAbove(st.absorb2, st.incomingHeal or st.health, 1) end
		topHealthOverlay = absorbLayer
	else
		if st.incomingHeal then setFrameLevelAbove(st.incomingHeal, absorbLayer, 1) end
		topHealthOverlay = st.incomingHeal or absorbLayer
	end
	if allowAbsorb and st.healAbsorb then
		local healAbsorbTextureKey = hc.healAbsorbTexture or hc.texture
		st.healAbsorb:SetStatusBarTexture(UFHelper.resolveTexture(healAbsorbTextureKey))
		if st.healAbsorb.SetStatusBarDesaturated then st.healAbsorb:SetStatusBarDesaturated(false) end
		UFHelper.configureSpecialTexture(st.healAbsorb, "HEALTH", healAbsorbTextureKey, hc)
		UF.StabilizeStatusBarTexture(st.healAbsorb)
		local reverseHealAbsorb = hc.healAbsorbReverseFill
		if reverseHealAbsorb == nil then reverseHealAbsorb = defH.healAbsorbReverseFill == true end
		local healAbsorbHeight = hc.healAbsorbOverlayHeight
		if healAbsorbHeight == nil then healAbsorbHeight = defH.healAbsorbOverlayHeight end
		local healAbsorbAnchorTop = hc.healAbsorbOverlayAnchorTop
		if healAbsorbAnchorTop == nil then healAbsorbAnchorTop = defH.healAbsorbOverlayAnchorTop == true end
		UFHelper.LayoutHealthOverlayBar(st.health, st.healAbsorb, {
			axis = healthAxis,
			regions = overlayRegions,
			role = "FULL",
			statusReverse = reverseHealAbsorb,
			thickness = healAbsorbHeight,
			crossAlign = healAbsorbAnchorTop and "MAX" or "MIN",
		})
		setFrameLevelAbove(st.healAbsorb, topHealthOverlay, 1)
		st.healAbsorb:SetMinMaxValues(0, 1)
		st.healAbsorb:SetValue(0, interpolation)
		-- no heal absorb glow
	end
	UF.syncAbsorbFrameLevels(st)
	if st.castBar and (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)) then
		local defc = (defaultsFor(unit) and defaultsFor(unit).cast) or {}
		local ccfg = cfg.cast or defc
		st.castBar:SetStatusBarTexture(UFHelper.resolveCastTexture((ccfg.texture or defc.texture or "DEFAULT")))
		UF._setCastBarMinMaxValues(st, 0, 1)
		UF._setCastBarValue(st, 0)
		applyCastLayout(cfg, unit)
		local castFont = ccfg.font or defc.font or hc.font
		local castFontSize = ccfg.fontSize or defc.fontSize or hc.fontSize or 12
		local castOutline = ccfg.fontOutline or defc.fontOutline or hc.fontOutline or "OUTLINE"
		UFHelper.applyFont(st.castName, castFont, castFontSize, castOutline)
		UFHelper.applyFont(st.castDuration, castFont, castFontSize, castOutline)
		local castFontColor = ccfg.fontColor or defc.fontColor
		if castFontColor then
			local r = castFontColor.r or castFontColor[1] or 1
			local g = castFontColor.g or castFontColor[2] or 1
			local b = castFontColor.b or castFontColor[3] or 1
			local a = castFontColor.a or castFontColor[4] or 1
			if st.castName then st.castName:SetTextColor(r, g, b, a) end
			if st.castDuration then st.castDuration:SetTextColor(r, g, b, a) end
		end
	end

	if st.dataBar then
		local dcfg = cfg.dataBar or {}
		local ddef = def.dataBar or {}
		if UF.DataBar.IsEnabled(cfg, def) then
			local textureKey = dcfg.texture or ddef.texture or "SOLID"
			local customAtlas = type(dcfg.customAtlas) == "string" and dcfg.customAtlas:match("^%s*(.-)%s*$") or ""
			local textureAsset = UFHelper.resolveTexture(textureKey)
			if customAtlas ~= "" and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(customAtlas) then textureAsset = customAtlas end
			st.dataBar:SetStatusBarTexture(textureAsset)
			if st.dataBar.SetStatusBarDesaturated then st.dataBar:SetStatusBarDesaturated(false) end
			local tex = st.dataBar.GetStatusBarTexture and st.dataBar:GetStatusBarTexture()
			if tex then
				if tex.SetTexCoord then tex:SetTexCoord(0, 1, 0, 1) end
				if tex.SetHorizTile then tex:SetHorizTile(false) end
				if tex.SetVertTile then tex:SetVertTile(false) end
			end
			UFHelper.applyStatusBarReverseFill(st.dataBar, false)
			applyBarBackdrop(st.dataBar, { backdrop = { enabled = false } })
			UFHelper.applyFont(st.dataBarTextLeft, dcfg.font, dcfg.fontSize or ddef.fontSize or 12, dcfg.fontOutline or ddef.fontOutline)
			UFHelper.applyFont(st.dataBarTextCenter, dcfg.font, dcfg.fontSize or ddef.fontSize or 12, dcfg.fontOutline or ddef.fontOutline)
			UFHelper.applyFont(st.dataBarTextRight, dcfg.font, dcfg.fontSize or ddef.fontSize or 12, dcfg.fontOutline or ddef.fontOutline)
			UF.DataBar.ApplyTextColor(st, unit, cfg, def)
			UF.DataBar.Update(cfg, unit)
		else
			UF.DataBar.Hide(st)
		end
	end

	UFHelper.applyFont(st.healthTextLeft, hc.font, hc.fontSize or 14, hc.fontOutline)
	UFHelper.applyFont(st.healthTextCenter, hc.font, hc.fontSize or 14, hc.fontOutline)
	UFHelper.applyFont(st.healthTextRight, hc.font, hc.fontSize or 14, hc.fontOutline)
	UFHelper.applyFont(st.powerTextLeft, pcfg.font, pcfg.fontSize or 14, pcfg.fontOutline)
	UFHelper.applyFont(st.powerTextCenter, pcfg.font, pcfg.fontSize or 14, pcfg.fontOutline)
	UFHelper.applyFont(st.powerTextRight, pcfg.font, pcfg.fontSize or 14, pcfg.fontOutline)
	if st.secondaryPowerTextLeft then
		UFHelper.applyFont(st.secondaryPowerTextLeft, secondaryCfg.font, secondaryCfg.fontSize or 14, secondaryCfg.fontOutline)
		UFHelper.applyFont(st.secondaryPowerTextCenter, secondaryCfg.font, secondaryCfg.fontSize or 14, secondaryCfg.fontOutline)
		UFHelper.applyFont(st.secondaryPowerTextRight, secondaryCfg.font, secondaryCfg.fontSize or 14, secondaryCfg.fontOutline)
	end
	syncTextFrameLevels(st)
end

function UF.ResolveNameTextColor(unit, st)
	if st._nameColorCustom == true then return st._nameCustomColorR, st._nameCustomColorG, st._nameCustomColorB, st._nameCustomColorA end
	local nr, ng, nb, na
	local isPlayerUnit = UnitIsPlayer and UnitIsPlayer(unit)
	if isPlayerUnit then
		local class = select(2, UnitClass(unit))
		local cr, cg, cb, ca = getClassColor(class)
		if cr then nr, ng, nb, na = cr, cg, cb, ca end
	else
		if st._nameUseReactionColor == true and UFHelper and UFHelper.getNPCHealthColor then nr, ng, nb, na = UFHelper.getNPCHealthColor(unit) end
		if not nr and st._nameNPCUsesNormalFallback == true then nr, ng, nb, na = st._nameNormalR, st._nameNormalG, st._nameNormalB, st._nameNormalA end
	end
	if not nr then nr, ng, nb, na = 1, 1, 1, 1 end
	return nr, ng, nb, na
end

function UF.CacheNameLevelRuntimePlan(st, cfg, def, unit)
	if not st then return end
	cfg, def = cfg or {}, def or {}
	local scfg, defStatus = cfg.status or {}, def.status or {}
	local nameColor = scfg.nameColor
	st._nameColorCustom = scfg.nameColorMode == "CUSTOM"
	st._nameCustomColorR = nameColor and nameColor[1] or 1
	st._nameCustomColorG = nameColor and nameColor[2] or 1
	st._nameCustomColorB = nameColor and nameColor[3] or 1
	st._nameCustomColorA = nameColor and nameColor[4] or 1
	local useReactionColor = scfg.nameUseReactionColor
	if useReactionColor == nil then useReactionColor = defStatus.nameUseReactionColor == true end
	st._nameUseReactionColor = useReactionColor == true
	st._nameNPCUsesNormalFallback = unit == UNIT.TARGET or unit == UNIT.TARGET_TARGET or unit == UNIT.FOCUS or isBossUnit(unit)
	local normalColor = NORMAL_FONT_COLOR
	st._nameNormalR = (normalColor and (normalColor.r or normalColor[1])) or 1
	st._nameNormalG = (normalColor and (normalColor.g or normalColor[2])) or 0.82
	st._nameNormalB = (normalColor and (normalColor.b or normalColor[3])) or 0
	st._nameNormalA = (normalColor and (normalColor.a or normalColor[4])) or 1
	local targetTargetCfg = scfg.targetTargetName or {}
	st._targetTargetNameEnabled = unit == UNIT.TARGET and (targetTargetCfg.enabled == true or scfg.showTargetTargetName == true)
	st._levelTextEnabled = scfg.levelEnabled ~= false
	st._levelHideAtMax = scfg.hideLevelAtMax == true
	local classificationCfg = scfg.classificationIcon or {}
	st._hideClassificationText = unit ~= UNIT.PLAYER and classificationCfg.enabled == true and classificationCfg.hideText == true
	local levelColor = scfg.levelColor
	st._levelColorCustom = scfg.levelColorMode == "CUSTOM"
	st._levelColorR = levelColor and levelColor[1] or 1
	st._levelColorG = levelColor and levelColor[2] or 0.85
	st._levelColorB = levelColor and levelColor[3] or 0
	st._levelColorA = levelColor and levelColor[4] or 1
end

local function updateNameAndLevel(cfg, unit, levelOverride, deferTextUpdate)
	local st = states[unit]
	if not st then return end
	cfg = cfg or st.cfg or ensureDB(unit)
	if cfg and cfg.enabled == false then return end
	if addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() and isBossUnit(unit) then
		local idx = tonumber(type(unit) == "string" and unit:match("^boss(%d+)$") or nil)
		if idx then
			applyBossEditSample(idx, cfg)
			return
		end
	end
	local def = st.def or defaultsFor(unit) or {}
	if st.nameText then
		local name = UnitName(unit)
		if issecretvalue and issecretvalue(name) then
			st.nameText:SetText(name)
		else
			st.nameText:SetText(name or "")
		end
		local appliedSecretClassColor = unit == UNIT.TARGET_TARGET and st._nameColorCustom ~= true and UF.ApplySecretUnitClassTextColor(st.nameText, unit)
		if appliedSecretClassColor then
			st._nameColorR, st._nameColorG, st._nameColorB, st._nameColorA = nil, nil, nil, nil
		else
			local nr, ng, nb, na = UF.ResolveNameTextColor(unit, st)
			if st._nameColorR ~= nr or st._nameColorG ~= ng or st._nameColorB ~= nb or st._nameColorA ~= na then
				st.nameText:SetTextColor(nr, ng, nb, na)
				st._nameColorR, st._nameColorG, st._nameColorB, st._nameColorA = nr, ng, nb, na
			end
		end
	end
	if st.targetTargetText then
		if st._targetTargetNameEnabled == true and UnitExists and UnitExists(UNIT.TARGET_TARGET) then
			if not UF.ApplySecretUnitClassTextColor(st.targetTargetText, UNIT.TARGET_TARGET) then
				local nr, ng, nb, na
				if UnitIsPlayer and UnitIsPlayer(UNIT.TARGET_TARGET) then
					local class = select(2, UnitClass(UNIT.TARGET_TARGET))
					nr, ng, nb, na = getClassColor(class)
				end
				if not nr then nr, ng, nb, na = UF.ResolveNameTextColor(UNIT.TARGET_TARGET, st) end
				st.targetTargetText:SetTextColor(nr, ng, nb, na)
			end
			local name = UnitName and UnitName(UNIT.TARGET_TARGET)
			if issecretvalue and issecretvalue(name) then
				st.targetTargetText:SetText(name)
			else
				st.targetTargetText:SetText(name or "")
			end
		else
			st.targetTargetText:SetText("")
		end
	end
	if st.levelText then
		local enabled = st._levelTextEnabled == true
		if enabled and st._levelHideAtMax == true and addon.variables and addon.variables.isMaxLevel then
			local level = UnitLevel(unit) or 0
			if addon.variables.isMaxLevel[level] then enabled = false end
		end
		st.levelText:SetShown(enabled)
		if enabled then
			local lr, lg, lb, la
			if st._levelColorCustom == true then
				lr, lg, lb, la = st._levelColorR, st._levelColorG, st._levelColorB, st._levelColorA
			else
				local class = select(2, UnitClass(unit))
				local cr, cg, cb, ca = getClassColor(class)
				if cr then
					lr, lg, lb, la = cr, cg, cb, ca
				else
					lr, lg, lb, la = 1, 0.85, 0, 1
				end
			end
			local levelText = UFHelper.getUnitLevelText(unit, levelOverride, st._hideClassificationText)
			st.levelText:SetText(levelText)
			st.levelText:SetTextColor(lr or 1, lg or 0.85, lb or 0, la or 1)
		end
	end
	if st._classificationIndicatorEnabled == true and UFHelper and UFHelper.updateClassificationIndicator then UFHelper.updateClassificationIndicator(st, unit, cfg, def, true) end
	if st._dataBarTextEnabled and (st.dataBarTextLeft or st.dataBarTextCenter or st.dataBarTextRight) then
		st._dataBarTextDirty = true
		if not deferTextUpdate and UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
	end
end

function UF.CacheTextRuntimePlan(st, cfg, def)
	if not st then return end
	cfg, def = cfg or {}, def or {}
	local hc, pcfg, secondaryCfg = cfg.health or {}, cfg.power or {}, cfg.secondaryPower or {}
	local dcfg, ddef = cfg.dataBar or {}, def.dataBar or {}
	local scfg, defStatus = cfg.status or {}, def.status or {}
	local classificationCfg = scfg.classificationIcon or defStatus.classificationIcon or {}
	st._classificationIndicatorEnabled = classificationCfg.enabled == true and cfg.enabled ~= false
	if not st._classificationIndicatorEnabled and st.classificationIcon then st.classificationIcon:Hide() end
	st._healthTextLeftMode = hc.textLeft or "PERCENT"
	st._healthTextCenterMode = hc.textCenter or "NONE"
	st._healthTextRightMode = hc.textRight or "CURMAX"
	st._healthTextUsesPercent = UFHelper.textModeUsesPercent(st._healthTextLeftMode)
		or UFHelper.textModeUsesPercent(st._healthTextCenterMode)
		or UFHelper.textModeUsesPercent(st._healthTextRightMode)
	st._healthTextUsesLevel = UFHelper.textModeUsesLevel(st._healthTextLeftMode)
		or UFHelper.textModeUsesLevel(st._healthTextCenterMode)
		or UFHelper.textModeUsesLevel(st._healthTextRightMode)
	st._healthTextUsesAbsorb = UF.HealthTextUsesAbsorbMode(st._healthTextLeftMode, st._healthTextCenterMode, st._healthTextRightMode)
	st._powerTextLeftMode = pcfg.textLeft or "PERCENT"
	st._powerTextCenterMode = pcfg.textCenter or "NONE"
	st._powerTextRightMode = pcfg.textRight or "CURMAX"
	st._powerTextUsesLevel = UFHelper.textModeUsesLevel(st._powerTextLeftMode)
		or UFHelper.textModeUsesLevel(st._powerTextCenterMode)
		or UFHelper.textModeUsesLevel(st._powerTextRightMode)
	st._secondaryPowerTextLeftMode = secondaryCfg.textLeft or "PERCENT"
	st._secondaryPowerTextCenterMode = secondaryCfg.textCenter or "NONE"
	st._secondaryPowerTextRightMode = secondaryCfg.textRight or "CURMAX"
	st._secondaryPowerTextUsesLevel = UFHelper.textModeUsesLevel(st._secondaryPowerTextLeftMode)
		or UFHelper.textModeUsesLevel(st._secondaryPowerTextCenterMode)
		or UFHelper.textModeUsesLevel(st._secondaryPowerTextRightMode)
	st._dataBarTextLeftMode = dcfg.textLeft or ddef.textLeft or "NAME"
	st._dataBarTextCenterMode = dcfg.textCenter or ddef.textCenter or "CURMAX"
	st._dataBarTextRightMode = dcfg.textRight or ddef.textRight or "PERCENT"
	st._dataBarTextUsesPercent = UFHelper.textModeUsesPercent(st._dataBarTextLeftMode)
		or UFHelper.textModeUsesPercent(st._dataBarTextCenterMode)
		or UFHelper.textModeUsesPercent(st._dataBarTextRightMode)
	st._dataBarTextEnabled = UF.DataBar.IsEnabled(cfg, def)
end

function UF.CacheCompiledTextWriters(st, cfg, def)
	if not st or not UFHelper or not UFHelper.compileTextWriter then return end
	cfg, def = cfg or {}, def or {}
	local hc, pcfg, secondaryCfg = cfg.health or {}, cfg.power or {}, cfg.secondaryPower or {}
	local h1, h2, h3 = st._healthTextDelimiter1, st._healthTextDelimiter2, st._healthTextDelimiter3
	local p1, p2, p3 = st._powerTextDelimiter1, st._powerTextDelimiter2, st._powerTextDelimiter3
	local sp1, sp2, sp3 = st._secondaryPowerTextDelimiter1, st._secondaryPowerTextDelimiter2, st._secondaryPowerTextDelimiter3
	local healthShort = hc.useShortNumbers ~= false
	local powerShort = pcfg.useShortNumbers ~= false
	local secondaryShort = secondaryCfg.useShortNumbers ~= false

	st._healthTextLeftWriter = UFHelper.compileTextWriter(st._healthTextLeftMode, healthShort, h1, h2, h3, hc.hidePercentSymbol == true, hc.roundPercent == true)
	st._healthTextCenterWriter = UFHelper.compileTextWriter(st._healthTextCenterMode, healthShort, h1, h2, h3, hc.hidePercentSymbol == true, hc.roundPercent == true)
	st._healthTextRightWriter = UFHelper.compileTextWriter(st._healthTextRightMode, healthShort, h1, h2, h3, hc.hidePercentSymbol == true, hc.roundPercent == true)
	st._powerTextLeftWriter = UFHelper.compileTextWriter(st._powerTextLeftMode, powerShort, p1, p2, p3, pcfg.hidePercentSymbol == true, pcfg.roundPercent == true)
	st._powerTextCenterWriter = UFHelper.compileTextWriter(st._powerTextCenterMode, powerShort, p1, p2, p3, pcfg.hidePercentSymbol == true, pcfg.roundPercent == true)
	st._powerTextRightWriter = UFHelper.compileTextWriter(st._powerTextRightMode, powerShort, p1, p2, p3, pcfg.hidePercentSymbol == true, pcfg.roundPercent == true)
	st._secondaryPowerTextLeftWriter = UFHelper.compileTextWriter(st._secondaryPowerTextLeftMode, secondaryShort, sp1, sp2, sp3, secondaryCfg.hidePercentSymbol == true, secondaryCfg.roundPercent == true)
	st._secondaryPowerTextCenterWriter = UFHelper.compileTextWriter(st._secondaryPowerTextCenterMode, secondaryShort, sp1, sp2, sp3, secondaryCfg.hidePercentSymbol == true, secondaryCfg.roundPercent == true)
	st._secondaryPowerTextRightWriter = UFHelper.compileTextWriter(st._secondaryPowerTextRightMode, secondaryShort, sp1, sp2, sp3, secondaryCfg.hidePercentSymbol == true, secondaryCfg.roundPercent == true)
end

function UF.BuildCompiledTextGroup(fontString1, mode1, writer1, fontString2, mode2, writer2, fontString3, mode3, writer3)
	if fontString1 and mode1 == "NONE" then fontString1:SetText("") fontString1 = nil end
	if fontString2 and mode2 == "NONE" then fontString2:SetText("") fontString2 = nil end
	if fontString3 and mode3 == "NONE" then fontString3:SetText("") fontString3 = nil end

	local active1, activeWriter1, active2, activeWriter2, active3, activeWriter3
	if fontString1 then active1, activeWriter1 = fontString1, writer1 end
	if fontString2 then
		if active1 then
			active2, activeWriter2 = fontString2, writer2
		else
			active1, activeWriter1 = fontString2, writer2
		end
	end
	if fontString3 then
		if active2 then
			active3, activeWriter3 = fontString3, writer3
		elseif active1 then
			active2, activeWriter2 = fontString3, writer3
		else
			active1, activeWriter1 = fontString3, writer3
		end
	end
	if not active1 then return nil, nil, nil end

	if active3 then
		return function(current, maximum, percent, levelText, absorbAmount)
			active1:SetText(activeWriter1(current, maximum, percent, levelText, nil, absorbAmount))
			active2:SetText(activeWriter2(current, maximum, percent, levelText, nil, absorbAmount))
			active3:SetText(activeWriter3(current, maximum, percent, levelText, nil, absorbAmount))
		end, function()
			active1:SetText("")
			active2:SetText("")
			active3:SetText("")
		end, function(text)
			active1:SetText(text)
			active2:SetText("")
			active3:SetText("")
		end
	elseif active2 then
		return function(current, maximum, percent, levelText, absorbAmount)
			active1:SetText(activeWriter1(current, maximum, percent, levelText, nil, absorbAmount))
			active2:SetText(activeWriter2(current, maximum, percent, levelText, nil, absorbAmount))
		end, function()
			active1:SetText("")
			active2:SetText("")
		end, function(text)
			active1:SetText(text)
			active2:SetText("")
		end
	end

	return function(current, maximum, percent, levelText, absorbAmount)
		active1:SetText(activeWriter1(current, maximum, percent, levelText, nil, absorbAmount))
	end, function()
		active1:SetText("")
	end, function(text)
		active1:SetText(text)
	end
end

function UF.CacheCompiledTextGroups(st)
	if not st then return end
	st._healthTextGroupWriter, st._healthTextGroupClearer, st._healthTextLifeWriter = UF.BuildCompiledTextGroup(
		st.healthTextLeft,
		st._healthTextLeftMode,
		st._healthTextLeftWriter,
		st.healthTextCenter,
		st._healthTextCenterMode,
		st._healthTextCenterWriter,
		st.healthTextRight,
		st._healthTextRightMode,
		st._healthTextRightWriter
	)
	st._powerTextGroupWriter, st._powerTextGroupClearer = UF.BuildCompiledTextGroup(
		st.powerTextLeft,
		st._powerTextLeftMode,
		st._powerTextLeftWriter,
		st.powerTextCenter,
		st._powerTextCenterMode,
		st._powerTextCenterWriter,
		st.powerTextRight,
		st._powerTextRightMode,
		st._powerTextRightWriter
	)
	st._secondaryPowerTextGroupWriter, st._secondaryPowerTextGroupClearer = UF.BuildCompiledTextGroup(
		st.secondaryPowerTextLeft,
		st._secondaryPowerTextLeftMode,
		st._secondaryPowerTextLeftWriter,
		st.secondaryPowerTextCenter,
		st._secondaryPowerTextCenterMode,
		st._secondaryPowerTextCenterWriter,
		st.secondaryPowerTextRight,
		st._secondaryPowerTextRightMode,
		st._secondaryPowerTextRightWriter
	)
end

function UF.CacheIdentityRuntimePlan(st, cfg, def)
	if not st then return end
	cfg, def = cfg or {}, def or {}
	local powerCfg, powerDef = cfg.power or {}, def.power or {}
	local powerEnabled = powerCfg.enabled
	if powerEnabled == nil then powerEnabled = powerDef.enabled ~= false end
	st._identityPowerEnabled = powerEnabled ~= false
	st._identityDataBarEnabled = UF.DataBar.IsEnabled(cfg, def)

	local castCfg, castDef = cfg.cast or {}, def.cast or {}
	local castEnabled = castCfg.enabled
	if castEnabled == nil then castEnabled = castDef.enabled ~= false end
	st._identityCastEnabled = castEnabled ~= false

	local raidCfg, raidDef = cfg.raidIcon or {}, def.raidIcon or {}
	local raidEnabled = raidCfg.enabled
	if raidEnabled == nil then raidEnabled = raidDef.enabled ~= false end
	st._identityRaidIconEnabled = raidEnabled ~= false

	local statusCfg, statusDef = cfg.status or {}, def.status or {}
	local unitStatusCfg = statusCfg.unitStatus or statusDef.unitStatus or {}
	st._identityUnitStatusEnabled = unitStatusCfg.enabled == true
	local combatCfg = statusCfg.combatIndicator or statusDef.combatIndicator or {}
	st._identityCombatIndicatorEnabled = combatCfg.enabled ~= false
	st._identityLeaderIndicatorEnabled = ((cfg.leaderIcon or def.leaderIcon or {}).enabled == true)
	st._identityPvPIndicatorEnabled = ((cfg.pvpIndicator or def.pvpIndicator or {}).enabled == true)
	st._identityRoleIndicatorEnabled = ((cfg.roleIndicator or def.roleIndicator or {}).enabled == true)

	local dispelCfg = statusCfg.dispelTint or {}
	local dispelDef = statusDef.dispelTint or {}
	local dispelEnabled = dispelCfg.enabled
	if dispelEnabled == nil then dispelEnabled = dispelDef.enabled ~= false end
	local dispelGlowEnabled = dispelCfg.glowEnabled
	if dispelGlowEnabled == nil then dispelGlowEnabled = dispelDef.glowEnabled == true end
	st._identityDispelEnabled = dispelEnabled == true or dispelGlowEnabled == true

	local auraCfg = cfg.auraIcons or def.auraIcons or {}
	local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(UNIT.TARGET, auraCfg, def.auraIcons)
	st._identityAurasEnabled = auraRuntime and auraRuntime.enabled == true or false
end

function UF.RecomputeTargetHighlightActivity()
	UF._targetHighlightActive = false
	for _, st in pairs(states) do
		if st and st._highlightCfg and st._highlightCfg.target == true then
			UF._targetHighlightActive = true
			return
		end
	end
end

refreshNameAndLevelSoon = function(unit)
	if not unit then return end
	UF._pendingNameLevelRefresh = UF._pendingNameLevelRefresh or {}
	if UF._pendingNameLevelRefresh[unit] then return end
	UF._pendingNameLevelRefresh[unit] = true

	local function getLiveStateAndConfig()
		local st = states[unit]
		if not st then return nil, nil end
		local cfg = st.cfg or ensureDB(unit)
		if not cfg or cfg.enabled == false then return st, nil end
		return st, cfg
	end

	local function refreshAll()
		local st, cfg = getLiveStateAndConfig()
		if not cfg then return end
		updateStatus(cfg, unit)
		syncTextFrameLevels(st)
		updateNameAndLevel(cfg, unit)
	end

	local function refreshIdentityText()
		local _, cfg = getLiveStateAndConfig()
		if cfg then updateNameAndLevel(cfg, unit) end
	end

	refreshAll()
	if not After then
		UF._pendingNameLevelRefresh[unit] = nil
		return
	end

	local delays = { 0, 0.05, 0.25, 0.75, 1.5 }
	local remaining = #delays
	for _, delay in ipairs(delays) do
		After(delay, function()
			refreshIdentityText()
			remaining = remaining - 1
			if remaining <= 0 then UF._pendingNameLevelRefresh[unit] = nil end
		end)
	end
end

local function applyConfig(unit)
	local cfg = ensureDB(unit)
	local def = defaultsFor(unit)
	states[unit] = states[unit] or {}
	local st = states[unit]
	AuraUtil.invalidateUnitSingleAuraRuntimeConfig(unit)
	st.cfg = cfg
	st.def = def
	if unit == UNIT.TARGET_TARGET then UF._targetTargetEnabled = cfg.enabled == true end
	UF.InvalidateHealthIdentityState(st)
	st._healthBackdropDirty = true
	st._powerColorDirty = true
	st._secondaryPowerColorDirty = true
	st._healthTextDirty = true
	st._powerTextDirty = true
	st._secondaryPowerTextDirty = true
	st._dataBarTextDirty = true
	if UF.ScheduleTextUpdate then UF.ScheduleTextUpdate() end
	if unit == UNIT.TARGET then syncTargetRangeFadeConfig(cfg, def) end
	if not cfg.enabled then
		if st and st.frame then
			if st.barGroup then st.barGroup:Hide() end
			if st.status then st.status:Hide() end
			UF.DataBar.Hide(st)
			if st.portrait then st.portrait:Hide() end
			if st.portraitHolder then st.portraitHolder:Hide() end
			if st.portraitSeparator then st.portraitSeparator:Hide() end
			if st.auraContainer then AuraUtil.hideAuraContainers(st) end
			if st._highlightFrame then st._highlightFrame:Hide() end
			st._hovered = false
		end
		if st then
			st._highlightCfg = nil
			st._displayPowerStructureKey = nil
		end
		UF.RecomputeTargetHighlightActivity()
		if UFHelper and UFHelper.updateCombatFeedback then UFHelper.updateCombatFeedback(st, unit, cfg, def) end
		applyVisibilityDriver(unit, false)
		if unit == UNIT.PLAYER then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.player, false) end
		if unit == UNIT.TARGET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.target, false) end
		if unit == UNIT.TARGET_TARGET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.targettarget, false) end
		if unit == UNIT.FOCUS then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, false) end
		if unit == UNIT.PET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.pet, false) end
		if unit == UNIT.PLAYER then
			ClassResourceUtil.restoreClassResourceFrames()
			TotemFrameUtil.restoreTotemFrame()
		end
		if unit == UNIT.PLAYER or unit == "target" or unit == UNIT.FOCUS or isBossUnit(unit) then AuraUtil.resetTargetAuras(unit) end
		if unit == UNIT.PLAYER then updateRestingIndicator(cfg) end
		if not isBossUnit(unit) then applyVisibilityRules(unit) end
		if unit == UNIT.TARGET and UFHelper and UFHelper.RangeFadeReset then UFHelper.RangeFadeReset() end
		if unit == UNIT.PLAYER and addon.functions and addon.functions.ApplyCastBarVisibility then addon.functions.ApplyCastBarVisibility() end
		AuraUtil.HideSingleDispelIndicator(unit)
		return
	end
	ensureFrames(unit)
	st = states[unit]
	st.cfg = cfg
	st.def = def
	UF.CacheTextRuntimePlan(st, cfg, def)
	UF.CacheNameLevelRuntimePlan(st, cfg, def, unit)
	if unit == UNIT.TARGET then UF.CacheIdentityRuntimePlan(st, cfg, def) end
	if UFHelper then
		local hc = (cfg and cfg.health) or {}
		local defH = (def and def.health) or {}
		local pcfg = (cfg and cfg.power) or {}
		local defP = (def and def.power) or {}
		local secondaryCfg = (cfg and cfg.secondaryPower) or {}
		local defSecondary = (def and def.secondaryPower) or {}

		local h1 = UFHelper.getTextDelimiter(hc, defH)
		local h2 = UFHelper.getTextDelimiterSecondary(hc, defH, h1)
		local h3 = UFHelper.getTextDelimiterTertiary(hc, defH, h1, h2)
		if UFHelper.resolveTextDelimiters then
			st._healthTextDelimiter1, st._healthTextDelimiter2, st._healthTextDelimiter3 = UFHelper.resolveTextDelimiters(h1, h2, h3)
		else
			st._healthTextDelimiter1, st._healthTextDelimiter2, st._healthTextDelimiter3 = h1, h2, h3
		end

		local p1 = UFHelper.getTextDelimiter(pcfg, defP)
		local p2 = UFHelper.getTextDelimiterSecondary(pcfg, defP, p1)
		local p3 = UFHelper.getTextDelimiterTertiary(pcfg, defP, p1, p2)
		if UFHelper.resolveTextDelimiters then
			st._powerTextDelimiter1, st._powerTextDelimiter2, st._powerTextDelimiter3 = UFHelper.resolveTextDelimiters(p1, p2, p3)
		else
			st._powerTextDelimiter1, st._powerTextDelimiter2, st._powerTextDelimiter3 = p1, p2, p3
		end

		local sp1 = UFHelper.getTextDelimiter(secondaryCfg, defSecondary)
		local sp2 = UFHelper.getTextDelimiterSecondary(secondaryCfg, defSecondary, sp1)
		local sp3 = UFHelper.getTextDelimiterTertiary(secondaryCfg, defSecondary, sp1, sp2)
		if UFHelper.resolveTextDelimiters then
			st._secondaryPowerTextDelimiter1, st._secondaryPowerTextDelimiter2, st._secondaryPowerTextDelimiter3 = UFHelper.resolveTextDelimiters(sp1, sp2, sp3)
		else
			st._secondaryPowerTextDelimiter1, st._secondaryPowerTextDelimiter2, st._secondaryPowerTextDelimiter3 = sp1, sp2, sp3
		end
		UF.CacheCompiledTextWriters(st, cfg, def)
		UF.CacheCompiledTextGroups(st)
	end
	st._highlightCfg = UFHelper.buildHighlightConfig(cfg, def)
	UF.RecomputeTargetHighlightActivity()
	applyVisibilityDriver(unit, cfg.enabled)
	if unit == UNIT.PLAYER then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.player, true) end
	if unit == UNIT.TARGET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.target, true) end
	if unit == UNIT.TARGET_TARGET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.targettarget, true) end
	if unit == UNIT.FOCUS then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, true) end
	if unit == UNIT.PET then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.pet, true) end
	applyBars(cfg, unit)
	if not InCombatLockdown() then
		layoutFrame(cfg, unit)
	else
		UFHelper.applyHighlightStyle(st, st._highlightCfg)
	end
	if unit == UNIT.PLAYER then UF.ApplyPlayerDisplayPowerManagedLayouts(cfg) end
	updateStatus(cfg, unit)
	if UFHelper and UFHelper.updateCombatFeedback then UFHelper.updateCombatFeedback(st, unit, cfg, def) end
	updateNameAndLevel(cfg, unit)
	updateHealth(cfg, unit)
	updatePower(cfg, unit)
	if unit == UNIT.PLAYER then
		local sig = UF.BuildPlayerDisplayPowerSignature(cfg)
		st._displayPowerStructureKey = sig and sig.key or nil
	end
	updatePortrait(cfg, unit)
	AuraUtil.UpdateSingleDispelIndicator(unit, UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit))
	checkRaidTargetIcon(unit, st)
	UFHelper.updateLeaderIndicator(st, unit, cfg, defaultsFor(unit), false)
	UFHelper.updatePvPIndicator(st, unit, cfg, defaultsFor(unit), false)
	UFHelper.updateRoleIndicator(st, unit, cfg, defaultsFor(unit), false)
	if UF.SupportsCombatIndicator(unit) then updateCombatIndicator(cfg, unit) end
	if unit == UNIT.PLAYER then updateRestingIndicator(cfg) end
	-- if unit == "target" then hideBlizzardTargetFrame() end
	if st and st.frame then
		if st.barGroup then st.barGroup:Show() end
		if st.status then st.status:Show() end
		UF.DataBar.Update(cfg, unit)
	end
	UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
	if unit == UNIT.PLAYER and st.castBar then
		if cfg.cast and cfg.cast.enabled ~= false then
			setCastInfoFromUnit(UNIT.PLAYER)
		else
			stopCast(UNIT.PLAYER)
			st.castBar:Hide()
		end
		if addon.functions and addon.functions.ApplyCastBarVisibility then addon.functions.ApplyCastBarVisibility() end
	end
	if unit == UNIT.TARGET and st.castBar then
		if cfg.cast and cfg.cast.enabled ~= false and UnitExists(UNIT.TARGET) then
			setCastInfoFromUnit(UNIT.TARGET)
		else
			stopCast(UNIT.TARGET)
			st.castBar:Hide()
		end
	end
	if isBossUnit(unit) and st.castBar then
		if cfg.cast and cfg.cast.enabled ~= false and UnitExists(unit) then
			setCastInfoFromUnit(unit)
		else
			stopCast(unit)
			st.castBar:Hide()
		end
	end
	if unit == UNIT.TARGET and states[unit] and states[unit].auraContainer then
		if addon.EditModeLib and addon.EditModeLib:IsInEditMode() then
			AuraUtil.fullScanTargetAuras(unit)
		else
			AuraUtil.updateTargetAuraIcons(1, unit)
		end
	elseif unit == UNIT.FOCUS and states[unit] and states[unit].auraContainer then
		AuraUtil.fullScanTargetAuras(unit)
	elseif unit == UNIT.PLAYER and states[unit] and states[unit].auraContainer then
		AuraUtil.fullScanTargetAuras(unit)
	elseif isBossUnit(unit) and states[unit] and states[unit].auraContainer then
		AuraUtil.fullScanTargetAuras(unit)
	end
	if not isBossUnit(unit) then applyVisibilityRules(unit) end
	if unit == UNIT.TARGET and UFHelper and UFHelper.RangeFadeApplyCurrent then UFHelper.RangeFadeApplyCurrent(true) end
end

local function layoutBossFrames(cfg)
	if not bossContainer then return end
	if InCombatLockdown() then
		bossLayoutDirty = true
		return
	end
	bossLayoutDirty = false
	cfg = cfg or ensureDB("boss")
	anchorBossContainer(cfg)
	local def = defaultsFor("boss")
	local spacing = cfg.spacing
	if spacing == nil and def then spacing = def.spacing end
	if spacing == nil then spacing = 4 end
	spacing = tonumber(spacing) or 4
	if spacing < BOSS_SPACING_MIN then spacing = BOSS_SPACING_MIN end
	local growth = (cfg.growth or (def and def.growth) or "DOWN"):upper()
	local last
	local shown = 0
	local maxWidth = 0
	local totalWidth = 0
	local totalHeight = 0
	local maxHeight = 0
	local horizontal = growth == "LEFT" or growth == "RIGHT"
	local bossCount = UF.GetBossFrameCount(cfg)
	for i = 1, bossCount do
		local unit = "boss" .. i
		local st = states[unit]
		if st and st.frame then
			local statusHeightDelta = tonumber(st.frame._eqolUFStatusHeightDelta) or 0
			st.frame:ClearAllPoints()
			if not last then
				if growth == "LEFT" then
					st.frame:SetPoint("TOPRIGHT", bossContainer, "TOPRIGHT", 0, -statusHeightDelta)
				elseif growth == "UP" then
					st.frame:SetPoint("BOTTOMLEFT", bossContainer, "BOTTOMLEFT", 0, 0)
				else
					st.frame:SetPoint("TOPLEFT", bossContainer, "TOPLEFT", 0, -statusHeightDelta)
				end
			else
				local lastStatusHeightDelta = tonumber(last.frame and last.frame._eqolUFStatusHeightDelta) or 0
				if growth == "RIGHT" then
					st.frame:SetPoint("TOPLEFT", last.frame, "TOPRIGHT", spacing, lastStatusHeightDelta - statusHeightDelta)
				elseif growth == "LEFT" then
					st.frame:SetPoint("TOPRIGHT", last.frame, "TOPLEFT", -spacing, lastStatusHeightDelta - statusHeightDelta)
				elseif growth == "UP" then
					st.frame:SetPoint("BOTTOMLEFT", last.frame, "TOPLEFT", 0, spacing + lastStatusHeightDelta)
				else
					st.frame:SetPoint("TOPLEFT", last.frame, "BOTTOMLEFT", 0, -(spacing + statusHeightDelta))
				end
			end
			last = st
			shown = shown + 1
			local width = st.frame:GetWidth() or 0
			local height = st.frame:GetHeight() or 0
			local visualHeight = height + statusHeightDelta
			maxWidth = math.max(maxWidth, width)
			totalWidth = totalWidth + width
			totalHeight = totalHeight + visualHeight
			maxHeight = math.max(maxHeight, visualHeight)
		end
	end
	if shown > 0 then
		if horizontal then
			totalWidth = totalWidth + spacing * (shown - 1)
			if totalWidth < maxWidth then totalWidth = maxWidth end
			bossContainer:SetWidth(totalWidth)
			bossContainer:SetHeight(maxHeight)
		else
			totalHeight = totalHeight + spacing * (shown - 1)
			if totalHeight < maxHeight then totalHeight = maxHeight end
			bossContainer:SetHeight(totalHeight)
			bossContainer:SetWidth(maxWidth)
		end
	end
end

local function hideBossFrames(forceHide)
	for i = 1, maxBossFrames do
		local st = states["boss" .. i]
		if st and st.frame then applyVisibilityDriver("boss" .. i, false) end
	end
	bossLayoutDirty = false
	if addon.EditModeLib and addon.EditModeLib:IsInEditMode() and ensureDB("boss").enabled and not forceHide then
		-- Keep container visible in edit mode for positioning
		if bossContainer then bossContainer:Show() end
		return
	end
	if InCombatLockdown() then
		bossHidePending = true
		bossShowPending = nil
		return
	end
	bossHidePending = nil
	bossShowPending = nil
	if bossContainer then
		if forceHide or not ensureDB("boss").enabled then
			bossContainer:Hide()
		else
			bossContainer:Show()
		end
	end
end

applyBossEditSample = function(idx, cfg)
	cfg = cfg or ensureDB("boss")
	local unit = "boss" .. idx
	local st = states[unit]
	if not st or not st.frame then return end
	local def = defaultsFor("boss")
	local defH = def.health or {}
	local defP = def.power or {}
	local hc = cfg.health or defH or {}
	local pcfg = cfg.power or defP or {}
	local cdef = cfg.cast or def.cast or {}
	local hideClassText = UF.ShouldHideClassificationText(cfg, unit)
	local interpolation = getSmoothInterpolation(cfg, def)
	local sampleHealthCur = 580000
	local sampleHealthMax = 1000000
	local sampleHealthPercent = 58
	local sampleHealthAbsorb = shouldShowSampleAbsorb(unit) and 600000 or 180000
	local samplePowerCur = 73
	local samplePowerMax = 100
	local samplePowerPercent = 73
	local sampleLevelText = hideClassText and "" or "??"

	st.health:SetMinMaxValues(0, sampleHealthMax)
	st.health:SetValue(sampleHealthCur, interpolation)
	local healthOrientation = UFHelper.normalizeStatusBarOrientation(hc.orientation or defH.orientation)
	local reverseHealth = hc.reverseFill
	if reverseHealth == nil then reverseHealth = defH.reverseFill == true end
	local healthAxis = UFHelper.GetHealthAxis(healthOrientation, reverseHealth)
	local overlayRegions = UFHelper.LayoutHealthOverlayRegions(st.health, healthAxis)
	if hc.absorbEnabled ~= false and st.absorb then
		local reverseAbsorb = hc.absorbReverseFill
		if reverseAbsorb == nil then reverseAbsorb = defH.absorbReverseFill == true end
		local dontOverflow = hc.absorbDontOverflowHealthBar
		if dontOverflow == nil then dontOverflow = defH.absorbDontOverflowHealthBar == true end
		dontOverflow = dontOverflow == true and reverseAbsorb == true
		local thickness = hc.absorbOverlayHeight
		if thickness == nil then thickness = defH.absorbOverlayHeight end
		local alignMax = hc.absorbOverlayAnchorTop
		if alignMax == nil then alignMax = defH.absorbOverlayAnchorTop == true end
		UFHelper.LayoutDamageAbsorb(st.health, st.absorb, st.absorb2, {
			axis = healthAxis,
			regions = overlayRegions,
			reverseAbsorb = reverseAbsorb,
			dontOverflow = dontOverflow,
			thickness = thickness,
			crossAlign = alignMax and "MAX" or "MIN",
		})
		st.absorb:SetMinMaxValues(0, sampleHealthMax)
		st.absorb:SetValue(sampleHealthAbsorb, interpolation)
		if reverseAbsorb and st.absorb2 then
			st.absorb2:SetMinMaxValues(0, sampleHealthMax)
			st.absorb2:SetValue(sampleHealthAbsorb, interpolation)
			st.absorb2:Show()
		end
		st.absorb:SetShown(not dontOverflow)
	end
	local baseR, baseG, baseB, baseA = UF.resolveHealthBaseColor(unit, hc, defH)
	local sampleR, sampleG, sampleB, sampleA = baseR, baseG, baseB, baseA
	st.health:SetStatusBarColor(sampleR or 0, sampleG or 0.8, sampleB or 0, sampleA or 1)
	local leftMode = hc.textLeft or "PERCENT"
	local centerMode = hc.textCenter or "NONE"
	local rightMode = hc.textRight or "CURMAX"
	local delimiter = UFHelper.getTextDelimiter(hc, defH)
	local delimiter2 = UFHelper.getTextDelimiterSecondary(hc, defH, delimiter)
	local delimiter3 = UFHelper.getTextDelimiterTertiary(hc, defH, delimiter, delimiter2)
	local hidePercentSymbol = hc.hidePercentSymbol == true
	local roundPercent = hc.roundPercent == true
	local levelText = sampleLevelText
	if st.healthTextLeft then
		if leftMode == "NONE" then
			st.healthTextLeft:SetText("")
		else
			st.healthTextLeft:SetText(
				UFHelper.formatText(
					leftMode,
					sampleHealthCur,
					sampleHealthMax,
					hc.useShortNumbers ~= false,
					sampleHealthPercent,
					delimiter,
					delimiter2,
					delimiter3,
					hidePercentSymbol,
					levelText,
					nil,
					roundPercent,
					nil,
					sampleHealthAbsorb
				)
			)
		end
	end
	if st.healthTextCenter then
		if centerMode == "NONE" then
			st.healthTextCenter:SetText("")
		else
			st.healthTextCenter:SetText(
				UFHelper.formatText(
					centerMode,
					sampleHealthCur,
					sampleHealthMax,
					hc.useShortNumbers ~= false,
					sampleHealthPercent,
					delimiter,
					delimiter2,
					delimiter3,
					hidePercentSymbol,
					levelText,
					nil,
					roundPercent,
					nil,
					sampleHealthAbsorb
				)
			)
		end
	end
	if st.healthTextRight then
		if rightMode == "NONE" then
			st.healthTextRight:SetText("")
		else
			st.healthTextRight:SetText(
				UFHelper.formatText(
					rightMode,
					sampleHealthCur,
					sampleHealthMax,
					hc.useShortNumbers ~= false,
					sampleHealthPercent,
					delimiter,
					delimiter2,
					delimiter3,
					hidePercentSymbol,
					levelText,
					nil,
					roundPercent,
					nil,
					sampleHealthAbsorb
				)
			)
		end
	end

	local powerEnabled = pcfg.enabled ~= false
	local powerDetached = pcfg.detached == true
	local borderCfg = cfg.border or {}
	local borderDef = def.border or {}
	local detachedPowerBorder = powerDetached and ((borderCfg.detachedPower ~= nil and borderCfg.detachedPower == true) or (borderCfg.detachedPower == nil and borderDef.detachedPower == true))
	if st.power then
		if powerEnabled then
			if st.power.SetAlpha then st.power:SetAlpha(1) end
			if st.powerGroup and st.powerGroup.SetAlpha then st.powerGroup:SetAlpha(1) end
			if st.barGroup then st.barGroup:Show() end
			if st.powerGroup then
				local powerParent = st.power.GetParent and st.power:GetParent() or nil
				if detachedPowerBorder or powerParent == st.powerGroup then
					st.powerGroup:Show()
				else
					st.powerGroup:Hide()
				end
			end
			st.power:SetMinMaxValues(0, samplePowerMax)
			st.power:SetValue(samplePowerCur, interpolation)
			local pr, pg, pb, pa = UFHelper.getPowerColor(0, "MANA")
			st.power:SetStatusBarColor(pr or 0.1, pg or 0.45, pb or 1, pa or 1)
			if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(0, "MANA")) end
			local pLeftMode = pcfg.textLeft or "PERCENT"
			local pCenterMode = pcfg.textCenter or "NONE"
			local pRightMode = pcfg.textRight or "CURMAX"
			local pDelimiter = UFHelper.getTextDelimiter(pcfg, defP)
			local pDelimiter2 = UFHelper.getTextDelimiterSecondary(pcfg, defP, pDelimiter)
			local pDelimiter3 = UFHelper.getTextDelimiterTertiary(pcfg, defP, pDelimiter, pDelimiter2)
			local pHidePercentSymbol = pcfg.hidePercentSymbol == true
			local pRoundPercent = pcfg.roundPercent == true
			local pLevelText = levelText
			if st.powerTextLeft then
				if pLeftMode == "NONE" then
					st.powerTextLeft:SetText("")
				else
					st.powerTextLeft:SetText(
						UFHelper.formatText(
							pLeftMode,
							samplePowerCur,
							samplePowerMax,
							pcfg.useShortNumbers ~= false,
							samplePowerPercent,
							pDelimiter,
							pDelimiter2,
							pDelimiter3,
							pHidePercentSymbol,
							pLevelText,
							nil,
							pRoundPercent
						)
					)
				end
			end
			if st.powerTextCenter then
				if pCenterMode == "NONE" then
					st.powerTextCenter:SetText("")
				else
					st.powerTextCenter:SetText(
						UFHelper.formatText(
							pCenterMode,
							samplePowerCur,
							samplePowerMax,
							pcfg.useShortNumbers ~= false,
							samplePowerPercent,
							pDelimiter,
							pDelimiter2,
							pDelimiter3,
							pHidePercentSymbol,
							pLevelText,
							nil,
							pRoundPercent
						)
					)
				end
			end
			if st.powerTextRight then
				if pRightMode == "NONE" then
					st.powerTextRight:SetText("")
				else
					st.powerTextRight:SetText(
						UFHelper.formatText(
							pRightMode,
							samplePowerCur,
							samplePowerMax,
							pcfg.useShortNumbers ~= false,
							samplePowerPercent,
							pDelimiter,
							pDelimiter2,
							pDelimiter3,
							pHidePercentSymbol,
							pLevelText,
							nil,
							pRoundPercent
						)
					)
				end
			end
			st.power:Show()
		else
			if st.powerGroup then st.powerGroup:Hide() end
			st.power:SetValue(0, interpolation)
			if st.powerTextLeft then st.powerTextLeft:SetText("") end
			if st.powerTextCenter then st.powerTextCenter:SetText("") end
			if st.powerTextRight then st.powerTextRight:SetText("") end
			st.power:Hide()
		end
	end
	if st.nameText then st.nameText:SetText((L["UFBossFrame"] or "Boss Frame") .. " " .. idx) end
	if st.levelText then
		st.levelText:SetText(sampleLevelText ~= "" and sampleLevelText or "??")
		st.levelText:Show()
	end
	if st.dataBar then
		if UF.DataBar.IsEnabled(cfg, def) then
			UF.DataBar.Update(cfg, unit)
			local dcfg = cfg.dataBar or {}
			local ddef = def.dataBar or {}
			local dDelimiter = UFHelper.getTextDelimiter(dcfg, ddef)
			local dDelimiter2 = UFHelper.getTextDelimiterSecondary(dcfg, ddef, dDelimiter)
			local dDelimiter3 = UFHelper.getTextDelimiterTertiary(dcfg, ddef, dDelimiter, dDelimiter2)
			local dHidePercentSymbol = dcfg.hidePercentSymbol == true
			local dRoundPercent = dcfg.roundPercent == true
			local function sampleDataBarText(mode)
				mode = tostring(mode or "NONE"):upper()
				if mode == "NONE" then return "" end
				if mode == "NAME" then return (L["UFBossFrame"] or "Boss Frame") .. " " .. idx end
				if mode == "LEVEL" then return sampleLevelText end
				return UFHelper.formatText(
					mode,
					sampleHealthCur,
					sampleHealthMax,
					dcfg.useShortNumbers ~= false,
					sampleHealthPercent,
					dDelimiter,
					dDelimiter2,
					dDelimiter3,
					dHidePercentSymbol,
					sampleLevelText,
					nil,
					dRoundPercent,
					true,
					sampleHealthAbsorb
				)
			end
			if st.dataBarTextLeft then st.dataBarTextLeft:SetText(sampleDataBarText(dcfg.textLeft or ddef.textLeft or "NAME")) end
			if st.dataBarTextCenter then st.dataBarTextCenter:SetText(sampleDataBarText(dcfg.textCenter or ddef.textCenter or "CURMAX")) end
			if st.dataBarTextRight then st.dataBarTextRight:SetText(sampleDataBarText(dcfg.textRight or ddef.textRight or "PERCENT")) end
			st._dataBarTextDirty = nil
		else
			UF.DataBar.Hide(st)
		end
	end
	if st.castBar then
		if cdef.enabled ~= false then
			UF.SetSampleCast(unit)
		else
			stopCast(unit)
			st.castBar:Hide()
		end
	end
end

function UF._setBossFrameInactive(unit)
	local st = states[unit]
	if not st or not st.frame then return end
	applyVisibilityDriver(unit, false)
	if st.barGroup then st.barGroup:Hide() end
	if st.status then st.status:Hide() end
	UF.DataBar.Hide(st)
	if st.auraContainer then AuraUtil.hideAuraContainers(st) end
	AuraUtil.resetTargetAuras(unit)
	AuraUtil.HideSingleDispelIndicator(unit)
	if st.castBar then
		stopCast(unit)
		st.castBar:Hide()
	end
	st._hovered = false
	UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
	AuraUtil.RefreshHealerBuffPlacementUnit(unit)
end

local function updateBossFrames(force)
	local cfg = ensureDB("boss")
	if not cfg.enabled then
		hideBossFrames(true)
		applyVisibilityRules("boss")
		return
	end
	if not bossContainer then ensureBossContainer() end
	DisableBossFrames()
	local inEdit = addon.EditModeLib and addon.EditModeLib:IsInEditMode()
	local bossCount = UF.GetBossFrameCount(cfg)
	for i = 1, maxBossFrames do
		local unit = "boss" .. i
		if i > bossCount then
			UF._setBossFrameInactive(unit)
		else
			if force or not states[unit] or not states[unit].frame or inEdit then applyConfig(unit) end
			local st = states[unit]
			if st then st.cfg = cfg end
			if st and st.frame then
				if inEdit then
					if not InCombatLockdown() then
						UF.ClearEqolVisibilityDriver(st, true)
						if UnregisterStateDriver then UnregisterStateDriver(st.frame, "visibility") end
						if st.frame.SetAttribute then st.frame:SetAttribute("state-visibility", nil) end
						UF.ClearBossUnitWatch(st.frame, "EQOL_BossUnitWatchRegistered", true)
						UF.ClearBossUnitWatch(st.powerGroup, "EQOL_BossPowerUnitWatchRegistered", false)
						if st.frame.SetAttribute then st.frame:SetAttribute("unit", "player") end
						st.frame:Show()
					else
						bossInitPending = true
					end
					if st.barGroup then st.barGroup:Show() end
					if st.status then st.status:Show() end
					UF.DataBar.Update(cfg, unit)
					applyBossEditSample(i, cfg)
					if st.auraContainer then AuraUtil.fullScanTargetAuras(unit) end
				else
					local exists = UnitExists and UnitExists(unit)
					if not InCombatLockdown() then
						if st.frame.SetAttribute then st.frame:SetAttribute("unit", unit) end
						applyVisibilityDriver(unit, cfg.enabled)
					else
						if exists then
							bossShowPending = true
							bossHidePending = nil
						else
							bossHidePending = true
							bossShowPending = nil
						end
					end
					if exists then
						if st.barGroup then st.barGroup:Show() end
						if st.status then st.status:Show() end
						UF.DataBar.Update(cfg, unit)
						updateNameAndLevel(cfg, unit)
						updateHealth(cfg, unit)
						updatePower(cfg, unit)
						checkRaidTargetIcon(unit, st)
						AuraUtil.fullScanTargetAuras(unit)
						if st.castBar and cfg.cast and cfg.cast.enabled ~= false then
							setCastInfoFromUnit(unit)
							if UF.ShouldShowSampleCast(unit) and (not st.castInfo or not UnitCastingInfo or (UnitCastingInfo and not UnitCastingInfo(unit))) then UF.SetSampleCast(unit) end
						elseif st.castBar then
							stopCast(unit)
							st.castBar:Hide()
						end
					else
						if st.barGroup then st.barGroup:Hide() end
						if st.status then st.status:Hide() end
						UF.DataBar.Hide(st)
						if st.auraContainer then AuraUtil.hideAuraContainers(st) end
						AuraUtil.resetTargetAuras(unit)
						if st.castBar then
							stopCast(unit)
							st.castBar:Hide()
						end
					end
				end
			end
			UFHelper.updateHighlight(st, unit, UNIT.PLAYER)
		end
	end
	anchorBossContainer(cfg)
	layoutBossFrames(cfg)
	if not InCombatLockdown() then
		if bossContainer then bossContainer:Show() end
		bossShowPending = nil
		bossHidePending = nil
	else
		bossShowPending = true
		bossHidePending = nil
	end
	applyVisibilityRules("boss")
end

local unitEvents = {
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_MAX_HEALTH_MODIFIERS_CHANGED",
	"UNIT_HEAL_PREDICTION",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	"UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
	"UNIT_POWER_UPDATE",
	"UNIT_POWER_FREQUENT",
	"UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER",
	"UNIT_NAME_UPDATE",
	"UNIT_CLASSIFICATION_CHANGED",
	"UNIT_FLAGS",
	"UNIT_CONNECTION",
	"UNIT_FACTION",
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_THREAT_LIST_UPDATE",
	"UNIT_AURA",
	"UNIT_TARGET",
	"UNIT_SPELLCAST_SENT",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_CHANNEL_UPDATE",
	"UNIT_SPELLCAST_EMPOWER_START",
	"UNIT_SPELLCAST_EMPOWER_UPDATE",
	"UNIT_SPELLCAST_DELAYED",
	"UNIT_SPELLCAST_EMPOWER_STOP",
	"UNIT_PET",
}
local unitEventsMap = {}
for _, evt in ipairs(unitEvents) do
	unitEventsMap[evt] = true
end
local portraitEvents = {
	"UNIT_PORTRAIT_UPDATE",
	"UNIT_MODEL_CHANGED",
	"UNIT_ENTERED_VEHICLE",
	"UNIT_EXITED_VEHICLE",
	"UNIT_EXITING_VEHICLE",
}
local portraitEventsMap = {}
for _, evt in ipairs(portraitEvents) do
	portraitEventsMap[evt] = true
end
local FREQUENT = { ENERGY = true, FOCUS = true, RAGE = true, RUNIC_POWER = true, LUNAR_POWER = true }

local generalEvents = {
	"PLAYER_ENTERING_WORLD",
	"PLAYER_LEVEL_UP",
	"PLAYER_DEAD",
	"PLAYER_ALIVE",
	"PLAYER_UNGHOST",
	"PLAYER_TARGET_CHANGED",
	"PLAYER_LOGIN",
	"PLAYER_TALENT_UPDATE",
	"ACTIVE_TALENT_GROUP_CHANGED",
	"ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
	"TRAIT_CONFIG_UPDATED",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
	"PLAYER_FLAGS_CHANGED",
	"PLAYER_UPDATE_RESTING",
	"GROUP_ROSTER_UPDATE",
	"PARTY_LEADER_CHANGED",
	"PLAYER_FOCUS_CHANGED",
	"RAID_TARGET_UPDATE",
	"SPELL_RANGE_CHECK_UPDATE",
	"CLIENT_SCENE_OPENED",
	"CLIENT_SCENE_CLOSED",
}

local eventFrame
UF._unitEventFrames = UF._unitEventFrames or {}
local onEvent

function UF.RecomputeAnyUFEnabled()
	if UF.RecomputeRuntimeConsumerActivity then UF.RecomputeRuntimeConsumerActivity() end
	UF._anyUFEnabledCached = UF.HasUnitRuntimeConsumers and UF.HasUnitRuntimeConsumers() or false
	return UF._anyUFEnabledCached
end

local function anyUFEnabled()
	if UF._anyUFEnabledCached ~= nil then return UF._anyUFEnabledCached == true end
	return UF.HasUnitRuntimeConsumers and UF.HasUnitRuntimeConsumers() or false
end

function UF.UnitHasDirtyTexts(unit)
	local st = states[unit]
	return st and (st._healthTextDirty or st._powerTextDirty or st._secondaryPowerTextDirty or st._dataBarTextDirty) and true or false
end

function UF.UpdateDirtyTextUnits(force)
	if UF.UnitHasDirtyTexts(UNIT.PLAYER) then UF.UpdateUnitTexts(UNIT.PLAYER, force) end
	if UF.UnitHasDirtyTexts(UNIT.TARGET) then UF.UpdateUnitTexts(UNIT.TARGET, force) end
	if UF.UnitHasDirtyTexts(UNIT.TARGET_TARGET) then UF.UpdateUnitTexts(UNIT.TARGET_TARGET, force) end
	if UF.UnitHasDirtyTexts(UNIT.FOCUS) then UF.UpdateUnitTexts(UNIT.FOCUS, force) end
	if UF.UnitHasDirtyTexts(UNIT.PET) then UF.UpdateUnitTexts(UNIT.PET, force) end
	for i = 1, maxBossFrames do
		local unit = "boss" .. i
		if UF.UnitHasDirtyTexts(unit) then UF.UpdateUnitTexts(unit, force) end
	end
end

function UF.UpdateTextUnits(force)
	UF.UpdateUnitTexts(UNIT.PLAYER, force)
	UF.UpdateUnitTexts(UNIT.TARGET, force)
	UF.UpdateUnitTexts(UNIT.TARGET_TARGET, force)
	UF.UpdateUnitTexts(UNIT.FOCUS, force)
	UF.UpdateUnitTexts(UNIT.PET, force)
	local bossCfg = states.boss and states.boss.cfg
	local bossCount = UF.GetBossFrameCount(bossCfg)
	for i = 1, bossCount do
		UF.UpdateUnitTexts("boss" .. i, force)
	end
end

function UF.HasDirtyTexts()
	if UF.UnitHasDirtyTexts(UNIT.PLAYER) then return true end
	if UF.UnitHasDirtyTexts(UNIT.TARGET) then return true end
	if UF.UnitHasDirtyTexts(UNIT.TARGET_TARGET) then return true end
	if UF.UnitHasDirtyTexts(UNIT.FOCUS) then return true end
	if UF.UnitHasDirtyTexts(UNIT.PET) then return true end
	for i = 1, maxBossFrames do
		if UF.UnitHasDirtyTexts("boss" .. i) then return true end
	end
	return false
end

local function portraitEnabledFor(unit)
	local cfg = ensureDB(unit)
	if not cfg or cfg.enabled == false then return false end
	local def = defaultsFor(unit)
	local pdef = def and def.portrait or {}
	local pcfg = cfg.portrait or {}
	local enabled = pcfg.enabled
	if enabled == nil then enabled = pdef.enabled end
	return enabled == true
end

local function anyPortraitEnabled()
	if portraitEnabledFor(UNIT.PLAYER) then return true end
	if portraitEnabledFor(UNIT.TARGET) then return true end
	if portraitEnabledFor(UNIT.TARGET_TARGET) then return true end
	if portraitEnabledFor(UNIT.FOCUS) then return true end
	if portraitEnabledFor(UNIT.PET) then return true end
	if portraitEnabledFor("boss") then return true end
	return false
end

function UF._clearUnitEventFrames()
	local unitEventFrames = UF._unitEventFrames
	for i = 1, #unitEventFrames do
		local frame = unitEventFrames[i]
		if frame then
			if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
			frame:SetScript("OnEvent", nil)
			unitEventFrames[i] = nil
		end
	end
end

function UF._buildRegisteredUnitTokens()
	local tokens = {}
	local seen = {}
	local function addToken(token)
		if token and token ~= "" and not seen[token] then
			seen[token] = true
			tokens[#tokens + 1] = token
		end
	end

	local playerCfg = ensureDB(UNIT.PLAYER)
	local targetCfg = ensureDB(UNIT.TARGET)
	local totCfg = ensureDB(UNIT.TARGET_TARGET)
	local focusCfg = ensureDB(UNIT.FOCUS)
	local petCfg = ensureDB(UNIT.PET)
	local bossCfg = ensureDB("boss")

	if playerCfg.enabled then addToken(UNIT.PLAYER) end
	if targetCfg.enabled or totCfg.enabled then addToken(UNIT.TARGET) end
	if totCfg.enabled then addToken(UNIT.TARGET_TARGET) end
	if focusCfg.enabled then addToken(UNIT.FOCUS) end
	if petCfg.enabled then
		addToken(UNIT.PET)
		addToken(UNIT.PLAYER) -- UNIT_PET uses "player" as event unit
	end
	if bossCfg.enabled then
		local bossCount = UF.GetBossFrameCount(bossCfg)
		for i = 1, bossCount do
			addToken("boss" .. i)
		end
	end

	return tokens
end

local function wantsUnitHealPredictionEvent(token)
	local info = UNITS[token]
	if info and info.disableAbsorb then return false end
	local cfg = ensureDB(token)
	if not cfg or cfg.enabled == false then return false end
	return cfg.health and cfg.health.incomingHealEnabled == true
end

function UF._registerUnitScopedEvents(includePortraitEvents)
	UF._clearUnitEventFrames()

	local tokens = UF._buildRegisteredUnitTokens()
	if #tokens == 0 then return end

	local unitEventFrames = UF._unitEventFrames
	for i = 1, #tokens do
		local token = tokens[i]
		local frame = unitEventFrames[i]
		if not frame then
			frame = CreateFrame("Frame")
			unitEventFrames[i] = frame
		end
		local wantsHealPrediction = wantsUnitHealPredictionEvent(token)
		local usesNativeAuraContainers = AuraUtil.UnitUsesNativeAuraContainers(token, UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(token))
		for _, evt in ipairs(unitEvents) do
			if (evt ~= "UNIT_HEAL_PREDICTION" or wantsHealPrediction) and (evt ~= "UNIT_AURA" or token == UNIT.PLAYER or not usesNativeAuraContainers) then
				frame:RegisterUnitEvent(evt, token)
			end
		end
		if includePortraitEvents then
			for _, evt in ipairs(portraitEvents) do
				frame:RegisterUnitEvent(evt, token)
			end
		end
		frame:SetScript("OnEvent", onEvent)
	end
end

local function ensureBossFramesReady(cfg)
	cfg = cfg or ensureDB("boss")
	if not cfg.enabled then return end
	if InCombatLockdown() then
		bossInitPending = true
		return
	end
	local bossCount = UF.GetBossFrameCount(cfg)
	for i = 1, maxBossFrames do
		local unit = "boss" .. i
		if i > bossCount then
			UF._setBossFrameInactive(unit)
		else
			applyConfig(unit)
			if addon.EditModeLib and addon.EditModeLib:IsInEditMode() then
				local st = states[unit]
				if st and st.frame then
					UF.ClearEqolVisibilityDriver(st, true)
					if UnregisterStateDriver then UnregisterStateDriver(st.frame, "visibility") end
					st.frame:SetAttribute("state-visibility", nil)
					UF.ClearBossUnitWatch(st.frame, "EQOL_BossUnitWatchRegistered", true)
					UF.ClearBossUnitWatch(st.powerGroup, "EQOL_BossPowerUnitWatchRegistered", false)
					st.frame:Show()
				end
			else
				applyVisibilityDriver(unit, cfg.enabled)
			end
		end
	end
	if bossContainer then bossContainer:Show() end
	bossInitPending = nil
end

local function isBossFrameSettingEnabled()
	if not maxBossFrames or maxBossFrames <= 0 then return false end
	local cfg = ensureDB("boss")
	return cfg and cfg.enabled == true
end

local allowedEventUnit = {}

local function rebuildAllowedEventUnits()
	if wipe then
		wipe(allowedEventUnit)
	else
		for k in pairs(allowedEventUnit) do
			allowedEventUnit[k] = nil
		end
	end
	local playerCfg = ensureDB(UNIT.PLAYER)
	local targetCfg = ensureDB(UNIT.TARGET)
	local totCfg = ensureDB(UNIT.TARGET_TARGET)
	local focusCfg = ensureDB(UNIT.FOCUS)
	local petCfg = ensureDB(UNIT.PET)
	local bossCfg = ensureDB("boss")

	if playerCfg.enabled then allowedEventUnit[UNIT.PLAYER] = true end
	if targetCfg.enabled or totCfg.enabled then allowedEventUnit[UNIT.TARGET] = true end
	if totCfg.enabled then allowedEventUnit[UNIT.TARGET_TARGET] = true end
	if focusCfg.enabled then allowedEventUnit[UNIT.FOCUS] = true end
	if petCfg.enabled then allowedEventUnit[UNIT.PET] = true end
	if bossCfg.enabled then
		local bossCount = UF.GetBossFrameCount(bossCfg)
		for i = 1, bossCount do
			allowedEventUnit["boss" .. i] = true
		end
	end
end

local function stopToTTicker()
	if totTicker and totTicker.Cancel then totTicker:Cancel() end
	totTicker = nil
end

local function ensureToTTicker()
	if totTicker or not NewTicker then return end
	totTicker = NewTicker(0.2, function()
		local st = states[UNIT.TARGET_TARGET]
		local cfg = st and st.cfg
		if not cfg or not cfg.enabled then return end
		local pcfg = cfg.power or {}
		local powerEnabled = pcfg.enabled ~= false
		if not UnitExists(UNIT.TARGET_TARGET) or not st.frame or not st.frame:IsShown() then return end
		if powerEnabled then
			local powerEnum, powerToken = UnitPowerType(UNIT.TARGET_TARGET)
			if st.power and powerToken and powerToken ~= st._lastPowerToken then
				if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(powerEnum, powerToken)) end
				UFHelper.configureSpecialTexture(st.power, powerToken, (cfg.power or {}).texture, cfg.power, powerEnum)
				st._lastPowerToken = powerToken
			end
		else
			if st.power then st.power:Hide() end
		end
		updateHealth(cfg, UNIT.TARGET_TARGET)
		updatePower(cfg, UNIT.TARGET_TARGET)
	end)
end

local function reapplyPlayerFrameAfterSpecChange()
	refreshMainPower(UNIT.PLAYER)
	applyConfig(UNIT.PLAYER)
end

function UF.BuildPlayerDisplayPowerSignature(cfg)
	local def = defaultsFor(UNIT.PLAYER) or {}
	local pcfg = cfg.power or {}
	local powerDef = def.power or {}
	local secondaryCfg = cfg.secondaryPower or {}
	local secondaryDef = def.secondaryPower or {}
	local rcfg = cfg.classResource or {}
	local resourceDef = def.classResource or {}
	local trackPrimary = pcfg.enabled ~= false
	local trackSecondary = secondaryCfg.enabled ~= false
	local classKey = addon.variables and addon.variables.unitClass
	local trackClassResource = classKey and classResourceFramesByClass[classKey] and rcfg.enabled ~= false
	local tcfg = normalizeTotemFrameConfig(rcfg.totemFrame)
	local tdef = normalizeTotemFrameConfig(resourceDef.totemFrame)
	local trackTotem = classKey and totemFrameClasses[classKey] and ((tcfg.enabled == true) or (tcfg.enabled == nil and tdef.enabled == true))
	local tracked = trackPrimary or trackSecondary or trackClassResource or trackTotem
	if not tracked then
		return {
			key = "0|0|0|0|-|-",
			tracked = false,
			needsBarLayout = false,
			needsAuxLayouts = false,
			trackPrimary = false,
			trackSecondary = false,
			trackClassResource = false,
			trackTotem = false,
		}
	end
	local mainEnum, mainToken
	if trackPrimary or trackClassResource or trackTotem then
		refreshMainPower(UNIT.PLAYER)
		mainEnum, mainToken = getMainPower(UNIT.PLAYER)
	end
	local primaryEnabled = trackPrimary
	if primaryEnabled and UFHelper and UFHelper.IsPrimaryPowerAllowed then primaryEnabled = UFHelper.IsPrimaryPowerAllowed(pcfg, powerDef, mainToken, mainEnum, UNIT.PLAYER) ~= false end
	local primaryDetached = primaryEnabled and pcfg.detached == true
	local secondaryToken
	if trackSecondary and UFHelper and UFHelper.ResolveSecondaryPowerToken then
		secondaryToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
	end
	local secondaryEnabled = trackSecondary and secondaryToken ~= nil
	local secondaryDetached = secondaryEnabled and secondaryCfg.detached == true
	local secondaryEnum, secondaryResolvedToken
	if secondaryEnabled and UFHelper and UFHelper.GetPowerValuesForToken then
		local _, _, enumId, tokenId = UFHelper.GetPowerValuesForToken(UNIT.PLAYER, secondaryToken)
		secondaryEnum, secondaryResolvedToken = enumId, tokenId
	end
	if secondaryEnabled then secondaryResolvedToken = secondaryResolvedToken or secondaryToken end
	local classResourceMode
	if (trackClassResource or trackTotem) and addon.variables and addon.variables.unitClass == "DRUID" then classResourceMode = mainToken == "ENERGY" and "CAT_LIKE" or "NON_CAT" end
	local key = (primaryEnabled and "1" or "0")
		.. "|"
		.. (primaryDetached and "1" or "0")
		.. "|"
		.. (secondaryEnabled and "1" or "0")
		.. "|"
		.. (secondaryDetached and "1" or "0")
		.. "|"
		.. (secondaryToken or "-")
		.. "|"
		.. (classResourceMode or "-")
	return {
		key = key,
		tracked = true,
		needsBarLayout = trackPrimary or trackSecondary,
		needsAuxLayouts = trackClassResource or trackTotem,
		trackPrimary = trackPrimary,
		trackSecondary = trackSecondary,
		trackClassResource = trackClassResource == true,
		trackTotem = trackTotem == true,
		mainEnum = mainEnum,
		mainToken = mainToken,
		primaryEnabled = primaryEnabled,
		secondaryEnabled = secondaryEnabled,
		secondaryToken = secondaryToken,
		secondaryEnum = secondaryEnum,
		secondaryResolvedToken = secondaryResolvedToken,
	}
end

function UF.ApplyPlayerDisplayPowerVisuals(cfg, sig, st)
	st = st or states[UNIT.PLAYER]
	if not st then return end
	local pcfg = cfg.power or {}
	local secondaryCfg = cfg.secondaryPower or {}
	if st.power and sig.trackPrimary and sig.primaryEnabled and UFHelper and UFHelper.configureSpecialTexture then
		UFHelper.configureSpecialTexture(st.power, sig.mainToken, pcfg.texture, pcfg, sig.mainEnum)
	end
	if st.secondaryPower and sig.trackSecondary and sig.secondaryEnabled and UFHelper and UFHelper.configureSpecialTexture then
		UFHelper.configureSpecialTexture(st.secondaryPower, sig.secondaryResolvedToken or sig.secondaryToken, secondaryCfg.texture, secondaryCfg, sig.secondaryEnum)
	end
	if sig.trackPrimary then st._powerColorDirty = true end
	if sig.trackSecondary then st._secondaryPowerColorDirty = true end
end

function UF.ApplyPlayerDisplayPowerManagedLayouts(cfg, sig)
	if sig and sig.needsAuxLayouts == false then return end
	if ClassResourceUtil.ApplyLayout then ClassResourceUtil.ApplyLayout(cfg) end
	if TotemFrameUtil.ApplyLayout then TotemFrameUtil.ApplyLayout(cfg) end
end

function UF.SchedulePlayerDisplayPowerFlush(reason, wantFullRebuild)
	if wantFullRebuild then UF._playerDPWantFull = true end
	UF._playerDPPending = true
	if InCombatLockdown and InCombatLockdown() then
		UF._playerDisplayPowerLayoutPending = true
		return
	end
	if UF._playerDPScheduled then return end
	UF._playerDPScheduled = true
	local function runner()
		UF._playerDPScheduled = nil
		if InCombatLockdown and InCombatLockdown() then
			UF._playerDisplayPowerLayoutPending = true
			return
		end
		UF.FlushPlayerDisplayPower(reason)
	end
	RunNextFrame(runner)
end

function UF.FlushPlayerDisplayPower(reason)
	if UF._playerDPBusy then
		UF._playerDPPending = true
		return
	end
	UF._playerDPBusy = true
	UF._playerDPPending = nil
	local ok = xpcall(function()
		local cfg = ensureDB(UNIT.PLAYER)
		if not cfg or cfg.enabled == false then
			UF._playerDPWantFull = nil
			return
		end
		local st = states[UNIT.PLAYER]
		if not st or not st.frame or not st.power then UF._playerDPWantFull = true end
		if UF._playerDPWantFull then
			UF._playerDPWantFull = nil
			reapplyPlayerFrameAfterSpecChange()
			st = states[UNIT.PLAYER]
			if st then
				local rebuiltSig = UF.BuildPlayerDisplayPowerSignature(cfg)
				st._displayPowerStructureKey = rebuiltSig and rebuiltSig.key or nil
			end
			return
		end
		local sig = UF.BuildPlayerDisplayPowerSignature(cfg)
		if not sig.tracked then
			st._displayPowerStructureKey = sig.key
			return
		end
		if sig.needsBarLayout and (not st._displayPowerStructureKey or st._displayPowerStructureKey ~= sig.key) then
			applyBars(cfg, UNIT.PLAYER)
			layoutFrame(cfg, UNIT.PLAYER)
		end
		if sig.needsAuxLayouts then UF.ApplyPlayerDisplayPowerManagedLayouts(cfg, sig) end
		st._displayPowerStructureKey = sig.key
		UF.ApplyPlayerDisplayPowerVisuals(cfg, sig, st)
		if sig.trackPrimary or sig.trackSecondary then updatePower(cfg, UNIT.PLAYER) end
		UF.UpdateUnitTexts(UNIT.PLAYER, true)
	end, geterrorhandler())
	UF._playerDPBusy = nil
	if not ok then
		UF._playerDPWantFull = true
		UF.SchedulePlayerDisplayPowerFlush(reason or "DISPLAYPOWER_ERROR", true)
		return
	end
	if UF._playerDPPending then
		local wantFull = UF._playerDPWantFull == true
		UF._playerDPPending = nil
		UF.SchedulePlayerDisplayPowerFlush(reason or "DISPLAYPOWER_DRAIN", wantFull)
	end
end

function UF.ApplyPlayerDisplayPowerChange()
	local cfg = ensureDB(UNIT.PLAYER)
	if not cfg or cfg.enabled == false then return end
	local st = states[UNIT.PLAYER]
	if not st or not st.frame or not st.power then
		UF.SchedulePlayerDisplayPowerFlush("DISPLAYPOWER_MISSING", true)
		return
	end
	if UF._playerDPBusy then
		UF._playerDPPending = true
		if InCombatLockdown and InCombatLockdown() then UF._playerDisplayPowerLayoutPending = true end
		return
	end
	UF._playerDPBusy = true
	local ok = xpcall(function()
		local sig = UF.BuildPlayerDisplayPowerSignature(cfg)
		if not sig.tracked then
			st._displayPowerStructureKey = sig.key
			return
		end
		UF.ApplyPlayerDisplayPowerVisuals(cfg, sig, st)
		if sig.trackPrimary or sig.trackSecondary then updatePower(cfg, UNIT.PLAYER, false) end
		if st._displayPowerStructureKey ~= sig.key then UF.SchedulePlayerDisplayPowerFlush("UNIT_DISPLAYPOWER", false) end
	end, geterrorhandler())
	UF._playerDPBusy = nil
	if not ok then
		UF._playerDPWantFull = true
		UF.SchedulePlayerDisplayPowerFlush("DISPLAYPOWER_IMMEDIATE_ERROR", true)
		return
	end
	if UF._playerDPPending then
		local wantFull = UF._playerDPWantFull == true
		UF._playerDPPending = nil
		UF.SchedulePlayerDisplayPowerFlush("UNIT_DISPLAYPOWER_DRAIN", wantFull)
	end
end

local function updateTargetTargetFrame(cfg, forceApply)
	cfg = cfg or ensureDB(UNIT.TARGET_TARGET)
	UF._targetTargetEnabled = cfg.enabled == true
	local st = states[UNIT.TARGET_TARGET]
	if not cfg.enabled then
		stopToTTicker()
		if st then
			if st.barGroup then st.barGroup:Hide() end
			if st.status then st.status:Hide() end
			UF.DataBar.Hide(st)
		end
		updatePortrait(cfg, UNIT.TARGET_TARGET)
		applyVisibilityRules(UNIT.TARGET_TARGET)
		return
	end
	if forceApply or not st or not st.frame then
		applyConfig(UNIT.TARGET_TARGET)
		st = states[UNIT.TARGET_TARGET]
	end
	if st then
		st.cfg = st.cfg or cfg
		UF.InvalidateHealthIdentityState(st)
	end
	local lHealth = UnitHealth("target")
	if UnitExists("target") and UnitExists(UNIT.TARGET_TARGET) and (issecretvalue and issecretvalue(lHealth) or lHealth > 0) then
		if st then
			if st.barGroup then st.barGroup:Show() end
			if st.status then st.status:Show() end
			UF.DataBar.Update(cfg, UNIT.TARGET_TARGET)
			local pcfg = cfg.power or {}
			local powerEnabled = pcfg.enabled ~= false
			updateNameAndLevel(cfg, UNIT.TARGET_TARGET)
			updateHealth(cfg, UNIT.TARGET_TARGET)
			if st.power and powerEnabled then
				local powerEnum, powerToken = getMainPower(UNIT.TARGET_TARGET)
				if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(powerEnum, powerToken)) end
				UFHelper.configureSpecialTexture(st.power, powerToken, (cfg.power or {}).texture, cfg.power, powerEnum)
				st._lastPowerToken = powerToken
			elseif st.power then
				st.power:Hide()
			end
			updatePower(cfg, UNIT.TARGET_TARGET)
			checkRaidTargetIcon(UNIT.TARGET_TARGET, st)
		end
	else
		if st then
			if st.barGroup then st.barGroup:Hide() end
			if st.status then st.status:Hide() end
			UF.DataBar.Hide(st)
		end
	end
	checkRaidTargetIcon(UNIT.TARGET_TARGET, st)
	updateUnitStatusIndicator(cfg, UNIT.TARGET_TARGET)
	updatePortrait(cfg, UNIT.TARGET_TARGET)
	UFHelper.updateHighlight(st, UNIT.TARGET_TARGET, UNIT.PLAYER)
	ensureToTTicker()
	applyVisibilityRules(UNIT.TARGET_TARGET)
end

local function updateFocusFrame(cfg, forceApply)
	cfg = cfg or ensureDB(UNIT.FOCUS)
	local st = states[UNIT.FOCUS]
	AuraUtil.HideSingleDispelIndicator(UNIT.FOCUS)
	if not cfg.enabled then
		if applyFrameRuleOverride then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, false) end
		if st then
			if st.barGroup then st.barGroup:Hide() end
			if st.status then st.status:Hide() end
			UF.DataBar.Hide(st)
			if st.auraContainer then AuraUtil.hideAuraContainers(st) end
		end
		AuraUtil.resetTargetAuras(UNIT.FOCUS)
		AuraUtil.HideSingleDispelIndicator(UNIT.FOCUS)
		updatePortrait(cfg, UNIT.FOCUS)
		applyVisibilityRules(UNIT.FOCUS)
		return
	end
	if applyFrameRuleOverride then applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, true) end
	if forceApply or not st or not st.frame then
		applyConfig(UNIT.FOCUS)
		st = states[UNIT.FOCUS]
	end
	if st then st.cfg = st.cfg or cfg end
	if UnitExists(UNIT.FOCUS) then
		if st then
			if st.barGroup then st.barGroup:Show() end
			if st.status then st.status:Show() end
			UF.DataBar.Update(cfg, UNIT.FOCUS)
			local pcfg = cfg.power or {}
			local powerEnabled = pcfg.enabled ~= false
			updateNameAndLevel(cfg, UNIT.FOCUS)
			updateHealth(cfg, UNIT.FOCUS)
			if st.power and powerEnabled then
				local powerEnum, powerToken = getMainPower(UNIT.FOCUS)
				if st.power.SetStatusBarDesaturated then st.power:SetStatusBarDesaturated(UFHelper.isPowerDesaturated(powerEnum, powerToken)) end
				UFHelper.configureSpecialTexture(st.power, powerToken, (cfg.power or {}).texture, cfg.power, powerEnum)
				st._lastPowerToken = powerToken
			elseif st.power then
				st.power:Hide()
			end
			updatePower(cfg, UNIT.FOCUS)
			if st.castBar then setCastInfoFromUnit(UNIT.FOCUS) end
			checkRaidTargetIcon(UNIT.FOCUS, st)
			if st.auraContainer then AuraUtil.fullScanTargetAuras(UNIT.FOCUS) end
		end
	else
		if st then
			if st.barGroup then st.barGroup:Hide() end
			if st.status then st.status:Hide() end
			UF.DataBar.Hide(st)
			if st.castBar then stopCast(UNIT.FOCUS) end
			if st.auraContainer then AuraUtil.hideAuraContainers(st) end
		end
		AuraUtil.resetTargetAuras(UNIT.FOCUS)
		AuraUtil.HideSingleDispelIndicator(UNIT.FOCUS)
	end
	checkRaidTargetIcon(UNIT.FOCUS, st)
	UFHelper.updateLeaderIndicator(st, UNIT.FOCUS, cfg, defaultsFor(UNIT.FOCUS), not forceApply)
	UFHelper.updatePvPIndicator(st, UNIT.FOCUS, cfg, defaultsFor(UNIT.FOCUS), not forceApply)
	UFHelper.updateRoleIndicator(st, UNIT.FOCUS, cfg, defaultsFor(UNIT.FOCUS), not forceApply)
	updateUnitStatusIndicator(cfg, UNIT.FOCUS)
	updateCombatIndicator(cfg, UNIT.FOCUS)
	updatePortrait(cfg, UNIT.FOCUS)
	UFHelper.updateHighlight(st, UNIT.FOCUS, UNIT.PLAYER)
	applyVisibilityRules(UNIT.FOCUS)
end

local function getCfg(unit)
	local st = states[unit]
	if st and st.cfg then return st.cfg end
	return ensureDB(unit)
end

function UF.UpdateUnitTexts(unit, force)
	local st = states[unit]
	if not st then return end
	if not force and not (st._healthTextDirty or st._powerTextDirty or st._secondaryPowerTextDirty or st._dataBarTextDirty) then return end

	local cfg = st.cfg or ensureDB(unit)
	if not cfg or cfg.enabled == false then
		st._healthTextDirty = nil
		st._powerTextDirty = nil
		st._secondaryPowerTextDirty = nil
		st._dataBarTextDirty = nil
		st._healthTextValuesReady = nil
		st._powerTextValuesReady = nil
		st._secondaryPowerTextValuesReady = nil
		UF.DataBar.ClearTexts(st)
		return
	end

	local inEdit = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode()
	if inEdit and isBossUnit(unit) then
		local idx = tonumber(type(unit) == "string" and unit:match("^boss(%d+)$") or nil)
		if idx then
			applyBossEditSample(idx, cfg)
			st._healthTextDirty = nil
			st._powerTextDirty = nil
			st._secondaryPowerTextDirty = nil
			st._dataBarTextDirty = nil
			return
		end
	end
	local exists = UnitExists and UnitExists(unit)
	if not exists and not inEdit then
		if st._healthTextGroupClearer then st._healthTextGroupClearer() end
		if st._powerTextGroupClearer then st._powerTextGroupClearer() end
		if st._secondaryPowerTextGroupClearer then st._secondaryPowerTextGroupClearer() end
		UF.DataBar.ClearTexts(st)
		st._healthTextDirty = nil
		st._powerTextDirty = nil
		st._secondaryPowerTextDirty = nil
		st._dataBarTextDirty = nil
		return
	end

	local def = st.def or defaultsFor(unit) or {}
	local cachedHealthCurrent, cachedHealthMaximum
	if st._healthTextValuesReady then
		cachedHealthCurrent = st._healthTextCurrent
		cachedHealthMaximum = st._healthTextMaximum
	end
	local healthPercentValue, healthPercentReady

	if st._dataBarTextDirty and (st.dataBarTextLeft or st.dataBarTextCenter or st.dataBarTextRight) then
		if not UF.DataBar.IsEnabled(cfg, def) then
			UF.DataBar.ClearTexts(st)
		else
			local dcfg = cfg.dataBar or {}
			local ddef = def.dataBar or {}
			local leftMode = st._dataBarTextLeftMode or dcfg.textLeft or ddef.textLeft or "NAME"
			local centerMode = st._dataBarTextCenterMode or dcfg.textCenter or ddef.textCenter or "CURMAX"
			local rightMode = st._dataBarTextRightMode or dcfg.textRight or ddef.textRight or "PERCENT"
			local cur = cachedHealthCurrent
			local maxv = cachedHealthMaximum
			if not st._healthTextValuesReady then
				cur = (UnitHealth and UnitHealth(unit)) or 0
				maxv = (UnitHealthMax and UnitHealthMax(unit)) or 0
				cachedHealthCurrent, cachedHealthMaximum = cur, maxv
			end
			local percentVal
			local usesDataBarPercent = st._dataBarTextUsesPercent
			if usesDataBarPercent == nil then
				usesDataBarPercent = UFHelper.textModeUsesPercent(leftMode) or UFHelper.textModeUsesPercent(centerMode) or UFHelper.textModeUsesPercent(rightMode)
			end
			if usesDataBarPercent == true then
				local calc = UF.RefreshHealPredictionCalculator(st, unit)
				percentVal = getHealthPercent(unit, cur, maxv, calc)
				healthPercentValue, healthPercentReady = percentVal, true
			end
			if st.dataBarTextLeft then st.dataBarTextLeft:SetText(UF.DataBar.GetText(leftMode, unit, cfg, def, cur, maxv, percentVal)) end
			if st.dataBarTextCenter then st.dataBarTextCenter:SetText(UF.DataBar.GetText(centerMode, unit, cfg, def, cur, maxv, percentVal)) end
			if st.dataBarTextRight then st.dataBarTextRight:SetText(UF.DataBar.GetText(rightMode, unit, cfg, def, cur, maxv, percentVal)) end
		end
		st._dataBarTextDirty = nil
	end

	if st._healthTextDirty and st._healthTextGroupWriter then
		local cur = cachedHealthCurrent
		local maxv = cachedHealthMaximum
		if not st._healthTextValuesReady then
			cur = UnitHealth(unit)
			maxv = UnitHealthMax(unit)
			cachedHealthCurrent, cachedHealthMaximum = cur, maxv
		end
		local useStatusText = shouldUseUnitStatusText(cfg, unit, st, def)
		local lifeStatusTag
		local isDead = UnitIsDead and UnitIsDead(unit)
		if issecretvalue and issecretvalue(isDead) then isDead = nil end
		if isDead then
			lifeStatusTag = DEAD or "Dead"
		else
			local isGhost = UnitIsGhost and UnitIsGhost(unit)
			if issecretvalue and issecretvalue(isGhost) then isGhost = nil end
			if isGhost then lifeStatusTag = GHOST or "Ghost" end
		end
		if lifeStatusTag and not useStatusText then
			st._healthTextLifeWriter(lifeStatusTag)
		elseif lifeStatusTag then
			st._healthTextGroupClearer()
		else
			local percentVal
			if st._healthTextUsesPercent then
				if healthPercentReady then
					percentVal = healthPercentValue
				else
					local calc = UF.RefreshHealPredictionCalculator(st, unit)
					percentVal = getHealthPercent(unit, cur, maxv, calc)
					healthPercentValue, healthPercentReady = percentVal, true
				end
			end

			local levelText
			local absorbTextAmount
			if st._healthTextUsesLevel == true then
				levelText = UFHelper.getUnitLevelText(unit, nil, UF.ShouldHideClassificationText(cfg, unit))
			end
			if st._healthTextUsesAbsorb == true then
				absorbTextAmount = st._healthTextAbsorbAmount
				if absorbTextAmount == nil then
					local calc = UF.RefreshHealPredictionCalculator(st, unit)
					absorbTextAmount = UF.CacheHealthTextAbsorbAmount(st, unit, maxv, st._absorbAmount, calc)
				end
			end

			st._healthTextGroupWriter(cur, maxv, percentVal, levelText, absorbTextAmount)
		end

		st._healthTextDirty = nil
	end
	if st._healthTextDirty and not st._healthTextGroupWriter then st._healthTextDirty = nil end
	st._healthTextValuesReady = nil

	if st._powerTextDirty and st._powerTextGroupWriter then
		local pcfg = cfg.power or {}
		local defP = def.power or {}
		if unit == UNIT.PLAYER then refreshMainPower(unit) end
		local powerEnum, powerToken = st._lastPowerEnum, st._lastPowerToken
		if powerEnum == nil then powerEnum, powerToken = getMainPower(unit) end
		local powerAllowed = true
		if unit == UNIT.PLAYER and UFHelper and UFHelper.IsPrimaryPowerAllowed then powerAllowed = UFHelper.IsPrimaryPowerAllowed(pcfg, defP, powerToken, powerEnum, unit) ~= false end
		if pcfg.enabled == false or not powerAllowed then
			st._powerTextGroupClearer()
			st._powerTextDirty = nil
			st._powerTextValuesReady = nil
			return
		end

		powerEnum = powerEnum or 0
		local cur, maxv
		if st._powerTextValuesReady and st._powerTextEnum == powerEnum then
			cur, maxv = st._powerTextCurrent, st._powerTextMaximum
		else
			cur = UnitPower(unit, powerEnum)
			maxv = UnitPowerMax(unit, powerEnum)
		end
		local percentVal
		if addon.variables and addon.variables.isMidnight then
			percentVal = getPowerPercent(unit, powerEnum, cur, maxv)
		elseif not issecretvalue or (not issecretvalue(cur) and not issecretvalue(maxv)) then
			percentVal = getPowerPercent(unit, powerEnum, cur, maxv)
		end

		local maxZero = false
		if not (issecretvalue and issecretvalue(maxv)) then maxZero = (maxv == 0) end
		local levelText
		if st._powerTextUsesLevel == true then
			levelText = UFHelper.getUnitLevelText(unit, nil, UF.ShouldHideClassificationText(cfg, unit))
		end

		if maxZero then
			st._powerTextGroupClearer()
		else
			st._powerTextGroupWriter(cur, maxv, percentVal, levelText)
		end

		st._powerTextDirty = nil
	end
	if st._powerTextDirty and not st._powerTextGroupWriter then st._powerTextDirty = nil end
	st._powerTextValuesReady = nil

	if st._secondaryPowerTextDirty and st._secondaryPowerTextGroupWriter then
		local secondaryCfg = cfg.secondaryPower or {}
		local secondaryDef = def.secondaryPower or {}
		local secondaryToken
		if unit == UNIT.PLAYER and UFHelper and UFHelper.ResolveSecondaryPowerToken then
			secondaryToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
		end
		if secondaryCfg.enabled == false or not secondaryToken then
			st._secondaryPowerTextGroupClearer()
			st._secondaryPowerTextDirty = nil
			st._secondaryPowerTextValuesReady = nil
			return
		end

		local cur, maxv, enumId, resolvedToken
		if st._secondaryPowerTextValuesReady then
			cur, maxv = st._secondaryPowerTextCurrent, st._secondaryPowerTextMaximum
			enumId, resolvedToken = st._secondaryPowerTextEnum, st._secondaryPowerTextResolvedToken
		elseif UFHelper and UFHelper.GetPowerValuesForToken then
			cur, maxv, enumId, resolvedToken = UFHelper.GetPowerValuesForToken(unit, secondaryToken)
		end
		cur = cur or 0
		maxv = maxv or 0
		local percentVal
		if addon.variables and addon.variables.isMidnight then
			if UFHelper and UFHelper.GetPowerPercentByToken then
				percentVal = UFHelper.GetPowerPercentByToken(unit, resolvedToken or secondaryToken, cur, maxv)
			else
				percentVal = getPowerPercent(unit, enumId or 0, cur, maxv)
			end
		elseif not issecretvalue or (not issecretvalue(cur) and not issecretvalue(maxv)) then
			if UFHelper and UFHelper.GetPowerPercentByToken then
				percentVal = UFHelper.GetPowerPercentByToken(unit, resolvedToken or secondaryToken, cur, maxv)
			else
				percentVal = getPowerPercent(unit, enumId or 0, cur, maxv)
			end
		end

		local maxZero = false
		if not (issecretvalue and issecretvalue(maxv)) then maxZero = (maxv == 0) end
		local levelText
		if st._secondaryPowerTextUsesLevel == true then
			levelText = UFHelper.getUnitLevelText(unit, nil, UF.ShouldHideClassificationText(cfg, unit))
		end

		if maxZero then
			st._secondaryPowerTextGroupClearer()
		else
			st._secondaryPowerTextGroupWriter(cur, maxv, percentVal, levelText)
		end

		st._secondaryPowerTextDirty = nil
	end
	if st._secondaryPowerTextDirty and not st._secondaryPowerTextGroupWriter then st._secondaryPowerTextDirty = nil end
	st._secondaryPowerTextValuesReady = nil
end

function UF.UpdateAllTexts(force)
	if force then
		UF.UpdateTextUnits(true)
		return
	end
	if not UF.HasDirtyTexts() then return end
	UF.UpdateDirtyTextUnits(false)
end

function UF.ScheduleTextUpdate()
	if UF._textUpdateScheduled then return end
	UF._textUpdateScheduled = true
	local function run()
		UF._textUpdateScheduled = nil
		if not anyUFEnabled() then return end
		UF._lastTextUpdateAt = GetTime and GetTime() or 0
		UF.UpdateAllTexts(false)
	end
	local now = GetTime and GetTime() or 0
	local delay = TEXT_UPDATE_INTERVAL - (now - (UF._lastTextUpdateAt or 0))
	if delay <= 0 and RunNextFrame then
		RunNextFrame(run)
	elseif After then
		After(delay > 0 and delay or 0, run)
	else
		run()
	end
end

function UF.CancelTextUpdate()
	UF._textUpdateScheduled = nil
end

function UF.UpdateAllPvPIndicators()
	UFHelper.updatePvPIndicator(states[UNIT.PLAYER], UNIT.PLAYER, getCfg(UNIT.PLAYER), defaultsFor(UNIT.PLAYER), false)
	UFHelper.updatePvPIndicator(states[UNIT.TARGET], UNIT.TARGET, getCfg(UNIT.TARGET), defaultsFor(UNIT.TARGET), false)
	UFHelper.updatePvPIndicator(states[UNIT.FOCUS], UNIT.FOCUS, getCfg(UNIT.FOCUS), defaultsFor(UNIT.FOCUS), false)
end

function UF.UpdateAllRoleIndicators(skipDisabled)
	UFHelper.updateRoleIndicator(states[UNIT.PLAYER], UNIT.PLAYER, getCfg(UNIT.PLAYER), defaultsFor(UNIT.PLAYER), skipDisabled)
	UFHelper.updateRoleIndicator(states[UNIT.TARGET], UNIT.TARGET, getCfg(UNIT.TARGET), defaultsFor(UNIT.TARGET), skipDisabled)
	UFHelper.updateRoleIndicator(states[UNIT.FOCUS], UNIT.FOCUS, getCfg(UNIT.FOCUS), defaultsFor(UNIT.FOCUS), skipDisabled)
end

function UF.UpdateAllLeaderIndicators(skipDisabled)
	UFHelper.updateLeaderIndicator(states[UNIT.PLAYER], UNIT.PLAYER, getCfg(UNIT.PLAYER), defaultsFor(UNIT.PLAYER), skipDisabled)
	UFHelper.updateLeaderIndicator(states[UNIT.TARGET], UNIT.TARGET, getCfg(UNIT.TARGET), defaultsFor(UNIT.TARGET), skipDisabled)
	UFHelper.updateLeaderIndicator(states[UNIT.FOCUS], UNIT.FOCUS, getCfg(UNIT.FOCUS), defaultsFor(UNIT.FOCUS), skipDisabled)
end

onEvent = function(self, event, unit, ...)
	local arg1 = ...
	if
		(unitEventsMap[event] or portraitEventsMap[event])
		and unit
		and not allowedEventUnit[unit]
		and event ~= "UNIT_THREAT_SITUATION_UPDATE"
		and event ~= "UNIT_THREAT_LIST_UPDATE"
		and event ~= "UNIT_PET"
	then
		return
	end
	if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
	if (unitEventsMap[event] or portraitEventsMap[event]) and unit and isBossUnit(unit) and not isBossFrameSettingEnabled() then return end
	if event == "SPELL_RANGE_CHECK_UPDATE" then
		local spellIdentifier = unit
		local isInRange, checksRange = ...
		if UFHelper and UFHelper.RangeFadeUpdateFromEvent then UFHelper.RangeFadeUpdateFromEvent(spellIdentifier, isInRange, checksRange) end
		return
	end
	if
		event == "PLAYER_SPECIALIZATION_CHANGED"
		or event == "PLAYER_TALENT_UPDATE"
		or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
		or event == "ACTIVE_TALENT_GROUP_CHANGED"
		or event == "TRAIT_CONFIG_UPDATED"
	then
		UF.ScheduleRangeFadeRefresh(true)
		if
			event == "PLAYER_SPECIALIZATION_CHANGED"
			or event == "PLAYER_TALENT_UPDATE"
			or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
			or event == "ACTIVE_TALENT_GROUP_CHANGED"
			or event == "TRAIT_CONFIG_UPDATED"
		then
			reapplyPlayerFrameAfterSpecChange()
			RunNextFrame(reapplyPlayerFrameAfterSpecChange)
		end
		return
	end
	if event == "PLAYER_LOGIN" then
		updateNameAndLevel(getCfg(UNIT.PLAYER), UNIT.PLAYER)
	elseif event == "PLAYER_ENTERING_WORLD" then
		local playerCfg = getCfg(UNIT.PLAYER)
		local targetCfg = getCfg(UNIT.TARGET)
		local totCfg = getCfg(UNIT.TARGET_TARGET)
		local petCfg = getCfg(UNIT.PET)
		local focusCfg = getCfg(UNIT.FOCUS)
		local bossCfg = getCfg("boss")
		UF.ScheduleRangeFadeRefresh(true)
		refreshMainPower(UNIT.PLAYER)
		applyConfig("player")
		refreshNameAndLevelSoon(UNIT.PLAYER)
		applyConfig("target")
		updateTargetTargetFrame(totCfg, true)
		if focusCfg.enabled then updateFocusFrame(focusCfg, true) end
		if petCfg.enabled then applyConfig(UNIT.PET) end
		updateCombatIndicator(playerCfg, UNIT.PLAYER)
		updateRestingIndicator(playerCfg)
		updateUnitStatusIndicator(playerCfg, UNIT.PLAYER)
		updateUnitStatusIndicator(targetCfg, UNIT.TARGET)
		updateUnitStatusIndicator(totCfg, UNIT.TARGET_TARGET)
		updateUnitStatusIndicator(focusCfg, UNIT.FOCUS)
		updateUnitStatusIndicator(petCfg, UNIT.PET)
		UF.UpdateAllPvPIndicators()
		UF.UpdateAllRoleIndicators(false)
		UF.UpdateAllLeaderIndicators(false)
		UFHelper.updateAllHighlights(states, UNIT, UF.GetBossFrameCount(bossCfg))
		updateAllRaidTargetIcons()
		if bossCfg.enabled then
			updateBossFrames(true)
		else
			hideBossFrames()
		end
	elseif event == "PLAYER_DEAD" then
		local playerCfg = getCfg(UNIT.PLAYER)
		local interpolation = getSmoothInterpolation(playerCfg, defaultsFor(UNIT.PLAYER))
		if states.player and states.player.health then states.player.health:SetValue(0, interpolation) end
		updateHealth(playerCfg, UNIT.PLAYER)
		applyVisibilityRulesAll()
	elseif event == "PLAYER_ALIVE" then
		local playerCfg = getCfg(UNIT.PLAYER)
		refreshMainPower(UNIT.PLAYER)
		updateHealth(playerCfg, UNIT.PLAYER)
		updatePower(playerCfg, UNIT.PLAYER)
		updateCombatIndicator(playerCfg, UNIT.PLAYER)
		updateRestingIndicator(playerCfg)
		updateUnitStatusIndicator(playerCfg, UNIT.PLAYER)
		applyVisibilityRulesAll()
	elseif event == "PLAYER_UNGHOST" then
		applyVisibilityRulesAll()
	elseif event == "PLAYER_FLAGS_CHANGED" then
		if unit and allowedEventUnit[unit] then
			updateUnitStatusIndicator(getCfg(unit), unit)
		else
			updateUnitStatusIndicator(getCfg(UNIT.PLAYER), UNIT.PLAYER)
		end
		UFHelper.updatePvPIndicator(states[UNIT.PLAYER], UNIT.PLAYER, getCfg(UNIT.PLAYER), defaultsFor(UNIT.PLAYER), true)
		UFHelper.updateLeaderIndicator(states[UNIT.PLAYER], UNIT.PLAYER, getCfg(UNIT.PLAYER), defaultsFor(UNIT.PLAYER), true)
		if allowedEventUnit[UNIT.TARGET_TARGET] then updateUnitStatusIndicator(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		applyVisibilityRulesAll()
	elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
		local playerCfg = getCfg(UNIT.PLAYER)
		updateCombatIndicator(playerCfg, UNIT.PLAYER)
		if UFHelper and UFHelper.updateAllHighlights then UFHelper.updateAllHighlights(states, UNIT, UF.GetBossFrameCount()) end
		if event == "PLAYER_REGEN_ENABLED" then
			local pendingDynamicAnchors = UF._pendingDynamicAnchorUnits
			UF._pendingDynamicAnchorUnits = nil
			for pendingUnit in pairs(pendingDynamicAnchors or {}) do
				if pendingUnit == "boss" then
					updateBossFrames(true)
				else
					UF.RefreshUnit(pendingUnit)
				end
			end
			if not UF._auraContainerDeferredLoadHandled and addon.AuraCompat and addon.AuraCompat._auraContainerLoadDeferred and addon.AuraCompat:HasAuraContainerSupport() then
				UF._auraContainerDeferredLoadHandled = true
				UF.Refresh()
			end
			if bossLayoutDirty then layoutBossFrames() end
			if bossHidePending then hideBossFrames(true) end
			if bossShowPending or bossInitPending then updateBossFrames(true) end
			bossLayoutDirty, bossHidePending, bossShowPending, bossInitPending = nil, nil, nil, nil
			if UF._playerDisplayPowerLayoutPending or UF._playerDPPending or UF._playerDPWantFull then
				UF._playerDisplayPowerLayoutPending = nil
				UF.SchedulePlayerDisplayPowerFlush("PLAYER_REGEN_ENABLED", UF._playerDPWantFull == true)
			end
			if UF._pendingProfileApply and UFProfileManager and UFProfileManager.ApplyCurrent then UFProfileManager.ApplyCurrent(UF._pendingProfileApplyReason or "PLAYER_REGEN_ENABLED") end
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		local targetCfg = getCfg(UNIT.TARGET)
		local totEnabled = UF._targetTargetEnabled == true
		local totCfg = totEnabled and getCfg(UNIT.TARGET_TARGET) or nil
		local unitToken = UNIT.TARGET
		local st = states[unitToken]
		if st and st._rangeFadeEnabledCfg == true then
			if UFHelper and UFHelper.RangeFadeRefreshTargetState then
				UFHelper.RangeFadeRefreshTargetState(unitToken)
			elseif UFHelper and UFHelper.RangeFadeReset then
				UFHelper.RangeFadeReset()
			end
		end
		if st and st._identityDispelEnabled and not AuraUtil.ShouldUseManagedDispelBorder() then AuraUtil.HideSingleDispelIndicator(unitToken) end
		if not st or not st.frame then
			AuraUtil.resetTargetAuras()
			AuraUtil.updateTargetAuraIcons()
			if totEnabled then updateTargetTargetFrame(totCfg) end
			if UF._targetHighlightActive and UFHelper and UFHelper.updateTargetHighlights then UFHelper.updateTargetHighlights(states, UNIT, maxBossFrames) end
			return
		end
		UF.InvalidateHealthIdentityState(st)
		if UnitExists(unitToken) then
			if not C_PlayerInteractionManager.IsReplacingUnit() then
				if UnitIsEnemy(unitToken, "player") then
					PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT)
				elseif UnitIsFriend("player", unitToken) then
					PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT)
				else
					PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT)
				end
			end

			local powerEnum, powerToken
			if st._identityPowerEnabled then powerEnum, powerToken = refreshMainPower(unitToken) end
			if st._identityAurasEnabled then AuraUtil.fullScanTargetAuras() end
			if st._identityDispelEnabled then AuraUtil.UpdateSingleDispelIndicator(unitToken, false, true) end
			local powerEnabled = st._identityPowerEnabled == true
			updateNameAndLevel(targetCfg, unitToken, nil, true)
			updateHealth(targetCfg, unitToken, true)
			if st.power and powerEnabled then
				UFHelper.configureSpecialTexture(st.power, powerToken, (targetCfg.power or {}).texture, targetCfg.power, powerEnum)
			elseif st.power then
				st.power:Hide()
			end
			if powerEnabled then updatePower(targetCfg, unitToken, nil, true, powerEnum, powerToken) end
			st.barGroup:Show()
			st.status:Show()
			if st._identityDataBarEnabled then UF.DataBar.Update(targetCfg, unitToken, true) end
			UF.UpdateUnitTexts(unitToken, false)
			if st._identityCastEnabled then setCastInfoFromUnit(unitToken) end
		else
			AuraUtil.resetTargetAuras()
			AuraUtil.updateTargetAuraIcons()
			if st._identityDispelEnabled then AuraUtil.HideSingleDispelIndicator(unitToken) end
			st.barGroup:Hide()
			st.status:Hide()
			UF.DataBar.Hide(st)
			if st._identityCastEnabled then stopCast(unitToken) end
		end
		if st._identityRaidIconEnabled then checkRaidTargetIcon(unitToken, st, true) end
		if st._portraitEnabled == true then updatePortrait(targetCfg, unitToken) end
		if totEnabled then updateTargetTargetFrame(totCfg) end
		if st._identityUnitStatusEnabled then updateUnitStatusIndicator(targetCfg, UNIT.TARGET) end
		if st._identityCombatIndicatorEnabled then updateCombatIndicator(targetCfg, UNIT.TARGET) end
		local targetDef = st.def or defaultsFor(UNIT.TARGET)
		if st._identityLeaderIndicatorEnabled then UFHelper.updateLeaderIndicator(st, UNIT.TARGET, targetCfg, targetDef, true) end
		if st._identityPvPIndicatorEnabled then UFHelper.updatePvPIndicator(st, UNIT.TARGET, targetCfg, targetDef, true) end
		if st._identityRoleIndicatorEnabled then UFHelper.updateRoleIndicator(st, UNIT.TARGET, targetCfg, targetDef, true) end
		if totEnabled then updateUnitStatusIndicator(totCfg, UNIT.TARGET_TARGET) end
		if UF._targetHighlightActive and UFHelper and UFHelper.updateTargetHighlights then UFHelper.updateTargetHighlights(states, UNIT, maxBossFrames) end
		AuraUtil.RefreshHealerBuffPlacementUnit(UNIT.TARGET)
	elseif event == "UNIT_AURA" and (unit == "target" or unit == UNIT.PLAYER or unit == UNIT.FOCUS or isBossUnit(unit)) then
		local cfg = getCfg(unit)
		if not cfg or cfg.enabled == false then return end
		local allowSample = UF.IsEditModeSampleEnabled and UF.IsEditModeSampleEnabled(unit)
		local inEditMode = addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() == true
		if inEditMode and (unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit)) then
			AuraUtil.fullScanTargetAuras(unit)
			return
		end
		local def = defaultsFor(unit)
		if unit == UNIT.PLAYER then
			local secondaryCfg = cfg.secondaryPower or {}
			local secondaryDef = (def and def.secondaryPower) or {}
			if secondaryCfg.enabled ~= false and UFHelper and UFHelper.ResolveSecondaryPowerToken then
				local token = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
				if token and UFHelper.IsSecondaryPowerTokenSpecial and UFHelper.IsSecondaryPowerTokenSpecial(token) then updatePower(cfg, unit) end
			end
		end
		if AuraUtil.UnitUsesNativeAuraContainers(unit, allowSample) then return end
		local ac = cfg.auraIcons or (def and def.auraIcons) or defaults.target.auraIcons or { size = 24, padding = 2, max = 16, showCooldown = true }
		local auraRuntime = AuraUtil.getUnitSingleAuraRuntimeConfig(unit, ac, def and def.auraIcons)
		if not auraRuntime.enabled then
			AuraUtil.UpdateSingleDispelIndicator(unit, allowSample)
			return
		end
		local buffAuras = auraRuntime.buff
		local debuffAuras = auraRuntime.debuff
		local showBuffs = auraRuntime.showBuffs
		local showDebuffs = auraRuntime.showDebuffs
		if not showBuffs and not showDebuffs then
			AuraUtil.resetTargetAuras(unit)
			AuraUtil.updateTargetAuraIcons(nil, unit)
			return
		end
		if allowSample then
			local st = states[unit]
			if st and st._sampleAurasActive then return end
			AuraUtil.fullScanTargetAuras(unit)
			return
		end
		if not AuraUtil.canReadAuraData() then
			AuraUtil.resetTargetAuras(unit)
			AuraUtil.updateTargetAuraIcons(nil, unit)
			AuraUtil.UpdateSingleDispelIndicator(unit, false)
			return
		end
		local helpfulFilter, harmfulFilter = AuraUtil.getUnitAuraFilters(unit, auraRuntime)
		local eventInfo = arg1
		if not UnitExists(unit) then
			AuraUtil.resetTargetAuras(unit)
			AuraUtil.updateTargetAuraIcons(nil, unit)
			return
		end
		if not eventInfo or eventInfo.isFullUpdate then
			AuraUtil.fullScanTargetAuras(unit)
			return
		end
		local st = states[unit]
		if not st or not st.auraContainer then return end
		local buffCache = AuraUtil.getAuraKindCache(unit, "buff")
		local debuffCache = AuraUtil.getAuraKindCache(unit, "debuff")
		if not buffCache or not debuffCache then return end
		local buffLimit = (buffAuras.max or 0) + 1
		local debuffLimit = (debuffAuras.max or 0) + 1
		local touchBuff
		local touchDebuff
		local touchDispel
		local trackDispel = AuraUtil.CanUnitShowPlayerDispel(unit, false)
		if eventInfo.addedAuras then
			for _, aura in ipairs(eventInfo.addedAuras) do
				local isDebuffAura = aura and showDebuffs and AuraUtil.isAuraFilteredIn(unit, aura, harmfulFilter)
				if trackDispel and aura and not isDebuffAura and AuraUtil.isAuraFilteredIn(unit, aura, "HARMFUL|INCLUDE_NAME_PLATE_ONLY|RAID_PLAYER_DISPELLABLE") then
					touchDispel = true
				end
				local isBuffAura = aura and showBuffs and not isDebuffAura and AuraUtil.isAuraFilteredIn(unit, aura, helpfulFilter)
				local shouldHide = false
				if aura then
					local hidePermanent = (isDebuffAura and debuffAuras.hidePermanentAuras == true) or (isBuffAura and buffAuras.hidePermanentAuras == true)
					shouldHide = (hidePermanent and AuraUtil.isPermanentAura(aura, unit))
						or (UF.GlobalAuraIgnore and UF.GlobalAuraIgnore.ShouldIgnoreAura and UF.GlobalAuraIgnore.ShouldIgnoreAura(unit, aura))
				end
				if aura and shouldHide then
					local buffIdx, debuffIdx = AuraUtil.removeTargetAuraFromCaches(unit, aura.auraInstanceID)
					if buffIdx and buffIdx <= buffLimit then touchBuff = true end
					if debuffIdx and debuffIdx <= debuffLimit then touchDebuff = true end
				elseif aura and showDebuffs and isDebuffAura then
					local oldBuffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "buff", aura.auraInstanceID)
					local _, idx = AuraUtil.cacheTargetAura(aura, unit, "debuff")
					if oldBuffIdx and oldBuffIdx <= buffLimit then touchBuff = true end
					if idx and idx <= debuffLimit then touchDebuff = true end
					if trackDispel then touchDispel = true end
				elseif aura and showBuffs and isBuffAura then
					local oldDebuffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "debuff", aura.auraInstanceID)
					local _, idx = AuraUtil.cacheTargetAura(aura, unit, "buff")
					if oldDebuffIdx and oldDebuffIdx <= debuffLimit then touchDebuff = true end
					if idx and idx <= buffLimit then touchBuff = true end
					if trackDispel and oldDebuffIdx then touchDispel = true end
				end
			end
		end
		if eventInfo.updatedAuraInstanceIDs and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
			for _, inst in ipairs(eventInfo.updatedAuraInstanceIDs) do
				local buffIdx = buffCache.indexById and buffCache.indexById[inst]
				local debuffIdx = debuffCache.indexById and debuffCache.indexById[inst]
				if buffIdx or debuffIdx then
					local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, inst)
					if data then
						if buffIdx then AuraUtil.cacheTargetAura(data, unit, "buff") end
						if debuffIdx then AuraUtil.cacheTargetAura(data, unit, "debuff") end
					else
						if buffIdx then AuraUtil.removeTargetAuraFromKindCache(unit, "buff", inst) end
						if debuffIdx then AuraUtil.removeTargetAuraFromKindCache(unit, "debuff", inst) end
					end
					if buffIdx and buffIdx <= buffLimit then touchBuff = true end
					if debuffIdx and debuffIdx <= debuffLimit then touchDebuff = true end
					if trackDispel and debuffIdx then touchDispel = true end
				end
			end
		end
		if eventInfo.removedAuraInstanceIDs then
			for _, inst in ipairs(eventInfo.removedAuraInstanceIDs) do
				local buffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "buff", inst)
				local debuffIdx = AuraUtil.removeTargetAuraFromKindCache(unit, "debuff", inst)
				if buffIdx and buffIdx <= buffLimit then touchBuff = true end
				if debuffIdx and debuffIdx <= debuffLimit then touchDebuff = true end
				if trackDispel and debuffIdx then touchDispel = true end
			end
		end
		AuraUtil.compactAuraCache(buffCache)
		AuraUtil.compactAuraCache(debuffCache)
		if touchBuff or touchDebuff then
			AuraUtil.updateTargetAuraIcons(nil, unit, touchBuff, touchDebuff)
		elseif touchDispel then
			AuraUtil.UpdateSingleDispelIndicator(unit, false)
		end
	elseif
		event == "UNIT_HEALTH"
		or event == "UNIT_MAXHEALTH"
		or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED"
		or event == "UNIT_HEAL_PREDICTION"
		or event == "UNIT_ABSORB_AMOUNT_CHANGED"
		or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"
	then
		if event == "UNIT_ABSORB_AMOUNT_CHANGED" and unit then
			local st = states[unit]
			if st then st._absorbAmount = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0 end
		elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and unit then
			local st = states[unit]
			if st then st._healAbsorbAmount = UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit) or 0 end
		end
		if unit == UNIT.PLAYER then
			local playerCfg = getCfg(UNIT.PLAYER)
			updateHealth(playerCfg, UNIT.PLAYER)
			local secondaryCfg = playerCfg and playerCfg.secondaryPower or {}
			if secondaryCfg.enabled ~= false and UFHelper and UFHelper.ResolveSecondaryPowerToken then
				local token = UFHelper.ResolveSecondaryPowerToken(
					secondaryCfg,
					defaultsFor(UNIT.PLAYER).secondaryPower,
					addon.variables and addon.variables.unitClass,
					addon.variables and addon.variables.unitSpec
				)
				if token and UFHelper.IsSecondaryPowerTokenSpecial and UFHelper.IsSecondaryPowerTokenSpecial(token) then updatePower(playerCfg, UNIT.PLAYER) end
			end
		end
		if unit == UNIT.TARGET then updateHealth(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.TARGET_TARGET then updateHealth(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.PET then updateHealth(getCfg(UNIT.PET), UNIT.PET) end
		if unit == UNIT.FOCUS then updateHealth(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then
				updateHealth(bossCfg, unit)
				UF.DataBar.Update(bossCfg, unit)
			end
		end
		if event ~= "UNIT_HEAL_PREDICTION" and unit and allowedEventUnit[unit] then updateUnitStatusIndicator(getCfg(unit), unit) end
	elseif event == "UNIT_MAXPOWER" then
		if unit == UNIT.PLAYER then updatePower(getCfg(UNIT.PLAYER), UNIT.PLAYER) end
		if unit == UNIT.TARGET then updatePower(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.PET then updatePower(getCfg(UNIT.PET), UNIT.PET) end
		if unit == UNIT.FOCUS then updatePower(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then updatePower(bossCfg, unit) end
		end
	elseif event == "UNIT_DISPLAYPOWER" then
		if unit == UNIT.PLAYER then
			local playerCfg = getCfg(UNIT.PLAYER)
			if playerCfg.enabled == false then return end
			UF.ApplyPlayerDisplayPowerChange()
		elseif unit == UNIT.TARGET then
			local targetCfg = getCfg(UNIT.TARGET)
			if targetCfg.enabled == false then return end
			local st = states[unit]
			local pcfg = targetCfg.power or {}
			if st and st.power and pcfg.enabled ~= false then
				local powerEnum, powerToken = getMainPower(unit)
				UFHelper.configureSpecialTexture(st.power, powerToken, (targetCfg.power or {}).texture, targetCfg.power, powerEnum)
			elseif st and st.power then
				st.power:Hide()
			end
			updatePower(targetCfg, UNIT.TARGET)
		elseif unit == UNIT.FOCUS then
			local focusCfg = getCfg(UNIT.FOCUS)
			if focusCfg.enabled == false then return end
			local st = states[unit]
			local pcfg = focusCfg.power or {}
			if st and st.power and pcfg.enabled ~= false then
				local powerEnum, powerToken = getMainPower(unit)
				UFHelper.configureSpecialTexture(st.power, powerToken, (focusCfg.power or {}).texture, focusCfg.power, powerEnum)
			elseif st and st.power then
				st.power:Hide()
			end
			updatePower(focusCfg, UNIT.FOCUS)
		elseif unit == UNIT.PET then
			local petCfg = getCfg(UNIT.PET)
			if petCfg.enabled == false then return end
			local st = states[unit]
			local pcfg = petCfg.power or {}
			if st and st.power and pcfg.enabled ~= false then
				local powerEnum, powerToken = getMainPower(unit)
				UFHelper.configureSpecialTexture(st.power, powerToken, (petCfg.power or {}).texture, petCfg.power, powerEnum)
			elseif st and st.power then
				st.power:Hide()
			end
			updatePower(petCfg, UNIT.PET)
		elseif isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then
				local st = states[unit]
				local pcfg = bossCfg.power or {}
				if st and st.power and pcfg.enabled ~= false then
					local powerEnum, powerToken = getMainPower(unit)
					UFHelper.configureSpecialTexture(st.power, powerToken, (bossCfg.power or {}).texture, bossCfg.power, powerEnum)
				elseif st and st.power then
					st.power:Hide()
				end
				updatePower(bossCfg, unit)
			end
		end
	elseif event == "UNIT_POWER_UPDATE" and not FREQUENT[arg1] then
		if unit == UNIT.PLAYER then updatePower(getCfg(UNIT.PLAYER), UNIT.PLAYER) end
		if unit == UNIT.TARGET then updatePower(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.PET then updatePower(getCfg(UNIT.PET), UNIT.PET) end
		if unit == UNIT.FOCUS then updatePower(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then updatePower(bossCfg, unit) end
		end
	elseif event == "UNIT_POWER_FREQUENT" and FREQUENT[arg1] then
		if unit == UNIT.PLAYER then updatePower(getCfg(UNIT.PLAYER), UNIT.PLAYER) end
		if unit == UNIT.TARGET then updatePower(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.PET then updatePower(getCfg(UNIT.PET), UNIT.PET) end
		if unit == UNIT.FOCUS then updatePower(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then updatePower(bossCfg, unit) end
		end
	elseif event == "UNIT_NAME_UPDATE" or event == "PLAYER_LEVEL_UP" then
		if event == "PLAYER_LEVEL_UP" then
			updateNameAndLevel(getCfg(UNIT.PLAYER), UNIT.PLAYER, unit)
		elseif unit == UNIT.PLAYER then
			updateNameAndLevel(getCfg(UNIT.PLAYER), UNIT.PLAYER)
		end
		if unit == UNIT.TARGET then updateNameAndLevel(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.FOCUS then updateNameAndLevel(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if unit == UNIT.PET then updateNameAndLevel(getCfg(UNIT.PET), UNIT.PET) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then
				updateNameAndLevel(bossCfg, unit)
				UF.DataBar.Update(bossCfg, unit)
			end
		end
	elseif event == "UNIT_CLASSIFICATION_CHANGED" then
		local classificationState = unit and states[unit]
		local classificationCfg = classificationState and getCfg(unit)
		if classificationState and classificationCfg and classificationCfg.enabled ~= false then
			updateNameAndLevel(classificationCfg, unit, nil, true)
			if classificationState._healthTextUsesLevel == true then classificationState._healthTextDirty = true end
			if classificationState._powerTextUsesLevel == true then classificationState._powerTextDirty = true end
			if classificationState._secondaryPowerTextUsesLevel == true then classificationState._secondaryPowerTextDirty = true end
			if
				classificationState._healthTextDirty
				or classificationState._powerTextDirty
				or classificationState._secondaryPowerTextDirty
				or classificationState._dataBarTextDirty
			then
				UF.ScheduleTextUpdate()
			end
		end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then UF.DataBar.Update(bossCfg, unit) end
		end
	elseif event == "UNIT_FLAGS" then
		updateUnitStatusIndicator(getCfg(unit), unit)
		if UF.SupportsCombatIndicator(unit) then updateCombatIndicator(getCfg(unit), unit) end
		UFHelper.updateLeaderIndicator(states[unit], unit, getCfg(unit), defaultsFor(unit), true)
		UFHelper.updatePvPIndicator(states[unit], unit, getCfg(unit), defaultsFor(unit), true)
		if states[unit] then states[unit]._healthColorDirty = true end
		if unit == UNIT.TARGET then updateHealth(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.TARGET_TARGET then updateHealth(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.FOCUS then updateHealth(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then
				updateHealth(bossCfg, unit)
				UF.DataBar.Update(bossCfg, unit)
			end
		end
		if allowedEventUnit[UNIT.TARGET_TARGET] then updateUnitStatusIndicator(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
	elseif event == "UNIT_CONNECTION" then
		updateUnitStatusIndicator(getCfg(unit), unit)
		if states[unit] then states[unit]._healthColorDirty = true end
		if allowedEventUnit[UNIT.TARGET_TARGET] then updateUnitStatusIndicator(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.PLAYER then updatePortrait(getCfg(UNIT.PLAYER), UNIT.PLAYER) end
		if unit == UNIT.TARGET then updatePortrait(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.TARGET_TARGET then updatePortrait(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.FOCUS then updatePortrait(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if unit == UNIT.PET then updatePortrait(getCfg(UNIT.PET), UNIT.PET) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then updatePortrait(bossCfg, unit) end
		end
	elseif event == "UNIT_FACTION" then
		UFHelper.updatePvPIndicator(states[unit], unit, getCfg(unit), defaultsFor(unit), true)
		if states[unit] then states[unit]._healthColorDirty = true end
		if unit == UNIT.TARGET then updateHealth(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.TARGET_TARGET then updateHealth(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.FOCUS then updateHealth(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then
				updateHealth(bossCfg, unit)
				UF.DataBar.Update(bossCfg, unit)
			end
		end
		if unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit) then AuraUtil.RefreshHealerBuffPlacementUnit(unit) end
	elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
		if unit ~= "player" and unit ~= "pet" then return end
		UFHelper.updateHighlight(states[UNIT.PLAYER], UNIT.PLAYER, UNIT.PLAYER)
		UFHelper.updateHighlight(states[UNIT.PET], UNIT.PET, UNIT.PLAYER)
	elseif portraitEventsMap[event] then
		if unit == UNIT.PLAYER then updatePortrait(getCfg(UNIT.PLAYER), UNIT.PLAYER) end
		if unit == UNIT.TARGET then updatePortrait(getCfg(UNIT.TARGET), UNIT.TARGET) end
		if unit == UNIT.TARGET_TARGET then updatePortrait(getCfg(UNIT.TARGET_TARGET), UNIT.TARGET_TARGET) end
		if unit == UNIT.FOCUS then updatePortrait(getCfg(UNIT.FOCUS), UNIT.FOCUS) end
		if unit == UNIT.PET then updatePortrait(getCfg(UNIT.PET), UNIT.PET) end
		if isBossUnit(unit) then
			local bossCfg = getCfg(unit)
			if bossCfg.enabled then updatePortrait(bossCfg, unit) end
		end
	elseif event == "UNIT_TARGET" and unit == UNIT.TARGET then
		local totCfg = getCfg(UNIT.TARGET_TARGET)
		if totCfg.enabled then updateTargetTargetFrame(totCfg) end
		local targetCfg = getCfg(UNIT.TARGET)
		local targetStatusCfg = targetCfg and targetCfg.status
		local targetTargetNameCfg = targetStatusCfg and targetStatusCfg.targetTargetName
		if (targetTargetNameCfg and targetTargetNameCfg.enabled == true) or (targetStatusCfg and targetStatusCfg.showTargetTargetName == true) then
			updateNameAndLevel(targetCfg, UNIT.TARGET)
		end
	elseif event == "UNIT_SPELLCAST_SENT" then
		if unit == UNIT.PLAYER then
			local st = states[unit]
			if st then st.castTarget = arg1 end
		end
	elseif
		event == "UNIT_SPELLCAST_START"
		or event == "UNIT_SPELLCAST_CHANNEL_START"
		or event == "UNIT_SPELLCAST_CHANNEL_UPDATE"
		or event == "UNIT_SPELLCAST_EMPOWER_START"
		or event == "UNIT_SPELLCAST_EMPOWER_UPDATE"
		or event == "UNIT_SPELLCAST_DELAYED"
	then
		if event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" or event == "UNIT_SPELLCAST_DELAYED" then
			local _, _, castBarID = ...
			if unit == UNIT.PLAYER or unit == UNIT.TARGET or unit == UNIT.FOCUS or isBossUnit(unit) then
				local st = states[unit]
				if not (st and st.castBar and st.castBar:IsShown()) then return end
				if st.castInfo and st.castInfo.castBarID and castBarID and st.castInfo.castBarID ~= castBarID then return end
			end
		end
		if unit == UNIT.PLAYER then setCastInfoFromUnit(UNIT.PLAYER) end
		if unit == UNIT.TARGET then setCastInfoFromUnit(UNIT.TARGET) end
		if unit == UNIT.FOCUS then setCastInfoFromUnit(UNIT.FOCUS) end
		if isBossUnit(unit) then setCastInfoFromUnit(unit) end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
		local castGUID, spellId, castBarID
		if event == "UNIT_SPELLCAST_INTERRUPTED" then
			castGUID, spellId, _, castBarID = ...
		else
			castGUID, spellId, castBarID = ...
		end
		if unit == UNIT.PLAYER and not shouldIgnoreCastFail(UNIT.PLAYER, castGUID, spellId, castBarID) then UF.ShowCastInterrupt(UNIT.PLAYER, event) end
		if unit == UNIT.TARGET and not shouldIgnoreCastFail(UNIT.TARGET, castGUID, spellId, castBarID) then UF.ShowCastInterrupt(UNIT.TARGET, event) end
		if unit == UNIT.FOCUS and not shouldIgnoreCastFail(UNIT.FOCUS, castGUID, spellId, castBarID) then UF.ShowCastInterrupt(UNIT.FOCUS, event) end
		if isBossUnit(unit) and not shouldIgnoreCastFail(unit, castGUID, spellId, castBarID) then UF.ShowCastInterrupt(unit, event) end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
		local castBarID, _
		if event == "UNIT_SPELLCAST_CHANNEL_STOP" then
			_, _, _, castBarID = ...
		elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
			_, _, _, _, castBarID = ...
		else
			_, _, castBarID = ...
		end
		local st = states[unit]
		if st and not st.castInterruptActive and st.castInfo and st.castInfo.castBarID and castBarID and st.castInfo.castBarID ~= castBarID then return end
		if unit == UNIT.PLAYER then
			if not (states[UNIT.PLAYER] and states[UNIT.PLAYER].castInterruptActive) then
				stopCast(UNIT.PLAYER)
				if UF.ShouldShowSampleCast(unit) then UF.SetSampleCast(unit) end
			end
		end
		if unit == UNIT.TARGET then
			if not (states[UNIT.TARGET] and states[UNIT.TARGET].castInterruptActive) then
				stopCast(UNIT.TARGET)
				if UF.ShouldShowSampleCast(unit) then UF.SetSampleCast(unit) end
			end
		end
		if unit == UNIT.FOCUS then
			if not (states[UNIT.FOCUS] and states[UNIT.FOCUS].castInterruptActive) then
				stopCast(UNIT.FOCUS)
				if UF.ShouldShowSampleCast(unit) then UF.SetSampleCast(unit) end
			end
		end
		if isBossUnit(unit) then
			if not (states[unit] and states[unit].castInterruptActive) then stopCast(unit) end
		end
	elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		updateBossFrames(true)
	elseif event == "UNIT_TARGETABLE_CHANGED" and isBossUnit(unit) then
		updateBossFrames(true)
	elseif event == "UNIT_PET" and unit == "player" then
		local petCfg = getCfg(UNIT.PET)
		if petCfg.enabled then
			applyConfig(UNIT.PET)
			updateNameAndLevel(petCfg, UNIT.PET)
			updateHealth(petCfg, UNIT.PET)
			updatePower(petCfg, UNIT.PET)
		end
	elseif event == "PLAYER_FOCUS_CHANGED" then
		local focusCfg = getCfg(UNIT.FOCUS)
		if focusCfg.enabled then
			updateFocusFrame(focusCfg, true)
			checkRaidTargetIcon(UNIT.FOCUS, states[UNIT.FOCUS])
		end
		updateUnitStatusIndicator(focusCfg, UNIT.FOCUS)
		updateCombatIndicator(focusCfg, UNIT.FOCUS)
		UFHelper.updateLeaderIndicator(states[UNIT.FOCUS], UNIT.FOCUS, focusCfg, defaultsFor(UNIT.FOCUS), true)
		UFHelper.updatePvPIndicator(states[UNIT.FOCUS], UNIT.FOCUS, focusCfg, defaultsFor(UNIT.FOCUS), true)
		UFHelper.updateRoleIndicator(states[UNIT.FOCUS], UNIT.FOCUS, focusCfg, defaultsFor(UNIT.FOCUS), true)
		UFHelper.updateHighlight(states[UNIT.FOCUS], UNIT.FOCUS, UNIT.PLAYER)
		AuraUtil.RefreshHealerBuffPlacementUnit(UNIT.FOCUS)
	elseif event == "PLAYER_UPDATE_RESTING" then
		updateRestingIndicator(getCfg(UNIT.PLAYER))
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
		local playerCfg = getCfg(UNIT.PLAYER)
		local defStatus = (defaultsFor(UNIT.PLAYER) and defaultsFor(UNIT.PLAYER).status) or {}
		local usDef = defStatus.unitStatus or {}
		local usCfg = (playerCfg.status and playerCfg.status.unitStatus) or usDef or {}
		if playerCfg.enabled ~= false and usCfg.enabled == true and usCfg.showGroup == true then updateUnitStatusIndicator(playerCfg, UNIT.PLAYER) end
		local targetCfg = getCfg(UNIT.TARGET)
		local targetDefStatus = (defaultsFor(UNIT.TARGET) and defaultsFor(UNIT.TARGET).status) or {}
		local targetUsDef = targetDefStatus.unitStatus or {}
		local targetUsCfg = (targetCfg.status and targetCfg.status.unitStatus) or targetUsDef or {}
		if targetCfg.enabled ~= false and targetUsCfg.enabled == true and targetUsCfg.showGroup == true then updateUnitStatusIndicator(targetCfg, UNIT.TARGET) end
		UF.UpdateAllRoleIndicators(true)
		UF.UpdateAllLeaderIndicators(true)
	elseif event == "CLIENT_SCENE_OPENED" then
		local sceneType = unit
		UF._clientSceneActive = addon.functions and addon.functions.IsMinigameClientScene and addon.functions.IsMinigameClientScene(sceneType) or false
		UF.RefreshClientSceneVisibility()
	elseif event == "CLIENT_SCENE_CLOSED" then
		UF._clientSceneActive = false
		UF.RefreshClientSceneVisibility()
	elseif event == "RAID_TARGET_UPDATE" then
		updateAllRaidTargetIcons()
	end
end

local function ensureEventHandling()
	rebuildAllowedEventUnits()
	UF.RecomputeAnyUFEnabled()
	if not anyUFEnabled() then
		hideBossFrames()
		UF.ScheduleRangeFadeRefresh(true)
		UF.CancelTextUpdate()
		if UFHelper and UFHelper.disableCombatFeedbackAll then UFHelper.disableCombatFeedbackAll(states) end
		if eventFrame and eventFrame.UnregisterAllEvents then eventFrame:UnregisterAllEvents() end
		if eventFrame then eventFrame:SetScript("OnEvent", nil) end
		eventFrame = nil
		UF._clearUnitEventFrames()
		return
	end
	if not eventFrame then
		eventFrame = CreateFrame("Frame")
		eventFrame:SetScript("OnEvent", onEvent)
		if not editModeHooked then
			editModeHooked = true

			addon.EditModeLib:RegisterCallback("enter", function()
				for _, st in pairs(states) do
					AuraUtil.HideNativeAuraContainers(st)
				end
				updateCombatIndicator(states[UNIT.PLAYER] and states[UNIT.PLAYER].cfg or ensureDB(UNIT.PLAYER), UNIT.PLAYER)
				updateCombatIndicator(states[UNIT.TARGET] and states[UNIT.TARGET].cfg or ensureDB(UNIT.TARGET), UNIT.TARGET)
				updateCombatIndicator(states[UNIT.FOCUS] and states[UNIT.FOCUS].cfg or ensureDB(UNIT.FOCUS), UNIT.FOCUS)
				ensureBossFramesReady(ensureDB("boss"))
				updateBossFrames(true)
				updateAllRaidTargetIcons()
				UF.UpdateAllPvPIndicators()
				UF.UpdateAllRoleIndicators(false)
				UF.UpdateAllLeaderIndicators(false)
				applyVisibilityRulesAll()
				if UF.Refresh then UF.Refresh() end
				if states[UNIT.PLAYER] and states[UNIT.PLAYER].castBar then setCastInfoFromUnit(UNIT.PLAYER) end
				if states[UNIT.TARGET] and states[UNIT.TARGET].castBar then setCastInfoFromUnit(UNIT.TARGET) end
				if states[UNIT.FOCUS] and states[UNIT.FOCUS].castBar then setCastInfoFromUnit(UNIT.FOCUS) end
				UF.ScheduleRangeFadeRefresh(false)
			end)

			addon.EditModeLib:RegisterCallback("exit", function()
				updateCombatIndicator(states[UNIT.PLAYER] and states[UNIT.PLAYER].cfg or ensureDB(UNIT.PLAYER), UNIT.PLAYER)
				updateCombatIndicator(states[UNIT.TARGET] and states[UNIT.TARGET].cfg or ensureDB(UNIT.TARGET), UNIT.TARGET)
				updateCombatIndicator(states[UNIT.FOCUS] and states[UNIT.FOCUS].cfg or ensureDB(UNIT.FOCUS), UNIT.FOCUS)
				hideBossFrames(true)
				if ensureDB("boss").enabled then updateBossFrames(true) end
				updateAllRaidTargetIcons()
				UF.UpdateAllPvPIndicators()
				UF.UpdateAllRoleIndicators(false)
				UF.UpdateAllLeaderIndicators(false)
				applyVisibilityRulesAll()
				if UF.Refresh then UF.Refresh() end
				if ensureDB("target").enabled then AuraUtil.fullScanTargetAuras(UNIT.TARGET) end
				if ensureDB(UNIT.FOCUS).enabled then AuraUtil.fullScanTargetAuras(UNIT.FOCUS) end
				if states[UNIT.PLAYER] and states[UNIT.PLAYER].castBar then setCastInfoFromUnit(UNIT.PLAYER) end
				if states[UNIT.TARGET] and states[UNIT.TARGET].castBar then setCastInfoFromUnit(UNIT.TARGET) end
				if states[UNIT.FOCUS] and states[UNIT.FOCUS].castBar then setCastInfoFromUnit(UNIT.FOCUS) end
				UF.ScheduleRangeFadeRefresh(false)
				if UFHelper and UFHelper.stopCombatFeedbackSample then
					for _, st in pairs(states) do
						UFHelper.stopCombatFeedbackSample(st)
					end
				end
			end)
		end
	end
	if eventFrame.UnregisterAllEvents then eventFrame:UnregisterAllEvents() end
	for _, evt in ipairs(generalEvents) do
		eventFrame:RegisterEvent(evt)
	end
	if eventFrame.RegisterUnitEvent then
		eventFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	else
		eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
	if ensureDB("boss").enabled then
		eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		eventFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
	end
	UF._registerUnitScopedEvents(anyPortraitEnabled())
	syncTargetRangeFadeConfig(ensureDB(UNIT.TARGET), defaultsFor(UNIT.TARGET))
	UF.ScheduleRangeFadeRefresh(false)
	UF.UpdateAllTexts(true)
end

function UF.RefreshStandaloneCastbar()
	local standalone = addon.Aura and addon.Aura.UFStandaloneCastbar
	if standalone and standalone.Refresh then standalone.Refresh() end
end

function UF.Enable()
	local cfg = ensureDB("player")
	cfg.enabled = true
	UF.SetRuntimeConsumerActive("unit", UNIT.PLAYER, true)
	ensureEventHandling()
	applyConfig("player")
	if UF.RegisterEnabledEditModeFrames then UF.RegisterEnabledEditModeFrames(UNIT.PLAYER) end
	if ensureDB("target").enabled then applyConfig("target") end
	local totCfg = ensureDB(UNIT.TARGET_TARGET)
	if totCfg.enabled then updateTargetTargetFrame(totCfg, true) end
	if ensureDB(UNIT.FOCUS).enabled then updateFocusFrame(ensureDB(UNIT.FOCUS), true) end
	if ensureDB(UNIT.PET).enabled then applyConfig(UNIT.PET) end
	local bossCfg = ensureDB("boss")
	if bossCfg.enabled then
		ensureBossFramesReady(bossCfg)
		updateBossFrames(true)
	end
	if addon.functions and addon.functions.UpdateClassResourceVisibility then addon.functions.UpdateClassResourceVisibility() end
	-- hideBlizzardPlayerFrame()
	-- hideBlizzardTargetFrame()
	UF.RefreshStandaloneCastbar()
end

function UF.Disable()
	local cfg = ensureDB("player")
	cfg.enabled = false
	UF.SetRuntimeConsumerActive("unit", UNIT.PLAYER, false)
	if states.player and states.player.frame then states.player.frame:Hide() end
	ClassResourceUtil.restoreClassResourceFrames()
	TotemFrameUtil.restoreTotemFrame()
	stopToTTicker()
	applyVisibilityRules("player")
	addon.variables.requireReload = true
	if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
	if _G.PlayerFrame and not InCombatLockdown() then
		_G.PlayerFrame:SetAlpha(1)
		_G.PlayerFrame:Show()
	end
	ensureEventHandling()
	if addon.functions and addon.functions.UpdateClassResourceVisibility then addon.functions.UpdateClassResourceVisibility() end
	UF.RefreshStandaloneCastbar()
end

function UF.Refresh()
	if UF.RecomputeRuntimeConsumerActivity then UF.RecomputeRuntimeConsumerActivity() end
	if UF.RegisterEnabledEditModeFrames then UF.RegisterEnabledEditModeFrames() end
	local bossCfg = ensureDB("boss")
	if bossCfg.enabled then DisableBossFrames() end
	ensureEventHandling()
	if not anyUFEnabled() then
		hideBossFrames()
		applyVisibilityRulesAll()
		return
	end
	applyConfig("player")
	applyConfig("target")
	local focusCfg = ensureDB(UNIT.FOCUS)
	if focusCfg.enabled then
		updateFocusFrame(focusCfg, true)
	elseif applyFrameRuleOverride then
		applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, false)
		applyVisibilityRules(UNIT.FOCUS)
	end
	local targetCfg = ensureDB("target")
	if targetCfg.enabled and UnitExists and UnitExists(UNIT.TARGET) and states[UNIT.TARGET] and states[UNIT.TARGET].frame then
		states[UNIT.TARGET].barGroup:Show()
		states[UNIT.TARGET].status:Show()
	end
	local totCfg = ensureDB(UNIT.TARGET_TARGET)
	updateTargetTargetFrame(totCfg, true)
	if ensureDB(UNIT.PET).enabled then
		applyConfig(UNIT.PET)
	elseif applyFrameRuleOverride then
		applyFrameRuleOverride(BLIZZ_FRAME_NAMES.pet, false)
		applyVisibilityRules(UNIT.PET)
	end
	if bossCfg.enabled then
		ensureBossFramesReady(bossCfg)
		updateBossFrames(true)
	else
		hideBossFrames()
		applyVisibilityRules("boss")
	end
	UF.RefreshStandaloneCastbar()
end

function UF.RefreshUnit(unit)
	ensureEventHandling()
	if not anyUFEnabled() then return end
	if UF.RegisterEnabledEditModeFrames then UF.RegisterEnabledEditModeFrames(UF.NormalizeDynamicAnchorUnit(unit or UNIT.PLAYER)) end
	if unit == UNIT.TARGET_TARGET then
		local totCfg = ensureDB(UNIT.TARGET_TARGET)
		updateTargetTargetFrame(totCfg, true)
		ensureToTTicker()
	elseif unit == UNIT.TARGET then
		applyConfig(UNIT.TARGET)
		local targetCfg = ensureDB("target")
		if targetCfg.enabled and UnitExists and UnitExists(UNIT.TARGET) and states[UNIT.TARGET] and states[UNIT.TARGET].frame then
			states[UNIT.TARGET].barGroup:Show()
			states[UNIT.TARGET].status:Show()
		end
	elseif unit == UNIT.FOCUS then
		local focusCfg = ensureDB(UNIT.FOCUS)
		if focusCfg.enabled then
			updateFocusFrame(focusCfg, true)
		elseif applyFrameRuleOverride then
			applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, false)
			applyVisibilityRules(UNIT.FOCUS)
		end
	elseif unit == UNIT.PET then
		if ensureDB(UNIT.PET).enabled then
			applyConfig(UNIT.PET)
		elseif applyFrameRuleOverride then
			applyFrameRuleOverride(BLIZZ_FRAME_NAMES.pet, false)
			applyVisibilityRules(UNIT.PET)
		end
	elseif isBossUnit(unit) then
		updateBossFrames(true)
	else
		applyConfig(UNIT.PLAYER)
	end
	if unit == nil or unit == UNIT.PLAYER then UF.RefreshStandaloneCastbar() end
end

function UF.Initialize()
	if addon.Aura.UFInitialized then return end
	if not addon.db then return end
	addon.Aura.UFInitialized = true
	UF.RegisterDynamicAnchors()
	if UF.RegisterSettings then UF.RegisterSettings() end
	if UF.RecomputeRuntimeConsumerActivity then UF.RecomputeRuntimeConsumerActivity() end
	local cfg = ensureDB("player")
	do
		local def = defaultsFor(UNIT.PLAYER)
		local rcfg = (cfg and cfg.classResource) or (def and def.classResource) or {}
		local frameLevelOffset = tonumber(rcfg.frameLevelOffset)
		if frameLevelOffset == nil then frameLevelOffset = tonumber(def and def.classResource and def.classResource.frameLevelOffset) end
		if frameLevelOffset == nil then frameLevelOffset = 5 end
		if frameLevelOffset < 0 then frameLevelOffset = 0 end
		if ClassResourceUtil.SetFrameLevelHookOffset then ClassResourceUtil.SetFrameLevelHookOffset(frameLevelOffset) end
	end
	if cfg.enabled then After(0.1, function() UF.Enable() end) end
	cfg = ensureDB("target")
	if cfg.enabled then
		ensureEventHandling()
		applyConfig("target")
		-- hideBlizzardTargetFrame()
	end
	cfg = ensureDB(UNIT.TARGET_TARGET)
	if cfg.enabled then
		ensureEventHandling()
		updateTargetTargetFrame(cfg, true)
		ensureToTTicker()
	end
	cfg = ensureDB(UNIT.PET)
	if cfg.enabled then
		ensureEventHandling()
		applyConfig(UNIT.PET)
	elseif applyFrameRuleOverride then
		applyFrameRuleOverride(BLIZZ_FRAME_NAMES.pet, false)
	end
	cfg = ensureDB(UNIT.FOCUS)
	if cfg.enabled then
		ensureEventHandling()
		updateFocusFrame(cfg, true)
	elseif applyFrameRuleOverride then
		applyFrameRuleOverride(BLIZZ_FRAME_NAMES.focus, false)
	end
	cfg = ensureDB("boss")
	if cfg.enabled then
		ensureEventHandling()
		ensureBossFramesReady(cfg)
		updateBossFrames(true)
	end
	if isBossFrameSettingEnabled() then DisableBossFrames() end
	UF.RefreshStandaloneCastbar()
end

addon.Aura.functions = addon.Aura.functions or {}
addon.Aura.functions.InitUnitFrames = function()
	if UF and UF.Initialize then UF.Initialize() end
end

UF.targetAuraKinds = targetAuraKinds
UF.defaults = defaults
UF.GetDefaults = function(unit) return defaultsFor(unit) end
UF.EnsureDB = ensureDB
UF.GetConfig = ensureDB
UF.EnsureFrames = ensureFrames
UF.ApplyVisibilityRules = applyVisibilityRules
UF.ApplyVisibilityRulesAll = applyVisibilityRulesAll
UF.StopEventsIfInactive = function() ensureEventHandling() end
UF.UpdateBossFrames = updateBossFrames
UF.HideBossFrames = hideBossFrames
UF.FullScanTargetAuras = AuraUtil.fullScanTargetAuras
UF.RefreshNativeAuraIgnoreFilters = AuraUtil.RefreshNativeAuraIgnoreFilters
UF.ResolveSingleAuraConfig = AuraUtil.resolveSingleAuraConfig
UF.EnsureSingleAuraConfig = AuraUtil.ensureSingleAuraConfig
UF.CopySettings = copySettings


addon.Aura.functions = addon.Aura.functions or {}
addon.Aura.functions.importUFProfile = UF.ImportProfile
addon.Aura.functions.exportUFProfile = UF.ExportProfile
addon.Aura.functions.getUFProfileNames = function() return UFProfileManager.GetSortedNames() end
addon.Aura.functions.getActiveUFProfile = function() return UFProfileManager.GetActiveName() end
addon.Aura.functions.setActiveUFProfile = function(name, source) return UFProfileManager.SetActiveName(name, source) end
addon.Aura.functions.getGlobalUFProfile = function() return UFProfileManager.GetGlobalName() end
addon.Aura.functions.setGlobalUFProfile = function(name) return UFProfileManager.SetGlobalName(name) end
addon.Aura.functions.getUFProfileSpecMapping = function(specID) return UFProfileManager.GetSpecMapping(specID) end
addon.Aura.functions.setUFProfileSpecMapping = function(specID, name) return UFProfileManager.SetSpecMapping(specID, name) end
addon.Aura.functions.createUFProfile = function(name) return UFProfileManager.Create(name) end
addon.Aura.functions.copyUFProfileToActive = function(name) return UFProfileManager.CopyToActive(name) end
addon.Aura.functions.deleteUFProfile = function(name) return UFProfileManager.Delete(name) end
addon.Aura.functions.applyUFProfile = function(reason) return UFProfileManager.ApplyCurrent(reason) end

addon.exportUFProfile = function(profileName, scopeKey) return UF.ExportProfile(scopeKey, profileName) end
addon.importUFProfile = function(encoded, scopeKey) return UF.ImportProfile(encoded, scopeKey) end
