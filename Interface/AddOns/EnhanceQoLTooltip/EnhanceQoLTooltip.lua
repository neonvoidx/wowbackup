local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local WHITE_FONT_COLOR = _G.WHITE_FONT_COLOR
local TOOLTIP_LABEL_COLOR = "|cffffd200"
local TOOLTIP_WHITE_COLOR = "|cffffffff"
local TOOLTIP_COLOR_CLOSE = "|r"

local frameLoad = CreateFrame("Frame")

-- ==== Inspect cache (spec/ilvl/score) ====
local InspectCache = {} -- [guid] = { ilvl, specName, score, last }
local CACHE_TTL = 30 -- seconds
local INSPECT_REQUEST_COOLDOWN = 1.25 -- avoid spamming NotifyInspect while hovering
local INSPECT_PENDING_TIMEOUT = 2.0 -- fail-safe in case INSPECT_READY is dropped
local function now() return GetTime() end

local function isSecret(value) return issecretvalue and issecretvalue(value) end

local function isTooltipRestricted() return addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true) end

local function canReadAuraData()
	return not addon.AuraCompat or addon.AuraCompat:CanReadAuraData()
end

local function safeEquals(a, b)
	if a == nil or b == nil then return false end
	if isSecret(a) or isSecret(b) then return false end
	return a == b
end

local function safeFind(text, pattern, plain)
	if not text or isSecret(text) then return nil end
	if pattern == nil or isSecret(pattern) then return nil end
	if type(text) ~= "string" or type(pattern) ~= "string" then return nil end
	return string.find(text, pattern, 1, plain)
end

local function safeMatch(text, pattern)
	if not text or isSecret(text) then return nil end
	if pattern == nil or isSecret(pattern) then return nil end
	if type(text) ~= "string" or type(pattern) ~= "string" then return nil end
	return string.match(text, pattern)
end

local function secureInvoke(func, ...)
	func(...)
	return true
end

local function safeSecureCall(func, ...)
	if not func then return false end
	if securecallfunction then return securecallfunction(secureInvoke, func, ...) == true end
	local ok = pcall(func, ...)
	return ok
end

local function IsTooltipMutable(tooltip)
	if not tooltip then return false end
	if tooltip.IsForbidden and tooltip:IsForbidden() then return false end
	if tooltip.IsProtected and tooltip:IsProtected() then return false end
	return true
end

local function IsUnitIdentitySecret(unit)
	if not unit or isSecret(unit) then return true end
	if not (C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret) then return false end
	local secret = C_Secrets.ShouldUnitIdentityBeSecret(unit)
	return secret == true or isSecret(secret)
end

local function IsSafeUnitToken(unit)
	return type(unit) == "string" and unit ~= "" and not IsUnitIdentitySecret(unit)
end

local function SafeUnitExists(unit)
	return IsSafeUnitToken(unit) and UnitExists(unit) and true or false
end

local function SafeUnitPlayerControlled(unit)
	if not IsSafeUnitToken(unit) or not UnitPlayerControlled then return nil end
	return UnitPlayerControlled(unit)
end

local function SafeUnitIsUnit(unit, otherUnit)
	if not UnitIsUnit or not IsSafeUnitToken(unit) or not IsSafeUnitToken(otherUnit) then return nil end
	local same = UnitIsUnit(unit, otherUnit)
	if isSecret(same) then return nil end
	return same == true
end

local function SafeUnitName(unit)
	if not unit or isSecret(unit) or not UnitName then return nil end
	local name, realm = UnitName(unit)
	if isSecret(name) or isSecret(realm) then return nil end
	return name, realm
end

local function IsSimpleGuildInfoUnitToken(unit)
	if type(unit) ~= "string" or unit == "" or isSecret(unit) then return false end
	if unit == "player" or unit == "target" or unit == "focus" or unit == "mouseover" then return true end
	return unit:match("^party%d+$") ~= nil
		or unit:match("^raid%d+$") ~= nil
		or unit:match("^arena%d+$") ~= nil
		or unit:match("^boss%d+$") ~= nil
		or unit:match("^nameplate%d+$") ~= nil
end

local function GetUnitTokenFromTooltip(tt)
	local hadTooltipUnit = false
	if not tt then return nil, hadTooltipUnit end
	local owner = tt and tt:GetOwner()
	if owner then
		local ownerUnit = owner.unit
		if ownerUnit ~= nil then
			hadTooltipUnit = true
			if not isSecret(ownerUnit) then return ownerUnit, hadTooltipUnit end
		end
		if owner.GetAttribute then
			local u = owner:GetAttribute("unit")
			if u ~= nil then
				hadTooltipUnit = true
				if not isSecret(u) then return u, hadTooltipUnit end
			end
		end
	end
	return nil, hadTooltipUnit
end

local function ColorText(text, color)
	if text == nil then return nil end
	return (color or TOOLTIP_WHITE_COLOR) .. tostring(text) .. TOOLTIP_COLOR_CLOSE
end

local function ColorTextRGB(text, r, g, b)
	if text == nil then return nil end
	return ("|cff%02x%02x%02x%s|r"):format((r or 1) * 255, (g or 1) * 255, (b or 1) * 255, tostring(text))
end

local function EnsureItemLevelColorFunc()
	if GetItemLevelColor then return end
	if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.LoadAddOn then
		if not C_AddOns.IsAddOnLoaded("Blizzard_UIPanels_Game") then C_AddOns.LoadAddOn("Blizzard_UIPanels_Game") end
	elseif UIParentLoadAddOn then
		UIParentLoadAddOn("Blizzard_UIPanels_Game")
	end
end

local function GetTooltipItemLevelColor()
	EnsureItemLevelColorFunc()
	if GetItemLevelColor then
		local r, g, b = GetItemLevelColor()
		if r then return r, g, b end
	end
	return 1, 1, 1
end

local function FormatDungeonRunLevel(run)
	if not run or not run.bestRunLevel or run.bestRunLevel <= 0 then return nil end
	local stars = ""
	if run.finishedSuccess then
		local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(run.challengeModeID))
		if timeLimit and run.bestRunDurationMS then
			local bestRunDuration = math.floor(run.bestRunDurationMS / 1000)
			if bestRunDuration <= timeLimit * 0.6 then
				stars = "+++"
			elseif bestRunDuration <= timeLimit * 0.8 then
				stars = "++"
			elseif bestRunDuration <= timeLimit then
				stars = "+"
			end
		end
	end
	return stars .. tostring(run.bestRunLevel)
end

local pendingGUID, pendingUnit, pendingRequestedAt
local EnsureUnitData -- forward declaration
local ResolveTooltipUnit -- forward declaration
local fInspect = CreateFrame("Frame")

local function IsInspectUIBusy()
	if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then return true end
	if PlayerSpellsFrame and PlayerSpellsFrame.IsInspecting and PlayerSpellsFrame:IsInspecting() then return true end
	return false
end

local function ClearTooltipInspectState()
	pendingGUID, pendingUnit, pendingRequestedAt = nil, nil, nil
end

local function FinishTooltipInspectRequest()
	ClearTooltipInspectState()
	if ClearInspectPlayer and not IsInspectUIBusy() then
		RunNextFrame(function()
			if ClearInspectPlayer and not IsInspectUIBusy() then ClearInspectPlayer() end
		end)
	end
end

-- Decide whether we need INSPECT_READY at all (opt-in)
local function ShouldUseInspectFeature() return (addon.db and (addon.db["TooltipUnitShowSpec"] or addon.db["TooltipUnitShowItemLevel"])) or false end

local function IsConfiguredModifierDown()
	local mod = addon.db and addon.db["TooltipMythicScoreModifier"] or "SHIFT"
	return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "ALT" and IsAltKeyDown()) or (mod == "CTRL" and IsControlKeyDown())
end

local function IsTooltipIDModifierDown()
	local mod = addon.db and addon.db["TooltipIDModifier"] or "ALT"
	return (mod == "SHIFT" and IsShiftKeyDown()) or (mod == "ALT" and IsAltKeyDown()) or (mod == "CTRL" and IsControlKeyDown())
end

local function ShouldShowTooltipIDDetails()
	if not addon.db or not addon.db["TooltipIDRequireModifier"] then return true end
	return IsTooltipIDModifierDown() == true
end

local function IsTooltipHideOverrideActive()
	if not addon.db or not addon.db["TooltipHideOverrideEnabled"] then return false end
	local mod = addon.db["TooltipHideOverrideModifier"] or "CTRL"
	if mod == "SHIFT" then return IsShiftKeyDown() end
	if mod == "ALT" then return IsAltKeyDown() end
	if mod == "CTRL" then return IsControlKeyDown() end
	return false
end

local function DoesKeyMatchConfiguredModifier(key)
	if not key or not addon.db then return false end
	local mod = addon.db["TooltipMythicScoreModifier"] or "SHIFT"
	if mod == "SHIFT" then return key == "LSHIFT" or key == "RSHIFT" end
	if mod == "ALT" then return key == "LALT" or key == "RALT" end
	if mod == "CTRL" then return key == "LCTRL" or key == "RCTRL" end
	return false
end

local function HasTooltipIDOptions()
	local db = addon.db
	if not db then return false end
	return db["TooltipShowSpellID"]
		or db["TooltipShowSpellIcon"]
		or db["TooltipShowItemID"]
		or db["TooltipShowTempEnchant"]
		or db["TooltipShowCurrencyID"]
		or db["TooltipShowNPCID"]
		or db["TooltipShowQuestID"]
		or db["TooltipShowQuestIDInQuestLog"]
end

local function UpdateInspectEventRegistration()
	if not addon.db then return end
	if not fInspect then return end
	fInspect:UnregisterEvent("INSPECT_READY")
	fInspect:UnregisterEvent("MODIFIER_STATE_CHANGED")
	if ShouldUseInspectFeature() then
		fInspect:RegisterEvent("INSPECT_READY")
		if addon.db["TooltipUnitInspectRequireModifier"] then fInspect:RegisterEvent("MODIFIER_STATE_CHANGED") end
	else
		ClearTooltipInspectState()
	end
