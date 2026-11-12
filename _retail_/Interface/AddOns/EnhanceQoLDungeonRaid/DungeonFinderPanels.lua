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

local openRaidLib = LibStub:GetLibrary("LibOpenKeystone-1.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local parentFrame = PVEFrame
local eventFrame = CreateFrame("Frame")
local doAfterCombat = false
local selectedMapId
local minFrameSize = 0
local issecretvalue = _G.issecretvalue
local mapInfo, mapIDInfo = {}, {}

local function GetTeleportFrame()
	local functions = addon.MythicPlus.functions
	return functions.GetDungeonTeleportFrame and functions.GetDungeonTeleportFrame()
end

local function ensureCurrentSeasonPortalCache(forceRefresh)
	local provider = addon.MythicPlus.functions.GetDungeonPortalMapInfo
	if provider then
		mapInfo, mapIDInfo = provider(forceRefresh)
		return
	end
	-- Dungeon information remains available with the Teleport Compendium disabled.
	mapInfo, mapIDInfo = {}, {}
	for _, id in ipairs(C_ChallengeMode.GetMapTable() or {}) do
		local name, _, _, texture, background, mapID = C_ChallengeMode.GetMapUIInfo(id)
		mapInfo[id] = { mapName = name, texture = texture, background = background }
		if mapID then mapIDInfo[mapID] = id end
	end
end

local function isRestrictedContent()
	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	local restrictedActions = _G.C_RestrictedActions
	if not (restrictionTypes and restrictedActions and restrictedActions.GetAddOnRestrictionState) then return false end
	for _, v in pairs(restrictionTypes) do
		if v ~= 4 then
			if restrictedActions.GetAddOnRestrictionState(v) == 2 then return true end
		end
	end
	return false
end

local function SafeSetSize(frame, width, height)
	if not frame then return end
	if InCombatLockdown() then
		doAfterCombat = true
	else
		frame:SetSize(width, height)
	end
end

local textList = {}
local textListUsed = 0
local gFrameAnchorScore
local measureFontString
local EnsureMeasureFontString

local function TryGetSafeNumber(getter)
	local ok, value = pcall(getter)
	if not ok or type(value) ~= "number" then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

local function TryGetSafeAnchorMetric(getter)
	local ok, value = pcall(getter)
	if not ok or type(value) ~= "number" then return nil end
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

local function ConfigureMeasureFont(fontString, fontObject, fontPath, fontSize, fontFlags)
	if not fontString then return end
	if fontObject then
		fontString:SetFontObject(fontObject)
	elseif fontPath and fontSize then
		fontString:SetFont(fontPath, fontSize, fontFlags)
	else
		fontString:SetFontObject(GameFontNormal)
	end
end

local function MeasureTextWidth(text, fontObject, fontPath, fontSize, fontFlags)
	local fontString = EnsureMeasureFontString and EnsureMeasureFontString()
	if not fontString then return 0 end
	ConfigureMeasureFont(fontString, fontObject, fontPath, fontSize, fontFlags)
	fontString:SetText(text and tostring(text) or "")
	return TryGetSafeNumber(function() return fontString:GetStringWidth() end) or 0
end

local function MeasureTextHeight(text, fontObject, fontPath, fontSize, fontFlags)
	local fontString = EnsureMeasureFontString and EnsureMeasureFontString()
	if not fontString then return 0 end
	ConfigureMeasureFont(fontString, fontObject, fontPath, fontSize, fontFlags)
	fontString:SetText(text and tostring(text) or "")
	return TryGetSafeNumber(function() return fontString:GetStringHeight() end) or 0
end

local function GetSafeFrameWidth(frame)
	if not (frame and frame.GetWidth) then return 0 end
	return TryGetSafeNumber(function() return frame:GetWidth() end) or 0
end

local function GetSafeElementBottomOffset(element)
	if not (element and element.GetPoint and element.GetHeight) then return nil end
	local ok, pointY = pcall(function()
		local _, _, _, _, y = element:GetPoint()
		return y
	end)
	if not ok then return nil end
	local yOffset = TryGetSafeAnchorMetric(function() return pointY end)
	local height = TryGetSafeAnchorMetric(function() return element:GetHeight() end)
	if yOffset == nil or height == nil then return nil end
	return yOffset - height
end

local function acquireRioText(index)
	local fs = textList[index]
	if fs then return fs end
	fs = gFrameAnchorScore:CreateFontString(nil, "OVERLAY")
	fs:SetFont(addon.variables.defaultFont, 14, "OUTLINE")
	textList[index] = fs
	return fs
end

local function updateRioLockButton(button)
	if not (button and button.icon) then return end
	button.isDocked = addon.db.dungeonScoreFrameLocked and true or false
	if button.isDocked then
		button.icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\ClosedLock.tga")
	else
		button.icon:SetTexture("Interface\\Addons\\EnhanceQoL\\Icons\\OpenLock.tga")
	end
end

local function hideUnusedRioText()
	for i = textListUsed + 1, #textList do
		textList[i]:Hide()
	end
end

local function createString(textLeft, textRight, colorLeft, colorRight, anchor, selected, fallbackY)
	local yOffset = fallbackY
	if yOffset == nil then
		yOffset = GetSafeElementBottomOffset(anchor)
		if yOffset then
			yOffset = yOffset - 10
		else
			yOffset = -30
		end
	end

	textListUsed = textListUsed + 1
	local titleScore1 = acquireRioText(textListUsed)
	titleScore1:SetFormattedText(textLeft)
	titleScore1:ClearAllPoints()
	titleScore1:SetPoint("TOPLEFT", 7, yOffset)
	if selected then
		titleScore1:SetTextColor(0, 1, 0, 1)
	elseif colorLeft then
		titleScore1:SetTextColor(colorLeft.r, colorLeft.g, colorLeft.b, 1)
	else
		titleScore1:SetTextColor(1, 1, 1, 1)
	end
	titleScore1:Show()

	textListUsed = textListUsed + 1
	local titleScoreValue = acquireRioText(textListUsed)
	titleScoreValue:SetFormattedText(textRight)
	titleScoreValue:ClearAllPoints()
	titleScoreValue:SetPoint("TOPRIGHT", -7, yOffset)
	if colorRight then
		titleScoreValue:SetTextColor(colorRight.r, colorRight.g, colorRight.b, 1)
	else
		titleScoreValue:SetTextColor(1, 1, 1, 1)
	end
	titleScoreValue:Show()
	return titleScore1, yOffset
end

local function ensureRioScoreFrame()
	if gFrameAnchorScore then return gFrameAnchorScore end

	local frameAnchorScore = _G["EQOLDungeonScoreFrame"]
	if not frameAnchorScore then frameAnchorScore = CreateFrame("Frame", "EQOLDungeonScoreFrame", parentFrame, "BackdropTemplate") end
	gFrameAnchorScore = frameAnchorScore
	if frameAnchorScore._eqolRioInitialized then return frameAnchorScore end

	frameAnchorScore._eqolRioInitialized = true
	frameAnchorScore:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frameAnchorScore:SetBackdropColor(0, 0, 0, 0.8)
	frameAnchorScore:SetFrameStrata("TOOLTIP")
	frameAnchorScore:SetMovable(true)
	frameAnchorScore:EnableMouse(true)
	frameAnchorScore:SetClampedToScreen(true)
	frameAnchorScore:RegisterForDrag("LeftButton")
	frameAnchorScore:SetScript("OnDragStart", function(self)
		if addon.db.dungeonScoreFrameLocked then return end
		if InCombatLockdown() then return end
		if not IsShiftKeyDown() then return end
		self:StartMoving()
	end)
	frameAnchorScore:SetScript("OnDragStop", function(self)
		if InCombatLockdown() then return end
		self:StopMovingOrSizing()
		local point, _, parentPoint, xOfs, yOfs = self:GetPoint()
		addon.db.dungeonScoreFrameData.point = point
		addon.db.dungeonScoreFrameData.parentPoint = parentPoint
		addon.db.dungeonScoreFrameData.x = xOfs
		addon.db.dungeonScoreFrameData.y = yOfs
	end)

	local btnDockScore = CreateFrame("Button", nil, frameAnchorScore)
	btnDockScore:SetPoint("TOPRIGHT", frameAnchorScore, "TOPRIGHT", -5, -5)
	btnDockScore:SetSize(16, 16)
	local iconScore = btnDockScore:CreateTexture(nil, "ARTWORK")
	iconScore:SetAllPoints(btnDockScore)
	btnDockScore.icon = iconScore
	updateRioLockButton(btnDockScore)
	btnDockScore:SetScript("OnClick", function(self)
		self.isDocked = not self.isDocked
		addon.db.dungeonScoreFrameLocked = self.isDocked
		updateRioLockButton(self)
		addon.MythicPlus.functions.RefreshDungeonFinderPanels()
	end)
	btnDockScore:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.isDocked then
			GameTooltip:SetText(L["frameUnlock"])
		else
			GameTooltip:SetText(L["frameLock"])
		end
		GameTooltip:Show()
	end)
	btnDockScore:SetScript("OnLeave", function() GameTooltip:Hide() end)
	frameAnchorScore.btnDockScore = btnDockScore

	local titleScore = frameAnchorScore:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleScore:SetFormattedText(DUNGEON_SCORE)
	titleScore:SetPoint("TOP", 0, -10)
	frameAnchorScore.titleScore = titleScore

	return frameAnchorScore
