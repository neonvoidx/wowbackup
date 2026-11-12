-------------------------------------------------------------------------
--
--	Copyright (c) 2019-2021 by Antoine Desmarets.
--	Cixi Delmont/Gaya Greyhoof of Wow Forever Horde
--
--	RepRewards is distributed in the hope that it will be useful/entertaining
--	but WITHOUT ANY WARRANTY. Use at your own risk.
--
-------------------------------------------------------------------------
--
-- 16001-09
--   - Adding Gelkis and Magram rep rewards
--   - Renamed addon from Reputations Rewards to Rep Rewards
--
-- 16001-08
--   - Fixed an issue where the quest text was getting stretched
--
-- 16001-07
--   - Removed forgotten debug traces
--
-- 16001-06
--   - Added Quartermaster locations
--   - Quest reputation gains now shown in quest text
--   - Options to show/hide reputations with no rewards, the [All Reputations] entry, and the quest reputation info
--
-- 16001-05
--   - Cached item list, with throttled preload/regular checks
--   - Improved filters to use stats instead of inferring from name
--   - Ability to favorite factions
--   - Tooltip relocation (as it was blocking the view)
--   - Ability to see all rewards cross-faction
--   - Filter to see what is currently available to the player (based on level, armor type, reputation standing etc)
--   - Cache retrieval dialog
--   - Saving filters per character
--
-- 16001-04
--   - Initial release
--   - UI frame, base list of reputations and rewards, basic filters
--


local addonName, addon = ...

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

RepRewards = LibStub("AceAddon-3.0"):NewAddon("RepRewards", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local Data = RepRewards_Data
local STANDING = Data.STANDING
local STANDING_NAMES = Data.STANDING_NAMES
local STANDING_COLORS = Data.STANDING_COLORS

local version = tostring(GetAddOnMetadata(addonName, "Version") or "1")
local frame
local rewardScroll
local filterWidgets = {}
local selectedFactionID
local bronzeChrome
local statusText = "RepRewards " .. version .. " by Cixi Delmont / Gaya Greyhoof"
local rewardPool = {}
local minimapIcon = LibStub("LibDBIcon-1.0", true)
local broker

-- Synthetic left-list entry that merges rewards from every available faction
local ALL_REPUTATIONS_ID = -1

local function IsAllReputations(factionID)
	return tonumber(factionID) == ALL_REPUTATIONS_ID
end

-- Left faction list (Attune-style cells)
local CELL_HEIGHT = 54
local CELL_GAP = 4
local LEFT_WIDTH = 290
local factionScroll
local factionContent
local factionCellPool = {}
local factionHeaderPool = {}
local activeFactionCells = {}
local splitFrame
local rightPanel
local RefreshFactionList
local detailWidgets = {}

local FILTER_DEFAULTS = {
	name = "",
	type = "Any",
	slot = "Any",
	stat = "Any",
	profession = "Any",
	suitableForMe = false,
	availableNow = false,
}

local filters = {
	name = "",
	type = "Any",
	slot = "Any",
	stat = "Any",
	profession = "Any",
	suitableForMe = false,
	availableNow = false,
}

-- Classic class armor / weapon usability (vanilla rules; Mail/Plate gated at 40)
local CLASS_ARMOR = {
	WARRIOR = { Cloth = true, Leather = true, Mail = true, Plate = true },
	PALADIN = { Cloth = true, Leather = true, Mail = true, Plate = true },
	HUNTER = { Cloth = true, Leather = true, Mail = true },
	ROGUE = { Cloth = true, Leather = true },
	PRIEST = { Cloth = true },
	SHAMAN = { Cloth = true, Leather = true, Mail = true },
	MAGE = { Cloth = true },
	WARLOCK = { Cloth = true },
	DRUID = { Cloth = true, Leather = true },
}

-- ItemWeaponSubclass IDs usable by each class (vanilla-oriented)
local CLASS_WEAPONS = {
	WARRIOR = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [10] = true, [13] = true, [15] = true, [16] = true, [18] = true },
	PALADIN = { [0] = true, [1] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [14] = true },
	HUNTER = { [0] = true, [1] = true, [2] = true, [3] = true, [6] = true, [7] = true, [8] = true, [10] = true, [13] = true, [15] = true, [16] = true, [18] = true },
	ROGUE = { [0] = true, [2] = true, [3] = true, [4] = true, [7] = true, [13] = true, [15] = true, [16] = true, [18] = true },
	PRIEST = { [4] = true, [10] = true, [15] = true, [19] = true },
	SHAMAN = { [0] = true, [1] = true, [4] = true, [5] = true, [10] = true, [13] = true, [15] = true, [14] = true },
	MAGE = { [7] = true, [10] = true, [15] = true, [19] = true },
	WARLOCK = { [7] = true, [10] = true, [15] = true, [19] = true },
	DRUID = { [4] = true, [5] = true, [10] = true, [13] = true, [15] = true },
}

local CLASS_SHIELDS = {
	WARRIOR = true, PALADIN = true, SHAMAN = true,
}

local function PlayerClassFile()
	local _, classFile = UnitClass("player")
	return classFile or ""
end

local function PlayerLevel()
	return UnitLevel("player") or 1
end

local function GetProfessionSkill(professionName)
	if not professionName or professionName == "" then return nil end
	if GetNumSkillLines and GetSkillLineInfo then
		for i = 1, GetNumSkillLines() do
			local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
			if not isHeader and skillName == professionName then
				return skillRank or 0
			end
		end
	end
	-- Retail-style fallback
	if GetProfessions and GetProfessionInfo then
		local profs = { GetProfessions() }
		for _, idx in ipairs(profs) do
			if idx then
				local name, _, rank = GetProfessionInfo(idx)
				if name == professionName then
					return rank or 0
				end
			end
		end
	end
	return nil
end

local function CanWearArmor(armor, classFile, level)
	if not armor or armor == "" then return true end
	local allowed = CLASS_ARMOR[classFile]
	if not allowed or not allowed[armor] then return false end
	if armor == "Plate" and level < 40 then return false end
	if armor == "Mail" and level < 40 and (classFile == "HUNTER" or classFile == "SHAMAN") then
		return false
	end
	return true
end

local function CanUseWeaponSubclass(subclassID, classFile)
	if subclassID == nil then return true end
	local allowed = CLASS_WEAPONS[classFile]
	if not allowed then return true end
	return allowed[subclassID] and true or false
end

local function RewardSkillRequired(reward)
	if reward.skill then return tonumber(reward.skill) end
	if reward.note then
		local sk = reward.note:match("[Ss]kill%s*(%d+)")
		if sk then return tonumber(sk) end
	end
	return nil
end

-------------------------------------------------------------------------
-- Reputation API (Forever / Midnight C_Reputation + Classic fallback)
-------------------------------------------------------------------------

local function GetFactionDataByID(factionID)
	factionID = tonumber(factionID)
	if not factionID then return nil end
	if C_Reputation and C_Reputation.GetFactionDataByID then
		return C_Reputation.GetFactionDataByID(factionID)
	end
	if GetFactionInfoByID then
		local name, description, standingID, barMin, barMax, barValue = GetFactionInfoByID(factionID)
		if not name then return nil end
		return {
			name = name,
			description = description,
			reaction = standingID,
			currentReactionThreshold = barMin,
			nextReactionThreshold = barMax,
			currentStanding = barValue,
			factionID = factionID,
		}
	end
	return nil
end

local function GetNumFactions()
	if C_Reputation and C_Reputation.GetNumFactions then
		return C_Reputation.GetNumFactions()
	end
	return GetNumFactions and GetNumFactions() or 0
end

local function GetFactionDataByIndex(index)
	if C_Reputation and C_Reputation.GetFactionDataByIndex then
		return C_Reputation.GetFactionDataByIndex(index)
	end
	if GetFactionInfo then
		local name, description, standingID, barMin, barMax, barValue, _, _, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID =
			GetFactionInfo(index)
		if not name then return nil end
		return {
			name = name,
			description = description,
			reaction = standingID,
			currentReactionThreshold = barMin,
			nextReactionThreshold = barMax,
			currentStanding = barValue,
			isHeader = isHeader,
			isCollapsed = isCollapsed,
			hasRep = hasRep,
			isWatched = isWatched,
			isChild = isChild,
			factionID = factionID,
		}
	end
	return nil
end

local function ExpandAllHeaders()
	local n = GetNumFactions()
	for i = n, 1, -1 do
		local data = GetFactionDataByIndex(i)
		if data and data.isHeader and data.isCollapsed then
			if ExpandFactionHeader then
				ExpandFactionHeader(i)
			elseif C_Reputation and C_Reputation.ExpandFactionHeader then
				C_Reputation.ExpandFactionHeader(i)
			end
		end
	end
end

-------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------

local function StandingLabel(reaction)
	return STANDING_NAMES[reaction] or ("Standing " .. tostring(reaction or "?"))
end

local function StandingColor(reaction, known)
	if known == false then
		local c = Data.UNKNOWN_COLOR or { 0.45, 0.45, 0.45 }
		return c[1], c[2], c[3]
	end
	local c = STANDING_COLORS[reaction]
	if not c then return 0.7, 0.7, 0.7 end
	return c[1], c[2], c[3]
end

local function Colorize(text, r, g, b)
	return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

local function PlayerFaction()
	local f = UnitFactionGroup("player")
	return f -- "Alliance" / "Horde"
end

local function IsAvailableToPlayer(side)
	if not side or side == "Neutral" then return true end
	return side == PlayerFaction()
end

local function MetaFor(factionID)
	return Data.factions[tonumber(factionID)]
end

local STAR_ON = "Interface\\AddOns\\" .. addonName .. "\\img\\star-on"
local STAR_OFF = "Interface\\AddOns\\" .. addonName .. "\\img\\star-off"

-- SavedVariables were renamed with the addon. Reuse the previous tables when they are still loaded.
local function AdoptAccountDB()
	if type(RepRewards_DB) == "table" and next(RepRewards_DB) then
		return RepRewards_DB
	end
	if type(ReputationRewards_DB) == "table" and next(ReputationRewards_DB) then
		RepRewards_DB = ReputationRewards_DB
		return RepRewards_DB
	end
	RepRewards_DB = (type(Reputations_DB) == "table" and Reputations_DB) or {}
	return RepRewards_DB