end

addon.functions.UpdateInspectEventRegistration = UpdateInspectEventRegistration

local function IsValidSpellIdentifier(id)
	if isSecret(id) then return false end
	local idType = type(id)
	return idType == "number" or idType == "string"
end

local function FindLineIndexByLabel(tt, label)
	local name = tt:GetName()
	for i = 1, tt:NumLines() do
		local left = _G[name .. "TextLeft" .. i]
		local text = left and left:GetText()
		if safeFind(text, label, true) then return i end
	end
	return nil
end

local function RefreshTooltipForGUID(guid)
	if not GameTooltip or not GameTooltip:IsShown() then return end
	local tt = GameTooltip
	local unit = ResolveTooltipUnit and ResolveTooltipUnit(tt) or GetUnitTokenFromTooltip(tt)
	if not unit then return end
	local uGuid = UnitGUID(unit)
	if not safeEquals(uGuid, guid) then return end
	local c = InspectCache[guid]
	if not c then return end

	local showSpec = addon.db["TooltipUnitShowSpec"] and c.specName
	local showIlvl = addon.db["TooltipUnitShowItemLevel"] and c.ilvl
	if addon.db["TooltipUnitInspectRequireModifier"] and not IsConfiguredModifierDown() then
		showSpec = false
		showIlvl = false
	end
	if not showSpec and not showIlvl then return end

	local labelSpec = SPECIALIZATION
	local labelIlvl = STAT_AVERAGE_ITEM_LEVEL or ITEM_LEVEL or "Item Level"

	local haveSpecLine = FindLineIndexByLabel(tt, labelSpec)
	local haveIlvlLine = FindLineIndexByLabel(tt, labelIlvl)

	local addedAny = false
	if showSpec then
		if haveSpecLine then
			local right = _G[tt:GetName() .. "TextRight" .. haveSpecLine]
			if right then right:SetText(ColorText(c.specName)) end
		else
			tt:AddDoubleLine(TOOLTIP_LABEL_COLOR .. labelSpec .. TOOLTIP_COLOR_CLOSE, ColorText(c.specName))
			addedAny = true
		end
	end
	if showIlvl then
		local r, g, b = GetTooltipItemLevelColor()
		if haveIlvlLine then
			local right = _G[tt:GetName() .. "TextRight" .. haveIlvlLine]
			if right then
				right:SetText(tostring(c.ilvl))
				right:SetTextColor(r, g, b)
			end
		else
			tt:AddDoubleLine(TOOLTIP_LABEL_COLOR .. labelIlvl .. TOOLTIP_COLOR_CLOSE, tostring(c.ilvl), 1, 1, 0, r, g, b)
			addedAny = true
		end
	end
	if addedAny then tt:Show() end
end

fInspect:SetScript("OnEvent", function(_, ev, arg1, arg2)
	if ev == "INSPECT_READY" then
		local guid = arg1
		if isSecret(guid) or isSecret(arg1) or isSecret(arg2) or isSecret(pendingGUID) then return end
		if not safeEquals(guid, pendingGUID) then return end
		local unitGuid = pendingUnit and UnitGUID(pendingUnit)
		if isSecret(unitGuid) or isSecret(pendingUnit) then
			FinishTooltipInspectRequest()
			return
		end
		local unit = (unitGuid == guid) and pendingUnit or nil
		FinishTooltipInspectRequest()
		if not SafeUnitExists(unit) then return end

		local ilvl
		if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
			ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
			if ilvl then ilvl = tonumber(string.format("%.1f", ilvl)) end
		end
		local getInspectSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization) or GetInspectSpecialization
		local specID = getInspectSpecialization and getInspectSpecialization(unit)
		local specName
		if not isSecret(specID) and specID and specID > 0 then
			local _, name = GetSpecializationInfoByID(specID)
			specName = name
		end
		local score = 0
		if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
			local s = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
			score = s and s.currentSeasonScore or score
		end

		local c = InspectCache[guid] or {}
		c.ilvl = ilvl
		c.specName = specName
		c.score = score
		c.last = now()
		InspectCache[guid] = c

		-- If the currently shown tooltip is for this unit, update it immediately
		RefreshTooltipForGUID(guid)
	elseif ev == "MODIFIER_STATE_CHANGED" then
		if not addon.db or not addon.db["TooltipUnitInspectRequireModifier"] then return end
		if not ShouldUseInspectFeature() then return end
		local key, state = arg1, arg2
		if state ~= 1 then return end
		if not DoesKeyMatchConfiguredModifier(key) then return end
		if not IsConfiguredModifierDown() then return end
		if not GameTooltip or not GameTooltip:IsShown() then return end
		local unit = ResolveTooltipUnit and ResolveTooltipUnit(GameTooltip) or GetUnitTokenFromTooltip(GameTooltip)
		if not unit or not UnitIsPlayer(unit) then return end
		EnsureUnitData(unit)
		local guid = UnitGUID(unit)
		if guid then RefreshTooltipForGUID(guid) end
	end
end)

EnsureUnitData = function(unit)
	if not unit or not UnitIsPlayer(unit) then return end
	if isTooltipRestricted() then return end
	-- Only fetch if at least one feature is enabled (opt-in)
	if not (addon.db["TooltipUnitShowSpec"] or addon.db["TooltipUnitShowItemLevel"]) then return end
	local guid = UnitGUID(unit)
	if type(guid) == "nil" or issecretvalue(guid) then return end
	if not guid then return end
	local tNow = now()
	local c = InspectCache[guid]
	if c then
		if tNow - (c.last or 0) < CACHE_TTL then return end
		if tNow - (c.requestAt or 0) < INSPECT_REQUEST_COOLDOWN then return end
	end

	-- Self: no inspect needed
	if SafeUnitIsUnit(unit, "player") then
		local ilvl
		if GetAverageItemLevel then
			local _, eq = GetAverageItemLevel()
			ilvl = eq and tonumber(string.format("%.1f", eq))
		end
		local specName
		local si = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
		if si then specName = select(2, C_SpecializationInfo.GetSpecializationInfo(si)) end
		local score = C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore and C_ChallengeMode.GetOverallDungeonScore()
		InspectCache[guid] = { ilvl = ilvl, specName = specName, score = score, last = now() }
		return
	end

	if addon.db["TooltipUnitInspectRequireModifier"] and not IsConfiguredModifierDown() then return end

	if IsInspectUIBusy() then
		ClearTooltipInspectState()
		return
	end

	if pendingGUID and pendingRequestedAt and (tNow - pendingRequestedAt) >= INSPECT_PENDING_TIMEOUT then FinishTooltipInspectRequest() end

	-- Others: request inspect if possible
	if CanInspect and CanInspect(unit) and not InCombatLockdown() and not issecretvalue(unit) then
		if pendingGUID and pendingUnit then
			local pendingUnitGuid = UnitGUID(pendingUnit)
			if issecretvalue(pendingUnitGuid) or issecretvalue(pendingGUID) or issecretvalue(guid) then
				ClearTooltipInspectState()
			elseif pendingUnitGuid == pendingGUID and pendingGUID == guid then
				return
			elseif pendingRequestedAt and (tNow - pendingRequestedAt) < INSPECT_PENDING_TIMEOUT then
				return
			else
				ClearTooltipInspectState()
			end
		end
		local cacheEntry = c or {}
		cacheEntry.requestAt = tNow
		InspectCache[guid] = cacheEntry
		pendingGUID = guid
		pendingUnit = unit
		pendingRequestedAt = tNow
		if NotifyInspect then NotifyInspect(unit) end
	end
end

local function GetNPCIDFromGUID(guid)
	if guid and not (issecretvalue and issecretvalue(guid)) then
		local type, _, _, _, _, npcID = strsplit("-", guid)
		if type == "Creature" or type == "Vehicle" then return tonumber(npcID) end
	end
	return nil
end

local function FormatUnitName(unit)
	if IsUnitIdentitySecret(unit) then return nil end
	if SafeUnitIsUnit(unit, "player") then return "<YOU>" end
	local name, realm = SafeUnitName(unit)
	if not name then return nil end
	if realm and realm ~= "" then name = name .. "-" .. realm end
	return name
end

local function FormatTargetOfTargetName(unit)
	if IsUnitIdentitySecret(unit) then return nil end
	if SafeUnitIsUnit(unit, "player") then return "<YOU>" end
	local name, realm = SafeUnitName(unit)
	if not name then return nil end
	local fullName = (realm and realm ~= "") and (name .. "-" .. realm) or name
	local mode = addon.db and addon.db["TooltipTargetOfTargetRealmMode"] or "SHOW"
	if mode == "HIDE" and Ambiguate then return Ambiguate(fullName, "short") or name end
	if mode == "STAR" and Ambiguate then
		local shortName = Ambiguate(fullName, "short") or name
		if shortName ~= fullName then return shortName .. "-(*)" end
		return shortName
	end
	return fullName
end

local function GetUnitReactionColor(unit)
	if not UnitReaction then return nil end
	local reaction = UnitReaction(unit, "player")
	if isSecret(reaction) then return nil end
	local factionColors = _G.FACTION_BAR_COLORS
	local color = reaction and factionColors and factionColors[reaction]
	if color then return color.r, color.g, color.b end
	return nil
end

local function ColorTargetOfTargetName(unit, text)
	if not text then return nil end
	if not (addon.db and addon.db["TooltipTargetOfTargetColorMode"] == "UNIT") then return ColorText(text) end
	if IsUnitIdentitySecret(unit) then return ColorText(text) end
	if SafeUnitIsUnit(unit, "player") then return ColorTextRGB(text, 0, 1, 0.6) end
	if UnitIsPlayer and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if not isSecret(class) then
			local r, g, b = GetClassColor(class)
			return ColorTextRGB(text, r, g, b)
		end
	end
	local r, g, b = GetUnitReactionColor(unit)
	if r then return ColorTextRGB(text, r, g, b) end
	return ColorText(text)