end

local function updateRioScoreFrame()
	if not gFrameAnchorScore then return end

	local frameAnchorScore = gFrameAnchorScore
	local titleScore = frameAnchorScore.titleScore
	local scoreTitleWidth = MeasureTextWidth(DUNGEON_SCORE, GameFontNormalLarge) + 20
	local portalTitleWidth = MeasureTextWidth(CHALLENGES, GameFontNormalLarge) + 20
	updateRioLockButton(frameAnchorScore.btnDockScore)
	titleScore:SetFormattedText(DUNGEON_SCORE)

	minFrameSize = max(scoreTitleWidth, portalTitleWidth, 205, minFrameSize)
	SafeSetSize(frameAnchorScore, minFrameSize, 170)
	if GetTeleportFrame() then
		frameAnchorScore:ClearAllPoints()
		frameAnchorScore:SetPoint("TOPLEFT", GetTeleportFrame(), "BOTTOMLEFT", 0, 0)
	elseif nil ~= RaiderIO_ProfileTooltip then
		local offsetX = GetSafeFrameWidth(RaiderIO_ProfileTooltip)
		frameAnchorScore:ClearAllPoints()
		frameAnchorScore:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", offsetX, 0)
	else
		frameAnchorScore:ClearAllPoints()
		frameAnchorScore:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 0, 0)
	end
	if not addon.db.dungeonScoreFrameLocked and addon.db.dungeonScoreFrameData and addon.db.dungeonScoreFrameData.point then
		frameAnchorScore:ClearAllPoints()
		frameAnchorScore:SetPoint(addon.db.dungeonScoreFrameData.point, UIParent, addon.db.dungeonScoreFrameData.parentPoint, addon.db.dungeonScoreFrameData.x, addon.db.dungeonScoreFrameData.y)
	end
	SafeSetSize(GetTeleportFrame(), minFrameSize, 170)

	textListUsed = 0

	local ratingInfo = {}
	local rating = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	if rating then
		for _, key in pairs(rating.runs) do
			ratingInfo[key.challengeModeID] = key
		end

		local r, g, b = C_ChallengeMode.GetDungeonScoreRarityColor(rating.currentSeasonScore):GetRGB()
		local titleHeight = max(MeasureTextHeight(DUNGEON_SCORE, GameFontNormalLarge), 16)
		local rowHeight = max(MeasureTextHeight("A", nil, addon.variables.defaultFont, 14, "OUTLINE"), 14)
		local nextRowY = -(titleHeight + 20)
		local l1, lastRowY = createString(BATTLEGROUND_RATING, rating.currentSeasonScore, nil, { r = r, g = g, b = b }, titleScore, nil, nextRowY)
		local nWidth = MeasureTextWidth(BATTLEGROUND_RATING, nil, addon.variables.defaultFont, 14, "OUTLINE") + 60
		nextRowY = lastRowY - (rowHeight + 10)
		local dungeonList = {}

		for _, key in pairs(C_ChallengeMode.GetMapTable()) do
			local mapName, _, timeLimit = C_ChallengeMode.GetMapUIInfo(key)
			r, g, b = 0.5, 0.5, 0.5

			local data = key
			local mId = key
			local stars = 0
			local score = 0
			if ratingInfo[key] then
				data = ratingInfo[key]
				mId = data.challengeModeID

				if data.bestRunLevel > 0 then
					r, g, b = 1, 1, 1

					local bestRunDuration = math.floor(data.bestRunDurationMS / 1000)
					local timeForPlus3 = timeLimit * 0.6
					local timeForPlus2 = timeLimit * 0.8
					local timeForPlus1 = timeLimit
					score = data.mapScore
					if bestRunDuration <= timeForPlus3 then
						stars = "|cFFFFD700+++|r"
					elseif bestRunDuration <= timeForPlus2 then
						stars = "|cFFFFD700++|r"
					elseif bestRunDuration <= timeForPlus1 then
						stars = "|cFFFFD700+|r"
					else
						stars = ""
						r = 0.5
						g = 0.5
						b = 0.5
					end
					stars = stars .. data.bestRunLevel
				else
					stars = 0
					r = 0.5
					g = 0.5
					b = 0.5
				end
			end

			local selected = false
			if key == selectedMapId then selected = true end
			local challengeMapLabels = addon.MythicPlus.variables.challengeMapID
			table.insert(dungeonList, {
				text = (challengeMapLabels and challengeMapLabels[mId]) or mapName or "UNKNOWN",
				stars = stars,
				score = score,
				r = r,
				g = g,
				b = b,
				select = selected,
			})
		end

		table.sort(dungeonList, function(a, b) return a.score > b.score end)

		local lastElement = l1
		for _, dungeon in ipairs(dungeonList) do
			lastElement, lastRowY = createString(dungeon.text, dungeon.stars, nil, { r = dungeon.r, g = dungeon.g, b = dungeon.b }, lastElement, dungeon.select, nextRowY)
			nextRowY = lastRowY - (rowHeight + 10)
		end

		minFrameSize = max(nWidth + 20, 205, portalTitleWidth, minFrameSize)
		SafeSetSize(frameAnchorScore, minFrameSize, max(lastRowY * -1 + 30, 170))
		SafeSetSize(GetTeleportFrame(), minFrameSize, 170)
	end

	hideUnusedRioText()
	frameAnchorScore:Show()