end

-- Per-character favorites + filter selection (RepRewards_CharDB).
local function EnsureCharDB()
	if type(RepRewards_CharDB) ~= "table" then
		if type(ReputationRewards_CharDB) == "table" then
			RepRewards_CharDB = ReputationRewards_CharDB
		else
			RepRewards_CharDB = {}
		end
	end
	if type(RepRewards_CharDB.favorites) ~= "table" then
		RepRewards_CharDB.favorites = {}
		-- One-time migrate from old account-wide favorites.
		local old = RepRewards_DB and RepRewards_DB.favorites
		if type(old) == "table" and next(old) then
			for k, v in pairs(old) do
				local id = tonumber(k)
				if id and v then
					RepRewards_CharDB.favorites[id] = true
				end
			end
			RepRewards_DB.favorites = nil
		end
	end
	if type(RepRewards_CharDB.filters) ~= "table" then
		RepRewards_CharDB.filters = {}
	end
	return RepRewards_CharDB
end

local function EnsureFavorites()
	return EnsureCharDB().favorites
end

local function LoadFilters()
	local saved = EnsureCharDB().filters
	for key, default in pairs(FILTER_DEFAULTS) do
		local value = saved[key]
		if value == nil then
			filters[key] = default
		else
			filters[key] = value
		end
	end
end

local function SaveFilters()
	local saved = EnsureCharDB().filters
	for key in pairs(FILTER_DEFAULTS) do
		saved[key] = filters[key]
	end
end

local function IsFavorite(factionID)
	factionID = tonumber(factionID)
	local fav = RepRewards_CharDB and RepRewards_CharDB.favorites
	if not factionID or not fav then return false end
	return (fav[factionID] or fav[tostring(factionID)]) and true or false
end

local function StyleStar(star, favored)
	if not star then return end
	local tex = star.icon or star:GetNormalTexture()
	if not tex then return end
	tex:SetTexture(favored and STAR_ON or STAR_OFF)
	tex:SetDesaturated(false)
	tex:SetVertexColor(1, 1, 1)
end

local function ToggleFavorite(factionID)
	factionID = tonumber(factionID)
	if not factionID or IsAllReputations(factionID) then return end
	local fav = EnsureFavorites()
	if IsFavorite(factionID) then
		fav[factionID] = nil
		fav[tostring(factionID)] = nil
	else
		fav[factionID] = true
	end
	if RefreshFactionList then
		RefreshFactionList(true)
	end
	if detailWidgets and detailWidgets.star then
		detailWidgets.star.factionID = selectedFactionID
		StyleStar(detailWidgets.star, IsFavorite(selectedFactionID))
		if selectedFactionID then
			detailWidgets.star:Show()
		else
			detailWidgets.star:Hide()
		end
	end
end

local function CreateStarButton(parent)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(16, 16)
	btn:RegisterForClicks("LeftButtonUp")
	local tex = btn:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetTexture(STAR_OFF)
	btn.icon = tex
	btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	btn:SetScript("OnClick", function(self)
		ToggleFavorite(self.factionID)
	end)
	StyleStar(btn, false)
	return btn
end

local function ProgressFor(factionID)
	if IsAllReputations(factionID) then
		return nil -- built via BuildAllReputationsInfo
	end

	local live = GetFactionDataByID(factionID)
	local meta = MetaFor(factionID)
	if not live and not meta then return nil end

	local name = (live and live.name) or (meta and meta.name) or ("Faction " .. factionID)
	local reaction = (live and live.reaction) or STANDING.NEUTRAL
	local barMin = (live and live.currentReactionThreshold) or 0
	local barMax = (live and live.nextReactionThreshold) or 0
	local barValue = (live and live.currentStanding) or 0
	local known = live ~= nil

	local into = 0
	local need = 0
	local pct = 0
	if reaction >= STANDING.EXALTED then
		into = 1
		need = 1
		pct = 1
	elseif barMax and barMax > barMin then
		into = math.max(0, barValue - barMin)
		need = math.max(1, barMax - barMin)
		pct = into / need
	end

	return {
		factionID = tonumber(factionID),
		name = name,
		description = (live and live.description) or (meta and meta.desc) or "",
		reaction = reaction,
		into = into,
		need = need,
		pct = pct,
		known = known,
		side = meta and meta.side or "Neutral",
		category = meta and meta.category or "Other",
		forever = meta and meta.forever,
		icon = meta and meta.icon,
		maxStanding = meta and meta.maxStanding,
		rewards = meta and meta.rewards or {},
	}
end