end

local function GetUnitMountInfo(unit)
	if not unit or not UnitIsPlayer or not UnitIsPlayer(unit) then return nil end
	if not (C_UnitAuras and C_UnitAuras.GetUnitAuras) then return nil end
	if not (C_MountJournal and C_MountJournal.GetMountFromSpell and C_MountJournal.GetMountInfoByID) then return nil end
	if not canReadAuraData() then return nil end
	local auras = C_UnitAuras.GetUnitAuras(unit, "HELPFUL")
	if type(auras) ~= "table" then return nil end
	for i = 1, #auras do
		local aura = auras[i]
		local spellID = aura and aura.spellId
		if spellID and (not issecretvalue or not issecretvalue(spellID)) then
			local mountID = C_MountJournal.GetMountFromSpell(spellID)
			if mountID then
				local name, _, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
				if not name or name == "" then
					if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(spellID) end
					if not name and GetSpellInfo then name = GetSpellInfo(spellID) end
				end
				if name and name ~= "" then
					local collected = isCollected == true
					if issecretvalue and issecretvalue(isCollected) then collected = false end
					return name, icon, collected
				end
			end
		end
	end
	return nil
end

local function GetRealmLanguageLabel(locale)
	if type(locale) ~= "string" or locale == "" then return nil end
	local localeKey = locale:upper()
	return _G["LFG_LIST_LANGUAGE_" .. localeKey] or _G[localeKey] or locale
end

local function GetRealmDataProvider()
	local realmData = addon.Tooltip and addon.Tooltip.variables and addon.Tooltip.variables.realmInfo
	if not realmData or not realmData.GetRealmInfo then return nil end
	return realmData
end

local realmLocaleFlagAssets = {
	deDE = "flag_de.tga",
	enGB = "flag_enGB.tga",
	enUS = "flag_enUS.tga",
	esES = "flag_esES.tga",
	esMX = "flag_esMX.tga",
	frFR = "flag_frFR.tga",
	itIT = "flag_itIT.tga",
	koKR = "flag_koKR.tga",
	ptBR = "flag_ptBR.tga",
	ptPT = "flag_ptPT.tga",
	ruRU = "flag_ruRU.tga",
	zhCN = "flag_zhCN.tga",
	zhTW = "flag_zhTW.tga",
}

local function GetRealmFlagFileName(info)
	if type(info) ~= "table" then return nil end
	if info.region == "US" and type(info.timezone) == "string" and safeFind(info.timezone, "Australia/", true) then return "flag_oce.tga" end
	return realmLocaleFlagAssets[info.locale]
end

local function FormatRealmFlagTexture(fileName, variant)
	if variant == "lfg" then
		return ("|TInterface\\AddOns\\EnhanceQoL\\Assets\\%s:13:20:0:-1|t"):format(fileName)
	end
	return ("|TInterface\\AddOns\\EnhanceQoL\\Assets\\%s:14:22:0:0|t"):format(fileName)
end

local function GetRealmFlagPlaceholder(info, allowTextures, variant)
	if type(info) ~= "table" then return nil end
	local locale = info.locale
	local fileName = GetRealmFlagFileName(info)
	if fileName and allowTextures then return FormatRealmFlagTexture(fileName, variant) end
	if fileName == "flag_oce.tga" then return "[enAU]" end
	if type(locale) == "string" and locale ~= "" then return "[" .. locale .. "]" end
	return nil
end

local function SetLFGRealmFlagTexture(owner, name, fileName)
	if not owner or not name then return end
	local texture = owner.__EnhanceQoLRealmFlagTexture
	if not fileName then
		if texture then texture:Hide() end
		return
	end
	if not texture then
		texture = owner:CreateTexture(nil, "ARTWORK")
		owner.__EnhanceQoLRealmFlagTexture = texture
	end
	texture:SetTexture("Interface\\AddOns\\EnhanceQoL\\Assets\\" .. fileName)
	texture:SetSize(20, 13)
	texture:ClearAllPoints()
	texture:SetPoint("LEFT", name, "LEFT", 0, 0)
	texture:Show()
end

local function IsRealmInfoFieldEnabled(field, legacyKey)
	local fields = addon.db and addon.db["TooltipRealmInfoFields"]
	if type(fields) == "table" then return fields[field] == true end
	return addon.db and addon.db[legacyKey] == true
end

local function IsLFGRealmDisplayEnabled(field)
	local displays = addon.db and addon.db["TooltipRealmLFGDisplay"]
	if type(displays) == "table" then return displays[field] == true end
	return true
end

local function NormalizeRealmFromNameString(value)
	local realmData = GetRealmDataProvider()
	local realm = realmData and realmData.GetRealmFromNameString and realmData.GetRealmFromNameString(value) or nil
	if type(realm) ~= "string" or realm == "" then return nil end
	realm = realm:gsub("%s+%b()", "")
	realm = realm:gsub("^%s+", ""):gsub("%s+$", "")
	return realm ~= "" and realm or nil
end

local function AddRealmInfo(tooltip, realm)
	if not addon.db["TooltipShowRealmInfo"] then return false end
	if not IsTooltipMutable(tooltip) then return false end
	if not realm or realm == "" then return end

	local realmData = GetRealmDataProvider()
	if not realmData then return false end

	local info = realmData.GetRealmInfo(realm)
	if not info then return false end

	local printedHeader = false
	local function ensureHeader()
		if printedHeader then return end
		tooltip:AddLine(" ")
		printedHeader = true
	end

	if IsRealmInfoFieldEnabled("language", "TooltipRealmShowLanguage") then
		local language = GetRealmLanguageLabel(info.locale)
		if language then
			local flag = GetRealmFlagPlaceholder(info, true)
			if flag then language = flag .. " " .. language end
			ensureHeader()
			tooltip:AddDoubleLine(L["TooltipRealmLanguage"], ColorText(language))
		end
	end

	if IsRealmInfoFieldEnabled("type", "TooltipRealmShowType") and realmData.FormatRealmType then
		local realmType = realmData.FormatRealmType(info)
		if realmType then
			ensureHeader()
			tooltip:AddDoubleLine(L["TooltipRealmType"], ColorText(realmType))
		end
	end

	if IsRealmInfoFieldEnabled("timezone", "TooltipRealmShowTimezone") and realmData.FormatRealmTimezone then
		local timezone = realmData.FormatRealmTimezone(info)
		if timezone then
			ensureHeader()
			tooltip:AddDoubleLine(L["TooltipRealmTimezone"], ColorText(timezone))
		end
	end

	if IsRealmInfoFieldEnabled("connected", "TooltipRealmShowConnected") and realmData.GetConnectionNames then
		local names = realmData.GetConnectionNames(info)
		if names and #names > 1 then
			ensureHeader()
			if #names <= 4 then
				tooltip:AddDoubleLine(L["TooltipRealmConnected"], ColorText(table.concat(names, ", ")))
			else
				tooltip:AddLine(L["TooltipRealmConnected"] .. ":")
				tooltip:AddLine(table.concat(names, ", "), 1, 1, 1, true)
			end
		end
	end

	if printedHeader then tooltip:Show() end
	return printedHeader
end

local function AddUnitRealmInfo(tooltip, unit)
	if not unit or not UnitIsPlayer(unit) then return end
	if IsUnitIdentitySecret(unit) then return end

	local _, realm = SafeUnitName(unit)
	if not realm or realm == "" then realm = GetRealmName and GetRealmName() or nil end
	AddRealmInfo(tooltip, realm)
end

local function GetLFGSearchResultInfo(resultID)
	if not resultID or not C_LFGList or not C_LFGList.GetSearchResultInfo then return nil end
	if C_LFGList.HasSearchResultInfo and not C_LFGList.HasSearchResultInfo(resultID) then return nil end
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
	if type(searchResultInfo) ~= "table" then return nil end
	return searchResultInfo
end

local function GetRealmInfoForLFGResult(resultID)
	local searchResultInfo = GetLFGSearchResultInfo(resultID)
	local leaderName = searchResultInfo and searchResultInfo.leaderName
	if isSecret(leaderName) then return nil end
	if type(leaderName) ~= "string" or leaderName == "" then return nil end
	local realm = NormalizeRealmFromNameString(leaderName)
	if not realm then return nil end

	local realmData = GetRealmDataProvider()
	local info = realmData and realmData.GetRealmInfo(realm) or nil
	return info, realm
end