end

local function CreateRioScore()
	if addon and addon.functions and addon.functions.IsTimerunner and addon.functions.IsTimerunner() then
		if gFrameAnchorScore then gFrameAnchorScore:Hide() end
		return
	end
	if addon.variables.maxLevel ~= UnitLevel("player") then
		if gFrameAnchorScore then gFrameAnchorScore:Hide() end
		return
	end
	if addon.db["groupfinderShowDungeonScoreFrame"] ~= true then
		if gFrameAnchorScore then gFrameAnchorScore:Hide() end
		return
	end

	ensureRioScoreFrame()
	updateRioScoreFrame()
end

local function ShouldInstallDungeonFinderTooltipHooks()
	return addon.db and addon.db.groupfinderShowDungeonScoreFrame == true
end

local function EnsureDungeonFinderTooltipHooks()
	if not GameTooltip or addon.MythicPlus.variables.dungeonFinderTooltipHooked or not ShouldInstallDungeonFinderTooltipHooks() then return end

	GameTooltip:HookScript("OnShow", function(self)
		if PVEFrame:IsVisible() then
			ensureCurrentSeasonPortalCache()
			selectedMapId = nil
			local owner = self:GetOwner()
			if
				owner
				and owner.GetParent
				and LFGListFrame
				and LFGListFrame.SearchPanel
				and LFGListFrame.SearchPanel.ScrollBox
				and LFGListFrame.SearchPanel.ScrollBox.ScrollTarget
				and owner:GetParent() == LFGListFrame.SearchPanel.ScrollBox.ScrollTarget
			then
				local resultID = owner.resultID
				if resultID then
					local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
					if searchResultInfo and not issecretvalue(searchResultInfo.activityIDs) then
						local mapData = C_LFGList.GetActivityInfoTable(searchResultInfo.activityIDs[1])
						if mapData then
							if mapIDInfo[mapData.mapID] then selectedMapId = mapIDInfo[mapData.mapID] end
						end
					end
				end
				CreateRioScore()
				local offsetX = 0
				if nil ~= RaiderIO_ProfileTooltip then offsetX = GetSafeFrameWidth(RaiderIO_ProfileTooltip) end
				if gFrameAnchorScore and addon.db["dungeonScoreFrameLocked"] then gFrameAnchorScore:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", offsetX, 0) end

				if GetTeleportFrame() then GetTeleportFrame():SetAlpha(0) end
			end
		end
	end)
	GameTooltip:HookScript("OnHide", function(self)
		if PVEFrame:IsVisible() then
			selectedMapId = nil
			CreateRioScore()
			if GetTeleportFrame() then GetTeleportFrame():SetAlpha(1) end
		end
	end)
	addon.MythicPlus.variables.dungeonFinderTooltipHooked = true