local function BuildAllReputationsInfo(factionList)
	local rewards = {}
	for _, info in ipairs(factionList or {}) do
		for _, reward in ipairs(info.rewards or {}) do
			local copy = {}
			for k, v in pairs(reward) do
				copy[k] = v
			end
			copy._sourceFactionID = info.factionID
			copy._sourceFactionName = info.name
			rewards[#rewards + 1] = copy
		end
	end

	return {
		factionID = ALL_REPUTATIONS_ID,
		name = "All Reputations",
		description = "Rewards from every available faction.",
		reaction = STANDING.EXALTED,
		into = 0,
		need = 0,
		pct = 0,
		known = true,
		side = "Neutral",
		category = "All",
		icon = "Interface\\Icons\\achievement_reputation_04",
		rewards = rewards,
		isAllReputations = true,
	}
end

local function CollectLiveFactions()
	ExpandAllHeaders()
	local seen = {}
	local list = {}

	local n = GetNumFactions()
	for i = 1, n do
		local data = GetFactionDataByIndex(i)
		if data and not data.isHeader and data.factionID then
			local id = tonumber(data.factionID)
			if id and not seen[id] then
				local meta = MetaFor(id)
				local side = (meta and meta.side) or "Neutral"
				-- Only show factions available to this character
				if IsAvailableToPlayer(side) then
					seen[id] = true
					local info = ProgressFor(id)
					if info then list[#list + 1] = info end
				end
			end
		end
	end

	-- Ensure catalogued factions for this character appear even if not yet discovered
	for id, meta in pairs(Data.factions) do
		if not seen[id] and IsAvailableToPlayer(meta.side) then
			local info = ProgressFor(id)
			if info then
				info.known = false
				list[#list + 1] = info
				seen[id] = true
			end
		end
	end

	table.sort(list, function(a, b)
		return a.name < b.name
	end)

	return list
end

local function StandingNameToID(name)
	if not name or name == "Any" then return nil end
	for id, label in pairs(STANDING_NAMES) do
		if label == name then return id end
	end
	return nil
end

local function RewardHasStat(reward, stat)
	if not reward or not stat or stat == "Any" then return true end
	for _, s in ipairs(reward.stats or {}) do
		if s == stat then return true end
	end
	-- Patterns/plans: also match stats on the crafted item
	for _, s in ipairs(reward.craftStats or {}) do
		if s == stat then return true end
	end
	return false
end

-- Armor type + player level (and weapon proficiency). No reputation / profession gates.
local function RewardSuitableForMe(reward)
	if not reward then return false end

	local classFile = PlayerClassFile()
	local level = PlayerLevel()
	local typ = reward.type or "Misc"
	local isRecipe = typ == "Recipe" or typ == "Enchant"

	local reqLevel = tonumber(reward.reqLevel) or 0
	if reqLevel > level then
		return false
	end

	if isRecipe then
		if reward.craftArmor and not CanWearArmor(reward.craftArmor, classFile, level) then
			return false
		end
		return true
	end

	if typ == "Armor" then
		if reward.slot == "Off Hand" then
			local cached = reward.itemID and Data.GetCachedItem(reward.itemID)
			local isShield = cached and cached.classID == 4 and cached.subclassID == 6
			if isShield and not CLASS_SHIELDS[classFile] then
				return false
			end
		end
		if reward.armor and not CanWearArmor(reward.armor, classFile, level) then
			return false
		end
	elseif typ == "Weapon" then
		local subclassID = reward.subclassID
		if subclassID == nil and reward.itemID then
			local cached = Data.GetCachedItem(reward.itemID)
			subclassID = cached and cached.subclassID
		end
		if not CanUseWeaponSubclass(subclassID, classFile) then
			return false
		end
	end

	return true
end

-- Suitable for me + reputation standing + profession skill
local function RewardAvailableNow(reward, progress)
	if not reward then return false end
	if not RewardSuitableForMe(reward) then
		return false
	end

	-- Reputation standing (source faction when viewing All Reputations)
	local standingProgress = progress
	if progress and progress.isAllReputations and reward._sourceFactionID then
		standingProgress = ProgressFor(reward._sourceFactionID)
	end
	if not standingProgress or not standingProgress.known then
		return false
	end
	if (standingProgress.reaction or 0) < (reward.standing or 0) then
		return false
	end

	local typ = reward.type or "Misc"
	if typ == "Recipe" or typ == "Enchant" then
		local prof = reward.profession
		if prof and prof ~= "" then
			local rank = GetProfessionSkill(prof)
			if not rank then
				return false
			end
			local needSkill = RewardSkillRequired(reward)
			if needSkill and rank < needSkill then
				return false
			end
		end
	end

	return true
end

local function RewardMatches(reward, progress)
	if not reward then return false end
	Data.NormalizeReward(reward)

	local nameQ = filters.name and filters.name:lower() or ""
	if nameQ ~= "" and not (reward.name or ""):lower():find(nameQ, 1, true) then
		return false
	end

	if filters.type ~= "Any" then
		local t = reward.type or "Misc"
		if filters.type == "Trinket" then
			if reward.slot ~= "Trinket" then return false end
		elseif t ~= filters.type then
			return false
		end
	end

	if filters.slot ~= "Any" then
		local slot = reward.slot or ""
		local craftSlot = reward.craftSlot or ""
		if slot ~= filters.slot and craftSlot ~= filters.slot then
			return false
		end
	end

	if filters.stat ~= "Any" and not RewardHasStat(reward, filters.stat) then
		return false
	end

	if filters.profession and filters.profession ~= "Any" then
		if (reward.profession or "") ~= filters.profession then
			return false
		end
	end

	if filters.suitableForMe and not RewardSuitableForMe(reward) then
		return false
	end

	if filters.availableNow and not RewardAvailableNow(reward, progress) then
		return false
	end

	return true
end

local function FilteredRewards(progress)
	local out = {}
	for _, reward in ipairs((progress and progress.rewards) or {}) do
		if RewardMatches(reward, progress) then
			out[#out + 1] = reward
		end
	end
	table.sort(out, function(a, b)
		if (a.standing or 0) ~= (b.standing or 0) then
			return (a.standing or 0) < (b.standing or 0)
		end
		return (a.name or "") < (b.name or "")
	end)
	return out
end

-------------------------------------------------------------------------
-- Chrome (Attune-style PortraitFrameTemplate)
-------------------------------------------------------------------------

local function HideLegacyArt(host)
	if not host then return end
	for _, region in ipairs({ host:GetRegions() }) do
		if region and region.GetObjectType and region:GetObjectType() == "Texture" then
			local draw = region.GetDrawLayer and region:GetDrawLayer()
			if draw == "BACKGROUND" or draw == "BORDER" then
				region:SetAlpha(0)
			end
		end
	end
end

local function RaisePiece(piece, level)
	if piece and piece.SetFrameLevel then
		piece:SetFrameLevel(level)
	end
end

local function SetChromeTitle(chrome, title)
	if not chrome then return end
	local fs = chrome.TitleText
	if not fs and chrome.TitleContainer then
		fs = chrome.TitleContainer.TitleText
	end
	if not fs then return end
	fs:SetText(title or "")
	fs:Show()
end

local function ApplyBronzeChrome(host)
	if not host or bronzeChrome then return end
	local ok, chrome = pcall(CreateFrame, "Frame", "RepRewardsBronzeChrome", host, "PortraitFrameTemplate")
	if not ok or type(chrome) ~= "table" then return end

	chrome:SetAllPoints(host)
	chrome:SetMovable(false)
	chrome:SetScript("OnMouseDown", nil)
	chrome:SetScript("OnDragStart", nil)
	chrome:SetFrameStrata(host:GetFrameStrata())
	chrome:SetFrameLevel(host:GetFrameLevel() + 1)
	HideLegacyArt(host)

	if frame and frame.titletext then
		local oldTitle = frame.titletext:GetParent()
		if oldTitle then oldTitle:Hide() end
	end
	if frame and frame.titlebg then
		frame.titlebg:Hide()
	end

	local top = chrome:GetFrameLevel() or 1
	for _, child in ipairs({ host:GetChildren() }) do
		if child ~= chrome and child.SetFrameLevel then
			child:SetFrameLevel(top + 10)
		end
	end
	local borderLevel = (chrome.NineSlice and chrome.NineSlice:GetFrameLevel()) or top
	RaisePiece(chrome.PortraitContainer or chrome.portrait, top + 40)
	RaisePiece(chrome.TitleContainer, borderLevel + 10)
	RaisePiece(chrome.CloseButton, borderLevel + 11)

	if chrome.TitleContainer then
		chrome.TitleContainer:EnableMouse(true)
		chrome.TitleContainer:SetScript("OnMouseDown", function() host:StartMoving() end)
		chrome.TitleContainer:SetScript("OnMouseUp", function()
			host:StopMovingOrSizing()
			if frame then
				local status = frame.status or frame.localstatus
				if status then
					status.top = host:GetTop()
					status.left = host:GetLeft()
				end
			end
		end)
	end

	if chrome.CloseButton then
		chrome.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end

	local portrait = chrome.PortraitContainer and chrome.PortraitContainer.portrait or chrome.portrait
	if portrait and portrait.SetTexture then
		portrait:SetTexture("Interface\\Icons\\achievement_reputation_04")
	end
	if portrait and portrait.EnableMouse then
		portrait:EnableMouse(false)
	end

	-- Addon name sits in the portrait title bar, above the filter strip.
	SetChromeTitle(chrome, "Rep Rewards")
	bronzeChrome = chrome

	if frame and frame.content then
		-- Leave room for the titled filter panel in the portrait header.
		frame.content:SetPoint("TOPLEFT", host, "TOPLEFT", 16, -142)
	end
end

-------------------------------------------------------------------------
-- Reward row widgets (flat list + standing accent)
-------------------------------------------------------------------------

local REWARD_ROW_HEIGHT = 48
local REWARD_ICON_SIZE = 36
local WOWHEAD_BASE = "https://wowhead.com/forever"

local function PlaceTooltipAtFrameRight()
	-- Top-left of tooltip = top-right of the main addon frame
	local anchor = _G["RepRewards_MainFrame"] or UIParent
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
end

local function SetTooltipAtFrameRight(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_NONE")
	PlaceTooltipAtFrameRight()
end

local function ShowWowheadURL(qstring)
	StaticPopupDialogs["REPREWARDS_SHOW_URL"] = {
		text = "Link to an online database",
		button1 = CLOSE or "Close",
		OnShow = function(self)
			local editBox = self.GetEditBox and self:GetEditBox() or self.editBox or self.EditBox
			if not editBox then return end
			editBox:SetText(WOWHEAD_BASE .. "/" .. qstring)
			editBox:HighlightText()
			editBox:SetFocus()
			editBox:SetScript("OnEscapePressed", function()
				StaticPopup_Hide("REPREWARDS_SHOW_URL")
			end)
		end,
		timeout = 0,
		hasEditBox = true,
		editBoxWidth = 350,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("REPREWARDS_SHOW_URL")
end

local function AcquireRewardRow(parent)
	local row = table.remove(rewardPool)
	if not row then
		row = CreateFrame("Button", nil, parent)
		row:SetHeight(REWARD_ROW_HEIGHT)
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		row.hl = row:CreateTexture(nil, "BACKGROUND")
		row.hl:SetAllPoints()
		row.hl:SetColorTexture(1, 1, 1, 0.05)
		row.hl:Hide()

		row.accent = row:CreateTexture(nil, "ARTWORK")
		row.accent:SetWidth(3)
		row.accent:SetPoint("TOPRIGHT", 0, -4)
		row.accent:SetPoint("BOTTOMRIGHT", 0, 4)

		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
		row.icon:SetPoint("LEFT", 6, 0)

		row.iconBorder = row:CreateTexture(nil, "OVERLAY")
		row.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		row.iconBorder:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -6, 6)
		row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 6, -6)
		row.iconBorder:SetVertexColor(0.55, 0.55, 0.55)

		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -2)
		row.name:SetPoint("RIGHT", row.accent, "LEFT", -8, 0)
		row.name:SetJustifyH("LEFT")
		row.name:SetWordWrap(false)

		row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.meta:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
		row.meta:SetPoint("RIGHT", row.accent, "LEFT", -8, 0)
		row.meta:SetJustifyH("LEFT")
		row.meta:SetWordWrap(false)
		row.meta:SetTextColor(0.65, 0.65, 0.65)

		row:SetScript("OnEnter", function(self)
			if self.hl then self.hl:Show() end
			if self.tooltipItemID then
				SetTooltipAtFrameRight(self)
				GameTooltip:SetItemByID(self.tooltipItemID)
				GameTooltip:Show()
				PlaceTooltipAtFrameRight()
			elseif self.tooltipName then
				SetTooltipAtFrameRight(self)
				GameTooltip:SetText(self.tooltipName, 1, 1, 1)
				if self.tooltipNote then
					GameTooltip:AddLine(self.tooltipNote, 0.8, 0.8, 0.8, true)
				end
				if self.tooltipStats and #self.tooltipStats > 0 then
					local label = self.tooltipCraft and "Crafted item stats: " or "Stats: "
					GameTooltip:AddLine(label .. table.concat(self.tooltipStats, ", "), 0.6, 0.9, 0.6)
				end
				GameTooltip:Show()
				PlaceTooltipAtFrameRight()
			end
		end)
		row:SetScript("OnLeave", function(self)
			if self.hl then self.hl:Hide() end
			GameTooltip:Hide()
		end)
		row:SetScript("OnClick", function(self, button)
			if button == "LeftButton" and IsModifiedClick() then
				local link
				if self.tooltipItemID then
					link = select(2, GetItemInfo(self.tooltipItemID))
				end
				if link then
					if HandleModifiedItemClick then
						HandleModifiedItemClick(link)
					elseif IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
						ChatEdit_InsertLink(link)
					elseif IsModifiedClick("DRESSUP") and DressUpItemLink then
						DressUpItemLink(link)
					end
				end
				return
			end
			if button ~= "RightButton" then return end
			if self.tooltipItemID then
				ShowWowheadURL("item=" .. self.tooltipItemID)
			elseif self.tooltipName and self.tooltipName ~= "" then
				ShowWowheadURL("search?q=" .. self.tooltipName:gsub(" ", "+"))
			end
		end)
	elseif row.accent then
		-- Ensure accent stays on the right for any recycled layout
		row.accent:ClearAllPoints()
		row.accent:SetPoint("TOPRIGHT", 0, -4)
		row.accent:SetPoint("BOTTOMRIGHT", 0, 4)
	end
	row:SetParent(parent)
	row:Show()
	return row
end

local function ReleaseRewardRows(container)
	if not container or not container.rows then return end
	for _, row in ipairs(container.rows) do
		row:Hide()
		row:ClearAllPoints()
		row.tooltipItemID = nil
		row.tooltipName = nil
		table.insert(rewardPool, row)
	end
	wipe(container.rows)
end

local function IconForReward(reward)
	if reward.icon then return reward.icon end
	if reward.itemID then
		Data.NormalizeReward(reward)
		if reward.icon then return reward.icon end
		local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(reward.itemID)
		if texture then return texture end
	end
	local t = reward.type or "Misc"
	if t == "Recipe" then return "Interface\\Icons\\inv_scroll_03" end
	if t == "Mount" then return "Interface\\Icons\\ability_mount_ridinghorse" end
	if t == "Pet" then return "Interface\\Icons\\inv_box_petcarrier_01" end
	if t == "Toy" then return "Interface\\Icons\\inv_misc_toy_10" end
	if t == "Tabard" then return "Interface\\Icons\\inv_shirt_guildtabard_01" end
	if t == "Consumable" then return "Interface\\Icons\\inv_misc_food_54" end
	if t == "Weapon" then return "Interface\\Icons\\inv_sword_04" end
	if t == "Enchant" then return "Interface\\Icons\\inv_misc_note_01" end
	if reward.slot == "Finger" then return "Interface\\Icons\\inv_jewelry_ring_01" end
	if reward.slot == "Trinket" then return "Interface\\Icons\\inv_jewelry_talisman_07" end
	if reward.slot == "Back" then return "Interface\\Icons\\inv_misc_cape_02" end
	if reward.armor == "Cloth" then return "Interface\\Icons\\inv_chest_cloth_17" end
	if reward.armor == "Leather" then return "Interface\\Icons\\inv_chest_leather_03" end
	if reward.armor == "Mail" then return "Interface\\Icons\\inv_chest_chain_05" end
	if reward.armor == "Plate" then return "Interface\\Icons\\inv_chest_plate04" end
	return "Interface\\Icons\\inv_misc_questionmark"
end

-------------------------------------------------------------------------
-- Detail / rewards panel
-------------------------------------------------------------------------


local function ClearDetail()
	ReleaseRewardRows(detailWidgets)
	if detailWidgets.header then detailWidgets.header:SetText("") end
	if detailWidgets.count then detailWidgets.count:SetText("") end
	if detailWidgets.star then
		detailWidgets.star.factionID = nil
		detailWidgets.star:Hide()
	end
	if detailWidgets.vendorRows then
		for _, row in ipairs(detailWidgets.vendorRows) do
			row:Hide()
		end
	end
	if detailWidgets.vendorGroup then
		detailWidgets.vendorGroup:SetHeight(1)
		if detailWidgets.vendorGroup.frame then
			detailWidgets.vendorGroup.frame:Hide()
		end
	end
end

local function FirstVendorMap(vendor)
	local ids = { vendor.map }
	if vendor.altMaps then
		for _, id in ipairs(vendor.altMaps) do
			ids[#ids + 1] = id
		end
	end
	if C_Map and C_Map.GetMapInfo then
		for _, id in ipairs(ids) do
			if id and C_Map.GetMapInfo(id) then
				return id
			end
		end
	end
	return vendor.map
end

local function SetVendorWaypoint(vendor)
	if not vendor then return end
	local mapID = FirstVendorMap(vendor)
	local x = tonumber(vendor.x)
	local y = tonumber(vendor.y)
	if not (mapID and x and y) then
		-- print(string.format("%s — %s", vendor.name or "Quartermaster", vendor.place or ""))
		return
	end

	local nx, ny = x / 100, y / 100
	local placed = false

	if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
		local ok = pcall(function()
			C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, nx, ny))
			if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
				C_SuperTrack.SetSuperTrackedUserWaypoint(true)
			end
		end)
		placed = ok
	end

	local tomtom = TomTom
	if tomtom and tomtom.AddWaypoint then
		local ok = pcall(function()
			tomtom:AddWaypoint(mapID, nx, ny, {
				title = vendor.name,
				persistent = false,
				minimap = true,
				world = true,
			})
		end)
		placed = placed or ok
	end

	local mapKnown = not (C_Map and C_Map.GetMapInfo) or C_Map.GetMapInfo(mapID)
	if mapKnown and WorldMapFrame and WorldMapFrame.SetMapID then
		pcall(function()
			ShowUIPanel(WorldMapFrame)
			WorldMapFrame:SetMapID(mapID)
		end)
	elseif mapKnown and C_Map and C_Map.OpenWorldMap then
		pcall(function()
			C_Map.OpenWorldMap(mapID)
		end)
	end

	-- if placed then
	-- 	print(string.format("Map marker: %s — %s (%.1f, %.1f)", vendor.name, vendor.place or "", x, y))
	-- else
	-- 	print(string.format("%s — %s (%.1f, %.1f)", vendor.name, vendor.place or "", x, y))
	-- end
end

local function CreateVendorRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(18)
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.label:SetPoint("LEFT", 4, 0)
	row.label:SetPoint("RIGHT", -4, 0)
	row.label:SetJustifyH("LEFT")
	row.label:SetWordWrap(false)
	row:SetScript("OnClick", function(self)
		SetVendorWaypoint(self.vendor)
	end)
	row:SetScript("OnEnter", function(self)
		if not self.vendor then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.vendor.name or "", 1, 0.82, 0)
		if self.vendor.place then
			GameTooltip:AddLine(self.vendor.place, 0.85, 0.85, 0.85, true)
		end
		if self.vendor.x then
			GameTooltip:AddLine("Click to set a map marker.", 0.4, 1, 0.4)
		end
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	return row
end

local function ShowVendors(factionID)
	local group = detailWidgets.vendorGroup
	if not group or not group.frame then return end
	local vendors = (Data.VendorsFor and Data.VendorsFor(factionID)) or {}
	detailWidgets.vendorRows = detailWidgets.vendorRows or {}
	local parent = group.frame

	if #vendors == 0 then
		for _, row in ipairs(detailWidgets.vendorRows) do
			row:Hide()
		end
		group:SetHeight(1)
		parent:Hide()
		if rightPanel and rightPanel.DoLayout then
			rightPanel:DoLayout()
		end
		return
	end

	parent:Show()
	for i, vendor in ipairs(vendors) do
		local row = detailWidgets.vendorRows[i]
		if not row then
			row = CreateVendorRow(parent)
			detailWidgets.vendorRows[i] = row
		end
		row.vendor = vendor
		local place = vendor.place or ""
		if vendor.x then
			row.label:SetText(string.format("|cffffd100%s|r  |cffcccccc%s|r", vendor.name, place))
		else
			row.label:SetText(string.format("|cffffd100%s|r  |cff888888%s|r", vendor.name, place))
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -((i - 1) * 18))
		row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -((i - 1) * 18))
		row:Show()
	end
	for i = #vendors + 1, #detailWidgets.vendorRows do
		detailWidgets.vendorRows[i]:Hide()
	end
	group:SetHeight((#vendors * 18) + 4)
	if rightPanel and rightPanel.DoLayout then
		rightPanel:DoLayout()
	end
end

local function ShowFactionDetail(factionID)
	selectedFactionID = tonumber(factionID)
	local progress
	if IsAllReputations(selectedFactionID) then
		progress = BuildAllReputationsInfo(CollectLiveFactions())
	else
		progress = ProgressFor(selectedFactionID)
	end
	if not progress then
		ClearDetail()
		return
	end

	if detailWidgets.header then
		detailWidgets.header:SetText(progress.name or "")
	end
	if progress.isAllReputations then
		ShowVendors(nil)
	else
		ShowVendors(selectedFactionID)
	end
	if detailWidgets.star then
		if progress.isAllReputations then
			detailWidgets.star.factionID = nil
			detailWidgets.star:Hide()
		else
			detailWidgets.star.factionID = selectedFactionID
			StyleStar(detailWidgets.star, IsFavorite(selectedFactionID))
			detailWidgets.star:Show()
		end
	end

	ReleaseRewardRows(detailWidgets)
	detailWidgets.rows = detailWidgets.rows or {}

	local rewards = FilteredRewards(progress)
	detailWidgets.count:SetText(string.format("%d reward%s", #rewards, #rewards == 1 and "" or "s"))

	local parent = detailWidgets.rewardParent
	local parentWidget = detailWidgets.rewardParentWidget
	local y = -2
	local sourceProgressCache = {}
	for _, reward in ipairs(rewards) do
		Data.NormalizeReward(reward)
		local row = AcquireRewardRow(parent)
		row:SetPoint("TOPLEFT", 2, y)
		row:SetPoint("TOPRIGHT", -2, y)

		local unlocked
		if progress.isAllReputations and reward._sourceFactionID then
			local src = sourceProgressCache[reward._sourceFactionID]
			if src == nil then
				src = ProgressFor(reward._sourceFactionID)
				sourceProgressCache[reward._sourceFactionID] = src or false
			end
			unlocked = src and src.known and (src.reaction or 0) >= (reward.standing or 0)
		else
			unlocked = progress.known and (progress.reaction or 0) >= (reward.standing or 0)
		end
		local sr, sg, sb = StandingColor(reward.standing)
		if row.accent then
			row.accent:SetColorTexture(sr, sg, sb, 1)
		end

		row.icon:SetTexture(IconForReward(reward))
		if unlocked then
			row.name:SetText(Colorize(reward.name, 0.85, 0.85, 0.85))
		else
			row.name:SetText(reward.name or "")
			row.name:SetTextColor(0.95, 0.95, 0.95)
		end

		local bits = {}
		bits[#bits + 1] = Colorize(StandingLabel(reward.standing), sr, sg, sb)
		if reward._sourceFactionName then bits[#bits + 1] = reward._sourceFactionName end
		if reward.type then bits[#bits + 1] = reward.type end
		if reward.slot then bits[#bits + 1] = reward.slot end
		if reward.armor then bits[#bits + 1] = reward.armor end
		if reward.ilvl then bits[#bits + 1] = "iLvl " .. reward.ilvl end
		if reward.note then bits[#bits + 1] = reward.note end
		row.meta:SetText(table.concat(bits, "  ·  "))

		local displayStats = reward.stats
		if (not displayStats or #displayStats == 0) and reward.craftStats and #reward.craftStats > 0 then
			displayStats = reward.craftStats
		elseif reward.craftStats and #reward.craftStats > 0 then
			if reward.type == "Recipe" or reward.type == "Enchant" then
				displayStats = reward.craftStats
			end
		end

		row.tooltipItemID = reward.itemID
		row.tooltipName = reward.name
		row.tooltipNote = reward.note
		row.tooltipStats = displayStats
		row.tooltipCraft = (reward.type == "Recipe" or reward.type == "Enchant") and reward.craftStats and #reward.craftStats > 0

		detailWidgets.rows[#detailWidgets.rows + 1] = row
		y = y - REWARD_ROW_HEIGHT
	end

	local contentHeight = math.max(40, (#rewards * REWARD_ROW_HEIGHT) + 8)
	if parentWidget then
		parentWidget:SetHeight(contentHeight)
	elseif parent then
		parent:SetHeight(contentHeight)
	end
	if rewardScroll then
		rewardScroll:DoLayout()
	end
end

-------------------------------------------------------------------------
-- Faction list (Attune-style colored cells)
-------------------------------------------------------------------------

local PaneBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local BAR_HEIGHT = 6
local CIRCLE_TEX = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

local function ColorPill(pill, r, g, b, a)
	a = a or 1
	pill.left:SetVertexColor(r, g, b, a)
	pill.right:SetVertexColor(r, g, b, a)
	pill.mid:SetVertexColor(r, g, b, a)
end

local function CreatePillLayer(parent, height, drawLayer)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(height)

	f.left = f:CreateTexture(nil, drawLayer)
	f.left:SetTexture(CIRCLE_TEX)
	f.left:SetSize(height, height)
	f.left:SetPoint("LEFT")

	f.right = f:CreateTexture(nil, drawLayer)
	f.right:SetTexture(CIRCLE_TEX)
	f.right:SetSize(height, height)
	f.right:SetPoint("RIGHT")

	f.mid = f:CreateTexture(nil, drawLayer)
	f.mid:SetTexture("Interface\\Buttons\\WHITE8X8")
	f.mid:SetPoint("TOPLEFT", f.left, "TOP", 0, 0)
	f.mid:SetPoint("BOTTOMRIGHT", f.right, "BOTTOM", 0, 0)

	return f
end

-- Pill-shaped progress bar: dark track + colored fill whose width follows progress
local function CreateRoundedBar(parent, height)
	height = height or BAR_HEIGHT
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(height)
	holder._barHeight = height

	local track = CreatePillLayer(holder, height, "BACKGROUND")
	track:SetAllPoints(holder)
	ColorPill(track, 0.04, 0.04, 0.04, 1)
	holder.track = track

	-- Fill grows from the left; right cap rides the progress edge (no clipping)
	local fill = CreatePillLayer(holder, height, "ARTWORK")
	fill:SetPoint("TOPLEFT", holder, "TOPLEFT")
	fill:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
	fill:SetWidth(height)
	holder.fill = fill

	holder._min, holder._max, holder._value = 0, 1, 0

	local function SyncLevels(self)
		local base = self:GetFrameLevel() or 1
		self.track:SetFrameLevel(base + 1)
		self.fill:SetFrameLevel(base + 2)
	end

	function holder:SetMinMaxValues(minV, maxV)
		self._min = minV or 0
		self._max = maxV or 1
		self:SetValue(self._value)
	end

	function holder:SetValue(v)
		self._value = v or 0
		local span = (self._max or 1) - (self._min or 0)
		local pct = span > 0 and ((self._value - (self._min or 0)) / span) or 0
		if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
		local fullW = self:GetWidth() or 0
		local w = fullW * pct
		if w <= 0.5 then
			self.fill:Hide()
		else
			self.fill:Show()
			-- Grow from the left; keep at least a round cap wide so color stays visible
			self.fill:SetWidth(math.max(w, self._barHeight))
		end
		SyncLevels(self)
	end

	function holder:SetStatusBarColor(r, g, b, a)
		ColorPill(self.fill, r, g, b, a)
	end

	holder:SetScript("OnSizeChanged", function(self)
		self:SetValue(self._value)
	end)
	holder:HookScript("OnShow", SyncLevels)

	return holder
end

local function FactionPassesFilters(info)
	local nameQ = (filters.name or ""):lower()
	local factionNameOk = nameQ == "" or info.name:lower():find(nameQ, 1, true)
	local hasMatchingReward = false
	if not factionNameOk then
		for _, reward in ipairs(info.rewards or {}) do
			if RewardMatches(reward, info) then
				hasMatchingReward = true
				break
			end
		end
	end

	local rewardFiltersActive = (filters.type ~= "Any") or (filters.slot ~= "Any")
		or (filters.stat ~= "Any") or (filters.profession ~= "Any")
		or filters.suitableForMe
		or filters.availableNow

	if rewardFiltersActive then
		for _, reward in ipairs(info.rewards or {}) do
			if RewardMatches(reward, info) then
				return true
			end
		end
		return false
	end

	if nameQ ~= "" and not factionNameOk then
		return hasMatchingReward
	end
	return true
end

local function BuildFactionEntries()
	local factions = CollectLiveFactions()
	local showEmpty = RepRewards:ShowEmptyReputations()
	local filtered = {}
	for _, info in ipairs(factions) do
		local hasRewards = type(info.rewards) == "table" and #info.rewards > 0
		if (showEmpty or hasRewards) and FactionPassesFilters(info) then
			filtered[#filtered + 1] = info
		end
	end

	local entries = {}
	if RepRewards:ShowAllReputationsEntry() then
		entries[#entries + 1] = { kind = "faction", info = BuildAllReputationsInfo(factions) }
	end

	local function byName(a, b) return a.name < b.name end

	local favorites, known, unknown = {}, {}, {}
	for _, info in ipairs(filtered) do
		if IsFavorite(info.factionID) then
			favorites[#favorites + 1] = info
		elseif info.known then
			known[#known + 1] = info
		else
			unknown[#unknown + 1] = info
		end
	end
	table.sort(favorites, byName)
	table.sort(known, byName)
	table.sort(unknown, byName)

	local function appendSection(title, list)
		if #list == 0 then return end
		entries[#entries + 1] = { kind = "header", text = title }
		for _, info in ipairs(list) do
			entries[#entries + 1] = { kind = "faction", info = info }
		end
	end

	appendSection("Favourites", favorites)
	appendSection("Encountered Reputations", known)
	appendSection("Not Encountered Reputations", unknown)

	return entries
end

local function ReleaseFactionCells()
	for _, cell in ipairs(activeFactionCells) do
		cell:Hide()
		cell:ClearAllPoints()
		cell:SetParent(nil)
		if not cell.isHeader then
			cell.factionID = nil
			cell.reaction = nil
			cell.known = nil
		end
		if cell.isHeader then
			factionHeaderPool[#factionHeaderPool + 1] = cell
		else
			factionCellPool[#factionCellPool + 1] = cell
		end
	end
	wipe(activeFactionCells)
end

local function AcquireHeaderCell(parent)
	local cell = table.remove(factionHeaderPool)
	if not cell then
		cell = CreateFrame("Frame", nil, parent)
		cell.isHeader = true
		cell:SetHeight(18)
		cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		cell.text:SetPoint("LEFT", 4, 0)
		cell.text:SetPoint("RIGHT", -4, 0)
		cell.text:SetJustifyH("LEFT")
		cell.text:SetTextColor(0.72, 0.72, 0.72)
	end
	if cell.SetBackdrop then
		cell:SetBackdrop(nil)
	end
	cell:SetParent(parent)
	cell:Show()
	return cell
end

local function ApplyCellTone(cell, r, g, b, selected, known)
	-- Dark card; color lives on the progress bar (and standing text)
	if selected then
		cell:SetBackdropColor(0.14, 0.14, 0.16, 0.95)
		cell:SetBackdropBorderColor(0.85, 0.75, 0.35, 1)
	else
		cell:SetBackdropColor(0.08, 0.08, 0.09, 0.92)
		cell:SetBackdropBorderColor(0.32, 0.32, 0.35, 0.95)
	end

	if cell.indicator then
		cell.indicator:Hide()
	end

	if cell.bar then
		if known then
			-- Progress fill is 20% darker than standing text color
			cell.bar:SetStatusBarColor(r * 0.8, g * 0.8, b * 0.8, 1)
			cell.bar:Show()
		else
			cell.bar:Hide()
		end
	end
end

local function AcquireFactionCell(parent)
	local cell = table.remove(factionCellPool)
	if not cell then
		cell = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
		cell.isHeader = false
		cell:SetHeight(CELL_HEIGHT)
		cell:SetBackdrop(PaneBackdrop)
		cell:RegisterForClicks("LeftButtonUp")

		cell.icon = cell:CreateTexture(nil, "ARTWORK")
		cell.icon:SetSize(36, 36)
		cell.icon:SetPoint("LEFT", 8, 0)
		cell.iconBorder = cell:CreateTexture(nil, "OVERLAY")
		cell.iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		cell.iconBorder:SetPoint("TOPLEFT", cell.icon, "TOPLEFT", -6, 6)
		cell.iconBorder:SetPoint("BOTTOMRIGHT", cell.icon, "BOTTOMRIGHT", 6, -6)
		cell.iconBorder:SetVertexColor(0.55, 0.55, 0.55)

		cell.title = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		cell.title:SetPoint("TOPLEFT", cell.icon, "TOPRIGHT", 8, 0)
		cell.title:SetJustifyH("LEFT")
		cell.title:SetWordWrap(false)
		cell.title:SetTextColor(1, 1, 1)

		cell.star = CreateStarButton(cell)
		cell.star:SetPoint("TOPRIGHT", -8, -6)
		cell.star:SetFrameLevel((cell:GetFrameLevel() or 1) + 4)
		cell.title:SetPoint("RIGHT", cell.star, "LEFT", -4, 0)

		cell.standing = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cell.standing:SetPoint("TOPLEFT", cell.title, "BOTTOMLEFT", 0, -4)
		cell.standing:SetJustifyH("LEFT")
		cell.standing:SetWordWrap(false)

		cell.rewardCount = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cell.rewardCount:SetPoint("TOP", cell.standing, "TOP", 0, 0)
		cell.rewardCount:SetPoint("RIGHT", -10, 0)
		cell.rewardCount:SetJustifyH("RIGHT")
		cell.rewardCount:SetWordWrap(false)
		cell.rewardCount:SetTextColor(0.70, 0.70, 0.70)

		cell.progress = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cell.progress:SetPoint("LEFT", cell.standing, "RIGHT", 6, 0)
		cell.progress:SetPoint("RIGHT", cell.rewardCount, "LEFT", -8, 0)
		cell.progress:SetJustifyH("LEFT")
		cell.progress:SetWordWrap(false)
		cell.progress:SetTextColor(0.70, 0.70, 0.70)

		cell.bar = CreateRoundedBar(cell, BAR_HEIGHT)
		cell.bar:SetPoint("BOTTOMLEFT", cell.icon, "BOTTOMRIGHT", 8, 0)
		cell.bar:SetPoint("BOTTOMRIGHT", -10, 6)
		cell.bar:SetFrameLevel((cell:GetFrameLevel() or 1) + 2)

		cell:SetScript("OnEnter", function(self)
			if self.factionID == selectedFactionID then return end
			local r, g, b = StandingColor(self.reaction, self.known)
			ApplyCellTone(self, r, g, b, true, self.known)
		end)
		cell:SetScript("OnLeave", function(self)
			local r, g, b = StandingColor(self.reaction, self.known)
			ApplyCellTone(self, r, g, b, self.factionID == selectedFactionID, self.known)
		end)
		cell:SetScript("OnClick", function(self)
			local id = self.factionID
			if not id then return end
			selectedFactionID = id
			ShowFactionDetail(id)
			RefreshFactionList(true)
		end)
	end
	cell:SetParent(parent)
	cell:Show()
	return cell
end

local function PopulateFactionCell(cell, info, selected)
	local r, g, b = StandingColor(info.reaction, info.known)
	ApplyCellTone(cell, r, g, b, selected, info.known)

	cell.icon:SetTexture(info.icon or "Interface\\Icons\\inv_misc_questionmark")
	cell.title:SetText(info.name)

	local listed = #FilteredRewards(info)
	if cell.rewardCount then
		cell.rewardCount:SetText(listed > 0 and tostring(listed) or "")
		cell.rewardCount:SetTextColor(0.70, 0.70, 0.70)
	end

	if info.isAllReputations then
		if cell.star then
			cell.star.factionID = nil
			cell.star:Hide()
		end
		cell.title:SetTextColor(1, 0.95, 0.75)
		cell.standing:SetText("All factions")
		cell.standing:SetTextColor(0.82, 0.74, 0.48)
		cell.progress:SetText("")
		cell.bar:SetValue(0)
		return
	end

	if cell.star then
		cell.star:Show()
		cell.star.factionID = info.factionID
		StyleStar(cell.star, IsFavorite(info.factionID))
	end

	if info.known then
		cell.title:SetTextColor(1, 1, 1)
		cell.standing:SetText(StandingLabel(info.reaction))
		cell.standing:SetTextColor(r, g, b)
		if info.reaction >= STANDING.EXALTED then
			cell.progress:SetText("")
			cell.bar:SetValue(1)
		else
			cell.progress:SetText(string.format("%d / %d", info.into or 0, info.need or 0))
			cell.bar:SetValue(info.pct or 0)
		end
		cell.progress:SetTextColor(0.70, 0.70, 0.70)
	else
		cell.title:SetTextColor(0.65, 0.65, 0.65)
		cell.standing:SetText("Not encountered")
		cell.standing:SetTextColor(0.50, 0.50, 0.50)
		cell.progress:SetText("")
		cell.bar:SetValue(0)
	end
end

RefreshFactionList = function(keepSelection)
	if not factionContent then return end
	ReleaseFactionCells()

	local entries = BuildFactionEntries()
	local y = -2
	local width = math.max(100, (factionContent:GetWidth() or LEFT_WIDTH) - 4)
	local HEADER_TOP_GAP = 14
	local sawHeader = false

	for _, entry in ipairs(entries) do
		if entry.kind == "header" then
			if sawHeader and not entry.spacer then
				y = y - HEADER_TOP_GAP
			end
			sawHeader = true
			local cell = AcquireHeaderCell(factionContent)
			cell:SetPoint("TOPLEFT", 2, y)
			cell:SetWidth(width)
			cell.text:SetText(entry.text or "")
			if entry.spacer then
				cell.text:SetTextColor(0.72, 0.72, 0.72)
			else
				cell.text:SetTextColor(0.82, 0.74, 0.48)
			end
			local headerH = entry.spacer and 8 or 18
			cell:SetHeight(headerH)
			activeFactionCells[#activeFactionCells + 1] = cell
			y = y - headerH - CELL_GAP
		else
			local info = entry.info
			local cell = AcquireFactionCell(factionContent)
			cell:SetPoint("TOPLEFT", 2, y)
			cell:SetWidth(width)
			cell.factionID = info.factionID
			cell.reaction = info.reaction
			cell.known = info.known

			PopulateFactionCell(cell, info, info.factionID == selectedFactionID)

			activeFactionCells[#activeFactionCells + 1] = cell
			y = y - CELL_HEIGHT - CELL_GAP
		end
	end

	factionContent:SetHeight(math.max(40, -y + 4))

	-- Pick a default selection if needed
	local stillValid = false
	if selectedFactionID then
		for _, entry in ipairs(entries) do
			if entry.kind == "faction" and entry.info.factionID == selectedFactionID then
				stillValid = true
				break
			end
		end
	end
	if not stillValid then
		selectedFactionID = nil
		for _, entry in ipairs(entries) do
			if entry.kind == "faction" then
				selectedFactionID = entry.info.factionID
				break
			end
		end
		if selectedFactionID then
			for _, cell in ipairs(activeFactionCells) do
				if not cell.isHeader and cell.factionID == selectedFactionID then
					-- selection already applied during populate; re-apply for safety
					local r, g, b = StandingColor(cell.reaction, cell.known)
					ApplyCellTone(cell, r, g, b, true, cell.known)
				end
			end
			if not keepSelection then
				ShowFactionDetail(selectedFactionID)
			end
		else
			ClearDetail()
		end
	end
end

-- Back-compat name used elsewhere
local function RefreshTree(keepSelection)
	RefreshFactionList(keepSelection)
	if keepSelection and selectedFactionID then
		ShowFactionDetail(selectedFactionID)
	end
end

local function LayoutSplit()
	if not splitFrame or not factionScroll or not rightPanel then return end
	local w = splitFrame:GetWidth() or 800
	local h = splitFrame:GetHeight() or 400
	factionScroll:ClearAllPoints()
	factionScroll:SetPoint("TOPLEFT", splitFrame, "TOPLEFT", 0, 0)
	factionScroll:SetPoint("BOTTOMLEFT", splitFrame, "BOTTOMLEFT", 0, 0)
	factionScroll:SetWidth(LEFT_WIDTH)

	rightPanel.frame:ClearAllPoints()
	rightPanel.frame:SetParent(splitFrame)
	rightPanel.frame:SetPoint("TOPLEFT", factionScroll, "TOPRIGHT", 8, 0)
	rightPanel.frame:SetPoint("BOTTOMRIGHT", splitFrame, "BOTTOMRIGHT", 0, 0)
	rightPanel.frame:Show()
	rightPanel:SetWidth(math.max(100, w - LEFT_WIDTH - 8))
	rightPanel:SetHeight(h)
	rightPanel:DoLayout()

	if factionContent then
		factionContent:SetWidth(LEFT_WIDTH - 20)
		RefreshFactionList(true)
	end
end

-------------------------------------------------------------------------
-- Filters UI
-------------------------------------------------------------------------

local function RefreshFromFilters()
	RefreshTree(true)
	if selectedFactionID then
		ShowFactionDetail(selectedFactionID)
	end
end

-- compact: single control (no label row) for the title-bar filter strip
local function AddDropdown(parent, label, list, key, width, compact)
	local group = AceGUI:Create("SimpleGroup")
	group:SetLayout("List")
	group:SetFullWidth(false)
	group:SetWidth(width or 130)
	group:SetAutoAdjustHeight(true)

	if not compact then
		local lbl = AceGUI:Create("Label")
		lbl:SetText(label)
		lbl:SetFullWidth(true)
		group:AddChild(lbl)
	end

	local dd = AceGUI:Create("Dropdown")
	local values, order = {}, {}
	for _, v in ipairs(list) do
		values[v] = v
		order[#order + 1] = v
	end
	dd:SetList(values, order)
	dd:SetValue(filters[key])
	dd:SetFullWidth(true)
	if compact and label and label ~= "" then
		dd:SetCallback("OnEnter", function(widget)
			GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
			GameTooltip:SetText(label)
			GameTooltip:Show()
		end)
		dd:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	dd:SetCallback("OnValueChanged", function(_, _, val)
		filters[key] = val
		SaveFilters()
		RefreshFromFilters()
	end)
	group:AddChild(dd)
	filterWidgets[key] = dd
	parent:AddChild(group)
	return dd
end

local function AddLabeledEditBox(parent, label, width, onEnter, compact)
	local group = AceGUI:Create("SimpleGroup")
	group:SetLayout("List")
	group:SetFullWidth(false)
	group:SetWidth(width or 80)
	group:SetAutoAdjustHeight(true)

	if not compact then
		local lbl = AceGUI:Create("Label")
		lbl:SetText(label)
		lbl:SetFullWidth(true)
		group:AddChild(lbl)
	end

	local box = AceGUI:Create("EditBox")
	box:SetLabel(compact and (label or "") or "")
	box:DisableButton(true)
	box:SetFullWidth(true)
	box:SetCallback("OnEnterPressed", function(widget)
		if onEnter then onEnter(widget) end
	end)
	group:AddChild(box)
	parent:AddChild(group)
	return box
end

-------------------------------------------------------------------------
-- Main frame
-------------------------------------------------------------------------

local function CreateMainFrame()
	if frame then return frame end

	AdoptAccountDB()
	RepRewards_DB.width = RepRewards_DB.width or 800
	RepRewards_DB.height = RepRewards_DB.height or 600
	RepRewards_DB.minimap = RepRewards_DB.minimap or { hide = false }
	EnsureCharDB()
	LoadFilters()

	frame = AceGUI:Create("Frame")
	frame:SetTitle("Rep Rewards")
	frame:SetStatusText(statusText)
	frame:SetWidth(RepRewards_DB.width)
	frame:SetHeight(RepRewards_DB.height)
	frame:SetAutoAdjustHeight(false)
	frame.frame:SetFrameStrata("HIGH")
	if frame.frame.SetResizeBounds then
		frame.frame:SetResizeBounds(820, 480)
	else
		frame.frame:SetMinResize(820, 480)
	end
	frame.frame:SetScript("OnSizeChanged", function(self)
		local hh, ww = self:GetHeight(), self:GetWidth()
		local parent = self:GetParent()
		if parent then
			if hh > parent:GetHeight() - 50 then hh = parent:GetHeight() - 50; self:SetHeight(hh) end
			if ww > parent:GetWidth() - 50 then ww = parent:GetWidth() - 50; self:SetWidth(ww) end
		end
		RepRewards_DB.height = hh
		RepRewards_DB.width = ww
		if frame then
			frame:DoLayout()
		end
	end)

	frame:SetCallback("OnClose", function(widget)
		-- keep frame for reuse
	end)

	_G["RepRewards_MainFrame"] = frame.frame
	tinsert(UISpecialFrames, "RepRewards_MainFrame")

	-- Body fills the frame; filters live in the portrait title bar (see below).
	frame:SetLayout("Fill")

	local body = AceGUI:Create("SimpleGroup")
	body:SetFullWidth(true)
	body:SetFullHeight(true)
	body:SetLayout("Fill")
	body:SetAutoAdjustHeight(false)
	frame:AddChild(body)

	-- Custom left list + right detail split
	splitFrame = CreateFrame("Frame", "RepRewardsSplit", body.frame)
	splitFrame:SetAllPoints(body.frame)

	factionScroll = CreateFrame("ScrollFrame", "RepRewardsFactionScroll", splitFrame, "UIPanelScrollFrameTemplate")
	factionScroll:SetWidth(LEFT_WIDTH)
	factionContent = CreateFrame("Frame", "RepRewardsFactionContent", factionScroll)
	factionContent:SetWidth(LEFT_WIDTH - 20)
	factionContent:SetHeight(100)
	factionScroll:SetScrollChild(factionContent)

	local scrollBar = _G["RepRewardsFactionScrollScrollBar"]
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", factionScroll, "TOPRIGHT", -18, -16)
		scrollBar:SetPoint("BOTTOMLEFT", factionScroll, "BOTTOMRIGHT", -18, 16)
	end

	-- Right content: title row (title left, count right) + scrolling list
	rightPanel = AceGUI:Create("SimpleGroup")
	rightPanel:SetLayout("Flow")
	rightPanel:SetAutoAdjustHeight(false)

	local titleBar = AceGUI:Create("SimpleGroup")
	titleBar:SetFullWidth(true)
	titleBar:SetHeight(40)
	titleBar:SetLayout(nil)
	rightPanel:AddChild(titleBar)

	local headerStar = CreateStarButton(titleBar.frame)
	headerStar:SetPoint("TOPLEFT", 6, -14)
	headerStar:SetFrameLevel((titleBar.frame:GetFrameLevel() or 1) + 4)
	headerStar:Hide()
	detailWidgets.star = headerStar

	local headerFS = titleBar.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	headerFS:SetPoint("LEFT", headerStar, "RIGHT", 6, 1)
	headerFS:SetPoint("RIGHT", titleBar.frame, "RIGHT", -120, 0)
	headerFS:SetJustifyH("LEFT")
	headerFS:SetWordWrap(false)
	headerFS:SetTextColor(1, 1, 1)
	headerFS:SetText("")
	detailWidgets.header = headerFS

	local countFS = titleBar.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	countFS:SetPoint("TOPRIGHT", -10, -16)
	countFS:SetJustifyH("RIGHT")
	countFS:SetText("")
	detailWidgets.count = countFS

	local vendorGroup = AceGUI:Create("SimpleGroup")
	vendorGroup:SetFullWidth(true)
	vendorGroup:SetHeight(1)
	vendorGroup:SetLayout(nil)
	vendorGroup:SetAutoAdjustHeight(false)
	rightPanel:AddChild(vendorGroup)
	vendorGroup.frame:Hide()
	detailWidgets.vendorGroup = vendorGroup
	detailWidgets.vendorRows = {}

	rewardScroll = AceGUI:Create("ScrollFrame")
	rewardScroll:SetFullWidth(true)
	rewardScroll:SetFullHeight(true)
	rewardScroll:SetLayout("List")
	rewardScroll:SetAutoAdjustHeight(false)
	rightPanel:AddChild(rewardScroll)

	local rewardParent = AceGUI:Create("SimpleGroup")
	rewardParent:SetFullWidth(true)
	rewardParent:SetLayout(nil)
	rewardParent:SetHeight(40)
	rewardScroll:AddChild(rewardParent)
	detailWidgets.rewardParentWidget = rewardParent
	detailWidgets.rewardParent = rewardParent.frame
	detailWidgets.rows = {}

	splitFrame:SetScript("OnSizeChanged", function()
		LayoutSplit()
	end)

	ApplyBronzeChrome(frame.frame)

	-- Compact filter panel in the portrait header (between icon and close).
	local host = frame.frame
	local filterStrip = AceGUI:Create("InlineGroup")
	filterStrip:SetTitle("Filters")
	filterStrip:SetLayout("List")
	filterStrip.frame:SetParent(host)
	filterStrip.frame:ClearAllPoints()
	filterStrip.frame:SetPoint("TOPLEFT", host, "TOPLEFT", 58, -30)
	filterStrip.frame:SetPoint("TOPRIGHT", host, "TOPRIGHT", -36, -30)
	filterStrip.frame:SetFrameStrata(host:GetFrameStrata())
	filterStrip.frame:SetFrameLevel((bronzeChrome and bronzeChrome:GetFrameLevel() or host:GetFrameLevel()) + 50)
	local function LayoutFilterStrip()
		local w = (host:GetWidth() or 800) - 94
		if w < 200 then w = 200 end
		filterStrip:SetWidth(w)
		filterStrip:DoLayout()
	end
	host:HookScript("OnSizeChanged", LayoutFilterStrip)

	local function AddFilterGap(parent, width)
		local gap = AceGUI:Create("Label")
		gap:SetText("")
		gap:SetWidth(width or 10)
		gap:SetHeight(1)
		parent:AddChild(gap)
	end

	local filterRow1 = AceGUI:Create("SimpleGroup")
	filterRow1:SetFullWidth(true)
	filterRow1:SetLayout("Flow")
	filterStrip:AddChild(filterRow1)

	local nameBox = AddLabeledEditBox(filterRow1, "", 160, function(widget)
		filters.name = widget:GetText() or ""
		SaveFilters()
		RefreshFromFilters()
	end, true)
	nameBox:SetText(filters.name or "")
	nameBox:SetCallback("OnTextChanged", function(_, _, text)
		filters.name = text or ""
		SaveFilters()
		RefreshFromFilters()
	end)
	nameBox:SetCallback("OnEnter", function(widget)
		GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
		GameTooltip:SetText("Name")
		GameTooltip:Show()
	end)
	nameBox:SetCallback("OnLeave", function()
		GameTooltip:Hide()
	end)
	filterWidgets.name = nameBox

	local function AddFilterCheckbox(parent, label, key, width)
		local check = AceGUI:Create("CheckBox")
		check:SetLabel(label)
		check:SetValue(filters[key] and true or false)
		check:SetWidth(width or 150)
		check:SetCallback("OnValueChanged", function(_, _, checked)
			filters[key] = checked and true or false
			SaveFilters()
			RefreshFromFilters()
		end)
		parent:AddChild(check)
		filterWidgets[key] = check
		return check
	end

	local className = UnitClass("player") or PlayerClassFile() or "Class"
	local suitableLabel = string.format("Suitable for me (%s, %d)", className, PlayerLevel())
	AddFilterGap(filterRow1, 10)
	AddFilterCheckbox(filterRow1, suitableLabel, "suitableForMe", 200)
	AddFilterGap(filterRow1, 6)
	AddFilterCheckbox(filterRow1, "Available to me now", "availableNow", 150)

	local filterRow2 = AceGUI:Create("SimpleGroup")
	filterRow2:SetFullWidth(true)
	filterRow2:SetLayout("Flow")
	filterStrip:AddChild(filterRow2)

	AddDropdown(filterRow2, "Type", Data.FILTER_TYPES, "type", 95, true)
	AddFilterGap(filterRow2, 8)
	AddDropdown(filterRow2, "Slot", Data.FILTER_SLOTS, "slot", 95, true)
	AddFilterGap(filterRow2, 8)
	AddDropdown(filterRow2, "Stat", Data.FILTER_STATS, "stat", 105, true)
	AddFilterGap(filterRow2, 8)
	AddDropdown(filterRow2, "Profession", Data.FILTER_PROFESSIONS, "profession", 125, true)
	AddFilterGap(filterRow2, 8)

	local clearBtn = AceGUI:Create("Button")
	clearBtn:SetText("Clear")
	clearBtn:SetWidth(70)
	clearBtn:SetCallback("OnClick", function()
		for key, default in pairs(FILTER_DEFAULTS) do
			filters[key] = default
		end
		nameBox:SetText("")
		if filterWidgets.suitableForMe then
			filterWidgets.suitableForMe:SetValue(false)
		end
		if filterWidgets.availableNow then
			filterWidgets.availableNow:SetValue(false)
		end
		for _, key in ipairs({ "type", "slot", "stat", "profession" }) do
			if filterWidgets[key] then filterWidgets[key]:SetValue("Any") end
		end
		SaveFilters()
		RefreshFromFilters()
	end)
	filterRow2:AddChild(clearBtn)

	LayoutFilterStrip()

	LayoutSplit()
	RefreshTree(false)
	if selectedFactionID then
		ShowFactionDetail(selectedFactionID)
	end

	frame:Hide()
	return frame
end

local cacheWaitFrame
local cacheWaitListenerRegistered = false
local suppressWaitOnClose = false

local function IsCacheWaitShown()
	return cacheWaitFrame and cacheWaitFrame.frame and cacheWaitFrame.frame:IsShown()
end

local function HideCacheWaitFrame()
	if not IsCacheWaitShown() then return end
	-- AceGUI Frame fires OnClose on Hide; don't treat that as a user cancel.
	suppressWaitOnClose = true
	cacheWaitFrame:Hide()
	suppressWaitOnClose = false
end

local function ShowCacheWaitFrame()
	if not cacheWaitFrame then
		cacheWaitFrame = AceGUI:Create("Frame")
		cacheWaitFrame:SetTitle("RepRewards")
		cacheWaitFrame:SetStatusText("")
		cacheWaitFrame:SetWidth(400)
		cacheWaitFrame:SetHeight(180)
		cacheWaitFrame:SetLayout("Fill")
		cacheWaitFrame:EnableResize(false)
		cacheWaitFrame:SetCallback("OnClose", function()
			-- User dismissed the dialog — do not auto-open when preload finishes.
			if not suppressWaitOnClose then
				cacheWaitListenerRegistered = false
			end
		end)

		-- Drop the AceGUI status footer; center the Close button under the text.
		local host = cacheWaitFrame.frame
		if cacheWaitFrame.statustext then
			local statusbg = cacheWaitFrame.statustext:GetParent()
			if statusbg then statusbg:Hide() end
		end
		if host then
			for _, child in ipairs({ host:GetChildren() }) do
				if child:IsObjectType("Button") and child.GetText and child:GetText() == CLOSE then
					child:ClearAllPoints()
					child:SetPoint("BOTTOM", host, "BOTTOM", 0, 16)
					break
				end
			end
			host:SetFrameStrata("DIALOG")
		end

		local body = AceGUI:Create("Label")
		body:SetFullWidth(true)
		body:SetFontObject(GameFontHighlight)
		body:SetJustifyH("CENTER")
		body:SetJustifyV("MIDDLE")
		body:SetText(
			"\n\n|cffffd100Currently retrieving item cache...|r\n\n"
				.. "Shouldn't take too long.\n\n"
				.. "This runs when the addon detects items\nthat it hasn't seen before."
		)
		cacheWaitFrame:AddChild(body)
	end
	cacheWaitFrame:Show()
	cacheWaitFrame:DoLayout()

	if cacheWaitListenerRegistered then return end
	cacheWaitListenerRegistered = true
	Data.WhenItemCacheReady(function()
		local wasShown = IsCacheWaitShown()
		cacheWaitListenerRegistered = false
		HideCacheWaitFrame()
		if wasShown then
			RepRewards:Open()
		end
	end)
end

local function EnsureCacheReadyOrWait()
	-- Kick scheduling if PEW has not fired yet; fresh caches become ready immediately.
	Data.ScheduleThrottledPreload()
	if Data.IsItemCacheReady() then
		return true
	end
	ShowCacheWaitFrame()
	return false
end

function RepRewards:Toggle()
	if not Data.IsItemCacheReady() then
		if IsCacheWaitShown() then
			HideCacheWaitFrame()
			return
		end
		if not EnsureCacheReadyOrWait() then
			return
		end
	end

	HideCacheWaitFrame()
	CreateMainFrame()
	if frame:IsShown() then
		frame:Hide()
	else
		RefreshTree(true)
		if selectedFactionID then ShowFactionDetail(selectedFactionID) end
		frame:Show()
		frame:DoLayout()
		LayoutSplit()
	end
end

function RepRewards:Open()
	if not EnsureCacheReadyOrWait() then
		return
	end

	HideCacheWaitFrame()
	CreateMainFrame()
	RefreshTree(true)
	if selectedFactionID then ShowFactionDetail(selectedFactionID) end
	frame:Show()
	frame:DoLayout()
	LayoutSplit()
end

-------------------------------------------------------------------------
-- Addon lifecycle
-------------------------------------------------------------------------

-- Nil means on, so existing profiles keep the current lists.
local function DBFlag(key)
	local db = RepRewards_DB
	if type(db) ~= "table" or db[key] == nil then
		return true
	end
	return not not db[key]
end

local function SetDBFlag(key, value)
	if type(RepRewards_DB) ~= "table" then
		RepRewards_DB = {}
	end
	RepRewards_DB[key] = not not value
end

function RepRewards:ShowQuestLogReputation()
	return DBFlag("showQuestLogReputation")
end

function RepRewards:ShowEmptyReputations()
	return DBFlag("showEmptyReputations")
end

function RepRewards:ShowAllReputationsEntry()
	return DBFlag("showAllReputations")
end

local optionsCategoryID

local function OpenOptions()
	if optionsCategoryID and Settings and Settings.OpenToCategory then
		Settings.OpenToCategory(optionsCategoryID)
		return
	end
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
	if AceConfigDialog then
		AceConfigDialog:Open("RepRewards")
	end
end

local function RegisterOptions()
	local AceConfig = LibStub("AceConfig-3.0", true)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
	if not AceConfig or not AceConfigDialog then return end

	AceConfig:RegisterOptionsTable("RepRewards", {
		type = "group",
		name = "RepRewards",
		args = {
			showAllReputations = {
				type = "toggle",
				name = "Show the [All Reputations] option",
				desc = "Show the All Reputations entry at the top of the list.",
				order = 3,
				width = "full",
				get = function()
					return RepRewards:ShowAllReputationsEntry()
				end,
				set = function(_, value)
					SetDBFlag("showAllReputations", value)
					if frame and frame:IsShown() then
						RefreshTree(true)
					end
				end,
			},
			showQuestLogReputation = {
				type = "toggle",
				name = "Show reputation in the quest log",
				desc = "List reputation gained, and the faction, at the bottom of the quest text.",
				order = 1,
				width = "full",
				get = function()
					return RepRewards:ShowQuestLogReputation()
				end,
				set = function(_, value)
					SetDBFlag("showQuestLogReputation", value)
					if RepRewards.RefreshQuestLogReputation then
						RepRewards:RefreshQuestLogReputation()
					end
				end,
			},
			showEmptyReputations = {
				type = "toggle",
				name = "Show reputations with no rewards",
				desc = "List factions that have no rewards.",
				order = 2,
				width = "full",
				get = function()
					return RepRewards:ShowEmptyReputations()
				end,
				set = function(_, value)
					SetDBFlag("showEmptyReputations", value)
					if frame and frame:IsShown() then
						RefreshTree(true)
					end
				end,
			},
		},
	})

	if Settings and Settings.RegisterCanvasLayoutCategory then
		local ok, _, categoryID = pcall(AceConfigDialog.AddToBlizOptions, AceConfigDialog, "RepRewards", "RepRewards")
		if ok then
			optionsCategoryID = categoryID
		end
	end
end

function RepRewards:OnInitialize()
	AdoptAccountDB()
	RepRewards_DB.minimap = RepRewards_DB.minimap or { hide = false }
	EnsureCharDB()
	LoadFilters()
	Data.EnsureItemCacheDB()
	RegisterOptions()

	self:RegisterChatCommand("rr", "SlashCmd")
	self:RegisterChatCommand("reprewards", "SlashCmd")
	self:RegisterChatCommand("reputationrewards", "SlashCmd")

	local ldb = LibStub("LibDataBroker-1.1", true)
	if ldb and minimapIcon then
		broker = ldb:NewDataObject("RepRewards_Broker", {
			type = "launcher",
			label = "RepRewards",
			icon = "Interface\\Icons\\achievement_reputation_04",
			OnClick = function(_, button)
				if button == "LeftButton" then
					RepRewards:Toggle()
				elseif button == "RightButton" then
					OpenOptions()
				end
			end,
			OnTooltipShow = function(tt)
				tt:AddLine("RepRewards")
				tt:AddLine("Left-click to open the reputation browser.", 0.8, 0.8, 0.8)
				tt:AddLine("Right-click to open options.", 0.8, 0.8, 0.8)
				tt:AddLine("/rr  or  /reprewards", 0.6, 0.6, 0.6)
			end,
		})
		minimapIcon:Register("RepRewards_Broker", broker, RepRewards_DB.minimap)
		if RepRewards_DB.minimap.hide then
			minimapIcon:Hide("RepRewards_Broker")
		end
	end
end

function RepRewards:OnEnable()
	self:RegisterEvent("UPDATE_FACTION")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
end

function RepRewards:SlashCmd(input)
	input = (input or ""):lower():match("^%s*(.-)%s*$")
	if input == "options" or input == "config" then
		OpenOptions()
		return
	end
	if input == "minimap" then
		RepRewards_DB.minimap.hide = not RepRewards_DB.minimap.hide
		if minimapIcon then
			if RepRewards_DB.minimap.hide then
				minimapIcon:Hide("RepRewards_Broker")
				self:Print("Minimap icon hidden.")
			else
				minimapIcon:Show("RepRewards_Broker")
				self:Print("Minimap icon shown.")
			end
		end
		return
	end
	self:Toggle()
end

function RepRewards:UPDATE_FACTION()
	if frame and frame:IsShown() then
		RefreshTree(true)
		if selectedFactionID then ShowFactionDetail(selectedFactionID) end
	end
end

function RepRewards:PLAYER_ENTERING_WORLD()
	-- Login/reload only: schedule cache scan 5s after the world is ready.
	Data.ScheduleThrottledPreload()
end

local itemRefreshPending = false
function RepRewards:GET_ITEM_INFO_RECEIVED(_, itemID, success)
	if success == false then return end
	Data.OnItemInfoReceived(itemID)
	if not (frame and frame:IsShown()) then return end
	-- Debounce UI rebuilds: many item-info events fire during preload.
	if itemRefreshPending then return end
	itemRefreshPending = true
	local function flush()
		itemRefreshPending = false
		if not (frame and frame:IsShown()) then return end
		RefreshFactionList(true)
		if selectedFactionID then
			ShowFactionDetail(selectedFactionID)
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0.35, flush)
	else
		flush()
	end
end