local function StripPreviousRealmFlagPrefix(entry, text)
	local prefix = entry and entry.__EnhanceQoLRealmFlagPrefix
	if type(prefix) ~= "string" or prefix == "" then return text end
	if type(text) ~= "string" or text == "" then return text end
	if text:sub(1, #prefix + 1) == prefix .. " " then return text:sub(#prefix + 2) end
	local indent, rest = text:match("^(%s+)(.*)$")
	if indent and rest and rest:sub(1, #prefix + 1) == prefix .. " " then return indent .. rest:sub(#prefix + 2) end
	return text
end

local function UpdateLFGSearchEntryRealmFlag(entry)
	if not addon.db or not addon.db["TooltipShowRealmInfo"] then return end
	if not IsLFGRealmDisplayEnabled("listingFlag") then return end
	if not entry or not entry.Name or not entry.Name.GetText or not entry.Name.SetText then return end
	local text = entry.Name:GetText()
	if isSecret(text) then return end
	text = StripPreviousRealmFlagPrefix(entry, text)

	local info = GetRealmInfoForLFGResult(entry.resultID)
	local fileName = not isTooltipRestricted() and GetRealmFlagFileName(info) or nil
	if not fileName then
		SetLFGRealmFlagTexture(entry, entry.Name, nil)
		entry.__EnhanceQoLRealmFlagPrefix = nil
		entry.Name:SetText(text)
		return
	end

	SetLFGRealmFlagTexture(entry, entry.Name, fileName)
	entry.__EnhanceQoLRealmFlagPrefix = nil
	entry.Name:SetText("      " .. (text or ""))
end

local function AddLFGSearchEntryRealmInfo(tooltip, resultID)
	if not addon.db or not addon.db["TooltipShowRealmInfo"] then return end
	if not IsLFGRealmDisplayEnabled("tooltip") then return end
	if isTooltipRestricted() then return end
	local _, realm = GetRealmInfoForLFGResult(resultID)
	if not realm then return end
	AddRealmInfo(tooltip, realm)
end

local function GetRealmInfoForLFGApplicant(appID, memberIdx)
	if isTooltipRestricted() then return nil end
	if isSecret(appID) or isSecret(memberIdx) then return nil end
	if not C_LFGList or not C_LFGList.GetApplicantMemberInfo then return nil end
	local name = C_LFGList.GetApplicantMemberInfo(appID, memberIdx or 1)
	if isSecret(name) then return nil end
	if type(name) ~= "string" or name == "" then return nil end
	local realm = NormalizeRealmFromNameString(name)
	if not realm then return nil end

	local realmData = GetRealmDataProvider()
	local info = realmData and realmData.GetRealmInfo(realm) or nil
	return info, realm
end

local function UpdateLFGApplicantMemberRealmFlag(memberFrame, appID, memberIdx)
	if not addon.db or not addon.db["TooltipShowRealmInfo"] then return end
	if not IsLFGRealmDisplayEnabled("listingFlag") then return end
	if isTooltipRestricted() then return end
	if not memberFrame or not memberFrame.Name or not memberFrame.Name.GetText or not memberFrame.Name.SetText then return end
	local text = memberFrame.Name:GetText()
	if isSecret(text) then return end
	text = StripPreviousRealmFlagPrefix(memberFrame, text)

	local info = GetRealmInfoForLFGApplicant(appID, memberIdx)
	local fileName = not isTooltipRestricted() and GetRealmFlagFileName(info) or nil
	if not fileName then
		SetLFGRealmFlagTexture(memberFrame, memberFrame.Name, nil)
		memberFrame.__EnhanceQoLRealmFlagPrefix = nil
		memberFrame.Name:SetText(text)
		return
	end

	SetLFGRealmFlagTexture(memberFrame, memberFrame.Name, fileName)
	memberFrame.__EnhanceQoLRealmFlagPrefix = nil
	memberFrame.Name:SetText("      " .. (text or ""))
end

local function fmtNum(n)
	if BreakUpLargeNumbers then
		return BreakUpLargeNumbers(n or 0)
	else
		return tostring(n or 0)
	end
end

local function checkCurrency(tooltip, id)
	if not IsTooltipMutable(tooltip) then return end
	if not id then return end

	if addon.db["TooltipShowCurrencyID"] and ShouldShowTooltipIDDetails() then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(L["CurrencyID"], id)
	end

	if not addon.db["TooltipShowCurrencyAccountWide"] then return end
	local charList = C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters(id)

	local playerName, playerRealm = UnitFullName("player")
	if not playerRealm or playerRealm == "" then playerRealm = GetRealmName():gsub("%s+", "") end
	local playerFullName = playerName .. "-" .. playerRealm
	local playerQty = C_CurrencyInfo.GetCurrencyInfo(id).quantity or 0

	if nil == charList or #charList == 0 then
		-- no warband resources - just skip all to only show the player itself by blizzard
		return
	end

	table.insert(charList, {
		fullCharacterName = playerFullName,
		characterName = playerName,
		characterGUID = UnitGUID("player"),
		currencyID = id,
		quantity = playerQty,
	})

	if charList and #charList > 0 then
		table.sort(charList, function(a, b) return a.quantity > b.quantity end)

		for i = tooltip:NumLines(), 1, -1 do
			local left = _G[tooltip:GetName() .. "TextLeft" .. i]
			local right = _G[tooltip:GetName() .. "TextRight" .. i]
			local text = left and left:GetText()
			if text and safeMatch(text, "^" .. TOTAL .. ":") then
				-- wipe both columns and break; there is only one such line
				left:SetText("")
				if right then right:SetText("") end
				break
			end
		end

		tooltip:AddLine(" ")
		local total = 0
		for _, entry in ipairs(charList) do
			total = total + entry.quantity
		end

		tooltip:AddLine(string.format("%s: |cFFFFFFFF%s|r", TOTAL, fmtNum(total)), 1, 0.82, 0)

		tooltip:AddLine(" ")

		for _, entry in ipairs(charList) do
			tooltip:AddLine(string.format("%s: |cFFFFFFFF%s|r", entry.characterName, fmtNum(entry.quantity)))
		end
		tooltip:Show()
	end
end

local spellTooltipIconIDCache = {}

local function GetTooltipSpellIconID(id)
	if not IsValidSpellIdentifier(id) then return nil end

	local key = id
	if type(id) == "string" then key = "s:" .. id end

	local cached = spellTooltipIconIDCache[key]
	if cached ~= nil then
		if cached == false then return nil end
		return cached
	end

	local spellInfo = C_Spell.GetSpellInfo(id)
	local iconID = spellInfo and spellInfo.iconID or false
	spellTooltipIconIDCache[key] = iconID
	if iconID == false then return nil end
	return iconID
end

local function ShouldRunSpellTooltipWork(id, isSpell)
	local db = addon.db
	if not db then return false end
	if db["TooltipShowSpellID"] then return true end
	if isSpell and IsValidSpellIdentifier(id) and (db["TooltipShowSpellIconInline"] or db["TooltipShowSpellIcon"]) then return true end
	return db["TooltipSpellHideType"] ~= 1
end

local function checkSpell(tooltip, id, name, isSpell)
	if not IsTooltipMutable(tooltip) then return end
	local db = addon.db
	if not db then return end

	local first = true
	local showIDDetails = ShouldShowTooltipIDDetails()
	local showSpellID = showIDDetails and db["TooltipShowSpellID"] and not isSecret(id)
	local canResolveSpellIcon = isSpell and IsValidSpellIdentifier(id)
	local showSpellIconInline = canResolveSpellIcon and db["TooltipShowSpellIconInline"]
	local showSpellIcon = showIDDetails and canResolveSpellIcon and db["TooltipShowSpellIcon"]
	local spellIconID
	if showSpellIconInline or showSpellIcon then spellIconID = GetTooltipSpellIconID(id) end

	if showSpellID then
		if id then
			if first then
				tooltip:AddLine(" ")
				first = false
			end
			tooltip:AddDoubleLine(name, id)
		end
	end

	if showSpellIconInline and spellIconID then
		local line = tooltip and _G[tooltip:GetName() .. "TextLeft1"]
		if line then
			local current = line:GetText()
			if current and not isSecret(current) and not safeFind(current, "|T", true) then
				local size = db["TooltipItemIconSize"] or 16
				if size < 10 then
					size = 10
				elseif size > 30 then
					size = 30
				end
				local tex = string.format("|T%d:%d:%d:0:0|t ", spellIconID, size, size)
				line:SetText(tex .. current)
			end
		end
	end

	if showSpellIcon and spellIconID then
		if first then
			tooltip:AddLine(" ")
			first = false
		end
		tooltip:AddDoubleLine(L["IconID"], spellIconID)
	end

	if db["TooltipSpellHideType"] == 1 then return end -- only hide when ON
	if db["TooltipSpellHideInDungeon"] and select(1, IsInInstance()) == false then return end -- only hide in dungeons
	if db["TooltipSpellHideInCombat"] and UnitAffectingCombat("player") == false then return end -- only hide in combat
	if IsTooltipHideOverrideActive() then return end
	tooltip:Hide()
end

ResolveTooltipUnit = function(tooltip)
	local unit, hadTooltipUnit = GetUnitTokenFromTooltip(tooltip)
	if SafeUnitExists(unit) then return unit end
	if hadTooltipUnit then return nil end
	if SafeUnitExists("mouseover") then return "mouseover" end
	return nil
end

local function GetTooltipDataKind(tooltip)
	if not (tooltip and tooltip.GetPrimaryTooltipInfo) then return nil end
	local info = tooltip:GetPrimaryTooltipInfo()
	if not info or isSecret(info.type) then return nil end
	return addon.Tooltip and addon.Tooltip.variables and addon.Tooltip.variables.kindsByID and addon.Tooltip.variables.kindsByID[tonumber(info.type)]
end

local function IsModifierTooltipRefreshNeeded()
	local db = addon.db
	if not db then return false end
	if db["TooltipHideOverrideEnabled"] then return true end
	if db["TooltipShowMythicScore"] then return true end
	if db["TooltipUnitInspectRequireModifier"] and (db["TooltipUnitShowSpec"] or db["TooltipUnitShowItemLevel"]) then return true end
	if db["TooltipIDRequireModifier"] and HasTooltipIDOptions() then return true end
	return false
end

local function RefreshVisibleTooltipForModifier()
	if not IsModifierTooltipRefreshNeeded() then return end
	if isTooltipRestricted() then return end
	if not GameTooltip or not GameTooltip.IsShown or not GameTooltip:IsShown() then return end
	if GameTooltip.IsForbidden and GameTooltip:IsForbidden() then return end

	local unit, hadTooltipUnit = GetUnitTokenFromTooltip(GameTooltip)
	local kind = GetTooltipDataKind(GameTooltip)
	if kind == "unit" or hadTooltipUnit then
		if not SafeUnitExists(unit) and ResolveTooltipUnit then unit = ResolveTooltipUnit(GameTooltip) end
		if not SafeUnitExists(unit) then return end
		if GameTooltip.SetUnit and safeSecureCall(GameTooltip.SetUnit, GameTooltip, unit) then GameTooltip:Show() end
		return
	end

	if not kind then return end
	if GameTooltip.RefreshData and safeSecureCall(GameTooltip.RefreshData, GameTooltip) then return end
	if not SafeUnitExists(unit) then return end
	if GameTooltip.SetUnit and safeSecureCall(GameTooltip.SetUnit, GameTooltip, unit) then GameTooltip:Show() end
end

local fModifierTooltipRefresh = CreateFrame("Frame")
fModifierTooltipRefresh:SetScript("OnEvent", function(_, _, key)
	if key ~= "LSHIFT" and key ~= "RSHIFT" and key ~= "LCTRL" and key ~= "RCTRL" and key ~= "LALT" and key ~= "RALT" then return end
	RefreshVisibleTooltipForModifier()
	if addon.functions.RefreshNativeAuraTooltipPolicy then addon.functions.RefreshNativeAuraTooltipPolicy() end
	if addon.db and addon.db["TooltipIDRequireModifier"] and addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.UpdateQuestIDInQuestLog then
		addon.Tooltip.functions.UpdateQuestIDInQuestLog()
	end
end)

addon.Tooltip = addon.Tooltip or {}
addon.Tooltip.functions = addon.Tooltip.functions or {}

local AURA_SPELL_ID_CVAR = "tooltipShowAuraSpellIDs"

function addon.Tooltip.functions.RequestNativeAuraSpellIDs()
	if not (addon.db and addon.db["TooltipShowSpellID"]) then return end
	if not (C_CVar and C_CVar.GetCVarBool and C_CVar.SetCVar) then return end
	if C_CVar.GetCVarBool(AURA_SPELL_ID_CVAR) ~= true then C_CVar.SetCVar(AURA_SPELL_ID_CVAR, "1") end
end

function addon.Tooltip.functions.UpdateModifierTooltipRefreshEventRegistration()
	if not fModifierTooltipRefresh then return end
	if IsModifierTooltipRefreshNeeded() then
		fModifierTooltipRefresh:RegisterEvent("MODIFIER_STATE_CHANGED")
	else
		fModifierTooltipRefresh:UnregisterEvent("MODIFIER_STATE_CHANGED")
	end
end

local function HasUnitTooltipOptions()
	local db = addon.db
	if not db then return false end
	if db["TooltipUnitHideType"] and db["TooltipUnitHideType"] ~= 1 then return true end
	if db["TooltipUnitHideInCombat"] or db["TooltipUnitHideInDungeon"] then return true end
	if db["TooltipUnitHideHealthBar"] then return true end
	if db["TooltipShowMythicScore"] then return true end
	if db["TooltipShowClassColor"] then return true end
	if db["TooltipShowNPCID"] then return true end
	if db["TooltipHideFaction"] or db["TooltipHidePVP"] then return true end
	if db["TooltipShowGuildRank"] or db["TooltipColorGuildName"] then return true end
	if db["TooltipUnitShowTargetOfTarget"] then return true end
	if db["TooltipUnitShowMount"] then return true end
	if db["TooltipShowRealmInfo"] then return true end
	if db["TooltipUnitShowSpec"] or db["TooltipUnitShowItemLevel"] then return true end
	return false
end

local function ShouldRunAdditionalTooltip()
	local db = addon.db
	if not db then return false end
	return db["TooltipShowNPCID"]
		or db["TooltipShowClassColor"]
		or db["TooltipHideFaction"]
		or db["TooltipHidePVP"]
		or db["TooltipShowGuildRank"]
		or db["TooltipColorGuildName"]
		or db["TooltipUnitShowTargetOfTarget"]
		or db["TooltipUnitShowMount"]
		or db["TooltipShowRealmInfo"]
		or db["TooltipShowMythicScore"]
end

local function checkAdditionalTooltip(tooltip)
	if not IsTooltipMutable(tooltip) then return end
	if not ShouldRunAdditionalTooltip() then return end
	local unit = ResolveTooltipUnit(tooltip)
	if unit and IsUnitIdentitySecret(unit) then return end
	local function challengeLabel(mapId)
		if addon.Tooltip and addon.Tooltip.variables and addon.Tooltip.variables.challengeMapID then
			local name = addon.Tooltip.variables.challengeMapID[mapId]
			if name and name ~= "" then return name end
		end
		if mapId then return "ID " .. tostring(mapId) end
		return "UNKNOWN"
	end
	if addon.db["TooltipShowNPCID"] and ShouldShowTooltipIDDetails() and SafeUnitExists(unit) and not SafeUnitPlayerControlled(unit) then
		local uGuid = UnitGUID(unit)
		local id = GetNPCIDFromGUID(uGuid)
		if id then
			tooltip:AddLine(" ")
			tooltip:AddDoubleLine(L["NPCID"], id)
		end
		return
	end
	if addon.db["TooltipShowClassColor"] and unit and UnitIsPlayer(unit) then
		local classDisplayName, class, classID = UnitClass(unit)
		if classDisplayName and not isSecret(classDisplayName) and not isSecret(class) and not isSecret(classID) then
			local r, g, b = GetClassColor(class)
			local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
			if nameLine then nameLine:SetTextColor(r, g, b) end
			for i = 1, tooltip:NumLines() do
				local line = _G[tooltip:GetName() .. "TextLeft" .. i]
				local text = line and line:GetText()
				if safeFind(text, classDisplayName, true) then
					line:SetTextColor(r, g, b)
					break
				end
			end
		end
	end
	if unit and UnitIsPlayer(unit) and IsSimpleGuildInfoUnitToken(unit) then
		local guildName, guildRank = GetGuildInfo(unit)
		if addon.db["TooltipHideFaction"] or addon.db["TooltipHidePVP"] then
			local ttName = tooltip:GetName()
			local factionName = addon.db["TooltipHideFaction"] and select(2, UnitFactionGroup(unit)) or nil
			local pvpText = addon.db["TooltipHidePVP"] and (PVP or "PvP") or nil
			for i = 1, tooltip:NumLines() do
				local line = _G[ttName .. "TextLeft" .. i]
				local text = line and line:GetText()
				if text then
					if factionName and safeEquals(text, factionName) then
						line:SetText("")
						line:Hide()
					elseif pvpText and safeEquals(text, pvpText) then
						line:SetText("")
						line:Hide()
					end
				end
			end
		end
		if guildName then
			local ttName = tooltip:GetName()
			local guildLine
			local guildLineText
			for i = 1, tooltip:NumLines() do
				local line = _G[ttName .. "TextLeft" .. i]
				local text = line and line:GetText()
				if safeFind(text, guildName, true) then
					guildLine = line
					guildLineText = text
					break
				end
			end

			local newText
			local nameText = guildName
			if addon.db["TooltipColorGuildName"] then
				local c = addon.db["TooltipGuildNameColor"] or { r = 1, g = 1, b = 1 }
				nameText = string.format("|cff%02x%02x%02x%s|r", (c.r or 1) * 255, (c.g or 1) * 255, (c.b or 1) * 255, guildName)
			end

			local rankText
			if addon.db["TooltipShowGuildRank"] and guildRank then
				local col = addon.db["TooltipGuildRankColor"] or { r = 1, g = 1, b = 1 }
				rankText = string.format("|cff%02x%02x%02x%s|r", (col.r or 1) * 255, (col.g or 1) * 255, (col.b or 1) * 255, guildRank)
			end

			if guildLine then
				newText = nameText
				if rankText and guildLineText and not isSecret(guildLineText) and not safeFind(guildLineText, guildRank or "", true) then newText = newText .. " - " .. rankText end
				guildLine:SetText(newText)
			else
				if rankText then
					tooltip:AddLine(" ")
					tooltip:AddDoubleLine(L["GuildRank"] or RANK, rankText)
				end
			end
		end
	end

	if unit and addon.db["TooltipUnitShowTargetOfTarget"] then
		local targetUnit = unit .. "target"
		if UnitExists(targetUnit) then
			local targetName = FormatTargetOfTargetName(targetUnit)
			if targetName then tooltip:AddDoubleLine(L["TooltipTargeting"] or "Targeting", ColorTargetOfTargetName(targetUnit, targetName)) end
		end
	end

	if unit and addon.db["TooltipUnitShowMount"] and UnitIsPlayer(unit) then
		local mountName, mountIcon, mountCollected = GetUnitMountInfo(unit)
		if mountName then
			if mountIcon then mountName = ("|T%d:16:16:0:0|t %s"):format(mountIcon, mountName) end
			if mountCollected then mountName = ("|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t %s"):format(mountName) end
			tooltip:AddDoubleLine(L["TooltipMount"] or "Mount", ColorText(mountName))
		end
	end

	if unit then AddUnitRealmInfo(tooltip, unit) end

	local showMythic = addon.db["TooltipShowMythicScore"] and SafeUnitExists(unit) and UnitCanAttack("player", unit) == false and addon.Tooltip.variables.maxLevel == UnitLevel(unit)
	if showMythic then
		local timeLimit
		local rating = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
		if rating then
			local r, g, b
			local bestDungeon
			local dungeonList = {}
			local ratingInfo = {}

			-- Read parts selection; default to show all if unset
			local parts = addon.db["TooltipMythicScoreParts"]
			local wantScore = type(parts) ~= "table" and true or parts.score == true
			local wantBest = type(parts) ~= "table" and true or parts.best == true
			local detailsRequireModifier = addon.db["TooltipMythicScoreRequireModifier"] == true
			local wantDungeons = type(parts) ~= "table" and true or parts.dungeons == true
			if detailsRequireModifier and not IsConfiguredModifierDown() then wantDungeons = false end

			if rating.currentSeasonScore > 0 and (wantBest or wantDungeons) then
				for _, key in pairs(rating.runs) do
					ratingInfo[key.challengeModeID] = key
				end

				for _, key in pairs(C_ChallengeMode.GetMapTable()) do
					timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(key))
					r, g, b = 0.5, 0.5, 0.5

					local data = key
					local mId = key
					local stars = 0
					local score = 0
					if ratingInfo[key] then
						data = ratingInfo[key]
						mId = data.challengeModeID
						if nil == bestDungeon then
							bestDungeon = data
						else
							if bestDungeon.mapScore < data.mapScore then bestDungeon = data end
						end

						if data.bestRunLevel > 0 then
							r, g, b = 1, 1, 1

							local bestRunDuration = math.floor(data.bestRunDurationMS / 1000)
							local timeForPlus3 = timeLimit * 0.6
							local timeForPlus2 = timeLimit * 0.8
							local timeForPlus1 = timeLimit
							score = data.mapScore
							if bestRunDuration <= timeForPlus3 then
								stars = "|cFFFFD700+++|r" -- Gold für 3 Sterne
							elseif bestRunDuration <= timeForPlus2 then
								stars = "|cFFFFD700++|r" -- Gold für 2 Sterne
							elseif bestRunDuration <= timeForPlus1 then
								stars = "|cFFFFD700+|r" -- Gold für 1 Stern
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

					table.insert(dungeonList, {
						text = challengeLabel(mId),
						level = stars,
						score = score,
						r = r,
						g = g,
						b = b,
					})
				end
			end

			if wantScore then
				r, g, b = C_ChallengeMode.GetDungeonScoreRarityColor(rating.currentSeasonScore):GetRGB()
				local scoreText = ColorTextRGB(rating.currentSeasonScore or 0, r, g, b)
				local bestLevel = wantBest and bestDungeon and bestDungeon.mapScore > 0 and FormatDungeonRunLevel(bestDungeon) or nil
				if bestLevel then scoreText = ("%s %s"):format(scoreText, ColorText("(" .. bestLevel .. ")")) end
				tooltip:AddDoubleLine(TOOLTIP_LABEL_COLOR .. DUNGEON_SCORE .. TOOLTIP_COLOR_CLOSE, scoreText, 1, 1, 1, 1, 1, 1)
			elseif wantBest and bestDungeon and bestDungeon.mapScore > 0 then
				local stars = FormatDungeonRunLevel(bestDungeon)
				local bestName = challengeLabel(bestDungeon.challengeModeID)
				if stars then
					tooltip:AddDoubleLine(TOOLTIP_LABEL_COLOR .. L["BestMythic+run"] .. TOOLTIP_COLOR_CLOSE, ("%s %s"):format(stars, bestName), 1, 1, 1, 1, 1, 1)
				end
			end

			if wantDungeons and #dungeonList > 0 then
				table.sort(dungeonList, function(a, b) return a.score > b.score end)
				for _, dungeon in ipairs(dungeonList) do
					tooltip:AddDoubleLine(dungeon.text, dungeon.level, 1, 1, 1, dungeon.r, dungeon.g, dungeon.b)
				end
			end
		end
	end
end

local function ShowCopyURL(url)
	if type(url) ~= "string" or url == "" then return end
	if not StaticPopupDialogs["ENHANCEQOL_COPY_URL"] then
		StaticPopupDialogs["ENHANCEQOL_COPY_URL"] = {
			text = L["copyUrlPopupText"],
			button1 = OKAY,
			hasEditBox = true,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			OnShow = function(self, data)
				local eb = self.editBox or self.GetEditBox and self:GetEditBox()
				if not eb then return end
				eb:SetAutoFocus(true)
				eb:SetText(data or "")
				eb:HighlightText()
				eb:SetCursorPosition(0)
			end,
			OnAccept = function(self) end,
			EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		}
	end
	StaticPopup_Show("ENHANCEQOL_COPY_URL", nil, nil, url)
end

local function UpdateTooltipHealthBarVisibility(tooltip)
	if not tooltip or not addon.db then return end
	local hideBar = addon.db["TooltipUnitHideHealthBar"] and true or false
	if not hideBar and not tooltip.__EnhanceQoLTooltipHealthBarTouched then return end

	local function handleAlpha(obj)
		if not obj or not obj.SetAlpha then return end
		if not obj.__EnhanceQoLTooltipOriginalAlpha then obj.__EnhanceQoLTooltipOriginalAlpha = (obj.GetAlpha and obj:GetAlpha()) or 1 end
		local alpha = hideBar and 0 or obj.__EnhanceQoLTooltipOriginalAlpha or 1
		obj:SetAlpha(alpha)
	end

	local function apply(bar)
		if not bar then return end
		if hideBar then
			if bar.SetShown then
				bar:SetShown(false)
			elseif bar.Hide then
				bar:Hide()
			end
		else
			if bar.SetShown then
				bar:SetShown(true)
			elseif bar.Show then
				bar:Show()
			end
		end
		handleAlpha(bar)
		handleAlpha(bar.Fill or bar.fill)
		handleAlpha(bar.Spark or bar.spark)
		handleAlpha(bar.Bg or bar.BG or bar.bg)
		handleAlpha(bar.Background or bar.background)
		handleAlpha(bar.TextString or bar.textString)
		handleAlpha(bar.Text or bar.text)
		handleAlpha(bar.Value or bar.value)
		handleAlpha(bar.LeftText)
		handleAlpha(bar.RightText)
		local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
		handleAlpha(texture)
		local name = bar.GetName and bar:GetName()
		if name then
			handleAlpha(_G[name .. "Spark"])
			handleAlpha(_G[name .. "BG"])
			handleAlpha(_G[name .. "Background"])
			handleAlpha(_G[name .. "Border"])
			handleAlpha(_G[name .. "BorderLeft"])
			handleAlpha(_G[name .. "BorderRight"])
		end
	end

	apply(tooltip.StatusBar)
	apply(tooltip.statusBar)
	apply(tooltip.healthBar)
	if tooltip.statusBarPool and tooltip.statusBarPool.EnumerateActive then
		for bar in tooltip.statusBarPool:EnumerateActive() do
			apply(bar)
		end
	end
	if tooltip.StatusBarPool and tooltip.StatusBarPool.EnumerateActive then
		for bar in tooltip.StatusBarPool:EnumerateActive() do
			apply(bar)
		end
	end
	if tooltip.healthBarPool and tooltip.healthBarPool.EnumerateActive then
		for bar in tooltip.healthBarPool:EnumerateActive() do
			apply(bar)
		end
	end
	if tooltip == GameTooltip then
		apply(GameTooltipStatusBar)
		handleAlpha(GameTooltipStatusBarTexture)
		handleAlpha(GameTooltipStatusBarBackground)
	end
	tooltip.__EnhanceQoLTooltipHealthBarTouched = hideBar or nil
end

local function checkUnit(tooltip)
	if not IsTooltipMutable(tooltip) then return end
	UpdateTooltipHealthBarVisibility(tooltip)
	if not HasUnitTooltipOptions() then return end
	if addon.db["TooltipUnitHideInDungeon"] and select(1, IsInInstance()) == false then
		checkAdditionalTooltip(tooltip)
		return
	end -- only hide in dungeons
	if addon.db["TooltipUnitHideInCombat"] and UnitAffectingCombat("player") == false then
		checkAdditionalTooltip(tooltip)
		return
	end -- only hide in combat
	if addon.db["TooltipUnitHideType"] == 1 then
		checkAdditionalTooltip(tooltip)
		return
	end -- hide never
	local override = IsTooltipHideOverrideActive()
	if addon.db["TooltipUnitHideType"] == 4 and not override then tooltip:Hide() end -- hide always because we selected BOTH
	if addon.db["TooltipUnitHideType"] == 2 and UnitCanAttack("player", "mouseover") and not override then tooltip:Hide() end
	if addon.db["TooltipUnitHideType"] == 3 and UnitCanAttack("player", "mouseover") == false and not override then tooltip:Hide() end
	checkAdditionalTooltip(tooltip)
end

local tooltipScaleTargets = {
	"GameTooltip",
	"ItemRefTooltip",
	"ShoppingTooltip1",
	"ShoppingTooltip2",
	"EmbeddedItemTooltip",
	"ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2",
}

local function GetConfiguredTooltipScale()
	local scale = addon.db and tonumber(addon.db["TooltipScale"]) or 1
	if not scale or scale <= 0 then scale = 1 end
	if scale < 0.5 then
		scale = 0.5
	elseif scale > 1.5 then
		scale = 1.5
	end
	return scale
end

local function ApplyTooltipScaleToTarget(tt)
	if not tt or not tt.SetScale then return end
	tt:SetScale(GetConfiguredTooltipScale())
	if not tt.HookScript or tt.__EnhanceQoLTooltipScaleHooked then return end
	tt.__EnhanceQoLTooltipScaleHooked = true
	tt:HookScript("OnShow", function(self) self:SetScale(GetConfiguredTooltipScale()) end)
end

local function ApplyTooltipScale()
	for _, name in ipairs(tooltipScaleTargets) do
		ApplyTooltipScaleToTarget(_G[name])
	end
end

addon.Tooltip = addon.Tooltip or {}
addon.Tooltip.ApplyScale = ApplyTooltipScale

local lastEntry
local function checkItem(tooltip, id, name, guid)
	if not IsTooltipMutable(tooltip) then return end
	local first = true

	-- Automatically preview housing items if enabled
	if addon.db["TooltipHousingAutoPreview"] and C_HousingCatalog and C_HousingCatalog.GetCatalogEntryInfoByItem then
		local housingData = C_HousingCatalog.GetCatalogEntryInfoByItem(id, false)
		if housingData and lastEntry ~= id then
			lastEntry = id

			if not HousingModelPreviewFrame and C_AddOns then C_AddOns.LoadAddOn("Blizzard_HousingModelPreview") end
			if HousingModelPreviewFrame and HousingModelPreviewFrame.ShowCatalogEntryInfo then HousingModelPreviewFrame:ShowCatalogEntryInfo(housingData) end
		end
	end

	local showItemID = addon.db["TooltipShowItemID"] and ShouldShowTooltipIDDetails()

	if showItemID and id then
		if first then
			tooltip:AddLine(" ")
			first = false
		end
		tooltip:AddDoubleLine(name, id)
	end

	if addon.db["TooltipShowItemIcon"] then
		local icon = nil
		if id then icon = select(5, C_Item.GetItemInfoInstant(id)) end
		local line = tooltip and _G[tooltip:GetName() .. "TextLeft1"]
		if line then
			local current = line:GetText()

			if current and icon and not isSecret(current) and not safeFind(current, "|T", true) then
				local size = addon.db and addon.db["TooltipItemIconSize"] or 16
				if size < 10 then
					size = 10
				elseif size > 30 then
					size = 30
				end
				local tex = string.format("|T%d:%d:%d:0:0|t ", icon, size, size)
				line:SetText(tex .. current)
			end
		end
	end

	if addon.db["TooltipShowTempEnchant"] and ShouldShowTooltipIDDetails() and guid then
		local mhHas, mhExp, _, mhID, ohHas, ohExp, _, ohID, rhHas, rhExp = GetWeaponEnchantInfo()
		if mhHas and guid == Item:CreateFromEquipmentSlot(16):GetItemGUID() then
			if mhID then
				if first then
					tooltip:AddLine(" ")
					first = false
				end
				tooltip:AddDoubleLine(L["Temp. EnchantID"], mhID)
			end
		elseif ohHas and guid == Item:CreateFromEquipmentSlot(17):GetItemGUID() then
			if ohID then
				if first then
					tooltip:AddLine(" ")
					first = false
				end
				tooltip:AddDoubleLine(L["Temp. EnchantID"], ohID)
			end
		end
	end
	if addon.db["TooltipShowItemCount"] then
		if id then
			if addon.db["TooltipShowSeperateItemCount"] then
				local bagCount = C_Item.GetItemCount(id) or 0
				local totalWithoutAccountBank = C_Item.GetItemCount(id, true) or bagCount
				local totalCount = C_Item.GetItemCount(id, true, false, false, true) or totalWithoutAccountBank
				local bankCount = math.max(0, totalWithoutAccountBank - bagCount)
				local accountCount = math.max(0, totalCount - totalWithoutAccountBank)

				if bagCount > 0 then
					if first then
						tooltip:AddLine(" ")
						first = false
					end
					tooltip:AddDoubleLine(L["Bag"], bagCount)
				end
				if bankCount > 0 then
					if first then
						tooltip:AddLine(" ")
						first = false
					end
					tooltip:AddDoubleLine(BANK, bankCount)
				end
				if accountCount > 0 then
					if first then
						tooltip:AddLine(" ")
						first = false
					end
					tooltip:AddDoubleLine(ACCOUNT_BANK_PANEL_TITLE, accountCount)
				end
			else
				local totalCount = C_Item.GetItemCount(id, true, false, false, true) or 0
				tooltip:AddDoubleLine(L["Itemcount"], totalCount)
			end
		end
	end
	if addon.db["TooltipItemHideType"] == 1 then return end -- only hide when ON
	if addon.db["TooltipItemHideInDungeon"] and select(1, IsInInstance()) == false then return end -- only hide in dungeons
	if addon.db["TooltipItemHideInCombat"] and UnitAffectingCombat("player") == false then return end -- only hide in combat
	if IsTooltipHideOverrideActive() then return end
	tooltip:Hide()
end

local function checkAura(tooltip, id)
	if not IsTooltipMutable(tooltip) then return end
	local first = true
	local showIDDetails = ShouldShowTooltipIDDetails()

	if addon.db["TooltipShowSpellIconInline"] and IsValidSpellIdentifier(id) then
		local spellInfo = C_Spell.GetSpellInfo(id)
		if spellInfo and spellInfo.iconID then --and (not issecretvalue or (issecretvalue and not issecretvalue(spellInfo.iconID))) then
			local line = tooltip and _G[tooltip:GetName() .. "TextLeft1"]
			if line then
				local current = line:GetText()
				if current and not isSecret(current) then
					local size = addon.db and addon.db["TooltipItemIconSize"] or 16
					if size < 10 then
						size = 10
					elseif size > 30 then
						size = 30
					end
					local tex = string.format("|T%d:%d:%d:0:0|t ", spellInfo.iconID, size, size)
					line:SetText(tex .. current)
				end
			end
		end
	end

	if addon.db["TooltipShowSpellIcon"] and showIDDetails and IsValidSpellIdentifier(id) then
		local spellInfo = C_Spell.GetSpellInfo(id)
		if spellInfo and spellInfo.iconID then
			if first then
				tooltip:AddLine(" ")
				first = false
			end
			tooltip:AddDoubleLine(L["IconID"], spellInfo.iconID)
		end
	end

	if addon.db["TooltipBuffHideType"] == 1 then return end -- only hide when ON
	if addon.db["TooltipBuffHideInDungeon"] and select(1, IsInInstance()) == false then return end -- only hide in dungeons
	if addon.db["TooltipBuffHideInCombat"] and UnitAffectingCombat("player") == false then return end -- only hide in combat
	if IsTooltipHideOverrideActive() then return end
	tooltip:Hide()
end

local function checkAdditionalUnit(tt)
	if not IsTooltipMutable(tt) then return end
	if not (addon.db["TooltipUnitShowSpec"] or addon.db["TooltipUnitShowItemLevel"]) then return end
	if isTooltipRestricted() then return end

	local unit = ResolveTooltipUnit(tt)
	if not unit or not UnitIsPlayer(unit) then return end

	EnsureUnitData(unit)
	local guid = UnitGUID(unit)
	if not guid or isSecret(guid) then return end
	local c = InspectCache[guid]
	if not c then return end

	local showSpec = addon.db["TooltipUnitShowSpec"] and c.specName
	local showIlvl = addon.db["TooltipUnitShowItemLevel"] and c.ilvl
	if addon.db["TooltipUnitInspectRequireModifier"] and not IsConfiguredModifierDown() then
		showSpec = false
		showIlvl = false
	end
	if showSpec then tt:AddDoubleLine(TOOLTIP_LABEL_COLOR .. SPECIALIZATION .. TOOLTIP_COLOR_CLOSE, ColorText(c.specName)) end
	if showIlvl then
		local label = STAT_AVERAGE_ITEM_LEVEL or ITEM_LEVEL or "Item Level"
		local r, g, b = GetTooltipItemLevelColor()
		tt:AddDoubleLine(TOOLTIP_LABEL_COLOR .. label .. TOOLTIP_COLOR_CLOSE, tostring(c.ilvl), 1, 1, 0, r, g, b)
	end
	if showSpec or showIlvl then tt:Show() end
end

local function ShouldRunTooltipPostCall()
	local db = addon.db
	if not db then return false end
	return db["TooltipShowSpellID"]
		or db["TooltipShowSpellIcon"]
		or db["TooltipShowSpellIconInline"]
		or db["TooltipShowItemID"]
		or db["TooltipShowItemIcon"]
		or db["TooltipShowTempEnchant"]
		or db["TooltipShowItemCount"]
		or (db["TooltipItemHideType"] and db["TooltipItemHideType"] ~= 1)
		or db["TooltipItemHideInDungeon"]
		or db["TooltipShowCurrencyID"]
		or db["TooltipShowCurrencyAccountWide"]
		or (db["TooltipUnitHideType"] and db["TooltipUnitHideType"] ~= 1)
		or db["TooltipUnitHideInCombat"]
		or db["TooltipUnitHideInDungeon"]
		or db["TooltipUnitHideHealthBar"]
		or db["TooltipUnitShowTargetOfTarget"]
		or db["TooltipUnitShowMount"]
		or db["TooltipShowRealmInfo"]
		or db["TooltipUnitShowSpec"]
		or db["TooltipUnitShowItemLevel"]
		or db["TooltipShowMythicScore"]
		or (db["TooltipBuffHideType"] and db["TooltipBuffHideType"] ~= 1)
		or db["TooltipBuffHideInDungeon"]
		or db["TooltipBuffHideInCombat"]
end

if TooltipDataProcessor then
	TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.SellPrice, function(tooltip, lineData)
		if not ShouldRunTooltipPostCall() then return end
		tooltip:AddLine(SELL_PRICE .. ": " .. GetMoneyString(lineData.price), WHITE_FONT_COLOR:GetRGB())
		return true
	end)

	TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip, data)
		if not ShouldRunTooltipPostCall() then return end
		if not data or not data.type then return end
		if not IsTooltipMutable(tooltip) then return end

		if issecretvalue and issecretvalue(data.type) then return end

		local id, name, _, timeLimit, kind

		kind = addon.Tooltip.variables.kindsByID[tonumber(data.type)]

		if kind == "spell" then
			id = data.id
			if not ShouldRunSpellTooltipWork(id, true) then return end
			name = L["SpellID"]
			checkSpell(tooltip, id, name, true)
			return
		elseif kind == "macro" then
			local ttInfo = tooltip:GetPrimaryTooltipInfo()
			id = data.id
			if ttInfo and ttInfo.getterArgs then
				local actionSlot = ttInfo.getterArgs[1]
				if actionSlot then id = C_ActionBar.GetActionText(actionSlot) end
			end
			if not ShouldRunSpellTooltipWork(id, false) then return end
			name = MACRO
			checkSpell(tooltip, id, name)
			return
		elseif kind == "unit" then
			checkUnit(tooltip)
			checkAdditionalUnit(tooltip)
			return
		elseif kind == "item" then
			id = data.id
			name = L["ItemID"]
			checkItem(tooltip, id, name, data.guid)
			return
		elseif kind == "aura" then
			id = data.id
			name = L["SpellID"]
			checkAura(tooltip, id, name)
			return
		elseif kind == "currency" then
			-- Show account‑wide character breakdown for the given currency
			id = data.id
			checkCurrency(tooltip, id)
			return
		end
	end)