end

local function SyncDungeonFinderEvents()
	local enabled = addon.db.groupfinderShowDungeonScoreFrame or addon.db.groupfinderShowPartyKeystone
	for _, event in ipairs({ "CHALLENGE_MODE_MAPS_UPDATE", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE", "GROUP_JOINED" }) do
		if enabled then eventFrame:RegisterEvent(event) else eventFrame:UnregisterEvent(event) end
	end
end

local keyStoneFrame
local KeystoneFrame = { styleVersion = 1 }
EnsureMeasureFontString = function()
	if measureFontString then return measureFontString end
	if not UIParent or not UIParent.CreateFontString then return nil end
	measureFontString = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if measureFontString and measureFontString.Hide then measureFontString:Hide() end
	return measureFontString
end

function KeystoneFrame.Clamp(value, minimum, maximum, fallback)
	value = tonumber(value) or fallback
	if value < minimum then return minimum end
	if value > maximum then return maximum end
	return value
end

function KeystoneFrame.Color(key, fallback)
	local color = addon.db and addon.db[key]
	if type(color) ~= "table" then color = fallback end
	return color.r or fallback.r, color.g or fallback.g, color.b or fallback.b, color.a or fallback.a
end

function KeystoneFrame.FontConfig()
	local fallback = (addon.variables and addon.variables.defaultFont) or STANDARD_TEXT_FONT
	local configured = addon.db.partyKeystoneFrameFont or fallback
	local face = addon.functions.ResolveFontFace and addon.functions.ResolveFontFace(configured, fallback) or fallback
	local style = addon.db.partyKeystoneFrameFontStyle or "NONE"
	local flags = ""
	if addon.functions.ResolveFontStyle then
		local _, resolvedFlags = addon.functions.ResolveFontStyle(style, "NONE")
		flags = resolvedFlags or ""
	end
	return face, flags or "", style
end

function KeystoneFrame.GetStyleState()
	local globalVersion = addon.functions.GetGlobalFontStateVersion and addon.functions.GetGlobalFontStateVersion() or 0
	return KeystoneFrame.styleVersion, globalVersion
end

function KeystoneFrame.ApplyFont(fontString, size)
	local face, _, style = KeystoneFrame.FontConfig()
	if addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(fontString, face, size, style, face, "NONE")
	else
		fontString:SetFont(face, size, "")
	end
end

function KeystoneFrame.GetUnitData(keystoneData, unit, showRealm)
	local name, realm = UnitFullName(unit)
	if not name then return nil end
	realm = realm or ""
	local fullName = realm ~= "" and (name .. "-" .. realm) or name
	local data = keystoneData[fullName] or keystoneData[name]
	if not data then return nil end
	local mapDataEntry
	if data.challengeMapID and data.challengeMapID > 0 then mapDataEntry = mapInfo[data.challengeMapID] end
	mapDataEntry = mapDataEntry or { mapName = L["NoKeystone"] }
	local displayName = name
	if showRealm == nil then showRealm = addon.db.partyKeystoneFrameShowRealm end
	if showRealm and realm ~= "" then displayName = fullName end
	local classColor = RAID_CLASS_COLORS[select(2, UnitClass(unit))] or { r = 1, g = 1, b = 1 }
	return {
		unit = unit,
		data = data,
		mapData = mapDataEntry,
		name = displayName,
		classColor = classColor,
	}
end

function KeystoneFrame.BuildEntries(keystoneData, showRealm)
	local entries = {}
	local player = KeystoneFrame.GetUnitData(keystoneData, "player", showRealm)
	if player then entries[#entries + 1] = player end
	for index = 1, 4 do
		local unit = "party" .. index
		if UnitExists(unit) then
			local entry = KeystoneFrame.GetUnitData(keystoneData, unit, showRealm)
			if entry then entries[#entries + 1] = entry end
		end
	end
	return entries
end

function addon.MythicPlus.functions.GetCurrentDungeonChallengeMapID()
	ensureCurrentSeasonPortalCache()
	local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
	if instanceType ~= "party" or difficultyID ~= 23 then return nil end
	return mapIDInfo[instanceID], instanceID
end

function addon.MythicPlus.functions.GetPartyKeystoneEntries(showRealm)
	ensureCurrentSeasonPortalCache()
	local keystoneData = openRaidLib and openRaidLib.GetAllKeystonesInfo and openRaidLib.GetAllKeystonesInfo()
	if type(keystoneData) ~= "table" then return {} end
	return KeystoneFrame.BuildEntries(keystoneData, showRealm)
end

function KeystoneFrame.MeasureWidth(entries, showIcon, iconSize)
	if addon.db.partyKeystoneFrameAutoWidth ~= true then return KeystoneFrame.Clamp(addon.db.partyKeystoneFrameWidth, 160, 600, 200) end
	local styleVersion, globalFontVersion = KeystoneFrame.GetStyleState()
	local signatureParts = { showIcon and "1" or "0", tostring(iconSize) }
	for _, entry in ipairs(entries) do
		signatureParts[#signatureParts + 1] = entry.name or ""
		signatureParts[#signatureParts + 1] = entry.mapData.mapName or ""
	end
	local contentSignature = table.concat(signatureParts, "\031")
	local widthCache = KeystoneFrame.widthCache
	if
		widthCache
		and widthCache.styleVersion == styleVersion
		and widthCache.globalFontVersion == globalFontVersion
		and widthCache.contentSignature == contentSignature
	then
		return widthCache.width
	end
	local face, flags = KeystoneFrame.FontConfig()
	local levelSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameLevelFontSize, 8, 32, 16)
	local locationSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameLocationFontSize, 8, 32, 12)
	local nameSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameNameFontSize, 8, 32, 12)
	local levelRegionWidth = max(showIcon and iconSize or 34, math.ceil(MeasureTextWidth("99", nil, face, levelSize, flags)) + 4)
	local prefixWidth = 20 + levelRegionWidth
	local width = 200
	for _, entry in ipairs(entries) do
		local locationWidth = MeasureTextWidth(entry.mapData.mapName or L["unknownDungeon"], nil, face, locationSize, flags)
		local nameWidth = MeasureTextWidth(entry.name, nil, face, nameSize, flags)
		width = max(width, prefixWidth + max(locationWidth, nameWidth) + 15)
	end
	width = KeystoneFrame.Clamp(math.ceil(width), 160, 600, 200)
	KeystoneFrame.widthCache = {
		styleVersion = styleVersion,
		globalFontVersion = globalFontVersion,
		contentSignature = contentSignature,
		width = width,
	}
	return width
end

function KeystoneFrame.EnsureContainer()
	if keyStoneFrame then return keyStoneFrame end
	keyStoneFrame = CreateFrame("Frame", nil, parentFrame)
	keyStoneFrame.rows = {}
	return keyStoneFrame
end

function KeystoneFrame.CreateRow(index)
	local container = KeystoneFrame.EnsureContainer()
	local row = CreateFrame("Button", nil, container, "InsecureActionButtonTemplate,BackdropTemplate")
	row:RegisterForClicks("AnyUp", "AnyDown")
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.iconBorder = row:CreateTexture(nil, "BORDER")
	row.iconBorder:SetColorTexture(1, 1, 1, 1)
	row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
	row.highlight:SetColorTexture(1, 1, 0, 0.25)
	row:SetHighlightTexture(row.highlight)
	row.level = row:CreateFontString(nil, "OVERLAY")
	row.level:SetJustifyH("CENTER")
	row.level:SetJustifyV("MIDDLE")
	row.level:SetWordWrap(false)
	row.level:SetMaxLines(1)
	row.location = row:CreateFontString(nil, "OVERLAY")
	row.location:SetJustifyH("LEFT")
	row.location:SetWordWrap(false)
	row.location:SetMaxLines(1)
	row.name = row:CreateFontString(nil, "OVERLAY")
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)
	row.name:SetMaxLines(1)
	container.rows[index] = row
	return row
end

function KeystoneFrame.ApplyAnchor(container, width, height)
	local offsetX = tonumber(addon.db.partyKeystoneFrameOffsetX) or 0
	local offsetY = tonumber(addon.db.partyKeystoneFrameOffsetY) or 0
	local anchor = addon.db.partyKeystoneFrameAnchor or "DEFAULT"
	local styleVersion, globalFontVersion = KeystoneFrame.GetStyleState()
	local cache = container._keystoneLayoutCache
	if
		cache
		and cache.styleVersion == styleVersion
		and cache.globalFontVersion == globalFontVersion
		and cache.width == width
		and cache.height == height
		and cache.offsetX == offsetX
		and cache.offsetY == offsetY
		and cache.anchor == anchor
	then
		return
	end
	container:ClearAllPoints()
	if anchor == "RIGHT" then
		container:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", offsetX, offsetY)
	elseif anchor == "LEFT" then
		container:SetPoint("TOPRIGHT", parentFrame, "TOPLEFT", offsetX, offsetY)
	elseif anchor == "TOP" then
		container:SetPoint("BOTTOMRIGHT", parentFrame, "TOPRIGHT", offsetX, offsetY)
	else
		local tabOffset = 0
		if PVEFrameTab1 and PVEFrameTab1:IsVisible() then tabOffset = -PVEFrameTab1:GetHeight() end
		container:SetPoint("TOPRIGHT", parentFrame, "BOTTOMRIGHT", offsetX, tabOffset + offsetY)
	end
	SafeSetSize(container, width, height)
	container._keystoneLayoutCache = {
		styleVersion = styleVersion,
		globalFontVersion = globalFontVersion,
		width = width,
		height = height,
		offsetX = offsetX,
		offsetY = offsetY,
		anchor = anchor,
	}
end

function KeystoneFrame.ApplyRow(row, entry, index, width, rowHeight, showIcon, iconSize)
	local contentIconSize = min(iconSize, rowHeight - 8)
	local styleVersion, globalFontVersion = KeystoneFrame.GetStyleState()
	local cache = row._keystoneStyleCache
	local styleChanged = not cache
		or cache.styleVersion ~= styleVersion
		or cache.globalFontVersion ~= globalFontVersion
		or cache.index ~= index
		or cache.width ~= width
		or cache.rowHeight ~= rowHeight
		or cache.showIcon ~= showIcon
		or cache.iconSize ~= contentIconSize
	if styleChanged then
		local levelSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameLevelFontSize, 8, 32, 16)
		local locationSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameLocationFontSize, 8, 32, 12)
		local nameSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameNameFontSize, 8, 32, 12)
		local levelFace, levelFlags = KeystoneFrame.FontConfig()
		local levelRegionWidth = max(showIcon and contentIconSize or 34, math.ceil(MeasureTextWidth("99", nil, levelFace, levelSize, levelFlags)) + 4)
		local textOffset = 15 + levelRegionWidth
		SafeSetSize(row, width, rowHeight)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", keyStoneFrame, "TOPLEFT", 0, -((index - 1) * rowHeight))

		local borderEnabled = addon.db.partyKeystoneFrameBorderEnabled == true
		local edgeFile
		if borderEnabled then
			local fallback = "Interface\\Tooltips\\UI-Tooltip-Border"
			edgeFile = addon.functions.ResolveLSMMedia and addon.functions.ResolveLSMMedia("border", addon.db.partyKeystoneFrameBorderStyle, fallback, true) or fallback
		end
		local borderSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameBorderSize, 1, 32, 16)
		row:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = edgeFile,
			edgeSize = borderSize,
		})
		row:SetBackdropColor(KeystoneFrame.Color("partyKeystoneFrameBackgroundColor", { r = 0, g = 0, b = 0, a = 0.8 }))
		if borderEnabled then row:SetBackdropBorderColor(KeystoneFrame.Color("partyKeystoneFrameBorderColor", { r = 1, g = 1, b = 1, a = 1 })) end

		row.icon:ClearAllPoints()
		row.iconBorder:ClearAllPoints()
		row.level:ClearAllPoints()
		row.highlight:ClearAllPoints()
		if showIcon then
			row.icon:SetSize(contentIconSize, contentIconSize)
			row.icon:SetPoint("LEFT", row, "LEFT", 10, 0)
			row.icon:Show()
			row.iconBorder:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -1, 1)
			row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 1, -1)
			row.iconBorder:Show()
			row.level:SetPoint("CENTER", row.icon, "CENTER", 0, 0)
			row.highlight:SetAllPoints(row.icon)
			row:SetHitRectInsets(10, max(0, width - 10 - contentIconSize), max(0, (rowHeight - contentIconSize) / 2), max(0, (rowHeight - contentIconSize) / 2))
		else
			row.icon:Hide()
			row.iconBorder:Hide()
			row.level:SetPoint("LEFT", row, "LEFT", 10, 0)
			row.highlight:SetAllPoints(row)
			row:SetHitRectInsets(0, 0, 0, 0)
		end
		row.level:SetSize(levelRegionWidth, rowHeight)

		KeystoneFrame.ApplyFont(row.level, levelSize)
		KeystoneFrame.ApplyFont(row.location, locationSize)
		KeystoneFrame.ApplyFont(row.name, nameSize)
		row.level:SetTextColor(KeystoneFrame.Color("partyKeystoneFrameLevelColor", { r = 1, g = 1, b = 1, a = 1 }))
		row.location:ClearAllPoints()
		row.location:SetPoint("TOPLEFT", row, "TOPLEFT", textOffset, -7)
		row.location:SetWidth(max(1, width - textOffset - 8))
		row.location:SetTextColor(KeystoneFrame.Color("partyKeystoneFrameLocationColor", { r = 1, g = 0.82, b = 0, a = 1 }))
		row.name:ClearAllPoints()
		row.name:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", textOffset, 7)
		row.name:SetWidth(max(1, width - textOffset - 8))
		row._keystoneStyleCache = {
			styleVersion = styleVersion,
			globalFontVersion = globalFontVersion,
			index = index,
			width = width,
			rowHeight = rowHeight,
			showIcon = showIcon,
			iconSize = contentIconSize,
		}
	end

	local contentCache = row._keystoneContentCache or {}
	local iconTexture = entry.mapData.texture or "Interface\\ICONS\\INV_Misc_QuestionMark"
	if showIcon and (styleChanged or contentCache.iconTexture ~= iconTexture) then row.icon:SetTexture(iconTexture) end
	local levelText = entry.data.level and entry.data.level > 0 and tostring(entry.data.level) or ""
	if contentCache.levelText ~= levelText then row.level:SetText(levelText) end
	local locationText = entry.mapData.mapName or L["unknownDungeon"]
	if contentCache.locationText ~= locationText then row.location:SetText(locationText) end
	if contentCache.nameText ~= entry.name then row.name:SetText(entry.name) end
	local nameR, nameG, nameB, nameA
	if addon.db.partyKeystoneFrameUseClassColor ~= false then
		nameR, nameG, nameB, nameA = entry.classColor.r, entry.classColor.g, entry.classColor.b, 1
	else
		nameR, nameG, nameB, nameA = KeystoneFrame.Color("partyKeystoneFrameNameColor", { r = 1, g = 1, b = 1, a = 1 })
	end
	if contentCache.nameR ~= nameR or contentCache.nameG ~= nameG or contentCache.nameB ~= nameB or contentCache.nameA ~= nameA then row.name:SetTextColor(nameR, nameG, nameB, nameA) end

	local spellID = entry.mapData.spellId
	local canTeleport = false
	if spellID and C_SpellBook.IsSpellInSpellBook(spellID) then
		local cooldownData = C_Spell.GetSpellCooldown(spellID)
		local enabled = cooldownData and cooldownData.isEnabled
		if cooldownData and ((issecretvalue and issecretvalue(enabled)) or enabled) then canTeleport = true end
	end
	if not contentCache.actionInitialized or contentCache.spellID ~= spellID or contentCache.canTeleport ~= canTeleport then
		row:SetAttribute("type", nil)
		row:SetAttribute("spell", nil)
		row.spellID = spellID
		if canTeleport then
			row:SetAttribute("type", "spell")
			row:SetAttribute("spell", spellID)
			row:EnableMouse(true)
		else
			row:EnableMouse(false)
		end
	end
	row._keystoneContentCache = {
		iconTexture = iconTexture,
		levelText = levelText,
		locationText = locationText,
		nameText = entry.name,
		nameR = nameR,
		nameG = nameG,
		nameB = nameB,
		nameA = nameA,
		spellID = spellID,
		canTeleport = canTeleport,
		actionInitialized = true,
	}
	if not row:IsShown() then row:Show() end
