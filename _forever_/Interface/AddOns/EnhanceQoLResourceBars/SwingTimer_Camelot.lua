local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

-- Each weapon has independent appearance, layout and event state.
addon.SwingTimers = addon.SwingTimers or {}
local function createSwingBar(hand, swingType, title, offsetY, color)
	local SwingBar = { swingType = swingType, title = title }

	local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
	local displayTitle = L["SwingTimer"] .. " - " .. title
	local EditMode = addon.EditMode
	local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType
	local LSM = LibStub("LibSharedMedia-3.0", true)

	local EDITMODE_ID = "swingBar" .. hand
	local DB_PREFIX = EDITMODE_ID
	SwingBar.dynamicAnchorId = "bar:swing:" .. hand
	local ANCHOR_TARGET_UI = "UIParent"
	local ANCHOR_TARGET_PLAYER_CASTBAR = "PLAYER_CASTBAR"
	local EQOL_PLAYER_CASTBAR = "EQOLUFPlayerHealthCast"
	local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
	local VALID_ANCHOR_POINTS = {}
	for _, point in ipairs(ANCHOR_POINTS) do
		VALID_ANCHOR_POINTS[point] = true
	end

	SwingBar.defaults = SwingBar.defaults
		or {
			width = 200,
			height = 18,
			texture = "DEFAULT",
			color = color,
			sparkEnabled = true,
			sparkGlowEnabled = false,
			sparkCustomColor = false,
			sparkColor = { r = 1, g = 1, b = 1, a = 1 },
			bgEnabled = true,
			bgTexture = "SOLID",
			bgColor = { r = 0, g = 0, b = 0, a = 0.35 },
			borderEnabled = false,
			borderTexture = "DEFAULT",
			borderColor = { r = 0, g = 0, b = 0, a = 0.8 },
			borderSize = 1,
			borderOffset = 0,
			progressMode = "ELAPSED",
			fillDirection = "LEFT",
			anchorRelativeFrame = ANCHOR_TARGET_UI,
			anchorMatchRelativeWidth = false,
			anchorMatchRelativeWidthOffset = 0,
			anchorPoint = "CENTER",
			anchorRelativePoint = "CENTER",
			anchorOffsetX = 0,
			anchorOffsetY = offsetY,
			hideInPetBattle = false,
			strata = nil,
			textEnabled = true,
			textFont = addon.functions.GetGlobalFontConfigKey(),
			textOutline = addon.functions.GetGlobalFontStyleConfigKey(),
			textSize = 12,
			textColor = { r = 1, g = 1, b = 1, a = 1 },
			textPoint = "RIGHT",
			textOffsetX = -8,
			textOffsetY = 0,
			alwaysShow = true,
			onlyInCombat = false,
			onlyUnmounted = false,
			showForms = { HUMANOID = true, BEAR = true, CAT = true, TRAVEL = true, MOONKIN = true, STAG = true },
			labelEnabled = true,
			labelFont = addon.functions.GetGlobalFontConfigKey(),
			labelOutline = addon.functions.GetGlobalFontStyleConfigKey(),
			labelSize = 12,
			labelColor = { r = 1, g = 1, b = 1, a = 1 },
			labelPoint = "LEFT",
			labelOffsetX = 8,
			labelOffsetY = 0,
		}

	local defaults = SwingBar.defaults
	local DISPLAY_FIELDS = { "sparkGlowEnabled", "sparkCustomColor", "sparkColor", "textEnabled", "textFont", "textOutline", "textSize", "textColor", "textPoint", "textOffsetX", "textOffsetY", "alwaysShow", "onlyInCombat", "onlyUnmounted", "showForms", "labelEnabled", "labelFont", "labelOutline", "labelSize", "labelColor", "labelPoint", "labelOffsetX", "labelOffsetY" }

	local DB_ENABLED = DB_PREFIX .. "Enabled"
	local DB_WIDTH = DB_PREFIX .. "Width"
	local DB_HEIGHT = DB_PREFIX .. "Height"
	local DB_TEXTURE = DB_PREFIX .. "Texture"
	local DB_COLOR = DB_PREFIX .. "Color"
	local DB_SPARK_ENABLED = DB_PREFIX .. "SparkEnabled"
	local DB_BG_ENABLED = DB_PREFIX .. "BackgroundEnabled"
	local DB_BG_TEXTURE = DB_PREFIX .. "BackgroundTexture"
	local DB_BG_COLOR = DB_PREFIX .. "BackgroundColor"
	local DB_BORDER_ENABLED = DB_PREFIX .. "BorderEnabled"
	local DB_BORDER_TEXTURE = DB_PREFIX .. "BorderTexture"
	local DB_BORDER_COLOR = DB_PREFIX .. "BorderColor"
	local DB_BORDER_SIZE = DB_PREFIX .. "BorderSize"
	local DB_BORDER_OFFSET = DB_PREFIX .. "BorderOffset"
	local DB_PROGRESS_MODE = DB_PREFIX .. "ProgressMode"
	local DB_FILL_DIRECTION = DB_PREFIX .. "FillDirection"
	local DB_ANCHOR_RELATIVE_FRAME = DB_PREFIX .. "AnchorTarget"
	local DB_ANCHOR_MATCH_WIDTH = DB_PREFIX .. "AnchorMatchWidth"
	local DB_ANCHOR_MATCH_WIDTH_OFFSET = DB_PREFIX .. "AnchorMatchWidthOffset"
	local DB_ANCHOR_POINT = DB_PREFIX .. "AnchorPoint"
	local DB_ANCHOR_RELATIVE_POINT = DB_PREFIX .. "AnchorRelativePoint"
	local DB_ANCHOR_OFFSET_X = DB_PREFIX .. "AnchorOffsetX"
	local DB_ANCHOR_OFFSET_Y = DB_PREFIX .. "AnchorOffsetY"
	local DB_HIDE_IN_PET_BATTLE = DB_PREFIX .. "HideInPetBattle"
	local DB_STRATA = DB_PREFIX .. "Strata"

	local DEFAULT_TEX = "Interface\\TargetingFrame\\UI-StatusBar"
	local SPARK_ATLAS = "XPBarAnim-OrangeSpark"
	local GetTime = GetTime
	local BAR_WIDTH_MIN = 6
	local BAR_HEIGHT_MIN = 1
	local BAR_SIZE_MAX = 2000
	local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
	local VALID_STRATA = {}
	for _, strata in ipairs(STRATA_ORDER) do
		VALID_STRATA[strata] = true
	end

	local function getCachedMediaNames(mediaType)
		if addon.functions and addon.functions.GetLSMMediaNames then
			local names = addon.functions.GetLSMMediaNames(mediaType)
			if type(names) == "table" then return names end
		end
		return {}
	end

	local function getCachedMediaHash(mediaType)
		if addon.functions and addon.functions.GetLSMMediaHash then
			local hash = addon.functions.GetLSMMediaHash(mediaType)
			if type(hash) == "table" then return hash end
		end
		return {}
	end

	local function getValue(key, fallback)
		if not addon.db then return fallback end
		local value = addon.db[key]
		if value == nil then return fallback end
		return value
	end

	local function shouldHideInPetBattleForSwing() return getValue(DB_HIDE_IN_PET_BATTLE, defaults.hideInPetBattle) == true end

	local function isPetBattleActive() return C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() == true end

	local function clamp(value, minValue, maxValue)
		value = tonumber(value) or minValue
		if value < minValue then return minValue end
		if value > maxValue then return maxValue end
		return value
	end

	local function normalizeColor(value, fallback)
		if type(value) == "table" then
			local r = value.r or value[1] or 1
			local g = value.g or value[2] or 1
			local b = value.b or value[3] or 1
			local a = value.a or value[4]
			return r, g, b, a
		elseif type(value) == "number" then
			return value, value, value
		end
		local d = fallback or defaults.color or {}
		return d.r or 1, d.g or 1, d.b or 1, d.a
	end

	local function isLikelyFilePath(value)
		if type(value) ~= "string" or value == "" then return false end
		return string.find(value, "[/\\]") ~= nil
	end

	local function resolveTexture(key)
		if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
		if not key or key == "" or key == "DEFAULT" then return DEFAULT_TEX end
		if LSM and LSM.Fetch then
			local tex = LSM:Fetch("statusbar", key, true)
			if tex then return tex end
		end
		if isLikelyFilePath(key) then return key end
		return DEFAULT_TEX
	end

	local function resolveBorderTexture(key)
		if key == "SOLID" then return "Interface\\Buttons\\WHITE8x8" end
		if not key or key == "" or key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
		if LSM and LSM.Fetch then
			local tex = LSM:Fetch("border", key, true)
			if tex then return tex end
		end
		if isLikelyFilePath(key) then return key end
		return "Interface\\Buttons\\WHITE8x8"
	end

	local function textureOptions()
		local list = {}
		local seen = {}
		local function add(value, label)
			local lv = tostring(value or ""):lower()
			if lv == "" or seen[lv] then return end
			seen[lv] = true
			list[#list + 1] = { value = value, label = label }
		end
		add("DEFAULT", _G.DEFAULT)
		add("SOLID", L["Solid"])
		local names = getCachedMediaNames("statusbar")
		local hash = getCachedMediaHash("statusbar")
		for i = 1, #names do
			local name = names[i]
			local path = hash[name]
			if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
		end
		return list
	end

	local function borderOptions()
		local list = {}
		local seen = {}
		local function add(value, label)
			local lv = tostring(value or ""):lower()
			if lv == "" or seen[lv] then return end
			seen[lv] = true
			list[#list + 1] = { value = value, label = label }
		end
		add("DEFAULT", _G.DEFAULT)
		add("SOLID", L["Solid"])
		local names = getCachedMediaNames("border")
		local hash = getCachedMediaHash("border")
		for i = 1, #names do
			local name = names[i]
			local path = hash[name]
			if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
		end
		return list
	end

	local function normalizeProgressMode(value)
		if value == "ELAPSED" then return "ELAPSED" end
		return "REMAINING"
	end

	local function normalizeFillDirection(value)
		if type(value) == "string" then value = string.upper(value) end
		if value == "RIGHT" then return "RIGHT" end
		if value == "UP" or value == "BOTTOM" then return "UP" end
		if value == "DOWN" or value == "TOP" then return "DOWN" end
		return "LEFT"
	end

	local function isVerticalFillDirection(value) return value == "UP" or value == "DOWN" end

	local function isReverseFillDirection(value) return value == "RIGHT" or value == "DOWN" end

	local function clamp01(value) return clamp(tonumber(value) or 0, 0, 1) end

	local function normalizeAnchorPoint(value, fallback)
		if value and VALID_ANCHOR_POINTS[value] then return value end
		if fallback and VALID_ANCHOR_POINTS[fallback] then return fallback end
		return "CENTER"
	end

	local function normalizeAnchorRelativeFrame(value)
		if value == ANCHOR_TARGET_PLAYER_CASTBAR or value == "PlayerCastingBarFrame" or value == EQOL_PLAYER_CASTBAR then return ANCHOR_TARGET_PLAYER_CASTBAR end
		if type(value) == "string" and value ~= "" then return value end
		return ANCHOR_TARGET_UI
	end

	local function normalizeStrataToken(value)
		if type(value) ~= "string" or value == "" then return nil end
		local token = string.upper(value)
		if VALID_STRATA[token] then return token end
		return nil
	end

	local function strataOptionsWithDefault()
		local options = { { value = "", label = _G.DEFAULT or "Default" } }
		for _, strata in ipairs(STRATA_ORDER) do
			options[#options + 1] = { value = strata, label = strata }
		end
		return options
	end

	local function normalizeAnchorOffset(value, fallback)
		local num = tonumber(value)
		if num == nil then num = fallback end
		if num == nil then num = 0 end
		return clamp(num, -1000, 1000)
	end

	local function refreshSettingsUI()
		local lib = addon.EditModeLib
		if not (lib and lib.internal) then return end
		if lib.internal.RefreshSettings then lib.internal:RefreshSettings() end
		if lib.internal.RefreshSettingValues then lib.internal:RefreshSettingValues() end
	end

	local function isCustomPlayerCastbarEnabled()
		local cfg = addon.db and addon.db.ufFrames and addon.db.ufFrames.player
		if not (cfg and cfg.enabled == true) then return false end
		local castCfg = cfg.cast
		if not castCfg then
			local uf = addon.Aura and addon.Aura.UF
			local defaults = uf and uf.defaults and uf.defaults.player
			castCfg = defaults and defaults.cast
		end
		if not castCfg then return false end
		return castCfg.enabled ~= false
	end

	local function resolvePlayerCastbarFrame()
		local wantsCustom = isCustomPlayerCastbarEnabled()
		if wantsCustom then
			local custom = _G and _G[EQOL_PLAYER_CASTBAR]
			if custom then return custom, true, true end
		end
		local blizz = _G and _G.PlayerCastingBarFrame
		if blizz then return blizz, false, wantsCustom end
		return UIParent, false, wantsCustom
	end

	function SwingBar:GetWidth() return clamp(getValue(DB_WIDTH, defaults.width), BAR_WIDTH_MIN, BAR_SIZE_MAX) end

	function SwingBar:GetHeight() return clamp(getValue(DB_HEIGHT, defaults.height), BAR_HEIGHT_MIN, BAR_SIZE_MAX) end

	function SwingBar:GetTextureKey()
		local key = getValue(DB_TEXTURE, defaults.texture)
		if not key or key == "" then key = defaults.texture end
		return key
	end

	function SwingBar:GetColor() return normalizeColor(getValue(DB_COLOR, defaults.color), defaults.color) end

	function SwingBar:GetSparkEnabled() return getValue(DB_SPARK_ENABLED, defaults.sparkEnabled) == true end

	function SwingBar:GetBackgroundEnabled() return getValue(DB_BG_ENABLED, defaults.bgEnabled) == true end

	function SwingBar:GetBackgroundTextureKey()
		local key = getValue(DB_BG_TEXTURE, defaults.bgTexture)
		if not key or key == "" then key = defaults.bgTexture end
		return key
	end

	function SwingBar:GetBackgroundColor() return normalizeColor(getValue(DB_BG_COLOR, defaults.bgColor), defaults.bgColor) end

	function SwingBar:GetBorderEnabled() return getValue(DB_BORDER_ENABLED, defaults.borderEnabled) == true end

	function SwingBar:GetBorderTextureKey()
		local key = getValue(DB_BORDER_TEXTURE, defaults.borderTexture)
		if not key or key == "" then key = defaults.borderTexture end
		return key
	end

	function SwingBar:GetBorderColor() return normalizeColor(getValue(DB_BORDER_COLOR, defaults.borderColor), defaults.borderColor) end

	function SwingBar:GetBorderSize() return clamp(getValue(DB_BORDER_SIZE, defaults.borderSize), 1, 20) end

	function SwingBar:GetBorderOffset() return clamp(getValue(DB_BORDER_OFFSET, defaults.borderOffset), -20, 20) end

	function SwingBar:GetProgressMode() return normalizeProgressMode(getValue(DB_PROGRESS_MODE, defaults.progressMode)) end

	function SwingBar:GetFillDirection() return normalizeFillDirection(getValue(DB_FILL_DIRECTION, defaults.fillDirection)) end

	function SwingBar:GetAnchorRelativeFrame()
		local target = getValue(DB_ANCHOR_RELATIVE_FRAME, defaults.anchorRelativeFrame or ANCHOR_TARGET_UI)
		return normalizeAnchorRelativeFrame(target)
	end

	function SwingBar:GetAnchorMatchWidth() return getValue(DB_ANCHOR_MATCH_WIDTH, defaults.anchorMatchRelativeWidth == true) == true end

	function SwingBar:GetAnchorMatchWidthOffset() return clamp(getValue(DB_ANCHOR_MATCH_WIDTH_OFFSET, defaults.anchorMatchRelativeWidthOffset or 0), -200, 200) end

	function SwingBar:GetAnchorPoint() return normalizeAnchorPoint(getValue(DB_ANCHOR_POINT, defaults.anchorPoint), defaults.anchorPoint) end

	function SwingBar:GetAnchorRelativePoint()
		local point = normalizeAnchorPoint(getValue(DB_ANCHOR_RELATIVE_POINT, defaults.anchorRelativePoint), self:GetAnchorPoint())
		return point
	end

	function SwingBar:GetAnchorOffsetX() return normalizeAnchorOffset(getValue(DB_ANCHOR_OFFSET_X, defaults.anchorOffsetX), defaults.anchorOffsetX) end

	function SwingBar:GetAnchorOffsetY() return normalizeAnchorOffset(getValue(DB_ANCHOR_OFFSET_Y, defaults.anchorOffsetY), defaults.anchorOffsetY) end

	function SwingBar:GetHideInPetBattle() return shouldHideInPetBattleForSwing() end

	function SwingBar:GetStrata() return normalizeStrataToken(getValue(DB_STRATA, defaults.strata)) end

	function SwingBar:AnchorUsesUIParent() return self:GetAnchorRelativeFrame() == ANCHOR_TARGET_UI end

	function SwingBar:AnchorUsesMatchedWidth() return self:GetAnchorMatchWidth() and not self:AnchorUsesUIParent() end

	local function anchorDefaultsFor(target)
		if target == ANCHOR_TARGET_UI then
			local point = defaults.anchorPoint or "CENTER"
			local relPoint = defaults.anchorRelativePoint or point
			return point, relPoint, defaults.anchorOffsetX or 0, defaults.anchorOffsetY or 0
		end
		return "TOPLEFT", "BOTTOMLEFT", 0, 0
	end

	function SwingBar:IsAnchorFrameReady(frame)
		if not (frame and frame.GetLeft and frame.GetBottom) then return false end
		local left, bottom = frame:GetLeft(), frame:GetBottom()
		if issecretvalue and (issecretvalue(left) or issecretvalue(bottom)) then return false end
		return type(left) == "number" and type(bottom) == "number"
	end

	function SwingBar:EnsureAnchorGeometryHooks(frame)
		if not frame or frame == UIParent or frame == self.frame then return end
		self._anchorGeometryHooks = self._anchorGeometryHooks or {}
		if self._anchorGeometryHooks[frame] then return end
		self._anchorGeometryHooks[frame] = true
		local queued = false
		local function geometryChanged()
			if queued or not getValue(DB_ENABLED, false) then return end
			queued = true
			RunNextFrame(function()
				queued = false
				if not getValue(DB_ENABLED, false) or _G[self:GetAnchorRelativeFrame()] ~= frame then return end
				local resolved = self:IsAnchorFrameReady(frame) and frame or UIParent
				if self._staticAnchorFrame ~= resolved then
					self:RefreshAnchor()
					self:ApplySize()
				end
			end)
		end
		frame:HookScript("OnShow", geometryChanged)
		frame:HookScript("OnSizeChanged", geometryChanged)
		hooksecurefunc(frame, "SetPoint", geometryChanged)
		hooksecurefunc(frame, "SetAllPoints", geometryChanged)
		hooksecurefunc(frame, "ClearAllPoints", geometryChanged)
	end

	function SwingBar:IsAnchorTargetAllowed(target)
		if target == ANCHOR_TARGET_UI then return true end
		local visited = {}
		local current = target
		while current do
			if current == "EQOL_SwingBar" .. hand or visited[current] then return false end
			visited[current] = true
			local targetHand = current:match("^EQOL_SwingBar(.+)$")
			local bar = targetHand and addon.SwingTimers[targetHand]
			current = bar and bar:GetAnchorRelativeFrame() or nil
		end
		local targetFrame = _G[target]
		local anchors = addon.EditModeAnchors
		if targetFrame and self.frame and anchors and anchors.FrameDependsOn and anchors:FrameDependsOn(targetFrame, self.frame) then return false end
		return true
	end

	function SwingBar:ResolveAnchorFrame()
		local target = self:GetAnchorRelativeFrame()
		if not self:IsAnchorTargetAllowed(target) then return UIParent end
		self._anchorUsingCustom = nil
		self._anchorWantsCustom = nil

		if target == ANCHOR_TARGET_UI then return UIParent end

		if target == ANCHOR_TARGET_PLAYER_CASTBAR then
			local frame, usingCustom, wantsCustom = resolvePlayerCastbarFrame()
			self._anchorUsingCustom = usingCustom
			self._anchorWantsCustom = wantsCustom
			if wantsCustom and not usingCustom then self:ScheduleAnchorRefresh(target) end
			return frame or UIParent
		end

		local frame = _G and _G[target]
		self:EnsureAnchorGeometryHooks(frame)
		if self:IsAnchorFrameReady(frame) then
			self._staticAnchorFrame = frame
			return frame
		end
		self._staticAnchorFrame = UIParent
		self:ScheduleAnchorRefresh(target)
		return UIParent
	end

	function SwingBar:GetDynamicAnchorWinner()
		return addon.DynamicAnchors and addon.DynamicAnchors:GetSimpleFrameWinner(self.dynamicAnchorId) or nil
	end

	function SwingBar:ApplyDynamicAnchor()
		if not self.frame then return false end
		local winner = self:GetDynamicAnchorWinner()
		if not (winner and winner.frame) then return false end
		local placement = winner.placement or {}
		local point = placement.point or "CENTER"
		local relativePoint = placement.relativePoint or point
		self.frame:ClearAllPoints()
		addon.PixelUtil.Point(self.frame, point, winner.frame, relativePoint, tonumber(placement.x) or 0, tonumber(placement.y) or 0)
		return true
	end

	local function cancelAnchorRefreshTicker()
		if SwingBar._anchorRefreshTicker then SwingBar._anchorRefreshTicker:Cancel() end
		SwingBar._anchorRefreshTicker = nil
		SwingBar._anchorRefreshTarget = nil
		SwingBar._anchorRefreshPasses = nil
	end

	local function onAnchorRefreshTick()
		local desired = SwingBar._anchorRefreshTarget
		if not desired then
			cancelAnchorRefreshTicker()
			return
		end

		SwingBar._anchorRefreshPasses = (SwingBar._anchorRefreshPasses or 0) + 1
		if SwingBar:GetAnchorRelativeFrame() ~= desired then
			cancelAnchorRefreshTicker()
			return
		end

		if desired == ANCHOR_TARGET_PLAYER_CASTBAR then
			local frame, usingCustom, wantsCustom = resolvePlayerCastbarFrame()
			if frame and (not wantsCustom or usingCustom) then
				cancelAnchorRefreshTicker()
				SwingBar:RefreshAnchor()
				return
			end
		elseif SwingBar:IsAnchorFrameReady(_G and _G[desired]) then
			cancelAnchorRefreshTicker()
			SwingBar:RefreshAnchor()
			return
		end

		if (SwingBar._anchorRefreshPasses or 0) >= 25 then cancelAnchorRefreshTicker() end
	end

	function SwingBar:ScheduleAnchorRefresh(target)
		if not (C_Timer and C_Timer.NewTicker) then return end
		local desired = normalizeAnchorRelativeFrame(target or self:GetAnchorRelativeFrame())
		if desired == ANCHOR_TARGET_UI then return end

		if self._anchorRefreshTicker then
			if self._anchorRefreshTarget == desired then return end
			cancelAnchorRefreshTicker()
		end

		self._anchorRefreshTarget = desired
		self._anchorRefreshPasses = 0
		self._anchorRefreshTicker = C_Timer.NewTicker(0.2, onAnchorRefreshTick)
	end

	function SwingBar:RefreshAnchor()
		if self._refreshingAnchor then return end
		if addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(self.dynamicAnchorId) then
			self:ApplyDynamicAnchor()
			return
		end
		local target = self:GetAnchorRelativeFrame()
		if self._anchorRefreshTicker and (target == ANCHOR_TARGET_UI or self._anchorRefreshTarget ~= target) then cancelAnchorRefreshTicker() end
		self._refreshingAnchor = true
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
		self._refreshingAnchor = nil
		if target == ANCHOR_TARGET_PLAYER_CASTBAR then
			if isCustomPlayerCastbarEnabled() and not (_G and _G[EQOL_PLAYER_CASTBAR]) then self:ScheduleAnchorRefresh(target) end
		elseif target ~= ANCHOR_TARGET_UI then
			if not self:IsAnchorFrameReady(_G and _G[target]) then self:ScheduleAnchorRefresh(target) end
		end
	end

	function SwingBar:MaybeUpdateAnchor()
		local target = self:GetAnchorRelativeFrame()
		if target == ANCHOR_TARGET_PLAYER_CASTBAR then
			if isCustomPlayerCastbarEnabled() then
				if _G and _G[EQOL_PLAYER_CASTBAR] and not self._anchorUsingCustom then
					self:RefreshAnchor()
				elseif not (_G and _G[EQOL_PLAYER_CASTBAR]) then
					self:ScheduleAnchorRefresh(target)
				end
			elseif self._anchorUsingCustom then
				self:RefreshAnchor()
			end
		elseif target ~= ANCHOR_TARGET_UI then
			if not self:IsAnchorFrameReady(_G and _G[target]) then self:ScheduleAnchorRefresh(target) end
		end
	end

	local widthMatchHookedFrames = {}
	local pendingWidthHookRetries = {}
	local widthHookRetryTimer
	local widthSyncQueued = false

	local function runDelayedMatchedWidthSync()
		widthSyncQueued = false
		if not (addon and addon.db and addon.db[DB_ENABLED] == true) then return end
		SwingBar:ApplySize()
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
	end

	local function processPendingWidthHookRetries()
		widthHookRetryTimer = nil
		local pending = pendingWidthHookRetries
		pendingWidthHookRetries = {}
		for frameName in pairs(pending) do
			if SwingBar and SwingBar.EnsureWidthSyncHook then SwingBar:EnsureWidthSyncHook(frameName) end
		end
	end

	local function onWidthMatchGeometryChanged()
		if SwingBar and SwingBar.AnchorUsesMatchedWidth and SwingBar:AnchorUsesMatchedWidth() then SwingBar:ScheduleMatchedWidthSync() end
	end

	local function onSwingBarEvent(_, event, ...) SwingBar:OnEvent(event, ...) end

	function SwingBar:ScheduleMatchedWidthSync()
		if widthSyncQueued then return end
		widthSyncQueued = true
		RunNextFrame(runDelayedMatchedWidthSync)
	end

	function SwingBar:EnsureWidthSyncHook(frameName)
		if not frameName or frameName == "" or frameName == ANCHOR_TARGET_UI or frameName == "EQOL_SwingBar" .. hand then return end
		if widthMatchHookedFrames[frameName] then return end
		local frame = _G and _G[frameName]
		if not frame then
			if C_Timer and C_Timer.After and not pendingWidthHookRetries[frameName] then
				pendingWidthHookRetries[frameName] = true
				if not widthHookRetryTimer then widthHookRetryTimer = C_Timer.NewTimer(1, processPendingWidthHookRetries) end
			end
			return
		end
		if frame.HookScript then
			local okSize = pcall(frame.HookScript, frame, "OnSizeChanged", onWidthMatchGeometryChanged)
			local okShow = pcall(frame.HookScript, frame, "OnShow", onWidthMatchGeometryChanged)
			local okHide = pcall(frame.HookScript, frame, "OnHide", onWidthMatchGeometryChanged)
			if okSize or okShow or okHide then widthMatchHookedFrames[frameName] = true end
		end
	end

	function SwingBar:EnsureWidthSyncHooks()
		if not self:AnchorUsesMatchedWidth() then return end
		local target = self:GetAnchorRelativeFrame()
		if target == ANCHOR_TARGET_PLAYER_CASTBAR then
			self:EnsureWidthSyncHook("PlayerCastingBarFrame")
			self:EnsureWidthSyncHook(EQOL_PLAYER_CASTBAR)
		elseif target ~= ANCHOR_TARGET_UI then
			self:EnsureWidthSyncHook(target)
		end
	end

	function SwingBar:GetResolvedWidth()
		local width = self:GetWidth()
		local winner = self:GetDynamicAnchorWinner()
		if winner then
			if not winner.matchRelativeWidth then return width end
			local relativeWidth = winner.frame and winner.frame.GetWidth and tonumber(winner.frame:GetWidth()) or 0
			if relativeWidth <= 0 then return width end
			return math.max(BAR_WIDTH_MIN, relativeWidth + (tonumber(winner.matchRelativeWidthOffset) or 0))
		end
		if not self:AnchorUsesMatchedWidth() then return width end
		local relativeFrame = self:ResolveAnchorFrame()
		if not (relativeFrame and relativeFrame.GetWidth) or relativeFrame == UIParent then return width end
		local relativeWidth = tonumber(relativeFrame:GetWidth()) or 0
		if relativeWidth <= 0 then return width end
		return math.max(BAR_WIDTH_MIN, relativeWidth + self:GetAnchorMatchWidthOffset())
	end

	function SwingBar:HideSpark()
		if self.frame and self.frame.spark then self.frame.spark:Hide() end
		if self.frame and self.frame.sparkGlow then self.frame.sparkGlow:Hide() end
	end

	function SwingBar:UpdateSpark(value)
		if not (self.frame and self.frame.spark) then return end
		local spark = self.frame.spark
		if not self:GetSparkEnabled() then
			self:HideSpark()
			return
		end
		if not (self.previewing or self._swingActive) then
			self:HideSpark()
			return
		end

		local width = tonumber(self.frame:GetWidth()) or 0
		local height = tonumber(self.frame:GetHeight()) or 0
		if width <= 0 or height <= 0 then
			self:HideSpark()
			return
		end

		local progress = value
		if progress == nil then
			if self.previewing then
				progress = 0.5
			elseif self.frame.GetValue then
				progress = self.frame:GetValue()
			end
		end
		progress = clamp01(progress)

		local fillDirection = self:GetFillDirection()
		local x = width * 0.5
		local y = height * 0.5
		if isVerticalFillDirection(fillDirection) then
			if fillDirection == "DOWN" then
				y = height * progress
			else
				y = height * (1 - progress)
			end
		else
			if fillDirection == "RIGHT" then
				x = width * (1 - progress)
			else
				x = width * progress
			end
		end
		spark:ClearAllPoints()
		addon.PixelUtil.Point(spark, "CENTER", self.frame, "TOPLEFT", x, -y)
		spark:Show()
		if self.frame.sparkGlow then self.frame.sparkGlow:SetShown(self:GetDisplayValue("sparkGlowEnabled") == true) end
	end

	function SwingBar:ApplySparkAppearance()
		if not (self.frame and self.frame.spark) then return end
		local spark = self.frame.spark
		if not self:GetSparkEnabled() then
			self:HideSpark()
			return
		end
		if spark.SetAtlas then
			local ok = spark:SetAtlas(SPARK_ATLAS, true)
			if ok == false then
				self:HideSpark()
				return
			end
		end
		addon.PixelUtil.ApplyTexturePixelSnapping(spark, 0)
		spark:SetBlendMode("ADD")
		spark:SetAlpha(1)
		local glow = self.frame.sparkGlow
		if not glow then
			-- Clip the trail independently so the spark can still extend across the bar's thickness.
			local clip = CreateFrame("Frame", nil, spark:GetParent())
			clip:SetAllPoints(self.frame)
			clip:SetClipsChildren(true)
			local content = CreateFrame("Frame", nil, clip)
			content:SetAllPoints(clip)
			glow = content:CreateTexture(nil, "OVERLAY", nil, -1)
			glow:SetAtlas("cast_standard_pipglow", false)
			glow:SetSize(37, 12)
			glow:SetBlendMode("ADD")
			self.frame.sparkGlow = glow
		end
		local direction = self:GetFillDirection()
		glow:ClearAllPoints()
		if direction == "RIGHT" then
			glow:SetRotation(math.pi)
			glow:SetPoint("CENTER", spark, "CENTER", 18, 0)
		elseif direction == "UP" then
			glow:SetRotation(math.pi * 0.5)
			glow:SetPoint("CENTER", spark, "CENTER", 0, -18)
		elseif direction == "DOWN" then
			glow:SetRotation(-math.pi * 0.5)
			glow:SetPoint("CENTER", spark, "CENTER", 0, 18)
		else
			glow:SetRotation(0)
			glow:SetPoint("CENTER", spark, "CENTER", -18, 0)
		end
		local custom = self:GetDisplayValue("sparkCustomColor") == true
		local r, g, b, a = 1, 1, 1, 1
		if custom then r, g, b, a = normalizeColor(self:GetDisplayValue("sparkColor"), defaults.sparkColor) end
		spark:SetDesaturated(custom)
		glow:SetDesaturated(custom)
		spark:SetVertexColor(r, g, b, a)
		glow:SetVertexColor(r, g, b, a)
		self:UpdateSpark()
	end

	function SwingBar:ApplyStrata()
		if not self.frame then return end
		local strata = self:GetStrata()
			or ((self.frame.GetParent and self.frame:GetParent() and self.frame:GetParent().GetFrameStrata and self.frame:GetParent():GetFrameStrata()) or self.frame:GetFrameStrata() or "MEDIUM")
		if self.frame.GetFrameStrata and self.frame.SetFrameStrata and self.frame:GetFrameStrata() ~= strata then self.frame:SetFrameStrata(strata) end
		if self.frame.border and self.frame.border.GetFrameStrata and self.frame.border.SetFrameStrata and self.frame.border:GetFrameStrata() ~= strata then self.frame.border:SetFrameStrata(strata) end
	end

	function SwingBar:GetDisplayValue(field)
		return getValue(DB_PREFIX .. field:sub(1, 1):upper() .. field:sub(2), defaults[field])
	end

	function SwingBar:ApplyTextAppearance()
		if not self.frame or not self.frame.timeText then return end
		for _, prefix in ipairs({ "text", "label" }) do
			local text = prefix == "text" and self.frame.timeText or self.frame.weaponLabel
			addon.functions.ApplyFontString(text, self:GetDisplayValue(prefix .. "Font"), clamp(self:GetDisplayValue(prefix .. "Size"), 6, 64), self:GetDisplayValue(prefix .. "Outline"))
			text:SetTextColor(normalizeColor(self:GetDisplayValue(prefix .. "Color"), defaults[prefix .. "Color"]))
			local point = normalizeAnchorPoint(self:GetDisplayValue(prefix .. "Point"), defaults[prefix .. "Point"])
			text:ClearAllPoints()
			addon.PixelUtil.Point(text, point, self.frame, point, clamp(self:GetDisplayValue(prefix .. "OffsetX"), -500, 500), clamp(self:GetDisplayValue(prefix .. "OffsetY"), -500, 500))
			text:SetShown(self:GetDisplayValue(prefix .. "Enabled") == true)
		end
	end

	function SwingBar:ApplyAppearance()
		if not self.frame then return end
		local texture = resolveTexture(self:GetTextureKey())
		self.frame:SetStatusBarTexture(texture)
		addon.PixelUtil.ApplyStatusBarTexturePixelSnapping(self.frame, 0)
		local r, g, b, a = self:GetColor()
		self.frame:SetStatusBarColor(r, g, b, a or 1)
		local fillDirection = self:GetFillDirection()
		if self.frame.SetOrientation then self.frame:SetOrientation(isVerticalFillDirection(fillDirection) and "VERTICAL" or "HORIZONTAL") end
		if self.frame.SetReverseFill then self.frame:SetReverseFill(isReverseFillDirection(fillDirection)) end

		if self.frame.bg then
			if self:GetBackgroundEnabled() then
				local bgTex = resolveTexture(self:GetBackgroundTextureKey())
				self.frame.bg:SetTexture(bgTex)
				addon.PixelUtil.ApplyTexturePixelSnapping(self.frame.bg, 0)
				local br, bg, bb, ba = self:GetBackgroundColor()
				local alpha = (ba == nil) and 1 or ba
				self.frame.bg:SetVertexColor(br or 0, bg or 0, bb or 0, alpha)
				self.frame.bg:Hide()
				if alpha > 0 then self.frame.bg:Show() end
			else
				self.frame.bg:Hide()
			end
		end

		if self.frame.border then
			if not self:GetBorderEnabled() then
				addon.functions.SetSafeBorder(self.frame.border, false, nil, nil, nil, nil, nil, nil, { stateKey = "_swingSafeBorder" })
			else
				local size = self:GetBorderSize()
				local offset = self:GetBorderOffset()
				local borderTex = resolveBorderTexture(self:GetBorderTextureKey())
				local br, bg, bb, ba = self:GetBorderColor()
				addon.PixelUtil.SetOutside(self.frame.border, self.frame, offset, offset)
				addon.functions.SetSafeBorder(self.frame.border, true, borderTex, size, br or 0, bg or 0, bb or 0, ba or 1, {
					stateKey = "_swingSafeBorder",
					defaultTexture = "Interface\\Buttons\\WHITE8x8",
					mediaType = "border",
					drawLayer = "OVERLAY",
					pixelPerfect = true,
				})
			end
		end

		self:ApplySparkAppearance()
		self:ApplyTextAppearance()
	end

	function SwingBar:OnMediaRegistered(mediaType, mediaKey)
		if type(mediaType) ~= "string" or type(mediaKey) ~= "string" or mediaKey == "" then return end
		if not (addon and addon.db and addon.db[DB_ENABLED] == true) then return end
		if not self.frame then return end

		local shouldRefresh = false
		if mediaType == "statusbar" then
			local textureKey = self:GetTextureKey()
			local bgTextureKey = self:GetBackgroundTextureKey()
			shouldRefresh = mediaKey == textureKey or mediaKey == bgTextureKey
		elseif mediaType == "font" then
			shouldRefresh = true
		elseif mediaType == "border" then
			shouldRefresh = mediaKey == self:GetBorderTextureKey()
		end

		if not shouldRefresh then return end

		self:ApplyAppearance()
		if self.previewing then
			self.frame:SetMinMaxValues(0, 1)
			self.frame:SetValue(1)
			self.frame:Show()
		elseif self._swingActive then
			self:UpdateTimer()
		end
		refreshSettingsUI()
	end

	function SwingBar:ApplySize()
		if not self.frame then return end
		if not (addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(self.dynamicAnchorId)) then self:EnsureWidthSyncHooks() end
		local width = self:GetResolvedWidth()
		local height = self:GetHeight()
		addon.PixelUtil.Size(self.frame, width, height)
		self:ApplyStrata()
		if self.frame.bg then addon.PixelUtil.SetInside(self.frame.bg, self.frame, 0, 0) end
		if self.frame.editBg then addon.PixelUtil.SetInside(self.frame.editBg, self.frame, 0, 0) end
		self:UpdateSpark()
	end

	function SwingBar:EnsureFrame()
		if self.frame then return self.frame end

		local bar = CreateFrame("StatusBar", "EQOL_SwingBar" .. hand, UIParent)
		bar:SetMinMaxValues(0, 1)
		bar:SetClampedToScreen(true)
		bar:Hide()

		local bg = bar:CreateTexture(nil, "BACKGROUND")
		addon.PixelUtil.SetInside(bg, bar, 0, 0)
		bar.bg = bg

		local editBg = bar:CreateTexture(nil, "BORDER")
		addon.PixelUtil.SetInside(editBg, bar, 0, 0)
		editBg:SetColorTexture(0.1, 0.6, 0.6, 0.2)
		editBg:Hide()
		bar.editBg = editBg

		local sparkLayer = CreateFrame("Frame", nil, bar)
		sparkLayer:SetAllPoints(bar)
		sparkLayer:SetFrameLevel((bar:GetFrameLevel() or 0) + 3)
		local spark = sparkLayer:CreateTexture(nil, "OVERLAY")
		spark:SetBlendMode("ADD")
		spark:Hide()
		bar.spark = spark

		local border = CreateFrame("Frame", nil, bar)
		addon.PixelUtil.SetInside(border, bar, 0, 0)
		border:SetFrameLevel((bar:GetFrameLevel() or 0) + 2)
		border:Hide()
		bar.border = border

		local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		addon.PixelUtil.Point(label, "CENTER", bar, "CENTER", 0, 0)
		label:SetText(displayTitle)
		label:Hide()
		bar.label = label

		bar.timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		bar.weaponLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		bar.weaponLabel:SetText(title)
		self.frame = bar
		self:ApplyAppearance()
		self:ApplySize()

		return bar
	end

	function SwingBar:ShowEditModeHint(show)
		if not self.frame then return end
		if show then
			if self.frame.editBg then self.frame.editBg:Show() end
			self.frame.label:ClearAllPoints()
			addon.PixelUtil.Point(self.frame.label, "BOTTOM", self.frame, "TOP", 0, 4)
			self.frame.label:Show()
			self.frame.timeText:SetText("1.5")
			self.previewing = true
			self.frame:SetMinMaxValues(0, 1)
			self.frame:SetValue(0.5)
			self.frame:Show()
			self:UpdateSpark(0.5)
		else
			if self.frame.editBg then self.frame.editBg:Hide() end
			self.frame.label:Hide()
			self.previewing = nil
			self:HideSpark()
			self:UpdateSwing()
		end
	end

	function SwingBar:ShouldShow()
		if self.previewing then return true end
		if self:GetDisplayValue("onlyInCombat") and not UnitAffectingCombat("player") then return false end
		if self:GetDisplayValue("onlyUnmounted") and IsMounted() then return false end
		local rb = addon.Aura and addon.Aura.ResourceBars
		if addon.variables.unitClass == "DRUID" and rb and rb.GetCurrentDruidFormKey then
			local forms = self:GetDisplayValue("showForms")
			if type(forms) == "table" and forms[rb.GetCurrentDruidFormKey()] == false then return false end
		end
		return true
	end

	function SwingBar:StopTimer()
		if self.frame and self.frame.SetScript then self.frame:SetScript("OnUpdate", nil) end
		self._swingActive = nil
		self._swingStart = nil
		self._swingDuration = nil
		if self.frame then
			self.frame:SetValue(0)
			self.frame.timeText:SetText("0.0")
			self.frame:SetShown(getValue(DB_ENABLED, false) and self:GetDisplayValue("alwaysShow") == true and self:ShouldShow() and self:CanSwing() and not (shouldHideInPetBattleForSwing() and isPetBattleActive()))
		end
		self:HideSpark()
	end

	function SwingBar:UpdateTimer()
		if self.previewing then return end
		if not self.frame then return end
		if not self._swingActive then return end
		local start = self._swingStart
		local duration = self._swingDuration
		if not start or not duration or duration <= 0 then
			self:StopTimer()
			return
		end
		local now = GetTime and GetTime() or 0
		local elapsed = now - start
		if elapsed >= duration then
			self:StopTimer()
			return
		end
		local progress = elapsed / duration
		if progress < 0 then progress = 0 end
		if progress > 1 then progress = 1 end
		local value = progress
		if self:GetProgressMode() ~= "ELAPSED" then value = 1 - progress end
		self.frame:SetMinMaxValues(0, 1)
		self.frame:SetValue(value)
		self.frame.timeText:SetFormattedText("%.1f", duration - elapsed)
		self.frame:SetShown(self:ShouldShow())
		self:UpdateSpark(value)
	end

	-- Forever's native PLAYER_SWING event supplies the duration for each weapon.
	-- Keep the same timing contract as the client swing timer, including ranged attacks.
	function SwingBar:CanSwing()
		if self.swingType == Enum.PlayerSwingType.MainHand then return true end
		local _, offHand, ranged = UnitAttackSpeed("player")
		local speed = ranged
		if self.swingType == Enum.PlayerSwingType.OffHand then speed = offHand end
		if issecretvalue and issecretvalue(speed) then
			-- Equipment remains usable when attack speed is restricted.
			if self.swingType == Enum.PlayerSwingType.OffHand then return C_PaperDollInfo.OffhandHasWeapon() end
			return GetInventoryItemID("player", INVSLOT_RANGED) ~= nil
		end
		return type(speed) == "number" and speed > 0
	end

	function SwingBar:UpdateSwing()
		if self.previewing or not self.frame then return end
		self:MaybeUpdateAnchor()
		if not getValue(DB_ENABLED, false) or not self:CanSwing() or (shouldHideInPetBattleForSwing() and isPetBattleActive()) then
			self:StopTimer()
			return
		end
		if self._swingActive then self:UpdateTimer() else self:StopTimer() end
	end

	function SwingBar:StartSwing(duration)
		if not getValue(DB_ENABLED, false) then return end
		if issecretvalue and issecretvalue(duration) then return end
		if type(duration) ~= "number" or duration <= 0 then return end
		self._swingStart = GetTime()
		self._swingDuration = duration
		self._swingActive = true
		self.frame:SetScript("OnUpdate", function() self:UpdateTimer() end)
		self:UpdateSwing()
	end

	function SwingBar:SuppressBlizzardFrame(frame)
		if not getValue(DB_ENABLED, false) then return end
		frame:Hide()
		frame:UnregisterEvent("PLAYER_SWING")
		frame:ClearSwingTimer()
		self._blizzardSuppressed = true
	end

	function SwingBar:SyncBlizzardFrame()
		local frame = _G["SwingTimer" .. hand .. "Frame"]
		if not frame then return end
		if getValue(DB_ENABLED, false) then
			if self._blizzardFrame ~= frame then
				self._blizzardFrame = frame
				frame:HookScript("OnShow", function(native) self:SuppressBlizzardFrame(native) end)
				-- Manager-dispatched swings can restart hidden frames without firing OnShow.
				hooksecurefunc(frame, "ResetSwingTimer", function(native) self:SuppressBlizzardFrame(native) end)
				-- Older clients register swing events on each frame instead of the shared manager.
				if type(frame.UpdateSwingEventRegistration) == "function" then
					hooksecurefunc(frame, "UpdateSwingEventRegistration", function(native) self:SuppressBlizzardFrame(native) end)
				end
			end
			self:SuppressBlizzardFrame(frame)
		elseif self._blizzardSuppressed then
			self._blizzardSuppressed = nil
			-- Restore the client's own CVar, equipment and Edit Mode visibility policy.
			frame:UpdateShownStateAndRegistration()
		end
	end

	function SwingBar:OnEvent(event, ...)
		if event == "PLAYER_SWING" then
			local duration, eventSwingType = ...
			if issecretvalue and issecretvalue(eventSwingType) then return end
			if eventSwingType == self.swingType then self:StartSwing(duration) end
		elseif event == "ADDON_LOADED" then
			if ... == "Blizzard_SwingTimer" then self:SyncBlizzardFrame() end
		elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DEAD" or event == "WEAPON_SLOT_CHANGED" then
			self:SyncBlizzardFrame()
			self:StopTimer()
			if self.previewing then self:ShowEditModeHint(true) end
		elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
			self:ApplySettingsMaxHeight()
			self:RefreshAnchor()
			self:ApplySize()
			self:ApplyAppearance()
		else
			self:UpdateSwing()
		end
	end

	function SwingBar:RegisterEvents()
		if self.eventsRegistered then return end
		local frame = self:EnsureFrame()
		for _, event in ipairs({ "PLAYER_SWING", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_DEAD", "WEAPON_SLOT_CHANGED", "PET_BATTLE_OPENING_START", "PET_BATTLE_CLOSE", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_MOUNT_DISPLAY_CHANGED", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS" }) do
			frame:RegisterEvent(event)
		end
		frame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
		frame:SetScript("OnEvent", onSwingBarEvent)
		self.eventsRegistered = true
	end

	function SwingBar:UnregisterEvents()
		if not self.frame then return end
		self.frame:UnregisterAllEvents()
		self.frame:SetScript("OnEvent", nil)
		self.eventsRegistered = false
	end

	local editModeRegistered = false

	function SwingBar:ApplyLayoutData(data)
		if not data or not addon.db then return end
		for _, field in ipairs(DISPLAY_FIELDS) do
			if data[field] ~= nil then addon.db[DB_PREFIX .. field:sub(1, 1):upper() .. field:sub(2)] = data[field] end
		end

		local width = clamp(data.width or defaults.width, BAR_WIDTH_MIN, BAR_SIZE_MAX)
		local height = clamp(data.height or defaults.height, BAR_HEIGHT_MIN, BAR_SIZE_MAX)
		local texture = data.texture or defaults.texture
		local r, g, b, a = normalizeColor(data.color or defaults.color, defaults.color)
		local sparkEnabled = addon.db[DB_SPARK_ENABLED] == true
		if data.sparkEnabled ~= nil then sparkEnabled = data.sparkEnabled == true end
		local bgEnabled = data.bgEnabled == true
		local bgTexture = data.bgTexture or defaults.bgTexture
		local bgr, bgg, bgb, bga = normalizeColor(data.bgColor or defaults.bgColor, defaults.bgColor)
		local borderEnabled = data.borderEnabled == true
		local borderTexture = data.borderTexture or defaults.borderTexture
		local bdr, bdg, bdb, bda = normalizeColor(data.borderColor or defaults.borderColor, defaults.borderColor)
		local borderSize = clamp(data.borderSize or defaults.borderSize, 1, 20)
		local borderOffset = clamp(data.borderOffset or defaults.borderOffset, -20, 20)
		local progressMode = normalizeProgressMode(data.progressMode or defaults.progressMode)
		local fillDirection = normalizeFillDirection(data.fillDirection or defaults.fillDirection)
		local anchorRelativeFrame = normalizeAnchorRelativeFrame(data.anchorRelativeFrame or data.anchorTarget or addon.db[DB_ANCHOR_RELATIVE_FRAME] or defaults.anchorRelativeFrame)
		local anchorMatchWidth = addon.db[DB_ANCHOR_MATCH_WIDTH] == true
		if data.anchorMatchWidth ~= nil then
			anchorMatchWidth = data.anchorMatchWidth == true
		elseif data.anchorMatchRelativeWidth ~= nil then
			anchorMatchWidth = data.anchorMatchRelativeWidth == true
		end
		local anchorMatchWidthOffset = clamp(data.anchorMatchWidthOffset or data.anchorMatchRelativeWidthOffset or addon.db[DB_ANCHOR_MATCH_WIDTH_OFFSET] or defaults.anchorMatchRelativeWidthOffset or 0, -200, 200)
		local anchorPoint = normalizeAnchorPoint(data.point or addon.db[DB_ANCHOR_POINT], defaults.anchorPoint)
		local anchorRelativePoint = normalizeAnchorPoint(data.relativePoint or addon.db[DB_ANCHOR_RELATIVE_POINT], anchorPoint)
		local anchorOffsetX = normalizeAnchorOffset(data.x ~= nil and data.x or addon.db[DB_ANCHOR_OFFSET_X], defaults.anchorOffsetX)
		local anchorOffsetY = normalizeAnchorOffset(data.y ~= nil and data.y or addon.db[DB_ANCHOR_OFFSET_Y], defaults.anchorOffsetY)
		local hideInPetBattle = addon.db[DB_HIDE_IN_PET_BATTLE] == true
		if data.hideInPetBattle ~= nil then hideInPetBattle = data.hideInPetBattle == true end
		local strata = normalizeStrataToken(data.strata or addon.db[DB_STRATA] or defaults.strata)

		addon.db[DB_WIDTH] = width
		addon.db[DB_HEIGHT] = height
		addon.db[DB_TEXTURE] = texture
		addon.db[DB_COLOR] = { r = r, g = g, b = b, a = a }
		addon.db[DB_SPARK_ENABLED] = sparkEnabled and true or false
		addon.db[DB_BG_ENABLED] = bgEnabled
		addon.db[DB_BG_TEXTURE] = bgTexture
		addon.db[DB_BG_COLOR] = { r = bgr, g = bgg, b = bgb, a = bga }
		addon.db[DB_BORDER_ENABLED] = borderEnabled
		addon.db[DB_BORDER_TEXTURE] = borderTexture
		addon.db[DB_BORDER_COLOR] = { r = bdr, g = bdg, b = bdb, a = bda }
		addon.db[DB_BORDER_SIZE] = borderSize
		addon.db[DB_BORDER_OFFSET] = borderOffset
		addon.db[DB_PROGRESS_MODE] = progressMode
		addon.db[DB_FILL_DIRECTION] = fillDirection
		local prevAnchorRelativeFrame = addon.db[DB_ANCHOR_RELATIVE_FRAME]
		addon.db[DB_ANCHOR_RELATIVE_FRAME] = anchorRelativeFrame
		addon.db[DB_ANCHOR_MATCH_WIDTH] = anchorMatchWidth and true or false
		addon.db[DB_ANCHOR_MATCH_WIDTH_OFFSET] = anchorMatchWidthOffset
		addon.db[DB_ANCHOR_POINT] = anchorPoint
		addon.db[DB_ANCHOR_RELATIVE_POINT] = anchorRelativePoint
		addon.db[DB_ANCHOR_OFFSET_X] = anchorOffsetX
		addon.db[DB_ANCHOR_OFFSET_Y] = anchorOffsetY
		addon.db[DB_HIDE_IN_PET_BATTLE] = hideInPetBattle and true or false
		addon.db[DB_STRATA] = strata

		self:ApplySize()
		self:ApplyAppearance()
		if prevAnchorRelativeFrame ~= anchorRelativeFrame then self:RefreshAnchor() end
		self:UpdateSwing()
	end

	local function applySetting(field, value)
		if not addon.db then return end
		local editField = field
		local skipEditValue

		if defaults[field] ~= nil and (field:sub(1, 4) == "text" or field:sub(1, 5) == "label" or field == "alwaysShow" or field == "onlyInCombat" or field == "onlyUnmounted" or field == "showForms" or field:sub(1, 5) == "spark") then
			if field == "textSize" or field == "labelSize" then value = clamp(value, 6, 64) end
			if field == "textOffsetX" or field == "textOffsetY" or field == "labelOffsetX" or field == "labelOffsetY" then value = clamp(value, -500, 500) end
			if field == "textPoint" or field == "labelPoint" then value = normalizeAnchorPoint(value, "CENTER") end
			addon.db[DB_PREFIX .. field:sub(1, 1):upper() .. field:sub(2)] = value
		elseif field == "width" then
			local width = clamp(value, BAR_WIDTH_MIN, BAR_SIZE_MAX)
			addon.db[DB_WIDTH] = width
			value = width
		elseif field == "height" then
			local height = clamp(value, BAR_HEIGHT_MIN, BAR_SIZE_MAX)
			addon.db[DB_HEIGHT] = height
			value = height
		elseif field == "texture" then
			local tex = value or defaults.texture
			addon.db[DB_TEXTURE] = tex
			value = tex
		elseif field == "color" then
			local r, g, b, a = normalizeColor(value, defaults.color)
			addon.db[DB_COLOR] = { r = r, g = g, b = b, a = a }
			value = addon.db[DB_COLOR]
		elseif field == "sparkEnabled" then
			local enabled = value == true
			addon.db[DB_SPARK_ENABLED] = enabled and true or false
			value = enabled
		elseif field == "bgEnabled" then
			local enabled = value == true
			addon.db[DB_BG_ENABLED] = enabled
			value = enabled
		elseif field == "bgTexture" then
			local tex = value or defaults.bgTexture
			addon.db[DB_BG_TEXTURE] = tex
			value = tex
		elseif field == "bgColor" then
			local r, g, b, a = normalizeColor(value, defaults.bgColor)
			addon.db[DB_BG_COLOR] = { r = r, g = g, b = b, a = a }
			value = addon.db[DB_BG_COLOR]
		elseif field == "borderEnabled" then
			local enabled = value == true
			addon.db[DB_BORDER_ENABLED] = enabled
			value = enabled
		elseif field == "borderTexture" then
			local tex = value or defaults.borderTexture
			addon.db[DB_BORDER_TEXTURE] = tex
			value = tex
		elseif field == "borderColor" then
			local r, g, b, a = normalizeColor(value, defaults.borderColor)
			addon.db[DB_BORDER_COLOR] = { r = r, g = g, b = b, a = a }
			value = addon.db[DB_BORDER_COLOR]
		elseif field == "borderSize" then
			local size = clamp(value, 1, 20)
			addon.db[DB_BORDER_SIZE] = size
			value = size
		elseif field == "borderOffset" then
			local offset = clamp(value, -20, 20)
			addon.db[DB_BORDER_OFFSET] = offset
			value = offset
		elseif field == "progressMode" then
			local mode = normalizeProgressMode(value)
			addon.db[DB_PROGRESS_MODE] = mode
			value = mode
		elseif field == "fillDirection" then
			local dir = normalizeFillDirection(value)
			addon.db[DB_FILL_DIRECTION] = dir
			value = dir
		elseif field == "anchorRelativeFrame" then
			local target = normalizeAnchorRelativeFrame(value)
			if not SwingBar:IsAnchorTargetAllowed(target) then return end
			local prev = addon.db[DB_ANCHOR_RELATIVE_FRAME]
			addon.db[DB_ANCHOR_RELATIVE_FRAME] = target
			editField = "anchorRelativeFrame"
			if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, editField, target, nil, true) end
			if prev ~= target then
				local point, relPoint, x, y = anchorDefaultsFor(target)
				addon.db[DB_ANCHOR_POINT] = point
				addon.db[DB_ANCHOR_RELATIVE_POINT] = relPoint
				addon.db[DB_ANCHOR_OFFSET_X] = x
				addon.db[DB_ANCHOR_OFFSET_Y] = y
				if EditMode and EditMode.SetValue then
					EditMode:SetValue(EDITMODE_ID, "point", point, nil, true)
					EditMode:SetValue(EDITMODE_ID, "relativePoint", relPoint, nil, true)
					EditMode:SetValue(EDITMODE_ID, "x", x, nil, true)
					EditMode:SetValue(EDITMODE_ID, "y", y, nil, true)
				end
				refreshSettingsUI()
			end
			value = target
			skipEditValue = true
		elseif field == "anchorMatchWidth" then
			local enabled = value == true
			addon.db[DB_ANCHOR_MATCH_WIDTH] = enabled and true or false
			value = enabled
			refreshSettingsUI()
		elseif field == "anchorMatchWidthOffset" then
			local offset = clamp(value, -200, 200)
			addon.db[DB_ANCHOR_MATCH_WIDTH_OFFSET] = offset
			value = offset
		elseif field == "anchorPoint" then
			local point = normalizeAnchorPoint(value, defaults.anchorPoint)
			addon.db[DB_ANCHOR_POINT] = point
			editField = "point"
			value = point
			local rel = normalizeAnchorPoint(addon.db[DB_ANCHOR_RELATIVE_POINT], point)
			if addon.db[DB_ANCHOR_RELATIVE_POINT] ~= rel then
				addon.db[DB_ANCHOR_RELATIVE_POINT] = rel
				if EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, "relativePoint", rel, nil, true) end
			end
		elseif field == "anchorRelativePoint" then
			local rel = normalizeAnchorPoint(value, defaults.anchorRelativePoint)
			addon.db[DB_ANCHOR_RELATIVE_POINT] = rel
			editField = "relativePoint"
			value = rel
		elseif field == "anchorOffsetX" then
			local offset = normalizeAnchorOffset(value, defaults.anchorOffsetX)
			addon.db[DB_ANCHOR_OFFSET_X] = offset
			editField = "x"
			value = offset
		elseif field == "anchorOffsetY" then
			local offset = normalizeAnchorOffset(value, defaults.anchorOffsetY)
			addon.db[DB_ANCHOR_OFFSET_Y] = offset
			editField = "y"
			value = offset
		elseif field == "hideInPetBattle" then
			local enabled = value == true
			addon.db[DB_HIDE_IN_PET_BATTLE] = enabled and true or false
			value = enabled
		elseif field == "strata" then
			local strata = normalizeStrataToken(value)
			addon.db[DB_STRATA] = strata
			value = strata or ""
		end

		if not skipEditValue and EditMode and EditMode.SetValue then EditMode:SetValue(EDITMODE_ID, editField, value, nil, true) end
		SwingBar:ApplySize()
		SwingBar:ApplyAppearance()
		SwingBar:RefreshAnchor()
		SwingBar:UpdateSwing()
	end

	function SwingBar:GetSettingsMaxHeight()
		local screenHeight = GetScreenHeight and tonumber(GetScreenHeight()) or nil
		if not screenHeight or screenHeight <= 0 then screenHeight = addon.variables and tonumber(addon.variables.screenHeight) end
		if not screenHeight or screenHeight <= 0 then return 900 end
		if screenHeight < 900 then return screenHeight end
		return math.max(900, screenHeight - 200)
	end

	function SwingBar:ApplySettingsMaxHeight()
		local lib = addon.EditModeLib or (EditMode and EditMode.lib)
		if lib and lib.SetFrameSettingsMaxHeight and self.frame then lib:SetFrameSettingsMaxHeight(self.frame, self:GetSettingsMaxHeight()) end
	end

	function SwingBar:RegisterEditMode()
		if editModeRegistered or not EditMode or not EditMode.RegisterFrame then return end

		local settings
		if SettingType then
			local function anchorFrameEntries()
				local entries = {}
				local seen = {}
				local function frameIsAvailable(key)
					if key == ANCHOR_TARGET_UI or key == ANCHOR_TARGET_PLAYER_CASTBAR then return true end
					return _G and _G[key] ~= nil
				end
				local function add(key, label, force)
					if not key or key == "" or key == "EQOLSharedSecondaryBar" or seen[key] then return end
					if not SwingBar:IsAnchorTargetAllowed(key) then return end
					if not force and not frameIsAvailable(key) then return end
					seen[key] = true
					entries[#entries + 1] = { key = key, label = label or key }
				end

				add(ANCHOR_TARGET_UI, L["Screen (UIParent)"] or "Screen (UIParent)", true)
				add(ANCHOR_TARGET_PLAYER_CASTBAR, L["Player Castbar"] or "Player Castbar", true)

				add("PlayerFrame", _G.HUD_EDIT_MODE_PLAYER_FRAME_LABEL or PLAYER or "Player Frame")
				add("TargetFrame", _G.HUD_EDIT_MODE_TARGET_FRAME_LABEL or TARGET or "Target Frame")

				add("EssentialCooldownViewer", L["cooldownViewerEssential"] or "Essential Cooldown Viewer")
				add("UtilityCooldownViewer", L["cooldownViewerUtility"] or "Utility Cooldown Viewer")
				add("BuffBarCooldownViewer", L["cooldownViewerBuffBar"] or "Buff Bar Cooldowns")
				add("BuffIconCooldownViewer", L["cooldownViewerBuffIcon"] or "Buff Icon Cooldowns")

				local cooldownPanels = addon.Aura and addon.Aura.CooldownPanels
				if cooldownPanels and cooldownPanels.GetRoot then
					local root = cooldownPanels:GetRoot()
					if root and root.panels then
						local order = root.order or {}
						local function addPanelEntry(panelId, panel)
							if not panel or panel.enabled == false then return end
								local label = (L["cooldownPanelReferenceLabel"]):format(tostring(panelId), panel.name or L["cooldownPanelDefaultName"])
							add("EQOL_CooldownPanel" .. tostring(panelId), label)
						end
						if #order > 0 then
							for _, panelId in ipairs(order) do
								addPanelEntry(panelId, root.panels[panelId])
							end
						else
							for panelId, panel in pairs(root.panels) do
								addPanelEntry(panelId, panel)
							end
						end
					end
				end

				local rb = addon.Aura and addon.Aura.ResourceBars
				for _, targetHand in ipairs({ "MainHand", "OffHand", "Ranged" }) do
					local bar = addon.SwingTimers[targetHand]
					if bar and targetHand ~= hand then add("EQOL_SwingBar" .. targetHand, L["SwingTimer"] .. " - " .. bar.title, true) end
				end
				if rb and rb.GetSharedSlotFrameName and rb.GetResolvedBarTypeForSharedSlot then
					local function addResourceSlot(slot, label)
						local frameName = rb.GetSharedSlotFrameName(slot)
						-- Preserve the selected slot across form changes without offering unassigned slots as new targets.
						if rb.GetResolvedBarTypeForSharedSlot(slot) or frameName == SwingBar:GetAnchorRelativeFrame() then add(frameName, label, true) end
					end
					addResourceSlot("MAIN", L["AutoEnableMain"])
					addResourceSlot("TERTIARY", L["ResourceBarsTertiary"])
				end
				add("EQOLHealthBar", HEALTH or "Health")
				if rb and rb.classPowerTypes then
					for _, pType in ipairs(rb.classPowerTypes) do
						local frameName = "EQOL" .. tostring(pType) .. "Bar"
						local label = (rb.PowerLabels and rb.PowerLabels[pType]) or _G["POWER_TYPE_" .. tostring(pType)] or tostring(pType)
						add(frameName, label)
					end
				end

				local current = SwingBar:GetAnchorRelativeFrame()
				if current and not seen[current] then add(current, current, true) end

				return entries
			end

			settings = {
				{
					name = L["Anchor to"] or "Anchor to",
					kind = SettingType.Dropdown,
					field = "anchorRelativeFrame",
					height = 180,
					get = function() return SwingBar:GetAnchorRelativeFrame() end,
					set = function(_, value) applySetting("anchorRelativeFrame", value) end,
					generator = function(_, root)
						for _, option in ipairs(anchorFrameEntries()) do
							root:CreateRadio(option.label, function() return SwingBar:GetAnchorRelativeFrame() == option.key end, function() applySetting("anchorRelativeFrame", option.key) end)
						end
					end,
				},
				{
					name = L["Anchor point"] or "Anchor point",
					kind = SettingType.Dropdown,
					field = "anchorPoint",
					height = 180,
					get = function() return SwingBar:GetAnchorPoint() end,
					set = function(_, value) applySetting("anchorPoint", value) end,
					generator = function(_, root)
						for _, point in ipairs(ANCHOR_POINTS) do
							root:CreateRadio(point, function() return SwingBar:GetAnchorPoint() == point end, function() applySetting("anchorPoint", point) end)
						end
					end,
				},
				{
					name = L["Relative point"] or "Relative point",
					kind = SettingType.Dropdown,
					field = "anchorRelativePoint",
					height = 180,
					get = function() return SwingBar:GetAnchorRelativePoint() end,
					set = function(_, value) applySetting("anchorRelativePoint", value) end,
					generator = function(_, root)
						for _, point in ipairs(ANCHOR_POINTS) do
							root:CreateRadio(point, function() return SwingBar:GetAnchorRelativePoint() == point end, function() applySetting("anchorRelativePoint", point) end)
						end
					end,
				},
				{
					name = L["X Offset"] or "X Offset",
					kind = SettingType.Slider,
					field = "anchorOffsetX",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					get = function() return SwingBar:GetAnchorOffsetX() end,
					set = function(_, value) applySetting("anchorOffsetX", value) end,
				},
				{
					name = L["Y Offset"] or "Y Offset",
					kind = SettingType.Slider,
					field = "anchorOffsetY",
					minValue = -1000,
					maxValue = 1000,
					valueStep = 1,
					allowInput = true,
					get = function() return SwingBar:GetAnchorOffsetY() end,
					set = function(_, value) applySetting("anchorOffsetY", value) end,
				},
				{
					name = L["Match relative frame width"] or "Match relative frame width",
					kind = SettingType.Checkbox,
					field = "anchorMatchWidth",
					default = defaults.anchorMatchRelativeWidth == true,
					get = function() return SwingBar:GetAnchorMatchWidth() end,
					set = function(_, value) applySetting("anchorMatchWidth", value) end,
					isEnabled = function() return not SwingBar:AnchorUsesUIParent() end,
				},
				{
					name = L["Offset"] or "Offset",
					kind = SettingType.Slider,
					field = "anchorMatchWidthOffset",
					minValue = -200,
					maxValue = 200,
					valueStep = 1,
					allowInput = true,
					default = defaults.anchorMatchRelativeWidthOffset or 0,
					get = function() return SwingBar:GetAnchorMatchWidthOffset() end,
					set = function(_, value) applySetting("anchorMatchWidthOffset", value) end,
					isEnabled = function() return SwingBar:AnchorUsesMatchedWidth() end,
				},
				{
					name = L["Hide in pet battles"] or "Hide in pet battles",
					kind = SettingType.Checkbox,
					field = "hideInPetBattle",
					default = defaults.hideInPetBattle == true,
					get = function() return SwingBar:GetHideInPetBattle() end,
					set = function(_, value) applySetting("hideInPetBattle", value) end,
				},
				{
					name = L["Frame strata"] or "Frame strata",
					kind = SettingType.Dropdown,
					field = "strata",
					height = 180,
					default = defaults.strata or "",
					get = function() return SwingBar:GetStrata() or "" end,
					set = function(_, value) applySetting("strata", value) end,
					generator = function(_, root)
						for _, option in ipairs(strataOptionsWithDefault()) do
							root:CreateRadio(option.label, function() return (SwingBar:GetStrata() or "") == option.value end, function() applySetting("strata", option.value) end)
						end
					end,
				},
				{
					name = L["Bar width"] or "Bar width",
					kind = SettingType.Slider,
					field = "width",
					default = defaults.width,
					minValue = BAR_WIDTH_MIN,
					maxValue = BAR_SIZE_MAX,
					valueStep = 1,
					allowInput = true,
					get = function() return SwingBar:GetWidth() end,
					set = function(_, value) applySetting("width", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isEnabled = function() return not SwingBar:AnchorUsesMatchedWidth() end,
				},
				{
					name = L["Bar height"] or "Bar height",
					kind = SettingType.Slider,
					field = "height",
					default = defaults.height,
					minValue = BAR_HEIGHT_MIN,
					maxValue = BAR_SIZE_MAX,
					valueStep = 1,
					allowInput = true,
					get = function() return SwingBar:GetHeight() end,
					set = function(_, value) applySetting("height", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
				},
				{
					name = L["Bar texture"] or "Bar texture",
					kind = SettingType.Dropdown,
					field = "texture",
					height = 180,
					get = function() return SwingBar:GetTextureKey() end,
					set = function(_, value) applySetting("texture", value) end,
					generator = function(_, root)
						for _, option in ipairs(textureOptions()) do
							root:CreateRadio(option.label, function() return SwingBar:GetTextureKey() == option.value end, function() applySetting("texture", option.value) end)
						end
					end,
				},
				{
					name = L["Bar color"] or "Bar color",
					kind = SettingType.Color,
					field = "color",
					default = defaults.color,
					hasOpacity = true,
					get = function()
						local r, g, b, a = SwingBar:GetColor()
						return { r = r, g = g, b = b, a = a }
					end,
					set = function(_, value) applySetting("color", value) end,
				},
				{
					name = L["gcdBarSparkEnabled"] or "Show spark",
					kind = SettingType.Checkbox,
					field = "sparkEnabled",
					default = defaults.sparkEnabled == true,
					get = function() return SwingBar:GetSparkEnabled() end,
					set = function(_, value) applySetting("sparkEnabled", value) end,
				},
				{
					name = L["Use background"] or "Use background",
					kind = SettingType.Checkbox,
					field = "bgEnabled",
					default = defaults.bgEnabled == true,
					get = function() return SwingBar:GetBackgroundEnabled() end,
					set = function(_, value) applySetting("bgEnabled", value) end,
				},
				{
					name = L["Background texture"] or "Background texture",
					kind = SettingType.Dropdown,
					field = "bgTexture",
					height = 180,
					get = function() return SwingBar:GetBackgroundTextureKey() end,
					set = function(_, value) applySetting("bgTexture", value) end,
					generator = function(_, root)
						for _, option in ipairs(textureOptions()) do
							root:CreateRadio(option.label, function() return SwingBar:GetBackgroundTextureKey() == option.value end, function() applySetting("bgTexture", option.value) end)
						end
					end,
					isEnabled = function() return SwingBar:GetBackgroundEnabled() end,
				},
				{
					name = L["Background color"] or "Background color",
					kind = SettingType.Color,
					field = "bgColor",
					default = defaults.bgColor,
					hasOpacity = true,
					get = function()
						local r, g, b, a = SwingBar:GetBackgroundColor()
						return { r = r, g = g, b = b, a = a }
					end,
					set = function(_, value) applySetting("bgColor", value) end,
					isEnabled = function() return SwingBar:GetBackgroundEnabled() end,
				},
				{
					name = L["Use border"] or "Use border",
					kind = SettingType.Checkbox,
					field = "borderEnabled",
					default = defaults.borderEnabled == true,
					get = function() return SwingBar:GetBorderEnabled() end,
					set = function(_, value) applySetting("borderEnabled", value) end,
				},
				{
					name = L["Border texture"] or "Border texture",
					kind = SettingType.Dropdown,
					field = "borderTexture",
					height = 180,
					get = function() return SwingBar:GetBorderTextureKey() end,
					set = function(_, value) applySetting("borderTexture", value) end,
					generator = function(_, root)
						for _, option in ipairs(borderOptions()) do
							root:CreateRadio(option.label, function() return SwingBar:GetBorderTextureKey() == option.value end, function() applySetting("borderTexture", option.value) end)
						end
					end,
					isEnabled = function() return SwingBar:GetBorderEnabled() end,
				},
				{
					name = L["Border size"] or "Border size",
					kind = SettingType.Slider,
					field = "borderSize",
					default = defaults.borderSize,
					minValue = 1,
					maxValue = 20,
					valueStep = 1,
					get = function() return SwingBar:GetBorderSize() end,
					set = function(_, value) applySetting("borderSize", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isEnabled = function() return SwingBar:GetBorderEnabled() end,
				},
				{
					name = L["Border offset"] or "Border offset",
					kind = SettingType.Slider,
					field = "borderOffset",
					default = defaults.borderOffset,
					minValue = -20,
					maxValue = 20,
					valueStep = 1,
					get = function() return SwingBar:GetBorderOffset() end,
					set = function(_, value) applySetting("borderOffset", value) end,
					formatter = function(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end,
					isEnabled = function() return SwingBar:GetBorderEnabled() end,
				},
				{
					name = EMBLEM_BORDER_COLOR,
					kind = SettingType.Color,
					field = "borderColor",
					default = defaults.borderColor,
					hasOpacity = true,
					get = function()
						local r, g, b, a = SwingBar:GetBorderColor()
						return { r = r, g = g, b = b, a = a }
					end,
					set = function(_, value) applySetting("borderColor", value) end,
					isEnabled = function() return SwingBar:GetBorderEnabled() end,
				},
				{
					name = L["gcdBarProgressMode"] or "Progress mode",
					kind = SettingType.Dropdown,
					field = "progressMode",
					height = 100,
					get = function() return SwingBar:GetProgressMode() end,
					set = function(_, value) applySetting("progressMode", value) end,
					generator = function(_, root)
						local opts = {
							{ value = "REMAINING", label = L["Deplete (remaining time)"] or "Deplete (remaining time)" },
							{ value = "ELAPSED", label = L["Fill (elapsed time)"] or "Fill (elapsed time)" },
						}
						for _, option in ipairs(opts) do
							root:CreateRadio(option.label, function() return SwingBar:GetProgressMode() == option.value end, function() applySetting("progressMode", option.value) end)
						end
					end,
				},
				{
					name = L["Fill direction"] or "Fill direction",
					kind = SettingType.Dropdown,
					field = "fillDirection",
					height = 140,
					get = function() return SwingBar:GetFillDirection() end,
					set = function(_, value) applySetting("fillDirection", value) end,
					generator = function(_, root)
						local opts = {
							{ value = "LEFT", label = L["Left to right"] or "Left to right" },
							{ value = "RIGHT", label = L["Right to left"] or "Right to left" },
							{ value = "UP", label = L["Bottom to top"] or "Bottom to top" },
							{ value = "DOWN", label = L["Top to bottom"] or "Top to bottom" },
						}
						for _, option in ipairs(opts) do
							root:CreateRadio(option.label, function() return SwingBar:GetFillDirection() == option.value end, function() applySetting("fillDirection", option.value) end)
						end
					end,
				},
			}
			for _, option in ipairs({
				{ "sparkGlowEnabled", L["swingBarSparkGlow"] },
				{ "sparkCustomColor", L["swingBarSparkCustomColor"] },
				{ "sparkColor", L["swingBarSparkColor"] },
			}) do
				local field = option[1]
				settings[#settings + 1] = {
					name = option[2], field = field, default = defaults[field],
					kind = field == "sparkColor" and SettingType.Color or SettingType.Checkbox,
					hasOpacity = field == "sparkColor",
					get = function() return SwingBar:GetDisplayValue(field) end,
					set = function(_, value) applySetting(field, value) end,
					isEnabled = function() return SwingBar:GetSparkEnabled() and (field ~= "sparkColor" or SwingBar:GetDisplayValue("sparkCustomColor") == true) end,
				}
			end
			settings[#settings + 1] = { name = L["Text"], kind = SettingType.Collapsible, id = EDITMODE_ID .. "Text" }
			local function addDisplaySetting(field, label, kind, options)
				local setting = {
					name = label, kind = kind, field = field, default = defaults[field], parentId = field:sub(1, 5) == "label" and EDITMODE_ID .. "Label" or EDITMODE_ID .. "Text",
					get = function() return SwingBar:GetDisplayValue(field) end,
					set = function(_, value) applySetting(field, value) end,
				}
				for key, value in pairs(options or {}) do setting[key] = value end
				settings[#settings + 1] = setting
			end
			local function dropdownOptions(field, getOptions)
				return { height = 180, generator = function(_, root)
					for _, option in ipairs(getOptions()) do
						root:CreateRadio(option.label, function() return SwingBar:GetDisplayValue(field) == option.value end, function() applySetting(field, option.value) end)
					end
				end }
			end
			table.insert(settings, 1, {
				name = L["Always show"], kind = SettingType.Checkbox, field = "alwaysShow", default = defaults.alwaysShow,
				get = function() return SwingBar:GetDisplayValue("alwaysShow") end,
				set = function(_, value) applySetting("alwaysShow", value) end,
			})
			addDisplaySetting("onlyInCombat", L["unitframeVisibility_showCombat"], SettingType.Checkbox)
			addDisplaySetting("onlyUnmounted", L["Not mounted"], SettingType.Checkbox)
			if addon.variables.unitClass == "DRUID" then
				settings[#settings + 1] = {
					name = L["swingTimerShowForms"], kind = SettingType.MultiDropdown, field = "showForms",
					default = CopyTable(defaults.showForms), height = 220,
					values = {
						{ value = "HUMANOID", label = L["Humanoid"] }, { value = "BEAR", label = L["Bear"] },
						{ value = "CAT", label = L["Cat"] }, { value = "TRAVEL", label = L["Travel"] },
						{ value = "MOONKIN", label = L["Moonkin"] }, { value = "STAG", label = L["Stag"] },
					},
					isSelected = function(_, value) return SwingBar:GetDisplayValue("showForms")[value] ~= false end,
					setSelected = function(_, value, selected)
						local forms = CopyTable(SwingBar:GetDisplayValue("showForms"))
						forms[value] = selected == true
						applySetting("showForms", forms)
					end,
				}
			end
			addDisplaySetting("textEnabled", L["xpBarTextEnabled"], SettingType.Checkbox)
			addDisplaySetting("textFont", L["Text font"], SettingType.Dropdown, dropdownOptions("textFont", function()
				local options = { { value = addon.functions.GetGlobalFontConfigKey(), label = addon.functions.GetGlobalFontConfigLabel() } }
				for _, name in ipairs(getCachedMediaNames("font")) do options[#options + 1] = { value = name, label = name } end
				return options
			end))
			addDisplaySetting("textOutline", L["Text outline"], SettingType.Dropdown, dropdownOptions("textOutline", function() return addon.functions.GetFontStyleOptionList(true) end))
			addDisplaySetting("textSize", L["Text size"], SettingType.Slider, { minValue = 6, maxValue = 64, valueStep = 1, allowInput = true })
			addDisplaySetting("textColor", L["Text color"], SettingType.Color, { hasOpacity = true })
			addDisplaySetting("textPoint", L["Anchor point"], SettingType.Dropdown, dropdownOptions("textPoint", function()
				local options = {}
				for _, point in ipairs(ANCHOR_POINTS) do options[#options + 1] = { value = point, label = point } end
				return options
			end))
			addDisplaySetting("textOffsetX", L["swingTimerTextOffsetX"], SettingType.Slider, { minValue = -500, maxValue = 500, valueStep = 1, allowInput = true })
			addDisplaySetting("textOffsetY", L["swingTimerTextOffsetY"], SettingType.Slider, { minValue = -500, maxValue = 500, valueStep = 1, allowInput = true })
			settings[#settings + 1] = { name = L["CooldownPanelBarLabelHeader"], kind = SettingType.Collapsible, id = EDITMODE_ID .. "Label" }
			addDisplaySetting("labelEnabled", L["CooldownPanelBarShowLabel"], SettingType.Checkbox)
			addDisplaySetting("labelFont", L["CooldownPanelBarLabelFont"], SettingType.Dropdown, dropdownOptions("labelFont", function()
				local options = { { value = addon.functions.GetGlobalFontConfigKey(), label = addon.functions.GetGlobalFontConfigLabel() } }
				for _, name in ipairs(getCachedMediaNames("font")) do options[#options + 1] = { value = name, label = name } end
				return options
			end))
			addDisplaySetting("labelOutline", L["CooldownPanelBarLabelStyle"], SettingType.Dropdown, dropdownOptions("labelOutline", function() return addon.functions.GetFontStyleOptionList(true) end))
			addDisplaySetting("labelSize", L["CooldownPanelBarLabelSize"], SettingType.Slider, { minValue = 6, maxValue = 64, valueStep = 1, allowInput = true })
			addDisplaySetting("labelColor", L["CooldownPanelBarLabelColor"], SettingType.Color, { hasOpacity = true })
			addDisplaySetting("labelPoint", L["CooldownPanelBarLabelAnchor"], SettingType.Dropdown, dropdownOptions("labelPoint", function()
				local options = {}
				for _, point in ipairs(ANCHOR_POINTS) do options[#options + 1] = { value = point, label = point } end
				return options
			end))
			addDisplaySetting("labelOffsetX", L["CooldownPanelBarLabelOffsetX"], SettingType.Slider, { minValue = -500, maxValue = 500, valueStep = 1, allowInput = true })
			addDisplaySetting("labelOffsetY", L["CooldownPanelBarLabelOffsetY"], SettingType.Slider, { minValue = -500, maxValue = 500, valueStep = 1, allowInput = true })
			local groups = {
				{ "Anchor", _G.HUD_EDIT_MODE_SETTING_ANCHOR or L["Anchor point"] },
				{ "Visibility", L["Visibility"] },
				{ "Frame", L["Frame"] },
				{ "Bar", L["Bar"] },
				{ "Background", L["Background"] },
				{ "Border", L["Border"] },
				{ "Text", L["Text"] },
				{ "Label", L["CooldownPanelBarLabelHeader"] },
			}
			local grouped = {}
			for _, group in ipairs(groups) do grouped[group[1]] = {} end
			for _, setting in ipairs(settings) do
				if setting.kind ~= SettingType.Collapsible then
					local field = setting.field or ""
					local group = "Bar"
					if field:sub(1, 6) == "anchor" then group = "Anchor"
					elseif field == "alwaysShow" or field == "hideInPetBattle" or field == "onlyInCombat" or field == "onlyUnmounted" or field == "showForms" then group = "Visibility"
					elseif field == "width" or field == "height" or field == "strata" then group = "Frame"
					elseif field:sub(1, 2) == "bg" then group = "Background"
					elseif field:sub(1, 6) == "border" then group = "Border"
					elseif field ~= "texture" and field:sub(1, 4) == "text" then group = "Text"
					elseif field:sub(1, 5) == "label" then group = "Label" end
					setting.parentId = EDITMODE_ID .. group
					grouped[group][#grouped[group] + 1] = setting
				end
			end
			settings = {}
			for _, group in ipairs(groups) do
				settings[#settings + 1] = { name = group[2], kind = SettingType.Collapsible, id = EDITMODE_ID .. group[1], defaultCollapsed = true }
				for _, setting in ipairs(grouped[group[1]]) do settings[#settings + 1] = setting end
			end
			local factory = CopyTable(defaults)
			factory.anchorMatchWidth = defaults.anchorMatchRelativeWidth
			factory.anchorMatchWidthOffset = defaults.anchorMatchRelativeWidthOffset
			factory.strata = defaults.strata or ""
			if addon.EditModeNavigationDefaults then addon.EditModeNavigationDefaults.Prepare(settings, factory) end
			local labels = {
				width = L["Width"], height = L["Height"], strata = L["Strata"], texture = L["Texture"], color = L["Color"],
				anchorOffsetX = L["Offset X"], anchorOffsetY = L["Offset Y"],
				bgTexture = L["Texture"], bgColor = L["Color"], borderTexture = L["Texture"], borderColor = L["Color"],
				borderSize = L["Size"], borderOffset = L["Offset"],
				textFont = L["Font"], textOutline = L["Font outline"], textSize = _G.FONT_SIZE or L["Font Size"], textColor = L["Color"],
				textPoint = L["Anchor"], textOffsetX = L["Offset X"], textOffsetY = L["Offset Y"],
				labelFont = L["Font"], labelOutline = L["Font outline"], labelSize = _G.FONT_SIZE or L["Font Size"], labelColor = L["Color"],
				labelPoint = L["Anchor"], labelOffsetX = L["Offset X"], labelOffsetY = L["Offset Y"],
			}
			for _, setting in ipairs(settings) do
				if labels[setting.field] then
					setting.searchTags = setting.name
					setting.name = labels[setting.field]
				end
			end
			if addon.DynamicAnchors then
				addon.DynamicAnchors:AddEditModeAssignmentSettings(settings, SettingType, {
					consumerId = self.dynamicAnchorId,
					parentId = EDITMODE_ID .. "Anchor",
					insertAfterId = EDITMODE_ID .. "Anchor",
					refresh = function(rebuild)
						if rebuild and EditMode and EditMode.RefreshFrame then
							EditMode:RefreshFrame(EDITMODE_ID)
							RunNextFrame(function()
								SwingBar:ApplyDynamicAnchor()
								SwingBar:ApplySize()
							end)
						else
							SwingBar:ApplyDynamicAnchor()
							SwingBar:ApplySize()
						end
					end,
					staticFields = {
						anchorRelativeFrame = true,
						anchorPoint = true,
						anchorRelativePoint = true,
						anchorOffsetX = true,
						anchorOffsetY = true,
						anchorMatchWidth = true,
						anchorMatchWidthOffset = true,
					},
				})
			end
		end

		local function seedEditModeRecordFromProfile(record)
			if type(record) ~= "table" then return end
			for _, field in ipairs(DISPLAY_FIELDS) do record[field] = self:GetDisplayValue(field) end
			record.point = self:GetAnchorPoint()
			record.relativePoint = self:GetAnchorRelativePoint()
			record.x = self:GetAnchorOffsetX()
			record.y = self:GetAnchorOffsetY()
			record.width = self:GetWidth()
			record.height = self:GetHeight()
			record.texture = self:GetTextureKey()
			record.sparkEnabled = self:GetSparkEnabled()
			record.bgEnabled = self:GetBackgroundEnabled()
			record.bgTexture = self:GetBackgroundTextureKey()
			do
				local r, g, b, a = self:GetBackgroundColor()
				record.bgColor = { r = r, g = g, b = b, a = a }
			end
			record.borderEnabled = self:GetBorderEnabled()
			record.borderTexture = self:GetBorderTextureKey()
			do
				local r, g, b, a = self:GetBorderColor()
				record.borderColor = { r = r, g = g, b = b, a = a }
			end
			record.borderSize = self:GetBorderSize()
			record.borderOffset = self:GetBorderOffset()
			record.progressMode = self:GetProgressMode()
			record.fillDirection = self:GetFillDirection()
			record.anchorRelativeFrame = self:GetAnchorRelativeFrame()
			record.anchorMatchWidth = self:GetAnchorMatchWidth()
			record.anchorMatchWidthOffset = self:GetAnchorMatchWidthOffset()
			record.hideInPetBattle = self:GetHideInPetBattle()
			record.strata = self:GetStrata() or ""
			do
				local r, g, b, a = self:GetColor()
				record.color = { r = r, g = g, b = b, a = a }
			end
		end

		EditMode:RegisterFrame(EDITMODE_ID, {
			frame = self:EnsureFrame(),
			anchorAdapter = {
				consumerId = SwingBar.dynamicAnchorId,
				inheritSizeSettings = true,
				snapshot = function()
					return {
						point = self:GetAnchorPoint(), relativePoint = self:GetAnchorRelativePoint(),
						x = self:GetAnchorOffsetX(), y = self:GetAnchorOffsetY(),
						anchorRelativeFrame = self:GetAnchorRelativeFrame(), anchorMatchWidth = self:GetAnchorMatchWidth(),
						width = self:GetWidth(), height = self:GetHeight(),
					}
				end,
				restore = function(saved)
					local data = EditMode:EnsureLayoutData(EDITMODE_ID)
					for key, value in pairs(saved) do data[key] = value end
					SwingBar:ApplyLayoutData(data)
				end,
				prepareSize = function(axis)
					if axis == "width" then applySetting("anchorMatchWidth", false) end
				end,
				detach = function(point, relativePoint, x, y)
					applySetting("anchorRelativeFrame", "UIParent")
					applySetting("anchorMatchWidth", false)
					EditMode:SetFramePosition(EDITMODE_ID, point, x, y, nil, false, relativePoint)
				end,
			},
			title = displayTitle,
			managerCategory = "resourceBars",
			layoutDefaults = {
				sparkGlowEnabled = self:GetDisplayValue("sparkGlowEnabled"),
				sparkCustomColor = self:GetDisplayValue("sparkCustomColor"),
				sparkColor = self:GetDisplayValue("sparkColor"),
				textEnabled = self:GetDisplayValue("textEnabled"),
				alwaysShow = self:GetDisplayValue("alwaysShow"),
				onlyInCombat = self:GetDisplayValue("onlyInCombat"),
				onlyUnmounted = self:GetDisplayValue("onlyUnmounted"),
				showForms = CopyTable(self:GetDisplayValue("showForms")),
				labelEnabled = self:GetDisplayValue("labelEnabled"),
				labelFont = self:GetDisplayValue("labelFont"),
				labelOutline = self:GetDisplayValue("labelOutline"),
				labelSize = self:GetDisplayValue("labelSize"),
				labelColor = self:GetDisplayValue("labelColor"),
				labelPoint = self:GetDisplayValue("labelPoint"),
				labelOffsetX = self:GetDisplayValue("labelOffsetX"),
				labelOffsetY = self:GetDisplayValue("labelOffsetY"),
				textFont = self:GetDisplayValue("textFont"),
				textOutline = self:GetDisplayValue("textOutline"),
				textSize = self:GetDisplayValue("textSize"),
				textColor = self:GetDisplayValue("textColor"),
				textPoint = self:GetDisplayValue("textPoint"),
				textOffsetX = self:GetDisplayValue("textOffsetX"),
				textOffsetY = self:GetDisplayValue("textOffsetY"),
				point = self:GetAnchorPoint(),
				relativePoint = self:GetAnchorRelativePoint(),
				x = self:GetAnchorOffsetX(),
				y = self:GetAnchorOffsetY(),
				width = self:GetWidth(),
				height = self:GetHeight(),
				texture = self:GetTextureKey(),
				sparkEnabled = self:GetSparkEnabled(),
				bgEnabled = self:GetBackgroundEnabled(),
				bgTexture = self:GetBackgroundTextureKey(),
				bgColor = (function()
					local r, g, b, a = self:GetBackgroundColor()
					return { r = r, g = g, b = b, a = a }
				end)(),
				borderEnabled = self:GetBorderEnabled(),
				borderTexture = self:GetBorderTextureKey(),
				borderColor = (function()
					local r, g, b, a = self:GetBorderColor()
					return { r = r, g = g, b = b, a = a }
				end)(),
				borderSize = self:GetBorderSize(),
				borderOffset = self:GetBorderOffset(),
				progressMode = self:GetProgressMode(),
				fillDirection = self:GetFillDirection(),
				anchorRelativeFrame = self:GetAnchorRelativeFrame(),
				anchorMatchWidth = self:GetAnchorMatchWidth(),
				anchorMatchWidthOffset = self:GetAnchorMatchWidthOffset(),
				hideInPetBattle = self:GetHideInPetBattle(),
				strata = self:GetStrata() or "",
				color = (function()
					local r, g, b, a = self:GetColor()
					return { r = r, g = g, b = b, a = a }
				end)(),
			},
			normalizePosition = true,
			onApply = function(_, _, data)
				if not self._eqolEditModeHydrated then
					self._eqolEditModeHydrated = true
					local record = data or {}
					seedEditModeRecordFromProfile(record)
					SwingBar:ApplyLayoutData(record)
					return
				end
				SwingBar:ApplyLayoutData(data)
			end,
			onEnter = function()
				SwingBar:ApplySettingsMaxHeight()
				SwingBar:ShowEditModeHint(true)
				if addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(SwingBar.dynamicAnchorId) then
					RunNextFrame(function()
						if SwingBar.previewing then SwingBar:ApplyDynamicAnchor() end
					end)
				end
			end,
			onExit = function() SwingBar:ShowEditModeHint(false) end,
			isEnabled = function() return addon.db and addon.db[DB_ENABLED] end,
			settings = settings,
			settingsMaxHeight = self:GetSettingsMaxHeight(),
			collapseExclusive = true,
			relativeTo = function()
				local winner = SwingBar:GetDynamicAnchorWinner()
				return winner and winner.frame or SwingBar:ResolveAnchorFrame()
			end,
			allowDrag = function()
				return not (addon.DynamicAnchors and addon.DynamicAnchors:IsFrameAssignmentEnabled(SwingBar.dynamicAnchorId)) and SwingBar:AnchorUsesUIParent()
			end,
			showOutsideEditMode = false,
			manageVisibilityOutsideEditMode = false,
			showReset = false,
			showSettingsReset = false,
			enableOverlayToggle = true,
		})

		editModeRegistered = true
	end

	function SwingBar:OnSettingChanged(enabled)
		if enabled then
			if addon.DynamicAnchors then
				addon.DynamicAnchors:RegisterSimpleFrame({
					id = self.dynamicAnchorId,
					owner = "EnhanceQoLResourceBars",
					label = displayTitle,
					menuGroup = "RESOURCE_BARS",
					menuGroupLabel = L["Resource Bars"],
					menuGroupOrder = 200,
					getFrame = function() return SwingBar.frame end,
					isAvailable = function(bar) return addon.db and addon.db[DB_ENABLED] == true and bar ~= nil and bar:IsShown() end,
					apply = function()
						SwingBar:ApplyDynamicAnchor()
						SwingBar:ApplySize()
					end,
				})
			end
			self:EnsureFrame()
			self:RegisterEditMode()
			self:ApplySettingsMaxHeight()
			self:RegisterEvents()
			self:ApplySize()
			self:ApplyAppearance()
			self:UpdateSwing()
		else
			self.previewing = nil
			self:UnregisterEvents()
			self:StopTimer()
			if self.frame then self.frame:Hide() end
			cancelAnchorRefreshTicker()
		end

		self:SyncBlizzardFrame()
		if EditMode and EditMode.RefreshFrame then EditMode:RefreshFrame(EDITMODE_ID) end
		if enabled then
			for _, bar in pairs(addon.SwingTimers) do
				if bar ~= self and bar.frame and bar:GetAnchorRelativeFrame() == "EQOL_SwingBar" .. hand then
					bar:RefreshAnchor()
					bar:ApplySize()
				end
			end
		end
	end

	return SwingBar
end

local types = Enum.PlayerSwingType
addon.SwingTimers.MainHand = createSwingBar("MainHand", types.MainHand, _G.SWING_TIMER_MAIN_HAND, -145, { r = 1, g = 0.82, b = 0.2, a = 1 })
addon.SwingTimers.OffHand = createSwingBar("OffHand", types.OffHand, _G.SWING_TIMER_OFF_HAND, -170, { r = 0.3, g = 0.75, b = 1, a = 1 })
addon.SwingTimers.Ranged = createSwingBar("Ranged", types.Ranged, _G.SWING_TIMER_RANGED, -195, { r = 0.4, g = 1, b = 0.4, a = 1 })
for hand, bar in pairs(addon.SwingTimers) do
	addon.functions.InitDBValue("swingBar" .. hand .. "Enabled", false)
	bar:OnSettingChanged(addon.db["swingBar" .. hand .. "Enabled"])
end

-- Resource slot frames may be created after a saved swing-bar anchor is applied.
local resourceBars = addon.Aura and addon.Aura.ResourceBars
if resourceBars and resourceBars.SyncSharedSlotProxyFrames then
	local refreshQueued = false
	hooksecurefunc(resourceBars, "SyncSharedSlotProxyFrames", function()
		if refreshQueued then return end
		refreshQueued = true
		RunNextFrame(function()
			refreshQueued = false
			for hand, bar in pairs(addon.SwingTimers) do
				if bar.frame and addon.db["swingBar" .. hand .. "Enabled"] then
					local target = bar:GetAnchorRelativeFrame()
					if resourceBars.GetSharedSlotFromFrameName(target) then
						bar:RefreshAnchor()
						bar:ApplySize()
					end
				end
			end
		end)
	end)
end