end

local function IsUnitTooltip(tt)
	local owner = tt and tt:GetOwner()
	if not owner then return false end
	return owner.unit or (owner.GetAttribute and owner:GetAttribute("unit"))
end

local function EnsureQuestIDInQuestLogLabel()
	if addon.Tooltip.variables.questIDInQuestLogLabel then return addon.Tooltip.variables.questIDInQuestLogLabel end
	if not QuestMapFrame or not QuestMapFrame.DetailsFrame or not QuestMapFrame.DetailsFrame.BackFrame then return end

	local backFrame = QuestMapFrame.DetailsFrame.BackFrame and QuestMapFrame.DetailsFrame.BackFrame.BackButton or QuestMapFrame.DetailsFrame.BackFrame
	local anchor = backFrame.AccountCompletedNotice or backFrame
	local fs = backFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetJustifyH("RIGHT")
	fs:SetJustifyV("MIDDLE")
	if anchor ~= backFrame then
		fs:SetPoint("RIGHT", anchor, "LEFT", -18, 0)
	else
		fs:SetPoint("TOPLEFT", backFrame, "TOPRIGHT", 14, -8)
	end
	fs:Hide()

	addon.Tooltip.variables.questIDInQuestLogLabel = fs
	return fs
end

local function UpdateQuestIDInQuestLogLabel(questID)
	local fs = EnsureQuestIDInQuestLogLabel()
	if not fs then return end
	if not addon.db or not addon.db["TooltipShowQuestIDInQuestLog"] or not ShouldShowTooltipIDDetails() or not questID or questID == 0 then
		fs:SetText("")
		fs:Hide()
		return
	end

	local label = ID or "ID"
	fs:SetText(("%s: %s"):format(label, tostring(questID)))
	fs:Show()