end

local function updateKeystoneInfo()
	if InCombatLockdown() then
		doAfterCombat = true
		return
	end
	if isRestrictedContent() then return end
	local container = KeystoneFrame.EnsureContainer()
	if not parentFrame:IsShown() or IsInRaid() or addon.db.groupfinderShowPartyKeystone ~= true then
		container:Hide()
		return
	end
	ensureCurrentSeasonPortalCache()
	local keystoneData = openRaidLib and openRaidLib.GetAllKeystonesInfo and openRaidLib.GetAllKeystonesInfo()
	if type(keystoneData) ~= "table" then
		container:Hide()
		return
	end
	local entries = KeystoneFrame.BuildEntries(keystoneData)
	if #entries == 0 then
		container:Hide()
		return
	end
	local rowHeight = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameHeight, 36, 100, 50)
	local showIcon = addon.db.partyKeystoneFrameShowIcon ~= false
	local iconSize = KeystoneFrame.Clamp(addon.db.partyKeystoneFrameIconSize, 16, 64, 30)
	local width = KeystoneFrame.MeasureWidth(entries, showIcon, iconSize)
	KeystoneFrame.ApplyAnchor(container, width, rowHeight * #entries)
	for index, entry in ipairs(entries) do
		local row = container.rows[index] or KeystoneFrame.CreateRow(index)
		KeystoneFrame.ApplyRow(row, entry, index, width, rowHeight, showIcon, iconSize)
	end
	for index = #entries + 1, #container.rows do
		container.rows[index]:Hide()
	end
	container:Show()
end

function addon.MythicPlus.functions.RefreshPartyKeystoneFrame()
	KeystoneFrame.styleVersion = KeystoneFrame.styleVersion + 1
	if keyStoneFrame and parentFrame:IsShown() then updateKeystoneInfo() end
end

function addon.MythicPlus.onKeystoneUpdate(unitName, keystoneInfo, keystoneData)
	if parentFrame:IsShown() then updateKeystoneInfo() end
	if addon.MythicPlus.functions.RefreshKeystoneDungeonIndicator then addon.MythicPlus.functions.RefreshKeystoneDungeonIndicator() end
end

local isRegistered = false
function addon.MythicPlus.functions.togglePartyKeystone()
	local shouldEnable = openRaidLib and addon.db["groupfinderShowPartyKeystone"] and not IsInRaid()
	SyncDungeonFinderEvents()
	if openRaidLib and openRaidLib.SetEnabled then openRaidLib.SetEnabled(shouldEnable) end

	if InCombatLockdown() then
		doAfterCombat = true
	else
		if shouldEnable then
			if not isRegistered then
				isRegistered = true
				EnsureMeasureFontString()
				openRaidLib.RegisterCallback(addon.MythicPlus, "KeystoneUpdate", "onKeystoneUpdate")
				openRaidLib.RegisterCallback(addon.MythicPlus, "KeystoneWipe", "onKeystoneUpdate")
				openRaidLib.RequestKeystoneDataFromParty()
			end
		else
			isRegistered = false
			if keyStoneFrame then keyStoneFrame:Hide() end
			if openRaidLib then openRaidLib.UnregisterCallback(addon.MythicPlus, "KeystoneUpdate", "onKeystoneUpdate") end
			if openRaidLib then openRaidLib.UnregisterCallback(addon.MythicPlus, "KeystoneWipe", "onKeystoneUpdate") end
			if openRaidLib then openRaidLib.WipeKeystoneData() end
		end
	end
	if addon.MythicPlus.functions.UpdateKeystoneDungeonIndicator then addon.MythicPlus.functions.UpdateKeystoneDungeonIndicator() end
end

function addon.MythicPlus.triggerRequest()
	if openRaidLib and not IsInRaid() then openRaidLib.RequestKeystoneDataFromParty() end
end

function addon.MythicPlus.functions.RefreshDungeonFinderPanels()
	SyncDungeonFinderEvents()
	EnsureDungeonFinderTooltipHooks()
	if InCombatLockdown() then doAfterCombat = true; return end
	doAfterCombat = false
	if isRestrictedContent() or (addon.functions.IsTimerunner and addon.functions.IsTimerunner()) then
		if gFrameAnchorScore then gFrameAnchorScore:Hide() end
		if keyStoneFrame then keyStoneFrame:Hide() end
		return
	end
	ensureCurrentSeasonPortalCache()
	CreateRioScore()
	if addon.db.groupfinderShowPartyKeystone then addon.MythicPlus.triggerRequest() end
	updateKeystoneInfo()
end

function addon.MythicPlus.functions.InitDungeonFinderPanels()
	if addon.MythicPlus.variables.dungeonFinderPanelsInitialized or not addon.db then return end
	addon.MythicPlus.variables.dungeonFinderPanelsInitialized = true
	eventFrame:SetScript("OnEvent", function(_, event)
		if event == "CHALLENGE_MODE_MAPS_UPDATE" then ensureCurrentSeasonPortalCache(true) end
		if event == "GROUP_ROSTER_UPDATE" or event == "GROUP_JOINED" or event == "PLAYER_REGEN_ENABLED" then
			addon.MythicPlus.functions.togglePartyKeystone()
		end
		if parentFrame:IsShown() or doAfterCombat then addon.MythicPlus.functions.RefreshDungeonFinderPanels() end
	end)
	parentFrame:HookScript("OnShow", function()
		addon.MythicPlus.functions.RefreshDungeonFinderPanels()
		if RaiderIO_ProfileTooltip then
			C_Timer.After(0.1, function()
				if parentFrame:IsShown() then addon.MythicPlus.functions.RefreshDungeonFinderPanels() end
			end)
		end
	end)
	if addon.MythicPlus.functions.toggleFrame then
		hooksecurefunc(addon.MythicPlus.functions, "toggleFrame", function()
			addon.MythicPlus.functions.RefreshDungeonFinderPanels()
		end)
	end
	addon.MythicPlus.functions.togglePartyKeystone()
	SyncDungeonFinderEvents()
	EnsureDungeonFinderTooltipHooks()
	if addon.db.groupfinderShowDungeonScoreFrame or addon.db.groupfinderShowPartyKeystone then C_MythicPlus.RequestMapInfo() end
end