end

local function RegisterLFGTooltipHooks()
	if addon.Tooltip.variables.lfgHooksInitialized then return end
	if not _G.LFGListUtil_SetSearchEntryTooltip or not _G.LFGListSearchEntry_Update or not _G.LFGListApplicationViewer_UpdateApplicantMember then return end
	addon.Tooltip.variables.lfgHooksInitialized = true

	hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
		if not IsTooltipMutable(tooltip) then return end
		AddLFGSearchEntryRealmInfo(tooltip, resultID)
	end)

	hooksecurefunc("LFGListSearchEntry_Update", function(entry)
		UpdateLFGSearchEntryRealmFlag(entry)
	end)

	hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(memberFrame, appID, memberIdx)
		UpdateLFGApplicantMemberRealmFlag(memberFrame, appID, memberIdx)
	end)
end

function addon.Tooltip.functions.UpdateQuestIDInQuestLog(questID)
	if not QuestMapFrame or not QuestMapFrame.DetailsFrame then return end
	local detailsFrame = QuestMapFrame.DetailsFrame
	if not detailsFrame:IsShown() then
		UpdateQuestIDInQuestLogLabel(nil)
		return
	end
	UpdateQuestIDInQuestLogLabel(questID or detailsFrame.questID)
end

local function ShouldInstallTooltipHooks()
	local db = addon.db
	if not db then return false end
	if ShouldRunTooltipPostCall() then return true end
	if IsModifierTooltipRefreshNeeded() then return true end
	if db["TooltipAnchorType"] and db["TooltipAnchorType"] ~= 1 then return true end
	if db["TooltipShowNPCWowheadLink"] then return true end
	if db["TooltipShowQuestID"] or db["TooltipShowQuestIDInQuestLog"] then return true end
	if db["TooltipUnitHideRightClickInstruction"] then return true end
	if db["TooltipShowRealmInfo"] then return true end
	return false
end

local function registerTooltipHooks()
	if addon.Tooltip.variables.hooksInitialized then return end
	addon.Tooltip.variables.hooksInitialized = true

	hooksecurefunc("GameTooltip_SetDefaultAnchor", function(s, p)
		if not addon.db then return end
		if not s or not s.SetOwner then return end
		if s.IsForbidden and s:IsForbidden() then return end
		if p and p.IsForbidden and p:IsForbidden() then return end
		if addon.db["TooltipAnchorType"] == 1 then return end
		local anchor
		if addon.db["TooltipAnchorType"] == 2 then anchor = "ANCHOR_CURSOR" end
		if addon.db["TooltipAnchorType"] == 3 then anchor = "ANCHOR_CURSOR_LEFT" end
		if addon.db["TooltipAnchorType"] == 4 then anchor = "ANCHOR_CURSOR_RIGHT" end
		if not anchor then return end
		local xOffset = addon.db["TooltipAnchorOffsetX"] or 0
		local yOffset = addon.db["TooltipAnchorOffsetY"] or 0
		if s.IsShown and s.GetOwner and s.GetAnchorType and s:IsShown() and safeEquals(s:GetOwner(), p) then
			local currentAnchor, currentX, currentY = s:GetAnchorType()
			currentX = currentX or 0
			currentY = currentY or 0
			if safeEquals(currentAnchor, anchor) and math.abs(currentX - xOffset) <= 0.01 and math.abs(currentY - yOffset) <= 0.01 then return end
		end
		s:SetOwner(p, anchor, xOffset, yOffset)
	end)

	if Menu and Menu.ModifyMenu then
		local function AddTargetWowheadEntry(owner, root)
			if not addon.db or not addon.db["TooltipShowNPCWowheadLink"] then return end
			if not SafeUnitExists("target") or SafeUnitPlayerControlled("target") then return end
			local guid = UnitGUID("target")
			if issecretvalue and issecretvalue(guid) then return end
			local npcID = GetNPCIDFromGUID()
			if not npcID then return end

			root:CreateDivider()
			local btn = root:CreateButton(L["CopyWowheadURL"], function() ShowCopyURL(("https://www.wowhead.com/npc=%d"):format(npcID)) end)
			if not btn then return end
			btn:AddInitializer(function()
				btn:SetTooltip(function(tt)
					GameTooltip_SetTitle(tt, L["wowhead"])
					GameTooltip_AddNormalLine(tt, ("npc=%d"):format(npcID))
				end)
			end)
		end

		Menu.ModifyMenu("MENU_UNIT_TARGET", AddTargetWowheadEntry)
	end

	hooksecurefunc("QuestMapLogTitleButton_OnEnter", function(self)
		if not addon.db or not addon.db["TooltipShowQuestID"] or not ShouldShowTooltipIDDetails() then return end
		if self then
			if self.questID and GameTooltip:IsShown() then
				GameTooltip:AddDoubleLine(ID, self.questID)
				GameTooltip:Show()
			end
		end
	end)

	hooksecurefunc("QuestMapFrame_ShowQuestDetails", function(questID)
		if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.UpdateQuestIDInQuestLog then addon.Tooltip.functions.UpdateQuestIDInQuestLog(questID) end
	end)

	hooksecurefunc("QuestMapFrame_CloseQuestDetails", function()
		if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.UpdateQuestIDInQuestLog then addon.Tooltip.functions.UpdateQuestIDInQuestLog() end
	end)

	RegisterLFGTooltipHooks()

	-- Optionally hide the default "Right-click for options" instruction on unit tooltips
	hooksecurefunc("GameTooltip_AddInstructionLine", function(tt, text)
		if not addon.db or not addon.db["TooltipUnitHideRightClickInstruction"] then return end
		if tt ~= GameTooltip then return end
		if text ~= UNIT_POPUP_RIGHT_CLICK then return end
		if not IsUnitTooltip(tt) then return end

		local i = tt:NumLines()
		local line = _G[tt:GetName() .. "TextLeft" .. i]
		if line then
			local tmpText = line:GetText()
			if isSecret(tmpText) then return end
			if safeEquals(tmpText, text) then
				line:SetText("")
				line:Hide()

				local mLine = _G[tt:GetName() .. "TextLeft" .. (i - 1)]
				local mText = mLine and mLine.GetText and mLine:GetText()
				if safeEquals(mText, " ") then mLine:Hide() end
				tt:Show()
			end
		end
	end)

	if addon.Tooltip and addon.Tooltip.functions and addon.Tooltip.functions.UpdateQuestIDInQuestLog then addon.Tooltip.functions.UpdateQuestIDInQuestLog() end
end

local function RegisterTooltipLifecycle()
	if addon.Tooltip.variables.scaleLifecycleInitialized then return end
	addon.Tooltip.variables.scaleLifecycleInitialized = true
	frameLoad:RegisterEvent("ADDON_LOADED")
	frameLoad:SetScript("OnEvent", function(_, _, loadedAddonName)
		if loadedAddonName == "Blizzard_GameTooltip" or loadedAddonName == "Blizzard_UIPanels_Game" then ApplyTooltipScale() end
		if loadedAddonName == "Blizzard_GroupFinder" and addon.Tooltip.variables.hooksInitialized then RegisterLFGTooltipHooks() end
	end)
end

function addon.Tooltip.functions.InitState()
	RegisterTooltipLifecycle()
	RunNextFrame(function()
		if addon.Tooltip and addon.Tooltip.ApplyScale then addon.Tooltip.ApplyScale() end
	end)
	if ShouldInstallTooltipHooks() then registerTooltipHooks() end
	if addon.Tooltip.functions.UpdateModifierTooltipRefreshEventRegistration then addon.Tooltip.functions.UpdateModifierTooltipRefreshEventRegistration() end
	addon.Tooltip.functions.RequestNativeAuraSpellIDs()
	UpdateInspectEventRegistration()
	if addon.functions.RefreshNativeAuraTooltipPolicy then addon.functions.RefreshNativeAuraTooltipPolicy() end
end

if addon.Tooltip.functions.InitDB then addon.Tooltip.functions.InitDB() end
if addon.Tooltip.functions.InitState then addon.Tooltip.functions.InitState() end
