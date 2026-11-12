-------------------------------------------------------------------------
-- RepRewardsData.lua
-- Faction metadata and reward catalogs for WoW:Forever
-- Sources: ForeverDB, Wowhead Forever faction pages
-------------------------------------------------------------------------

RepRewards_Data = RepRewards_Data or {}

-- Standing indices match FACTION_STANDING_LABEL / reaction values (4=Neutral ... 8=Exalted)
RepRewards_Data.STANDING = {
	HATED = 1, HOSTILE = 2, UNFRIENDLY = 3, NEUTRAL = 4,
	FRIENDLY = 5, HONORED = 6, REVERED = 7, EXALTED = 8,
}

RepRewards_Data.STANDING_NAMES = {
	[1] = "Hated", [2] = "Hostile", [3] = "Unfriendly", [4] = "Neutral",
	[5] = "Friendly", [6] = "Honored", [7] = "Revered", [8] = "Exalted",
}

RepRewards_Data.STANDING_COLORS = {
	-- Wowhead Forever reputation standing colors (20% darker)
	[1] = { 0.44, 0.06, 0.06 }, -- Hated (maroon)
	[2] = { 0.80, 0.10, 0.10 }, -- Hostile (red)
	[3] = { 0.80, 0.40, 0.00 }, -- Unfriendly (orange)
	[4] = { 0.80, 0.80, 0.00 }, -- Neutral (yellow)
	[5] = { 0.44, 0.74, 0.12 }, -- Friendly (lime)
	[6] = { 0.04, 0.72, 0.16 }, -- Honored (green)
	[7] = { 0.04, 0.70, 0.58 }, -- Revered (teal)
	[8] = { 0.04, 0.60, 0.80 }, -- Exalted (cyan)
}

RepRewards_Data.UNKNOWN_COLOR = { 0.36, 0.36, 0.36 }

local S = RepRewards_Data.STANDING

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
local GetItemStats = GetItemStats or (C_Item and C_Item.GetItemStats)

-- Persisted item cache (RepRewards_DB.itemCache), warmed by throttled preload.
-- Fields: name, ilvl, texture, quality, stats, type, slot, armor, profession,
--         craftItemID, craftStats, craftSlot, craftArmor, craftType, resolved, updatedAt
-- Login/reload only: after a 5s delay, refresh missing or >1-week-old IDs at 5 / 0.2s.
-- Stats come from GetItemStats; recipes also store the crafted item's stats.
local ItemCache = {}
local itemCacheReady = false
local CACHE_TTL = 7 * 24 * 60 * 60 -- refresh entries older than 1 week
local preloadQueue = {}
local preloadIndex = 1
local preloadTicker = nil
local preloadPending = {}
local preloadTotal = 0
local preloadAnnounced = false
local preloadScheduled = false
local preloadStarted = false
local preloadSessionDone = false
local preloadSettlePending = false
local preloadCompleteCallbacks = {}
local PRELOAD_DELAY = 2 -- seconds after game load before scanning starts
local PRELOAD_BATCH = 5
local PRELOAD_INTERVAL = 0.2
local PRELOAD_SETTLE = 1.5 -- wait for async GET_ITEM_INFO_RECEIVED after last batch

local function CacheNow()
	return time()
end

local function IsCacheFresh(entry)
	if not entry or not entry.resolved or not entry.name then
		return false
	end
	-- Legacy rows / incomplete recipe rows need a rescan for stats.
	if entry.stats == nil then
		return false
	end
	if (entry.type == "Recipe" or entry.type == "Enchant") and entry.craftStats == nil then
		return false
	end
	local updatedAt = tonumber(entry.updatedAt)
	-- Older saves may lack updatedAt; treat resolved rows as fresh and stamp them once.
	if not updatedAt or updatedAt <= 0 then
		entry.updatedAt = CacheNow()
		return true
	end
	return (CacheNow() - updatedAt) < CACHE_TTL
end

-- Bind live cache to SavedVariables; migrate string keys → numeric.
function RepRewards_Data.EnsureItemCacheDB()
	if type(RepRewards_DB) ~= "table" then
		RepRewards_DB = {}
	end
	if type(RepRewards_DB.itemCache) ~= "table" then
		RepRewards_DB.itemCache = {}
	end

	ItemCache = RepRewards_DB.itemCache

	local pending = {}
	for key, entry in pairs(ItemCache) do
		local id = tonumber(key)
		if id and type(key) == "string" then
			pending[#pending + 1] = { id = id, key = key, entry = entry }
		end
		if type(entry) == "table" and entry.resolved == nil and entry.name then
			entry.resolved = true
		end
	end
	for _, row in ipairs(pending) do
		if not ItemCache[row.id] then
			ItemCache[row.id] = row.entry
		end
		ItemCache[row.key] = nil
	end

	itemCacheReady = true
	return ItemCache
end

local function GetCacheEntry(itemID)
	if not itemCacheReady then
		RepRewards_Data.EnsureItemCacheDB()
	end
	return ItemCache[itemID]
end

local function StoreCacheEntry(itemID, entry)
	if not itemCacheReady then
		RepRewards_Data.EnsureItemCacheDB()
	end
	entry.updatedAt = CacheNow()
	entry.resolved = true
	ItemCache[itemID] = entry
	return entry
end

local ITEM_CLASS_CONSUMABLE = (Enum and Enum.ItemClass and Enum.ItemClass.Consumable) or LE_ITEM_CLASS_CONSUMABLE or 0
local ITEM_CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or LE_ITEM_CLASS_WEAPON or 2
local ITEM_CLASS_ARMOR = (Enum and Enum.ItemClass and Enum.ItemClass.Armor) or LE_ITEM_CLASS_ARMOR or 4
local ITEM_CLASS_RECIPE = (Enum and Enum.ItemClass and Enum.ItemClass.Recipe) or LE_ITEM_CLASS_RECIPE or 9
local ITEM_CLASS_MISCELLANEOUS = (Enum and Enum.ItemClass and Enum.ItemClass.Miscellaneous) or LE_ITEM_CLASS_MISCELLANEOUS or 15

local ITEM_STAT_LABELS = {
	ITEM_MOD_STRENGTH_SHORT = "Strength",
	ITEM_MOD_AGILITY_SHORT = "Agility",
	ITEM_MOD_STAMINA_SHORT = "Stamina",
	ITEM_MOD_INTELLECT_SHORT = "Intellect",
	ITEM_MOD_SPIRIT_SHORT = "Spirit",
	ITEM_MOD_ATTACK_POWER_SHORT = "Attack Power",
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Attack Power",
	ITEM_MOD_SPELL_POWER_SHORT = "Spell Power",
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "Spell Power",
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Spell Power",
	ITEM_MOD_CRIT_RATING_SHORT = "Critical Strike",
	ITEM_MOD_CRIT_MELEE_RATING_SHORT = "Critical Strike",
	ITEM_MOD_CRIT_RANGED_RATING_SHORT = "Critical Strike",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "Critical Strike",
	ITEM_MOD_HIT_RATING_SHORT = "Hit",
	ITEM_MOD_HIT_MELEE_RATING_SHORT = "Hit",
	ITEM_MOD_HIT_RANGED_RATING_SHORT = "Hit",
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "Hit",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense",
	ITEM_MOD_DODGE_RATING_SHORT = "Dodge",
	ITEM_MOD_PARRY_RATING_SHORT = "Parry",
	ITEM_MOD_HEALTH_SHORT = "Health",
	ITEM_MOD_HEALTH = "Health",
}

local EQUIP_LOC_TO_SLOT = {
	INVTYPE_HEAD = "Head",
	INVTYPE_NECK = "Neck",
	INVTYPE_SHOULDER = "Shoulder",
	INVTYPE_BODY = "Shirt",
	INVTYPE_CHEST = "Chest",
	INVTYPE_ROBE = "Chest",
	INVTYPE_WAIST = "Waist",
	INVTYPE_LEGS = "Legs",
	INVTYPE_FEET = "Feet",
	INVTYPE_WRIST = "Wrist",
	INVTYPE_HAND = "Hands",
	INVTYPE_FINGER = "Finger",
	INVTYPE_TRINKET = "Trinket",
	INVTYPE_CLOAK = "Back",
	INVTYPE_WEAPON = "One-Hand",
	INVTYPE_WEAPONMAINHAND = "One-Hand",
	INVTYPE_WEAPONOFFHAND = "Off Hand",
	INVTYPE_SHIELD = "Off Hand",
	INVTYPE_HOLDABLE = "Off Hand",
	INVTYPE_2HWEAPON = "Two-Hand",
	INVTYPE_RANGED = "Ranged",
	INVTYPE_RANGEDRIGHT = "Ranged",
	INVTYPE_THROWN = "Ranged",
	INVTYPE_RELIC = "Relic",
	INVTYPE_TABARD = "Tabard",
}

local ARMOR_SUBCLASS_TO_ARMOR = {
	[1] = "Cloth",
	[2] = "Leather",
	[3] = "Mail",
	[4] = "Plate",
}

local RECIPE_SUBCLASS_TO_PROFESSION = {
	[1] = "Leatherworking",
	[2] = "Tailoring",
	[3] = "Engineering",
	[4] = "Blacksmithing",
	[5] = "Cooking",
	[6] = "Alchemy",
	[7] = "First Aid",
	[8] = "Enchanting",
	[10] = "Jewelcrafting",
}

local function ClassifyFromClient(classID, subclassID, equipLoc)
	local slot = equipLoc and equipLoc ~= "" and EQUIP_LOC_TO_SLOT[equipLoc] or nil
	local typ, armor, profession = "Misc", nil, nil

	if classID == ITEM_CLASS_WEAPON then
		typ = "Weapon"
	elseif classID == ITEM_CLASS_ARMOR then
		typ = (slot == "Tabard") and "Tabard" or "Armor"
		armor = ARMOR_SUBCLASS_TO_ARMOR[subclassID or -1]
	elseif classID == ITEM_CLASS_CONSUMABLE then
		typ = "Consumable"
	elseif classID == ITEM_CLASS_RECIPE then
		typ = (subclassID == 8) and "Enchant" or "Recipe"
		profession = RECIPE_SUBCLASS_TO_PROFESSION[subclassID or -1]
	elseif classID == ITEM_CLASS_MISCELLANEOUS then
		if subclassID == 5 then
			typ = "Mount"
		elseif subclassID == 2 then
			typ = "Pet"
		end
	elseif classID == nil then
		typ = nil
	end

	return typ, slot, armor, profession
end

-- R(itemID, standing, opts)  — preferred (name/icon/stats resolved from the client)
-- R(name, standing, opts)    — legacy fallback when no itemID is known yet
local function R(idOrName, standing, opts)
	opts = opts or {}
	local reward = {
		standing = standing,
		type = opts.type,
		slot = opts.slot,
		armor = opts.armor,
		stats = opts.stats,
		statsLocked = opts.stats ~= nil,
		ilvl = opts.ilvl,
		note = opts.note,
		profession = opts.profession,
	}
	if type(idOrName) == "number" then
		reward.itemID = idOrName
		reward.name = opts.name
	else
		reward.name = idOrName
		reward.itemID = opts.itemID
	end
	return reward
end

function RepRewards_Data.RequestItem(itemID)
	itemID = tonumber(itemID)
	if not itemID then return end
	if C_Item and C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	elseif GetItemInfo then
		GetItemInfo(itemID)
	end
end

local function StatLabelsFromLink(link, itemID)
	if not GetItemStats then return {} end
	local raw = GetItemStats(link or ("item:" .. itemID))
	if not raw then return {} end
	local labels, seen = {}, {}
	for key, value in pairs(raw) do
		local label = ITEM_STAT_LABELS[key]
		if label and value and value ~= 0 and not seen[label] then
			seen[label] = true
			labels[#labels + 1] = label
		end
	end
	return labels
end

-- Pull the crafted/result itemID from a recipe tooltip (client data, not name inference).
local scanTip
local function EnsureScanTip()
	if scanTip then return scanTip end
	scanTip = CreateFrame("GameTooltip", "RepRewardsItemScanTip", nil, "GameTooltipTemplate")
	scanTip:SetOwner(UIParent, "ANCHOR_NONE")
	return scanTip
end

local function ItemIDFromTooltipText(text, excludeID)
	if not text then return nil end
	for id in string.gmatch(text, "item:(%d+)") do
		id = tonumber(id)
		if id and id ~= excludeID then
			return id
		end
	end
	return nil
end

local function CraftItemIDFromRecipe(recipeID)
	recipeID = tonumber(recipeID)
	if not recipeID then return nil end

	if C_TooltipInfo and C_TooltipInfo.GetItemByID then
		local data = C_TooltipInfo.GetItemByID(recipeID)
		if data then
			local linkID = ItemIDFromTooltipText(data.hyperlink, recipeID)
			if linkID then return linkID end
			for _, line in ipairs(data.lines or {}) do
				local text = line.leftText or line.rightText
				if not text and line.args then
					for _, arg in ipairs(line.args) do
						if type(arg.stringVal) == "string" and arg.stringVal:find("item:", 1, true) then
							text = arg.stringVal
							break
						end
					end
				end
				local id = ItemIDFromTooltipText(text, recipeID)
				if id then return id end
			end
		end
	end

	local tip = EnsureScanTip()
	tip:ClearLines()
	tip:SetHyperlink("item:" .. recipeID)
	local tipName = tip:GetName()
	for i = 1, tip:NumLines() do
		local left = _G[tipName .. "TextLeft" .. i]
		local right = _G[tipName .. "TextRight" .. i]
		local id = ItemIDFromTooltipText(left and left:GetText(), recipeID)
			or ItemIDFromTooltipText(right and right:GetText(), recipeID)
		if id then return id end
	end
	return nil
end

-- Fill craftStats / craftSlot from the created item's GetItemInfo + GetItemStats.
local function ApplyCraftedItemFields(entry, craftItemID)
	entry.craftItemID = craftItemID
	if not craftItemID then
		entry.craftStats = {}
		return true
	end

	local cName, cLink, _, _, _, _, _, _, cEquip, _, _, cClass, cSub
	if GetItemInfo then
		cName, cLink, _, _, _, _, _, _, cEquip, _, _, cClass, cSub = GetItemInfo(craftItemID)
	end
	if GetItemInfoInstant and (not cEquip or not cClass) then
		local _, _, _, instantEquip, _, instantClass, instantSub = GetItemInfoInstant(craftItemID)
		cEquip = cEquip or instantEquip
		cClass = cClass or instantClass
		cSub = cSub or instantSub
	end

	if not cName then
		RepRewards_Data.RequestItem(craftItemID)
		-- Incomplete until the crafted item loads; leave craftStats nil so we rescan.
		return false
	end

	entry.craftStats = StatLabelsFromLink(cLink, craftItemID)
	local cTyp, cSlot, cArmor = ClassifyFromClient(cClass, cSub, cEquip)
	entry.craftType = cTyp
	entry.craftSlot = cSlot
	entry.craftArmor = cArmor
	return true
end

local function RefreshRecipesUsingCraftItem(craftItemID)
	craftItemID = tonumber(craftItemID)
	if not craftItemID or not itemCacheReady then return end
	for id, entry in pairs(ItemCache) do
		if type(entry) == "table" and entry.craftItemID == craftItemID then
			if ApplyCraftedItemFields(entry, craftItemID) then
				entry.updatedAt = CacheNow()
				entry.resolved = true
				preloadPending[id] = nil
			end
		end
	end
end

-- Resolve and cache one item.
-- requestIfMissing=false: SavedVariables only (no client fill — keeps expand()/UI reads cheap).
-- requestIfMissing=true: hit GetItemInfo / RequestLoad for preload and GET_ITEM_INFO_RECEIVED.
function RepRewards_Data.CacheItem(itemID, requestIfMissing)
	itemID = tonumber(itemID)
	if not itemID then return nil end

	local cached = GetCacheEntry(itemID)
	if IsCacheFresh(cached) then
		return cached
	end

	-- Passive reads must not warm the whole catalog during file load / NormalizeReward.
	if not requestIfMissing then
		if cached and cached.resolved and cached.name then
			return cached
		end
		return nil
	end

	local name, link, quality, ilvl, minLevel, _, _, _, equipLoc, texture, _, classID, subclassID
	if GetItemInfo then
		name, link, quality, ilvl, minLevel, _, _, _, equipLoc, texture, _, classID, subclassID = GetItemInfo(itemID)
	end

	-- Instant classification can fill slot/type before the full name payload arrives
	if GetItemInfoInstant then
		local _, _, _, instantEquip, instantIcon, instantClass, instantSub = GetItemInfoInstant(itemID)
		equipLoc = equipLoc or instantEquip
		texture = texture or instantIcon
		classID = classID or instantClass
		subclassID = subclassID or instantSub
	end

	if not name then
		RepRewards_Data.RequestItem(itemID)
		-- Serve stale persisted data until a refresh succeeds
		if cached and cached.resolved and cached.name then
			return cached
		end
		return nil
	end

	local typ, slot, armor, profession = ClassifyFromClient(classID, subclassID, equipLoc)
	local entry = {
		name = name,
		ilvl = ilvl,
		reqLevel = minLevel or 0,
		texture = texture,
		quality = quality,
		stats = StatLabelsFromLink(link, itemID),
		type = typ,
		slot = slot,
		armor = armor,
		profession = profession,
		classID = classID,
		subclassID = subclassID,
	}

	if typ == "Recipe" or typ == "Enchant" then
		ApplyCraftedItemFields(entry, CraftItemIDFromRecipe(itemID))
	end

	return StoreCacheEntry(itemID, entry)
end

function RepRewards_Data.GetCachedItem(itemID)
	itemID = tonumber(itemID or 0)
	if not itemID then return nil end
	return GetCacheEntry(itemID)
end

-- Pull cached fields. Fresh SV entries avoid client calls; missing ones are added when found.
function RepRewards_Data.GetItemBasics(itemID)
	itemID = tonumber(itemID)
	if not itemID then return nil end
	local cached = RepRewards_Data.CacheItem(itemID, false)
	if not cached or not cached.resolved or not cached.name then return nil end
	return cached
end

-- Queue unique reward itemIDs that are missing from SV or older than CACHE_TTL.
local function BuildPreloadQueue()
	RepRewards_Data.EnsureItemCacheDB()
	local seen, queue = {}, {}
	for _, faction in pairs(RepRewards_Data.factions or {}) do
		for _, reward in ipairs(faction.rewards or {}) do
			local id = tonumber(reward.itemID)
			if id and not seen[id] then
				seen[id] = true
				if not IsCacheFresh(ItemCache[id]) then
					queue[#queue + 1] = id
				end
			end
		end
	end
	return queue
end

local function StopPreloadTicker()
	if not preloadTicker then return end
	if preloadTicker.Cancel then
		preloadTicker:Cancel()
	elseif preloadTicker.SetScript then
		preloadTicker:SetScript("OnUpdate", nil)
	end
	preloadTicker = nil
end

local function CountPreloadResolved()
	local n = 0
	for _, id in ipairs(preloadQueue) do
		local entry = ItemCache[id]
		if entry and entry.resolved and entry.name then
			n = n + 1
		end
	end
	return n
end

local function NotifyPreloadCompleteListeners()
	local cbs = preloadCompleteCallbacks
	preloadCompleteCallbacks = {}
	for i = 1, #cbs do
		local ok, err = pcall(cbs[i])
		if not ok then
			geterrorhandler()(err)
		end
	end
end

local function MarkPreloadSessionDone(announceCount)
	if preloadSessionDone then return end
	preloadSessionDone = true
	preloadAnnounced = true
	preloadPending = {}
	preloadSettlePending = false
	if announceCount and announceCount > 0 then
		print(string.format("RepRewards scanned %d items", announceCount))
	end
	NotifyPreloadCompleteListeners()
end

local function AnnouncePreloadComplete()
	if preloadAnnounced then return end
	if preloadTotal <= 0 then
		MarkPreloadSessionDone(0)
		return
	end
	MarkPreloadSessionDone(CountPreloadResolved())
end

function RepRewards_Data.IsItemCacheReady()
	return preloadSessionDone and true or false
end

-- Run cb now if ready, otherwise after AnnouncePreloadComplete / empty-queue finish.
function RepRewards_Data.WhenItemCacheReady(cb)
	if type(cb) ~= "function" then return end
	if preloadSessionDone then
		cb()
		return
	end
	preloadCompleteCallbacks[#preloadCompleteCallbacks + 1] = cb
end

local function TryFinishPreload()
	if preloadAnnounced then return end
	if preloadIndex <= #preloadQueue then return end
	StopPreloadTicker()

	-- Still waiting on client item data: settle briefly so async resolves count.
	if next(preloadPending) then
		if preloadSettlePending then return end
		preloadSettlePending = true
		if C_Timer and C_Timer.After then
			C_Timer.After(PRELOAD_SETTLE, function()
				AnnouncePreloadComplete()
			end)
		else
			AnnouncePreloadComplete()
		end
		return
	end

	AnnouncePreloadComplete()
end

local function PreloadStep()
	if preloadIndex > #preloadQueue then
		TryFinishPreload()
		return
	end
	local stop = math.min(preloadIndex + PRELOAD_BATCH - 1, #preloadQueue)
	for i = preloadIndex, stop do
		local id = preloadQueue[i]
		local cached = RepRewards_Data.CacheItem(id, true)
		local waitingOnCraft = cached
			and (cached.type == "Recipe" or cached.type == "Enchant")
			and cached.craftStats == nil
		if not cached or not cached.name or waitingOnCraft then
			preloadPending[id] = true
		else
			preloadPending[id] = nil
		end
	end
	preloadIndex = stop + 1
	if preloadIndex > #preloadQueue then
		TryFinishPreload()
	end
end

-- Run the throttled cache warm-up (missing / older than 1 week). Once per session.
function RepRewards_Data.StartThrottledPreload()
	if preloadStarted or preloadTicker or preloadSessionDone then return end
	RepRewards_Data.EnsureItemCacheDB()
	preloadQueue = BuildPreloadQueue()
	preloadIndex = 1
	preloadTotal = #preloadQueue
	preloadPending = {}
	preloadSettlePending = false
	preloadAnnounced = false
	preloadStarted = true
	if preloadTotal == 0 then
		MarkPreloadSessionDone(0)
		return
	end

	PreloadStep()
	if preloadIndex > #preloadQueue then return end

	if C_Timer and C_Timer.NewTicker then
		preloadTicker = C_Timer.NewTicker(PRELOAD_INTERVAL, PreloadStep)
		return
	end

	-- Fallback when C_Timer is unavailable
	local driver = CreateFrame("Frame")
	local elapsed = 0
	driver:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed < PRELOAD_INTERVAL then return end
		elapsed = 0
		PreloadStep()
	end)
	preloadTicker = driver
end

-- Login/reload only: wait PRELOAD_DELAY after the world is up, then start scanning.
-- If the SV cache is already fresh, mark ready immediately so the UI can open.
function RepRewards_Data.ScheduleThrottledPreload()
	if preloadScheduled or preloadStarted or preloadSessionDone then return end
	preloadScheduled = true
	RepRewards_Data.EnsureItemCacheDB()

	local queue = BuildPreloadQueue()
	if #queue == 0 then
		preloadStarted = true
		MarkPreloadSessionDone(0)
		return
	end

	local function begin()
		RepRewards_Data.StartThrottledPreload()
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(PRELOAD_DELAY, begin)
		return
	end

	local driver = CreateFrame("Frame")
	local elapsed = 0
	driver:SetScript("OnUpdate", function(self, dt)
		elapsed = elapsed + dt
		if elapsed < PRELOAD_DELAY then return end
		self:SetScript("OnUpdate", nil)
		begin()
	end)
end

-- Apply a single resolved itemID to matching rewards (avoids full-catalog rescans).
function RepRewards_Data.OnItemInfoReceived(itemID)
	itemID = tonumber(itemID)
	if not itemID then return false end

	-- Crafted results may arrive after their parent recipe was scanned.
	RefreshRecipesUsingCraftItem(itemID)

	local cached = RepRewards_Data.CacheItem(itemID, true)
	local waitingOnCraft = cached
		and (cached.type == "Recipe" or cached.type == "Enchant")
		and cached.craftStats == nil
	if preloadPending[itemID] and cached and cached.name and not waitingOnCraft then
		preloadPending[itemID] = nil
		TryFinishPreload()
	elseif not waitingOnCraft then
		TryFinishPreload()
	end
	if not cached or not cached.resolved then return false end

	local touched = false
	for _, faction in pairs(RepRewards_Data.factions or {}) do
		for _, reward in ipairs(faction.rewards or {}) do
			local rewardCache = reward.itemID and ItemCache[reward.itemID]
			if reward.itemID == itemID
				or reward.craftItemID == itemID
				or (rewardCache and rewardCache.craftItemID == itemID)
			then
				RepRewards_Data.NormalizeReward(reward)
				touched = true
			end
		end
	end
	return touched
end

-- Infer type/slot/armor from item name when metadata is thin
function RepRewards_Data.ClassifyName(name)
	if not name then return "Misc", nil, nil end
	local lower = name:lower()
	local typ, slot, armor = "Misc", nil, nil

	if lower:find("^pattern:") or lower:find("^plans:") or lower:find("^formula:")
		or lower:find("^recipe:") or lower:find("^schematic:") then
		typ = "Recipe"
	elseif lower:find("tabard") then
		typ = "Tabard"; slot = "Tabard"
	elseif lower:find("reins of") or lower:find("whistle of") then
		typ = "Mount"
	elseif lower:find("treat") and lower:find("mule") then
		typ = "Pet"
	elseif lower:find("sign") and (lower:find("toy") or lower:find("tradeskill") or lower:find("license")) then
		typ = "Toy"
	elseif lower:find("cloak") or lower:find("cape") or lower:find("drape") or lower:find("mantle of the") then
		typ = "Armor"; slot = "Back"
	elseif lower:find("ring") or lower:find("band") or lower:find("signet") or lower:find("seal") then
		typ = "Armor"; slot = "Finger"
	elseif lower:find("necklace") or lower:find("amulet") or lower:find("pendant") or lower:find("choker") or lower:find("talisman") then
		typ = "Armor"; slot = "Neck"
	elseif lower:find("trinket") then
		typ = "Armor"; slot = "Trinket"
	elseif lower:find("sword") or lower:find("blade") or lower:find("mace") or lower:find("axe")
		or lower:find("dagger") or lower:find("staff") or lower:find("bow") or lower:find("gun")
		or lower:find("wand") or lower:find("reaper") or lower:find("bludgeon") or lower:find("claw")
		or lower:find("tome") or lower:find("manifesto") then
		typ = "Weapon"
	elseif lower:find("helm") or lower:find("hood") or lower:find("cowl") or lower:find("cover")
		or lower:find("fedora") or lower:find("headband") or lower:find("eyepatch") or lower:find("monocle") then
		typ = "Armor"; slot = "Head"
	elseif lower:find("shoulder") or lower:find("spaulders") or lower:find("epaulets")
		or lower:find("pauldrons") or lower:find("mantle") or lower:find("drapes") then
		typ = "Armor"; slot = "Shoulder"
	elseif lower:find("chest") or lower:find("breastplate") or lower:find("tunic") or lower:find("vest")
		or lower:find("harness") or lower:find("jerkin") or lower:find("robe") then
		typ = "Armor"; slot = "Chest"
	elseif lower:find("bracer") or lower:find("wrist") or lower:find("cuff") or lower:find("armguard") then
		typ = "Armor"; slot = "Wrist"
	elseif lower:find("glove") or lower:find("gauntlet") or lower:find("handwrap") or lower:find("handguard")
		or lower:find("mitt") or lower:find("grip") or lower:find("clencher") then
		typ = "Armor"; slot = "Hands"
	elseif lower:find("belt") or lower:find("girdle") or lower:find("cord") or lower:find("strap") or lower:find("waist") then
		typ = "Armor"; slot = "Waist"
	elseif lower:find("leg") or lower:find("pant") or lower:find("trouser") or lower:find("kilt") or lower:find("woolies") then
		typ = "Armor"; slot = "Legs"
	elseif lower:find("boot") or lower:find("greave") or lower:find("treader") or lower:find("foot")
		or lower:find("shoe") or lower:find("stomper") then
		typ = "Armor"; slot = "Feet"
	elseif lower:find("ration") or lower:find("biscuit") or lower:find("bandage") or lower:find("elixir")
		or lower:find("potion") or lower:find("oil") or lower:find("juice") or lower:find("fruit")
		or lower:find("water") or lower:find("sleep") then
		typ = "Consumable"
	elseif lower:find("enchant") or lower:find("scroll:") then
		typ = "Enchant"
	end

	if lower:find("cloth") or lower:find("gustwoven") or lower:find("stormsewn") or lower:find("windraveled") then
		armor = "Cloth"
	elseif lower:find("leather") or lower:find("lizardhide") or lower:find("hide") then
		armor = "Leather"
	elseif lower:find("mail") or lower:find("chain") or lower:find("skyforged") then
		armor = "Mail"
	elseif lower:find("plate") or lower:find("lamellar") then
		armor = "Plate"
	end

	return typ, slot, armor
end

local function CraftedNameFromRecipe(name)
	if not name or name == "" then return nil end
	local lower = name:lower()
	return lower:gsub("^pattern:%s*", ""):gsub("^plans:%s*", ""):gsub("^formula:%s*", "")
		:gsub("^recipe:%s*", ""):gsub("^schematic:%s*", "")
end

-- Infer equip slot of the item a recipe/pattern creates.
function RepRewards_Data.InferCraftSlot(name)
	local crafted = CraftedNameFromRecipe(name)
	if not crafted then return nil end
	local _, slot = RepRewards_Data.ClassifyName(crafted)
	return slot
end

--[[ Disabled: stat filtering uses GetItemStats from the item / crafted item cache.
-- Infer stats on the item a recipe/pattern creates (and enchant/formula targets).
function RepRewards_Data.InferCraftStats(name)
	if not name or name == "" then return {} end
	local crafted = CraftedNameFromRecipe(name)

	local stats = {}
	local function add(...)
		for i = 1, select("#", ...) do
			local s = select(i, ...)
			local seen = false
			for _, e in ipairs(stats) do if e == s then seen = true break end end
			if not seen then stats[#stats + 1] = s end
		end
	end

	-- Direct stat words in enchant/item names
	if crafted:find("strength") then add("Strength") end
	if crafted:find("agility") then add("Agility") end
	if crafted:find("intellect") then add("Intellect") end
	if crafted:find("spirit") then add("Spirit") end
	if crafted:find("stamina") or crafted:find("fortitude") or crafted:find("health") then add("Stamina") end
	if crafted:find("spellpower") or crafted:find("spell power") or crafted:find("spellblasting")
		or crafted:find("healing power") or crafted:find("mighty spell") or crafted:find("mighty healing") then
		add("Spell Power")
	end
	if crafted:find("attack power") or crafted:find("ferocity") or crafted:find("frenzy") then add("Attack Power") end
	if crafted:find("deflection") or crafted:find("defense") or crafted:find("phalanx") then add("Defense") end
	if crafted:find("dodge") then add("Dodge") end
	if crafted:find("parry") then add("Parry") end
	if crafted:find("hit ") or crafted:find(" hit") then add("Hit") end
	if crafted:find("critical") or crafted:find("crit") then add("Critical Strike") end

	-- Forever Merchant's Favor / profession set families (possessive / specific)
	local sets = {
		-- Leatherworking
		["brawler's"] = { "Strength", "Stamina" },
		["defender's"] = { "Stamina", "Defense" },
		["stormrider's"] = { "Agility", "Stamina" },
		["totemic"] = { "Intellect", "Spirit" },
		["trapper's"] = { "Agility", "Stamina" },
		["wisdom's"] = { "Intellect", "Spirit" },
		["mender's"] = { "Intellect", "Spirit" },
		["skycaller's"] = { "Intellect", "Spell Power" },
		["prowler's"] = { "Agility", "Attack Power" },
		["skulker's"] = { "Agility", "Stamina" },
		["warden's"] = { "Strength", "Stamina" },
		["skirmisher's"] = { "Agility", "Stamina" },
		["stalker's"] = { "Agility", "Attack Power" },
		-- Blacksmithing mail/plate sets
		["acolyte's"] = { "Intellect", "Spirit" },
		["crusader's"] = { "Strength", "Stamina" },
		["guard's"] = { "Strength", "Stamina" },
		["protector's"] = { "Stamina", "Defense" },
		["veteran's"] = { "Strength", "Stamina" },
		["justicar's"] = { "Strength", "Stamina" },
		["officer's"] = { "Strength", "Stamina" },
		["sentinel's"] = { "Agility", "Stamina" },
		["warder's"] = { "Stamina", "Defense" },
		["prefect's"] = { "Intellect", "Spell Power" },
		["enriched thorium"] = { "Strength", "Stamina" },
		["thorium greatmace"] = { "Strength", "Stamina" },
		["thorium cestus"] = { "Agility", "Stamina" },
		["legionite"] = { "Strength", "Stamina" },
		-- Tailoring sets
		["flame boot"] = { "Intellect", "Spell Power" },
		["flame glove"] = { "Intellect", "Spell Power" },
		["flame sash"] = { "Intellect", "Spell Power" },
		["flame circlet"] = { "Intellect", "Spell Power" },
		["flame gown"] = { "Intellect", "Spell Power" },
		["flame legging"] = { "Intellect", "Spell Power" },
		["pearly"] = { "Intellect", "Spirit" },
		["pristine"] = { "Intellect", "Spirit" },
		["shadow boot"] = { "Intellect", "Spell Power" },
		["shadow glove"] = { "Intellect", "Spell Power" },
		["shadow sash"] = { "Intellect", "Spell Power" },
		["shadow circlet"] = { "Intellect", "Spell Power" },
		["shadow gown"] = { "Intellect", "Spell Power" },
		["shadow legging"] = { "Intellect", "Spell Power" },
		["shining"] = { "Intellect", "Spell Power" },
		["silky"] = { "Intellect", "Spirit" },
		["black handwrap"] = { "Intellect", "Spell Power" },
		["black waistcord"] = { "Intellect", "Spell Power" },
		["black sandal"] = { "Intellect", "Spell Power" },
		["fiery"] = { "Intellect", "Spell Power" },
		["frothing"] = { "Intellect", "Spell Power" },
		["golden"] = { "Intellect", "Spirit" },
		["radiant"] = { "Intellect", "Spell Power" },
		["netherflame"] = { "Intellect", "Spell Power" },
		["netherfroth"] = { "Intellect", "Spell Power" },
		["nethergeld"] = { "Intellect", "Spell Power" },
		["netherlight"] = { "Intellect", "Spell Power" },
		["netherpearl"] = { "Intellect", "Spirit" },
		["nethershine"] = { "Intellect", "Spell Power" },
		["gilded"] = { "Intellect", "Spirit" },
		-- Forever cloudy/azure craftables
		["gustwoven"] = { "Intellect", "Spirit" },
		["stormsewn"] = { "Intellect", "Spell Power" },
		["windraveled"] = { "Agility", "Stamina" },
		["skyforged"] = { "Strength", "Stamina" },
		-- Classic patterned sets
		["bloodvine"] = { "Intellect", "Spell Power" },
		["bloodsoul"] = { "Agility", "Stamina" },
		["darksoul"] = { "Strength", "Stamina" },
		["primal batskin"] = { "Agility", "Stamina" },
		["blood tiger"] = { "Strength", "Agility" },
		["corehound"] = { "Agility", "Stamina" },
		["flarecore"] = { "Intellect", "Stamina" },
		["molten helm"] = { "Stamina" },
		["molten belt"] = { "Stamina" },
		["timbermaw"] = { "Stamina" },
		["warbear"] = { "Strength", "Stamina" },
		["argent boot"] = { "Stamina" },
		["argent shoulder"] = { "Stamina" },
		["dawn treader"] = { "Stamina" },
		["girdle of the dawn"] = { "Stamina" },
		["gloves of the dawn"] = { "Stamina" },
		["dawnbringer"] = { "Strength", "Stamina" },
		["icebane"] = { "Stamina" },
		["obsidian"] = { "Stamina" },
		["dark iron"] = { "Stamina" },
		["fiery chain"] = { "Intellect", "Stamina" },
		["black dragonscale"] = { "Agility", "Stamina" },
		["chromatic"] = { "Strength", "Agility", "Intellect" },
		["lava belt"] = { "Stamina" },
	}
	for key, list in pairs(sets) do
		if crafted:find(key, 1, true) then
			add(unpack(list))
		end
	end

	-- Alchemy consumables that buff a primary
	if crafted:find("elixir of the whale") or crafted:find("greater fortitude") then add("Stamina") end
	if crafted:find("elixir of the owl") or crafted:find("intellect") or crafted:find("sages") or crafted:find("mageblood")
		or crafted:find("cleric") or crafted:find("arcane elixir") then add("Intellect") end
	if crafted:find("elixir of lesser spirit") or crafted:find("greater spirit") then add("Spirit") end
	if crafted:find("ferocity") or crafted:find("grizzly") or crafted:find("cunning") then add("Agility") end
	if crafted:find("nature power") then add("Spell Power") end

	return stats
end
]]

-- Infer crafting profession from recipe/pattern/plans naming conventions.
function RepRewards_Data.InferProfession(name, reward)
	if not name or name == "" then return nil end
	if reward and reward.profession and reward.profession ~= "" then
		return reward.profession
	end

	local lower = name:lower()
	local armor = reward and reward.armor

	if lower:find("^plans:") then
		return "Blacksmithing"
	end
	if lower:find("^schematic:") then
		return "Engineering"
	end
	if lower:find("^design:") then
		return "Jewelcrafting"
	end
	if lower:find("^manual:") then
		if lower:find("bandage") or lower:find("first aid") then return "First Aid" end
		return nil
	end

	if lower:find("^formula:") then
		if lower:find("anti%-venom") or lower:find("bandage") then
			return "First Aid"
		end
		return "Enchanting"
	end

	if lower:find("^pattern:") then
		if armor == "Cloth"
			or lower:find("cloth", 1, true) or lower:find("robe", 1, true)
			or lower:find("bag", 1, true) or lower:find("satchel", 1, true)
			or lower:find("mooncloth", 1, true) or lower:find("felcloth", 1, true)
			or lower:find("shadoweave", 1, true) or lower:find("silk", 1, true)
			or lower:find("linen", 1, true) or lower:find("wool", 1, true)
			or lower:find("cape", 1, true) or lower:find("cloak", 1, true)
			or lower:find("vestment", 1, true) or lower:find("sylvan", 1, true)
			or lower:find("flarecore", 1, true) or lower:find("argent boot", 1, true)
			or lower:find("argent shoulder", 1, true) or lower:find("wisdom of the timbermaw", 1, true)
			or lower:find("mantle of the timbermaw", 1, true) or lower:find("gaea's embrace", 1, true)
		then
			return "Tailoring"
		end
		-- Leather / mail patterns (including dragonscale) are Leatherworking
		return "Leatherworking"
	end

	if lower:find("^recipe:") then
		if lower:find("bandage", 1, true) then return "First Aid" end
		if lower:find("feast", 1, true) or lower:find("steak", 1, true) or lower:find("sausage", 1, true)
			or lower:find("bread", 1, true) or lower:find("soup", 1, true) or lower:find("chowder", 1, true)
			or lower:find("roast", 1, true) or lower:find("smoked", 1, true) or lower:find("fillet", 1, true)
			or lower:find("cookie", 1, true) or lower:find("pie", 1, true) or lower:find("barbecue", 1, true)
		then
			return "Cooking"
		end
		-- Transmutes, elixirs, potions, oils → Alchemy
		return "Alchemy"
	end

	if reward and reward.type == "Enchant" then
		return "Enchanting"
	end

	return nil
end

function RepRewards_Data.NormalizeReward(reward)
	if not reward then return nil end

	local fromCache = false
	if reward.itemID then
		local info = RepRewards_Data.GetItemBasics(reward.itemID)
		if info then
			fromCache = true
			reward.name = info.name
			reward.icon = info.texture
			if info.ilvl and (not reward.ilvl or reward.ilvl == 0) then
				reward.ilvl = info.ilvl
			end
			-- Client cache drives filter fields for accuracy
			if info.type then reward.type = info.type end
			reward.slot = info.slot
			reward.armor = info.armor
			reward.reqLevel = info.reqLevel or reward.reqLevel
			reward.classID = info.classID
			reward.subclassID = info.subclassID
			if not reward.statsLocked then
				reward.stats = info.stats or {}
			end
			-- Recipe/pattern: crafted-item stats/slot from GetItemStats on the created item.
			reward.craftItemID = info.craftItemID
			reward.craftStats = info.craftStats or {}
			if info.craftSlot then reward.craftSlot = info.craftSlot end
			if info.craftArmor then reward.craftArmor = info.craftArmor end
			if info.craftType then reward.craftType = info.craftType end
			if not reward.professionLocked then
				reward.profession = info.profession
			end
			reward._resolved = true
		else
			if not reward.name or reward.name == "" then
				reward.name = string.format("Item %d", reward.itemID)
			end
			reward._resolved = false
		end
	end

	-- Fallback for name-only rows, or itemIDs not yet in cache
	if not fromCache then
		local typ, slot, armor = RepRewards_Data.ClassifyName(reward.name)
		if not reward.type or reward.type == "Misc" then reward.type = typ end
		if not reward.slot then reward.slot = slot end
		if not reward.armor then reward.armor = armor end
		if not reward.professionLocked then
			reward.profession = RepRewards_Data.InferProfession(reward.name, reward) or reward.profession
		end
	end

	-- Skill requirement may live on the reward or only in the note ("skill 175")
	if not reward.skill and reward.note then
		local sk = reward.note:match("[Ss]kill%s*(%d+)")
		if sk then reward.skill = tonumber(sk) end
	end

	reward.stats = reward.stats or {}
	local isRecipe = reward.type == "Recipe" or reward.type == "Enchant"
	if isRecipe then
		reward.craftStats = reward.craftStats or {}
		-- Slot/armor fallback from name only when the crafted item is not cached yet.
		if not reward.craftSlot then
			reward.craftSlot = RepRewards_Data.InferCraftSlot(reward.name)
		end
		if not reward.craftArmor and not reward.craftType then
			local crafted = (reward.name or ""):lower()
				:gsub("^pattern:%s*", ""):gsub("^plans:%s*", ""):gsub("^formula:%s*", "")
				:gsub("^recipe:%s*", ""):gsub("^schematic:%s*", "")
			local craftType, _, craftArmor = RepRewards_Data.ClassifyName(crafted)
			reward.craftType = craftType
			reward.craftArmor = craftArmor
		end
	else
		reward.craftStats = reward.craftStats or {}
		reward.craftSlot = nil
	end

	return reward
end

-- Re-resolve unresolved itemID rewards from the session cache.
function RepRewards_Data.RefreshResolvedRewards()
	for _, faction in pairs(RepRewards_Data.factions or {}) do
		for _, reward in ipairs(faction.rewards or {}) do
			if reward.itemID and not reward._resolved then
				RepRewards_Data.NormalizeReward(reward)
			elseif reward.itemID and not reward.statsLocked then
				local cached = RepRewards_Data.GetCachedItem(reward.itemID)
				local wantStats = cached and cached.resolved and (
					(cached.stats and #cached.stats > 0)
					or (cached.craftStats and #cached.craftStats > 0)
				)
				if wantStats and (#(reward.stats or {}) == 0 and #(reward.craftStats or {}) == 0) then
					RepRewards_Data.NormalizeReward(reward)
				end
			end
		end
	end
end

-- Kick (or continue) the throttled login preload instead of requesting everything at once.
function RepRewards_Data.RequestAllRewardItems()
	RepRewards_Data.StartThrottledPreload()
end

local function expand(list)
	local out = {}
	for _, r in ipairs(list or {}) do
		out[#out + 1] = RepRewards_Data.NormalizeReward(r)
	end
	return out
end

-------------------------------------------------------------------------
-- Quartermasters / supply officers who sell faction rewards.
-- map: UiMapID (C_Map). x/y are 0-100 zone coords. side limits the row.
-- altMaps: tried if the primary map id is missing on this client.
-------------------------------------------------------------------------
--  check location with /dump C_Map.GetBestMapForUnit("player") 
--  map ids https://wowpedia.fandom.com/wiki/UiMapID (Classic section)


RepRewards_Data.vendors = {
	[529] = { -- Argent Dawn
		{ name = "Quartermaster Miranda Breechlock", place = "Light's Hope Chapel, Eastern Plaguelands", map = 1423, x = 81.6, y = 60.0 },
		{ name = "Argent Quartermaster Lightspark", place = "Chillwind Camp, Western Plaguelands", map = 1422, x = 42.8, y = 83.8, side = "Alliance" },
		{ name = "Argent Quartermaster Hasana", place = "The Bulwark, Tirisfal Glades", map = 1420, x = 83.2, y = 68.2, side = "Horde" },
	},
	[609] = { -- Cenarion Circle
		{ name = "Mishta", place = "Cenarion Hold, Silithus", map = 1451, x = 49.8, y = 36.4 },
		{ name = "Kania", place = "Cenarion Hold, Silithus", map = 1451, x = 52.0, y = 39.6 },
		{ name = "Vargus", place = "Cenarion Hold, Silithus", map = 1451, x = 51.2, y = 38.8 },
		{ name = "Aendel Windspear", place = "Southwind Village, Silithus", map = 1451, x = 62.6, y = 49.8 },
		{ name = "Lieutenant General Andorov", place = "Ruins of Ahn'Qiraj, after Kurinnaxx"},
	},
	[59] = { -- Thorium Brotherhood
		{ name = "Lokhtos Darkbargainer", place = "Blackrock Depths, Grim Guzzler" },
	},
	[576] = { -- Timbermaw Hold
		{ name = "Meilosh", place = "Timbermaw Hold, Felwood", map = 1448, x = 64.9, y = 5.2 },
		{ name = "Gorn One Eye", place = "Timbermaw Hold, Felwood", map = 1448, x = 64.9, y = 5.2 },
	},
	[270] = { -- Zandalar Tribe
		{ name = "Rin'wosho the Trader", place = "Yojamba Isle, Stranglethorn Vale", map = 1434, altMaps = { 50 }, x = 15.1, y = 16.0 },
	},
	[910] = { -- Brood of Nozdormu
		{ name = "Andorgos, Vethsera, and Kandrostrasz", place = "Temple of Ahn'Qiraj, after C'Thun" },
	},
	[589] = { -- Wintersaber Trainers
		{ name = "Rivern Frostwind", place = "Frostsaber Rock, Winterspring", map = 1452, x = 49.8, y = 9.8, side = "Alliance" },
	},
	[809] = { -- Shen'dralar
		{ name = "Lorekeeper Lydros", place = "Dire Maul library, Feralas", map = 1444, x = 59.1, y = 43.8 },
	},
	[93] = { -- Magram Clan Centaur
		{ name = "Gorhak", place = "Magram Village, Desolace", map = 1443, x = 66.2, y = 79.4 },
	},
	[92] = { -- Gelkis Clan Centaur
		{ name = "Molkar", place = "Gelkis Village, Desolace", map = 1443, x = 35.6, y = 92.0 },
	},
	[509] = { -- The League of Arathor
		{ name = "Samuel Hawke", place = "Refuge Pointe, Arathi Highlands", map = 1417, x = 45.9, y = 46.6, side = "Alliance" },
	},
	[510] = { -- The Defilers
		{ name = "Rutherford Twing", place = "Hammerfall, Arathi Highlands", map = 1417, x = 73.4, y = 33.8, side = "Horde" },
	},
	[730] = { -- Stormpike Guard
		{ name = "Thanthaldis Snowgleam", place = "Alterac Mountains, Alterac Valley entrance", map = 1416, x = 39.4, y = 81.6, side = "Alliance" },
		{ name = "Gaelden Hammersmith", place = "Stormpike Aid Station, inside Alterac Valley", side = "Alliance" },
	},
	[729] = { -- Frostwolf Clan
		{ name = "Jekyll Flandring", place = "Alterac Mountains, Alterac Valley entrance", map = 1416, x = 62.2, y = 58.6, side = "Horde" },
		{ name = "Grunnda Wolfheart", place = "Frostwolf Village, inside Alterac Valley", side = "Horde" },
	},
	[890] = { -- Silverwing Sentinels
		{ name = "Illiyana Moonblaze", place = "Silverwing Grove, Ashenvale", map = 1440, x = 61.8, y = 83.8, side = "Alliance" },
	},
	[889] = { -- Warsong Outriders
		{ name = "Kelm Hargunth", place = "Mor'shan Base Camp, The Barrens", map = 1413, altMaps = { 10 }, x = 46.6, y = 8.4, side = "Horde" },
	},
	[21] = { -- Booty Bay
		{ name = "Gezzy Gunkgear", place = "Booty Bay, Stranglethorn Vale", map = 1434, altMaps = { 50 }, x = 28.2, y = 74.8 },
	},
	[470] = { -- Ratchet
		{ name = "Winklespark", place = "Ratchet, The Barrens", map = 1413, altMaps = { 10 }, x = 62.5, y = 37.5 },
	},
	[369] = { -- Gadgetzan
		{ name = "Rettrick", place = "Gadgetzan, Tanaris", map = 1446, x = 51.7, y = 28.7 },
	},
	[577] = { -- Everlook
		{ name = "Zippie Fizzbolt", place = "Everlook, Winterspring", map = 1452, x = 61.0, y = 38.4 },
	},
	[2827] = { -- Powderfuse
		{ name = "Friz Frazzlespark", place = "Powderfuse Port, Riverglades", map = 2548, x = 77.1, y = 52.8 },
	},
	[2758] = { -- Nightclaw Druids
		{ name = "Vayn Moongaze", place = "Nightclaw Cavern, Zephras Isle", map = 2521, x = 63.8, y = 36.0 },
	},
    [2787] = { -- Earthen Ring
        { name = "Sutara Plainstalker", place = "Skywatcher Plateau, Mulgore", map = 1412, x= 33.4, y = 22.4, side = "Horde" },
    },
	[2586] = { -- Azeroth Commerce Authority
		{ name = "Supply vendors", place = "Three Corners, Redridge Mountains", map = 1433, x = 10.5, y = 72.7, side = "Alliance" },
	},
	[2587] = { -- Durotar Supply and Logistics
		{ name = "Supply vendors", place = "Outside the Crossroads, The Barrens", map = 1413, x = 50.0, y = 29.3, side = "Horde" },
	},
}

function RepRewards_Data.VendorsFor(factionID)
	local list = RepRewards_Data.vendors[tonumber(factionID) or 0]
	if not list then return {} end
	local side = UnitFactionGroup and UnitFactionGroup("player")
	local out = {}
	for _, vendor in ipairs(list) do
		if not vendor.side or vendor.side == side then
			out[#out + 1] = vendor
		end
	end
	return out
end

-------------------------------------------------------------------------
-- Faction catalog
-- id: Wowhead / client faction ID
-- side: "Alliance" | "Horde" | "Neutral"
-- category: grouping for the tree
-- forever: new in WoW Forever
-- maxStanding: optional cap (e.g. Earthen Ring stops at Honored)
-------------------------------------------------------------------------

RepRewards_Data.factions = {
	-- Cities / home (Alliance / Horde parent reps live here too)
	[469] = { name = "Alliance", side = "Alliance", category = "Cities", icon = "Interface\\Icons\\inv_bannerpvp_02",
		rewards = expand({
			R(270868, S.NEUTRAL), -- Dwarven Tradeskill Signpost
		}),
	},
	[67] = { name = "Horde", side = "Horde", category = "Cities", icon = "Interface\\Icons\\inv_bannerpvp_01",
		rewards = expand({
			R(270870, S.NEUTRAL), -- Orcish Tradeskill Signpost
			-- R(20310, S.NEUTRAL), -- Flayed Demon Skin
		}),
	},
	[72]  = { name = "Stormwind", side = "Alliance", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_human" },
	[47]  = { name = "Ironforge", side = "Alliance", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_dwarf" },
	[54]  = { name = "Gnomeregan Exiles", side = "Alliance", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_gnome" },
	[69]  = { name = "Darnassus", side = "Alliance", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_nightelf" },
	[76]  = { name = "Orgrimmar", side = "Horde", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_orc" },
	[81]  = { name = "Thunder Bluff", side = "Horde", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_tauren" },
	[68]  = { name = "Undercity", side = "Horde", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_scourge" },
	[530] = { name = "Darkspear Trolls", side = "Horde", category = "Cities", icon = "Interface\\Icons\\inv_misc_tournaments_banner_troll" },

	-- Steamwheedle
	[21]  = { name = "Booty Bay", side = "Neutral", category = "Steamwheedle Cartel", forever = false, icon = "Interface\\Icons\\inv_misc_coin_02",
		rewards = expand({
			R(274745, S.FRIENDLY), -- Deckswabber's Mitts
			R(274746, S.FRIENDLY), -- Sea Giant's Toe Ring
			R(274747, S.FRIENDLY), -- Soggy Boots
			R(274748, S.HONORED), -- Booty Bay Bruiser's Buckshot
			R(274749, S.HONORED), -- Souvenir Sea Shell
			R(274022, S.REVERED), -- Tough Guy's Eyepatch
		}),
	},
	[369] = { name = "Gadgetzan", side = "Neutral", category = "Steamwheedle Cartel", icon = "Interface\\Icons\\inv_misc_gear_01",
		rewards = expand({
			R(274750, S.FRIENDLY), -- Reflective Wristguards
			R(274752, S.FRIENDLY), -- Sandstorm Cover
			R(274751, S.FRIENDLY), -- Sunburn Spaulders
			R(274753, S.HONORED), -- Jhordy's Misplaced Screwdriver
			R(274754, S.HONORED), -- Suspicious Spare Part
			R(274023, S.REVERED), -- Stolen Wastewander Cowl
		}),
	},
	[470] = { name = "Ratchet", side = "Neutral", category = "Steamwheedle Cartel", icon = "Interface\\Icons\\inv_misc_coin_01",
    desc = "Part of the Steamwheedle Cartel, this goblin city provides a neutral haven for those that wish to trade goods and services in the Barrens.",
		rewards = expand({
			R(274740, S.FRIENDLY), -- Quilted Cloak
			R(274742, S.FRIENDLY), -- Ratchet Wristwraps
			R(274741, S.FRIENDLY), -- Rumpled Kilt
			R(274744, S.HONORED), -- Barrens Basher
			R(274743, S.HONORED), -- Defective Samophlange
			R(274021, S.REVERED), -- Barrens Headband
		}),
	},
	[577] = { name = "Everlook", side = "Neutral", category = "Steamwheedle Cartel", icon = "Interface\\Icons\\inv_misc_statue_07",
		rewards = expand({
			R(274758, S.FRIENDLY), -- Coldmetal Guard
			R(274756, S.FRIENDLY), -- Impractical Headwarmer
			R(274755, S.FRIENDLY), -- Steamwheedle Grips
			R(274757, S.FRIENDLY), -- Substandard Belt Chain
			R(274760, S.HONORED), -- Everlook Delivery Bot
			R(274759, S.HONORED), -- Everlook Pathcarver
			R(274761, S.HONORED), -- Parachute-Priest Pager
			R(274024, S.REVERED), -- Fizzbolt's Fashionable Fedora
		}),
	},
	[2827] = { name = "Powderfuse", side = "Neutral", category = "Steamwheedle Cartel", forever = true, icon = "Interface\\Icons\\inv_misc_bomb_02",
		desc = "A strong arm of the Steamwheedle Cartel, this port is home to seafaring sailors and back-alley dealers spanning the eastern sea trading routes.",
		rewards = expand({
			R(276200, S.FRIENDLY), -- Crawler's Clackers
			R(276202, S.FRIENDLY), -- Disengagement Ring
			R(276201, S.FRIENDLY), -- Misplaced Pantaloons
			R(276203, S.HONORED), -- Primitive Fishing Pole
			R(276204, S.HONORED), -- Thrash's Trash
			R(276199, S.REVERED), -- Haughty Fellow's Monocle
		}),
	},

	-- PvP
	[509] = { name = "The League of Arathor", side = "Alliance", category = "PvP", icon = "Interface\\Icons\\inv_jewelry_amulet_07",
		rewards = expand({
			R(21119, S.FRIENDLY), -- Talisman of Arathor
			R(20225, S.FRIENDLY), -- Highlander's Enriched Ration
			R(20226, S.FRIENDLY), -- Highlander's Field Ration
			R(20227, S.FRIENDLY), -- Highlander's Iron Ration
			R(20237, S.FRIENDLY), -- Highlander's Mageweave Bandage
			R(20243, S.FRIENDLY), -- Highlander's Runecloth Bandage
			R(20244, S.FRIENDLY), -- Highlander's Silk Bandage
			R(20090, S.HONORED), -- Highlander's Chain Girdle
			R(20099, S.HONORED), -- Highlander's Cloth Girdle
			R(20108, S.HONORED), -- Highlander's Lamellar Girdle
			R(20117, S.HONORED), -- Highlander's Leather Girdle
			R(20105, S.HONORED), -- Highlander's Lizardhide Girdle
			R(20044, S.HONORED), -- Highlander's Mail Girdle
			R(20126, S.HONORED), -- Highlander's Plate Girdle
			R(20093, S.REVERED), -- Highlander's Chain Greaves
			R(20096, S.REVERED), -- Highlander's Cloth Boots
			R(20111, S.REVERED), -- Highlander's Lamellar Greaves
			R(20114, S.REVERED), -- Highlander's Leather Boots
			R(20102, S.REVERED), -- Highlander's Lizardhide Boots
			R(20051, S.REVERED), -- Highlander's Mail Greaves
			R(20129, S.REVERED), -- Highlander's Plate Greaves
			R(20073, S.EXALTED), -- Cloak of the Honor Guard
			R(20055, S.EXALTED), -- Highlander's Chain Pauldrons
			R(20061, S.EXALTED), -- Highlander's Epaulets
			R(20058, S.EXALTED), -- Highlander's Lamellar Spaulders
			R(20059, S.EXALTED), -- Highlander's Leather Shoulders
			R(20060, S.EXALTED), -- Highlander's Lizardhide Shoulders
			R(20056, S.EXALTED), -- Highlander's Mail Pauldrons
			R(20057, S.EXALTED), -- Highlander's Plate Spaulders
			R(20069, S.EXALTED), -- Ironbark Staff
			R(20070, S.EXALTED), -- Sageclaw
			R(20132, S.EXALTED), -- Arathor Battle Tabard
		}),
	},
	[510] = { name = "The Defilers", side = "Horde", category = "PvP", icon = "Interface\\Icons\\inv_jewelry_amulet_07",
		rewards = expand({
			R(21120, S.FRIENDLY), -- Defiler's Talisman
			R(20222, S.FRIENDLY), -- Defiler's Enriched Ration
			R(20223, S.FRIENDLY), -- Defiler's Field Ration
			R(20224, S.FRIENDLY), -- Defiler's Iron Ration
			R(20232, S.FRIENDLY), -- Defiler's Mageweave Bandage
			R(20234, S.FRIENDLY), -- Defiler's Runecloth Bandage
			R(20235, S.FRIENDLY), -- Defiler's Silk Bandage
			R(20150, S.HONORED), -- Defiler's Chain Girdle
            R(20151, S.HONORED), -- Defiler's Chain Girdle
            R(20152, S.HONORED), -- Defiler's Chain Girdle
            R(20153, S.HONORED), -- Defiler's Chain Girdle
			R(20166, S.HONORED), -- Defiler's Cloth Girdle
			R(20190, S.HONORED), -- Defiler's Leather Girdle
            R(20191, S.HONORED), -- Defiler's Leather Girdle
            R(20192, S.HONORED), -- Defiler's Leather Girdle
            R(20193, S.HONORED), -- Defiler's Leather Girdle
			R(20171, S.HONORED), -- Defiler's Lizardhide Girdle
            R(20172, S.HONORED), -- Defiler's Lizardhide Girdle
            R(20173, S.HONORED), -- Defiler's Lizardhide Girdle
            R(20174, S.HONORED), -- Defiler's Lizardhide Girdle
			R(20195, S.HONORED), -- Defiler's Mail Girdle
			R(20196, S.HONORED), -- Defiler's Mail Girdle
			R(20197, S.HONORED), -- Defiler's Mail Girdle
			R(20198, S.HONORED), -- Defiler's Mail Girdle
            R(20204, S.HONORED), -- Defiler's Plate Girdle
            R(20205, S.HONORED), -- Defiler's Plate Girdle
            R(20206, S.HONORED), -- Defiler's Plate Girdle
			R(20207, S.HONORED), -- Defiler's Plate Girdle
			R(20154, S.REVERED), -- Defiler's Chain Greaves
            R(20155, S.REVERED), -- Defiler's Chain Greaves
            R(20156, S.REVERED), -- Defiler's Chain Greaves
            R(20157, S.REVERED), -- Defiler's Chain Greaves
			R(20159, S.REVERED), -- Defiler's Cloth Boots
            R(20160, S.REVERED), -- Defiler's Cloth Boots
            R(20161, S.REVERED), -- Defiler's Cloth Boots
            R(20162, S.REVERED), -- Defiler's Cloth Boots
			R(20186, S.REVERED), -- Defiler's Leather Boots
            R(20187, S.REVERED), -- Defiler's Leather Boots
            R(20188, S.REVERED), -- Defiler's Leather Boots
            R(20189, S.REVERED), -- Defiler's Leather Boots
			R(20167, S.REVERED), -- Defiler's Lizardhide Boots
            R(20168, S.REVERED), -- Defiler's Lizardhide Boots
            R(20169, S.REVERED), -- Defiler's Lizardhide Boots
            R(20170, S.REVERED), -- Defiler's Lizardhide Boots
			R(20199, S.REVERED), -- Defiler's Mail Greaves
            R(20200, S.REVERED), -- Defiler's Mail Greaves
            R(20201, S.REVERED), -- Defiler's Mail Greaves
            R(20202, S.REVERED), -- Defiler's Mail Greaves
			R(20208, S.REVERED), -- Defiler's Plate Greaves
            R(20209, S.REVERED), -- Defiler's Plate Greaves
            R(20210, S.REVERED), -- Defiler's Plate Greaves
            R(20211, S.REVERED), -- Defiler's Plate Greaves
			R(20068, S.EXALTED), -- Deathguard's Cloak
			R(20158, S.EXALTED), -- Defiler's Chain Pauldrons
			R(20176, S.EXALTED), -- Defiler's Epaulets
			R(20194, S.EXALTED), -- Defiler's Leather Shoulders
			R(20175, S.EXALTED), -- Defiler's Lizardhide Shoulders
			R(20203, S.EXALTED), -- Defiler's Mail Pauldrons
			R(20212, S.EXALTED), -- Defiler's Plate Spaulders
			R(20220, S.EXALTED), -- Ironbark Staff
			R(20214, S.EXALTED), -- Mindfang
			R(20131, S.EXALTED), -- Battle Tabard of the Defilers
		}),
	},
	[730] = { name = "Stormpike Guard", side = "Alliance", category = "PvP", icon = "Interface\\Icons\\inv_jewelry_frostwolftrinket_01" },
	[729] = { name = "Frostwolf Clan", side = "Horde", category = "PvP", icon = "Interface\\Icons\\inv_jewelry_frostwolftrinket_01" },
	[890] = { name = "Silverwing Sentinels", side = "Alliance", category = "PvP", icon = "Interface\\Icons\\ability_racial_shadowmeld" },
	[889] = { name = "Warsong Outriders", side = "Horde", category = "PvP", icon = "Interface\\Icons\\ability_warrior_warcry" },
	[2799] = { name = "Theramore Expeditionary Force", side = "Alliance", category = "PvP", forever = true, icon = "Interface\\Icons\\inv_bannerpvp_02",
		desc = "Loyal partisans for their city; battles the Darkspear Raiders for Darkspear Islands.",
		rewards = expand({
			R(271905, S.FRIENDLY), -- Enriched Seal
            R(271903, S.FRIENDLY), -- Enriched Seal
			R(271904, S.FRIENDLY), -- Volunteer's Lucky Seal
            R(271906, S.FRIENDLY), -- Volunteer's Lucky Seal
			R(271907, S.HONORED), -- Expeditionary's Cape
            R(271921, S.HONORED), -- Expeditionary's Cape
			R(271922, S.HONORED), -- Expeditionary's Cape
            R(271923, S.HONORED), -- Expeditionary's Cape
			R(271913, S.HONORED), -- Militant's Band
            R(271914, S.HONORED), -- Militant's Band
            R(271915, S.HONORED), -- Militant's Band
            R(271916, S.HONORED), -- Militant's Band
			R(271917, S.HONORED), -- Seal of the Expedition
            R(271918, S.HONORED), -- Seal of the Expedition
            R(271919, S.HONORED), -- Seal of the Expedition
            R(271920, S.HONORED), -- Seal of the Expedition
			R(271908, S.HONORED), -- Theramore Signet
            R(271909, S.HONORED), -- Theramore Signet
            R(271910, S.HONORED), -- Theramore Signet
            R(271911, S.HONORED), -- Theramore Signet
			R(271928, S.REVERED), -- Clever Expeditionary's Spellblade
            R(271929, S.REVERED), -- Clever Expeditionary's Spellblade
            R(271930, S.REVERED), -- Clever Expeditionary's Spellblade
            R(271931, S.REVERED), -- Clever Expeditionary's Spellblade
			R(271936, S.REVERED), -- Guerrilla's Jagged Mace
            R(271937, S.REVERED), -- Guerrilla's Jagged Mace
            R(271938, S.REVERED), -- Guerrilla's Jagged Mace
            R(271939, S.REVERED), -- Guerrilla's Jagged Mace
			R(271932, S.REVERED), -- Insurgent's Manifesto
            R(271933, S.REVERED), -- Insurgent's Manifesto
            R(271934, S.REVERED), -- Insurgent's Manifesto
            R(271935, S.REVERED), -- Insurgent's Manifesto
			R(271924, S.REVERED), -- Rebels' Rugged Reaper
            R(271925, S.REVERED), -- Rebels' Rugged Reaper
            R(271926, S.REVERED), -- Rebels' Rugged Reaper
            R(271927, S.REVERED), -- Rebels' Rugged Reaper
			R(271956, S.EXALTED), -- Theramore Epaulets
			R(271940, S.EXALTED), -- Theramore Gauntlets    
			R(271941, S.EXALTED), -- Theramore Gauntlets    
			R(271948, S.EXALTED), -- Theramore Gloves
            R(271949, S.EXALTED), -- Theramore Gloves
			R(271950, S.EXALTED), -- Theramore Handguards
            R(271951, S.EXALTED), -- Theramore Handguards
			R(271945, S.EXALTED), -- Theramore Handwraps
            R(271946, S.EXALTED), -- Theramore Handwraps
			R(271957, S.EXALTED), -- Theramore Mantle
			R(271955, S.EXALTED), -- Theramore Pauldrons
			R(272957, S.EXALTED), -- Theramore Shoulderguards
			R(271953, S.EXALTED), -- Theramore Shoulderguards
			R(271954, S.EXALTED), -- Theramore Shoulders
			R(271959, S.EXALTED), -- Theramore Spaulders
			R(276504, S.EXALTED), -- Theramore Battle Tabard
		}),
	},
	[2798] = { name = "Darkspear Raiders", side = "Horde", category = "PvP", forever = true, icon = "Interface\\Icons\\inv_bannerpvp_01",
		desc = "Loyal to the troll nation; battles the Theramore Expeditionary Force for Darkspear Islands.",
		rewards = expand({
			R(272061, S.FRIENDLY), -- Darkspear Voodoo Seal
			R(272062, S.FRIENDLY), -- Relentless Raider's Seal
			R(272055, S.FRIENDLY), -- Darkspear Islands Enriched Ration
			R(272053, S.FRIENDLY), -- Darkspear Islands Field Ration
			R(272054, S.FRIENDLY), -- Darkspear Islands Iron Ration
			R(272057, S.FRIENDLY), -- Darkspear Islands Mageweave Bandage
			R(272058, S.FRIENDLY), -- Darkspear Islands Runecloth Bandage
			R(272056, S.FRIENDLY), -- Darkspear Islands Silk Bandage
			R(17349, S.FRIENDLY), -- Superior Healing Draught
			R(17352, S.FRIENDLY), -- Superior Mana Draught
			R(272078, S.HONORED), -- Darkspear Raider's Cloak
			R(272071, S.HONORED), -- Darkspear Signet
			R(272075, S.HONORED), -- Darkspear Warding Pendant
			R(272067, S.HONORED), -- Insurgent's Band
			R(17348, S.HONORED), -- Major Healing Draught
			R(17351, S.HONORED), -- Major Mana Draught
			R(272086, S.REVERED), -- Darkspear Insurgent's Spellblade
			R(272082, S.REVERED), -- Darkspear Raider's Reaper
			R(272094, S.REVERED), -- Darkspear Skirmisher's Bludgeon
			R(272090, S.REVERED), -- Tome of the Darkspear Prophecy
			R(272106, S.EXALTED), -- Darkspear Epaulets
			R(272107, S.EXALTED), -- Darkspear Mantle
			R(272105, S.EXALTED), -- Darkspear Pauldrons
			R(272958, S.EXALTED), -- Darkspear Shoulderguards
			R(272103, S.EXALTED), -- Darkspear Shoulderpads
			R(272104, S.EXALTED), -- Darkspear Shoulders
			R(272108, S.EXALTED), -- Darkspear Spaulders
			R(272096, S.EXALTED), -- Raider Gauntlets
			R(272100, S.EXALTED), -- Raider Gloves
			R(272102, S.EXALTED), -- Raider Handguards
			R(272098, S.EXALTED), -- Raider Handwraps
			R(276502, S.EXALTED), -- Darkspear Battle Tabard
		}),
	},

	-- Profession / supply
	[2586] = { name = "Azeroth Commerce Authority", side = "Alliance", category = "Professions", forever = true, icon = "Interface\\Icons\\inv_misc_coin_17",
		desc = "Alliance supply faction. Earn Merchant's Favor from Waylaid Crates and Craftsman's Writs. Vendors sell recipes, a mount, pet, toy, and titles. Recipes require Neutral; tabard/license are reputation-gated.",
		-- rewards filled by RepRewardsMerchantFavor.lua
	},
	[2587] = { name = "Durotar Supply and Logistics", side = "Horde", category = "Professions", forever = true, icon = "Interface\\Icons\\inv_misc_coin_15",
		desc = "Horde supply faction. Earn Merchant's Favor from Waylaid Crates and Craftsman's Writs. Recipes require Neutral; tabard/license are reputation-gated.",
		-- rewards filled by RepRewardsMerchantFavor.lua
	},

	-- Classic world factions
	[529] = { name = "Argent Dawn", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_jewelry_talisman_08",
		rewards = expand({
			R(13724, S.FRIENDLY), -- Enriched Manna Biscuit
			R(13482, S.HONORED), -- Recipe: Transmute Air to Fire
			R(227813, S.HONORED), -- Drinkable Stratholme Holy Water
			R(19446, S.HONORED), -- Formula: Enchant Bracer - Mana Regeneration
			R(19442, S.HONORED), -- Formula: Powerful Anti-Venom
			R(22014, S.HONORED), -- Hallowed Brazier
			R(19216, S.HONORED), -- Pattern: Argent Boots
			R(19328, S.HONORED), -- Pattern: Dawn Treaders
			R(19203, S.HONORED), -- Plans: Girdle of the Dawn
			R(1164, S.HONORED), -- Sam's Tome
			R(12698, S.REVERED), -- Plans: Dawnbringer Shoulders
			R(13810, S.REVERED), -- Blessed Sunfruit
			R(13813, S.REVERED), -- Blessed Sunfruit Juice
			R(19447, S.REVERED), -- Formula: Enchant Bracer - Healing
			R(19217, S.REVERED), -- Pattern: Argent Shoulders
			R(19329, S.REVERED), -- Pattern: Golden Mantle of the Dawn
			R(19205, S.REVERED), -- Plans: Gloves of the Dawn
			R(22690, S.REVERED), -- Leggings of the Plague Hunter
			R(22691, S.EXALTED), -- Plans: Icebane Breastplate
		}),
	},
	[609] = { name = "Cenarion Circle", side = "Neutral", category = "World", icon = "Interface\\Icons\\ability_druid_manatree",
		rewards = expand({
			R(275586, S.FRIENDLY), -- Pattern: Bileblister Claws
			R(275595, S.FRIENDLY), -- Pattern: Broodwatcher's Clenchers
			R(275589, S.FRIENDLY), -- Pattern: Hivethrasher's Claws
			R(275592, S.FRIENDLY), -- Pattern: Scalegut Clenchers
			R(275583, S.FRIENDLY), -- Pattern: Swarmtender's Gloves
			R(275580, S.FRIENDLY), -- Pattern: Venomspew Gloves
			R(275601, S.FRIENDLY), -- Plans: Clutchlord's Grips
			R(275598, S.FRIENDLY), -- Plans: Goregasher Grips
			R(234272, S.FRIENDLY), -- Formula: Enchanted Repellent
			R(234271, S.FRIENDLY), -- Formula: Scroll: Wrath of the Swarm
			R(20732, S.FRIENDLY), -- Formula: Enchant Cloak - Greater Fire Resistance
			R(22310, S.FRIENDLY), -- Pattern: Cenarion Herb Bag
			R(22772, S.FRIENDLY), -- Pattern: Sylvan Shoulders
			R(275588, S.HONORED), -- Pattern: Bileblister Boots
			R(275587, S.HONORED), -- Pattern: Bileblister Girdle
			R(275596, S.HONORED), -- Pattern: Broodwatcher's Belt
			R(275597, S.HONORED), -- Pattern: Broodwatcher's Treaders
			R(275591, S.HONORED), -- Pattern: Hivethrasher's Boots
			R(275590, S.HONORED), -- Pattern: Hivethrasher's Girdle
			R(275593, S.HONORED), -- Pattern: Scalegut Belt
			R(275594, S.HONORED), -- Pattern: Scalegut Treaders
			R(275584, S.HONORED), -- Pattern: Swarmtender's Cord
			R(275585, S.HONORED), -- Pattern: Swarmtender's Footpads
			R(275581, S.HONORED), -- Pattern: Venomspew Cord
			R(275582, S.HONORED), -- Pattern: Venomspew Footpads
			R(275603, S.HONORED), -- Plans: Clutchlord's Stompers
			R(275602, S.HONORED), -- Plans: Clutchlord's Support
			R(275600, S.HONORED), -- Plans: Goregasher Stompers
			R(275599, S.HONORED), -- Plans: Goregasher Support
			R(20733, S.HONORED), -- Formula: Enchant Cloak - Greater Nature Resistance
			R(22773, S.HONORED), -- Pattern: Sylvan Crown
			R(22683, S.REVERED), -- Pattern: Gaea's Embrace
			R(22312, S.REVERED), -- Pattern: Satchel of Cenarius
			R(22774, S.REVERED), -- Pattern: Sylvan Vest
			R(22195, S.REVERED), -- Light Obsidian Belt
			R(22194, S.EXALTED), -- Black Grasp of the Destroyer
		}),
	},
	[59] = { name = "Thorium Brotherhood", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_armorkit_08",
		rewards = expand({
			R(17051, S.FRIENDLY), -- Plans: Dark Iron Bracers
			R(19444, S.FRIENDLY), -- Formula: Enchant Weapon - Strength
			R(17022, S.FRIENDLY), -- Pattern: Corehound Boots
			R(17018, S.FRIENDLY), -- Pattern: Flarecore Gloves
			R(17023, S.FRIENDLY), -- Pattern: Molten Helm
			R(20761, S.FRIENDLY), -- Recipe: Transmute Elemental Fire
			R(17060, S.HONORED), -- Plans: Dark Iron Destroyer
			R(17059, S.HONORED), -- Plans: Dark Iron Reaver
			R(17049, S.HONORED), -- Plans: Fiery Chain Girdle
			R(229008, S.HONORED), -- Formula: Enchant Cloak - Greater Fire Resistance
			R(229009, S.HONORED), -- Formula: Enchant Cloak - Greater Nature Resistance
			R(19448, S.HONORED), -- Formula: Enchant Weapon - Mighty Spirit
			R(17025, S.HONORED), -- Pattern: Black Dragonscale Boots
			R(17017, S.HONORED), -- Pattern: Flarecore Mantle
			R(19219, S.HONORED), -- Pattern: Flarecore Robe
			R(19330, S.HONORED), -- Pattern: Lava Belt
			R(19206, S.HONORED), -- Plans: Dark Iron Helm
			R(17052, S.REVERED), -- Plans: Dark Iron Leggings
			R(17053, S.REVERED), -- Plans: Fiery Chain Shoulders
			R(19449, S.REVERED), -- Formula: Enchant Weapon - Mighty Intellect
			R(19331, S.REVERED), -- Pattern: Chromatic Gauntlets
			R(19332, S.REVERED), -- Pattern: Corehound Belt
			R(19220, S.REVERED), -- Pattern: Flarecore Leggings
			R(19333, S.REVERED), -- Pattern: Molten Belt
			R(19208, S.REVERED), -- Plans: Black Amnesty
			R(19209, S.REVERED), -- Plans: Blackfury
			R(19207, S.REVERED), -- Plans: Dark Iron Gauntlets
			R(19211, S.EXALTED), -- Plans: Blackguard
			R(20040, S.EXALTED), -- Plans: Dark Iron Boots
			R(19210, S.EXALTED), -- Plans: Ebon Hand
			R(19212, S.EXALTED), -- Plans: Nightfall
		}),
	},
	[576] = { name = "Timbermaw Hold", side = "Neutral", category = "World", icon = "Interface\\Icons\\ability_druid_demoralizingroar",
		rewards = expand({
			R(13483, S.FRIENDLY), -- Recipe: Transmute Fire to Earth
			R(22392, S.FRIENDLY), -- Formula: Enchant 2H Weapon - Agility
			R(20253, S.FRIENDLY), -- Pattern: Warbear Harness
			R(20254, S.FRIENDLY), -- Pattern: Warbear Woolies
			R(19445, S.HONORED), -- Formula: Enchant Weapon - Agility
			R(19202, S.HONORED), -- Pattern: Heavy Timbermaw Belt
			R(19215, S.HONORED), -- Pattern: Wisdom of the Timbermaw
			R(19218, S.HONORED), -- Pattern: Mantle of the Timbermaw
			R(228982, S.REVERED), -- Formula: Enchant Shield - Law of Nature
			R(251470, S.REVERED), -- Plans: Bagh Nakh
			R(251469, S.REVERED), -- Plans: Stormcarver
			R(19204, S.REVERED), -- Pattern: Heavy Timbermaw Boots
			R(19219, S.REVERED), -- Pattern: Flarecore Robe
			R(19326, S.REVERED), -- Pattern: Might of the Timbermaw
			R(21326, S.EXALTED), -- Defender of the Timbermaw
		}),
	},
	[270] = { name = "Zandalar Tribe", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_coin_08",
		rewards = expand({
			R(20726, S.FRIENDLY), -- Formula: Enchant Gloves - Threat
			R(19784, S.FRIENDLY), -- Death's Embrace
			R(19771, S.FRIENDLY), -- Pattern: Primal Batskin Bracers
			R(19776, S.FRIENDLY), -- Plans: Bloodsoul Breastplate
			R(19779, S.FRIENDLY), -- Plans: Darksoul Breastplate
			R(20012, S.FRIENDLY), -- Recipe: Greater Dreamless Sleep
			R(20000, S.FRIENDLY), -- Schematic: Bloodvine Goggles
			R(20731, S.HONORED), -- Formula: Enchant Gloves - Superior Agility
			R(232610, S.HONORED), -- Formula: Magnificent Trollshine
			R(19772, S.HONORED), -- Pattern: Blood Tiger Breastplate
			R(19785, S.HONORED), -- Falcon's Call
			R(19773, S.HONORED), -- Pattern: Blood Tiger Shoulders
			R(19777, S.HONORED), -- Plans: Bloodsoul Shoulders
			R(19780, S.HONORED), -- Plans: Darksoul Leggings
			R(20011, S.HONORED), -- Recipe: Mageblood Elixir
			R(20001, S.HONORED), -- Schematic: Bloodvine Lens
			R(19770, S.REVERED), -- Pattern: Primal Batskin Gloves
			R(19786, S.REVERED), -- Vodouisant's Vigilant Embrace
			R(19774, S.REVERED), -- Souldarite
			R(19778, S.REVERED), -- Plans: Bloodsoul Gauntlets
			R(19781, S.REVERED), -- Plans: Darksoul Shoulders
			R(20013, S.REVERED), -- Recipe: Living Action Potion
			R(20014, S.EXALTED), -- Recipe: Major Troll's Blood Elixir
		}),
	},
	[749] = { name = "Hydraxian Waterlords", side = "Neutral", category = "World", icon = "Interface\\Icons\\spell_frost_summonwaterelemental",
		rewards = expand({
			R(228979, S.REVERED), -- Enchanted Sigil: Flowing Waters
			R(22689, S.REVERED), -- Sanctified Leather Helm
		}),
	},
	[910] = { name = "Brood of Nozdormu", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_head_dragon_bronze",
		rewards = expand({
			R(21196, S.NEUTRAL, { note = "Rank upgrades through Exalted" }), -- Signet Ring of the Bronze Dragonflight
			R(21197, S.FRIENDLY), -- Signet Ring of the Bronze Dragonflight
			R(21198, S.HONORED), -- Signet Ring of the Bronze Dragonflight
			R(21199, S.REVERED), -- Signet Ring of the Bronze Dragonflight
			R(21200, S.EXALTED), -- Signet Ring of the Bronze Dragonflight
		}),
	},
	[87]  = { name = "Bloodsail Buccaneers", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_head_human_02" },
	[92]  = { name = "Gelkis Clan Centaur", side = "Neutral", category = "World", icon = "Interface\\Icons\\ability_warstomp",
		-- Sold by Gorhak (Magram) and Molkar (Gelkis). Each pattern requires both factions.
		rewards = expand({
			R(249486, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Formula: Enchant Bracer - Lesser Agility
			R(249489, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Formula: Enchant Bracer - Lesser Healing Power
			R(252833, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Pattern: Mystic Thick Armor Kit
			R(253974, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Pattern: Silk Reagent Bag
			R(254682, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Pattern: Stormcloth Gloves
			R(274491, S.HONORED, { note = "Also Exalted with Magram Clan Centaur" }), -- Pattern: Centaur Hoofwarmers
			R(250979, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Recipe: Greater Spellblasting Potion
			R(250985, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Recipe: Greater Frenzy Potion
			R(251390, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Plans: Hard Gold Gauntlet
			R(251458, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Plans: Iron Morningstar
			R(269901, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Schematic: Centaur Banner Deployment Device
			R(269903, S.EXALTED, { note = "Also Honored with Magram Clan Centaur" }), -- Schematic: Hoof-Shaped Foot Pedal
		}),
	},
	[93]  = { name = "Magram Clan Centaur", side = "Neutral", category = "World", icon = "Interface\\Icons\\ability_warstomp",
		rewards = expand({
			R(250979, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Recipe: Greater Spellblasting Potion
			R(250985, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Recipe: Greater Frenzy Potion
			R(251390, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Plans: Hard Gold Gauntlet
			R(251458, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Plans: Iron Morningstar
			R(269901, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Schematic: Centaur Banner Deployment Device
			R(269903, S.HONORED, { note = "Also Exalted with Gelkis Clan Centaur" }), -- Schematic: Hoof-Shaped Foot Pedal
			R(249486, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Formula: Enchant Bracer - Lesser Agility
			R(249489, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Formula: Enchant Bracer - Lesser Healing Power
			R(252833, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Pattern: Mystic Thick Armor Kit
			R(253974, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Pattern: Silk Reagent Bag
			R(254682, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Pattern: Stormcloth Gloves
			R(274491, S.EXALTED, { note = "Also Honored with Gelkis Clan Centaur" }), -- Pattern: Centaur Hoofwarmers
		}),
	},
	[349] = { name = "Ravenholdt", side = "Neutral", category = "World", icon = "Interface\\Icons\\ability_stealth" },
	[70]  = { name = "Syndicate", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_head_human_01" },
	[809] = { name = "Shen'dralar", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_book_06" },
	[909] = { name = "Darkmoon Faire", side = "Neutral", category = "World", icon = "Interface\\Icons\\inv_misc_ticket_darkmoon_01" },
	[589] = { name = "Wintersaber Trainers", side = "Alliance", category = "World", icon = "Interface\\Icons\\ability_hunter_pet_cat" },
	[630] = { name = "Ravasaur Trainers", side = "Horde", category = "World", icon = "Interface\\Icons\\ability_hunter_pet_raptor" },
	[471] = { name = "Wildhammer Clan", side = "Alliance", category = "World", icon = "Interface\\Icons\\inv_misc_head_dwarf_01" },
	[2641] = { name = "Emerald Wardens", side = "Neutral", category = "World", icon = "Interface\\Icons\\spell_nature_protectionformnature" },

	-- Forever world / zone factions
	[2719] = { name = "Cenarion Scouts", side = "Neutral", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_druid_treeoflife",
		desc = "Young nature enthusiasts dedicated to exploring and protecting the wilds of Azeroth." },
	[2740] = { name = "Kirin Tor", side = "Alliance", category = "Forever", forever = true, icon = "Interface\\Icons\\inv_misc_tournaments_symbol_human",
		desc = "An elite cadre of wizards leading the magical nation of Dalaran.",
		rewards = expand({
			R(276986, S.FRIENDLY), -- Pattern: Azure Gustwoven Hood
			R(276987, S.FRIENDLY), -- Pattern: Azure Gustwoven Spaulders
			R(276990, S.FRIENDLY), -- Pattern: Azure Stormsewn Cowl
			R(276991, S.FRIENDLY), -- Pattern: Azure Stormsewn Epaulets
			R(276988, S.FRIENDLY), -- Pattern: Azure Windraveled Cover
			R(276989, S.FRIENDLY), -- Pattern: Azure Windraveled Drapes
			R(276984, S.FRIENDLY), -- Plans: Azure Skyforged Helm
			R(276985, S.FRIENDLY), -- Plans: Azure Skyforged Pauldrons
			R(28532, S.EXALTED), -- Kirin Tor Tabard
		}),
	},
	[2747] = { name = "Barkskin Burrow", side = "Neutral", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_druid_demoralizingroar",
		desc = "Uncorrupted furbolg tribe safeguarding their spiritual heritage on Mount Hyjal." },
	[2758] = { name = "Nightclaw Druids", side = "Neutral", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_druid_catform",
		desc = "Secretive druids of the Shadowgale Forest on Zephras Isle.",
		rewards = expand({
			R(276961, S.FRIENDLY), -- Pattern: Azure Gustwoven Belt
			R(276963, S.FRIENDLY), -- Pattern: Azure Gustwoven Boots
			R(276959, S.FRIENDLY), -- Pattern: Azure Gustwoven Bracers
			R(276960, S.FRIENDLY), -- Pattern: Azure Gustwoven Gloves
			R(276973, S.FRIENDLY), -- Pattern: Azure Stormsewn Cord
			R(276971, S.FRIENDLY), -- Pattern: Azure Stormsewn Cuffs
			R(276972, S.FRIENDLY), -- Pattern: Azure Stormsewn Handwraps
			R(276975, S.FRIENDLY), -- Pattern: Azure Stormsewn Shoes
			R(276965, S.FRIENDLY), -- Pattern: Azure Windraveled Armguards
			R(276969, S.FRIENDLY), -- Pattern: Azure Windraveled Footwraps
			R(276966, S.FRIENDLY), -- Pattern: Azure Windraveled Mitts
			R(276967, S.FRIENDLY), -- Pattern: Azure Windraveled Strap
			R(276937, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Belt
			R(276939, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Boots
			R(276935, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Bracers
			R(276936, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Gloves
			R(276949, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Cord
			R(276947, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Cuffs
			R(276948, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Handwraps
			R(276951, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Shoes
			R(276941, S.FRIENDLY), -- Pattern: Cloudy Windraveled Armguards
			R(276945, S.FRIENDLY), -- Pattern: Cloudy Windraveled Footwraps
			R(276942, S.FRIENDLY), -- Pattern: Cloudy Windraveled Mitts
			R(276943, S.FRIENDLY), -- Pattern: Cloudy Windraveled Strap
			R(276955, S.FRIENDLY), -- Plans: Azure Skyforged Chain
			R(276954, S.FRIENDLY), -- Plans: Azure Skyforged Gauntlets
			R(276957, S.FRIENDLY), -- Plans: Azure Skyforged Greaves
			R(276953, S.FRIENDLY), -- Plans: Azure Skyforged Wristguards
			R(276931, S.FRIENDLY), -- Plans: Cloudy Skyforged Chain
			R(276930, S.FRIENDLY), -- Plans: Cloudy Skyforged Gauntlets
			R(276933, S.FRIENDLY), -- Plans: Cloudy Skyforged Greaves
			R(276929, S.FRIENDLY), -- Plans: Cloudy Skyforged Wristguards
			R(276958, S.HONORED), -- Pattern: Azure Gustwoven Harness
			R(276962, S.HONORED), -- Pattern: Azure Gustwoven Trousers
			R(276974, S.HONORED), -- Pattern: Azure Stormsewn Leggings
			R(276970, S.HONORED), -- Pattern: Azure Stormsewn Vest
			R(276964, S.HONORED), -- Pattern: Azure Windraveled Jerkin
			R(276968, S.HONORED), -- Pattern: Azure Windraveled Pants
			R(276934, S.HONORED), -- Pattern: Cloudy Gustwoven Harness
			R(276938, S.HONORED), -- Pattern: Cloudy Gustwoven Trousers
			R(276950, S.HONORED), -- Pattern: Cloudy Stormsewn Leggings
			R(276946, S.HONORED), -- Pattern: Cloudy Stormsewn Vest
			R(276940, S.HONORED), -- Pattern: Cloudy Windraveled Jerkin
			R(276944, S.HONORED), -- Pattern: Cloudy Windraveled Pants
			R(276952, S.HONORED), -- Plans: Azure Skyforged Chainmail
			R(276956, S.HONORED), -- Plans: Azure Skyforged Legguards
			R(276928, S.HONORED), -- Plans: Cloudy Skyforged Chainmail
			R(276932, S.HONORED), -- Plans: Cloudy Skyforged Legguards
			R(280347, S.REVERED), -- Shadowgale Squirrel
			R(280363, S.EXALTED), -- Nightclaw Mantle
		}),
	},
	[2765] = { name = "Guardians of Hyjal", side = "Neutral", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_druid_forceofnature",
		desc = "Charged with protecting Mount Hyjal; a splinter of the Cenarion Circle.",
		rewards = expand({
			R(274379, S.REVERED), -- Rousing Seed Pod
			R(274025, S.EXALTED), -- Guardians of Hyjal Tabard
		}),
	},
	[2778] = { name = "Windshapers", side = "Horde", category = "Forever", forever = true, icon = "Interface\\Icons\\spell_nature_earthbind",
		desc = "Shamanistic spiritual leaders of the Skyborne people on Zephras Isle." },
	[2779] = { name = "High Order", side = "Alliance", category = "Forever", forever = true, icon = "Interface\\Icons\\spell_arcane_teleportstormwind",
		desc = "Skyborne descendants of Highborne magisters seeking ancient arcane knowledge." },
	[2782] = { name = "Bolder'ok Clan", side = "Horde", category = "Forever", forever = true, icon = "Interface\\Icons\\spell_shadow_twilight",
		desc = "Exiled former Twilight's Hammer members forging their own path in the Riverglades." },
	[2787] = { name = "Earthen Ring", side = "Horde", category = "Forever", forever = true, maxStanding = S.HONORED, icon = "Interface\\Icons\\spell_nature_earthquake",
		desc = "The Earthen Ring is a loose collective of Horde-aligned shamans and druids who seek to maintain and nurture the balance of nature on Azeroth.",
		rewards = expand({
			R(276978, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Hood
			R(276979, S.FRIENDLY), -- Pattern: Cloudy Gustwoven Spaulders
			R(276982, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Cowl
			R(276983, S.FRIENDLY), -- Pattern: Cloudy Stormsewn Epaulets
			R(276980, S.FRIENDLY), -- Pattern: Cloudy Windraveled Cover
			R(276981, S.FRIENDLY), -- Pattern: Cloudy Windraveled Drapes
			R(276976, S.FRIENDLY), -- Plans: Cloudy Skyforged Helm
			R(276977, S.FRIENDLY), -- Plans: Cloudy Skyforged Pauldrons
		}),
	},
	[2819] = { name = "The Watchers", side = "Neutral", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_warrior_revenge",
		desc = "Jailers and marshals of night elf society, guarding an underground prison network.",
		rewards = expand({
			R("Brilliant Watcher's Signet", S.FRIENDLY, { type = "Armor", slot = "Finger", stats = { "Intellect", "Spell Power" }, ilvl = 55 }),
			R("Ferocious Watcher's Signet", S.FRIENDLY, { type = "Armor", slot = "Finger", stats = { "Agility", "Attack Power" }, ilvl = 55 }),
			R("Stalwart Watcher's Signet", S.FRIENDLY, { type = "Armor", slot = "Finger", stats = { "Strength", "Stamina" }, ilvl = 55 }),
			R("Vigilant Watcher's Signet", S.FRIENDLY, { type = "Armor", slot = "Finger", stats = { "Stamina", "Defense" }, ilvl = 55 }),
			R("Brilliant Watcher's Signet", S.HONORED, { type = "Armor", slot = "Finger", stats = { "Intellect", "Spell Power" }, ilvl = 58, note = "Upgraded" }),
			R("Ferocious Watcher's Signet", S.HONORED, { type = "Armor", slot = "Finger", stats = { "Agility", "Attack Power" }, ilvl = 58, note = "Upgraded" }),
			R("Nelanna's Enchanted Jewel", S.HONORED, { type = "Armor", slot = "Trinket", stats = { "Intellect" }, ilvl = 58 }),
			R("Stalwart Watcher's Signet", S.HONORED, { type = "Armor", slot = "Finger", stats = { "Strength", "Stamina" }, ilvl = 58, note = "Upgraded" }),
			R("Vigilant Watcher's Signet", S.HONORED, { type = "Armor", slot = "Finger", stats = { "Stamina", "Defense" }, ilvl = 58, note = "Upgraded" }),
			R("Intricate Filigree", S.HONORED, { type = "Misc" }),
			R("Brilliant Watcher's Signet", S.REVERED, { type = "Armor", slot = "Finger", stats = { "Intellect", "Spell Power" }, ilvl = 60, note = "Upgraded" }),
			R("Ferocious Watcher's Signet", S.REVERED, { type = "Armor", slot = "Finger", stats = { "Agility", "Attack Power" }, ilvl = 60, note = "Upgraded" }),
			R("Stalwart Watcher's Signet", S.REVERED, { type = "Armor", slot = "Finger", stats = { "Strength", "Stamina" }, ilvl = 60, note = "Upgraded" }),
			R("Vigilant Watcher's Signet", S.REVERED, { type = "Armor", slot = "Finger", stats = { "Stamina", "Defense" }, ilvl = 60, note = "Upgraded" }),
			R("Brilliant Watcher's Signet", S.EXALTED, { type = "Armor", slot = "Finger", stats = { "Intellect", "Spell Power" }, ilvl = 60, note = "Max rank" }),
			R("Ferocious Watcher's Signet", S.EXALTED, { type = "Armor", slot = "Finger", stats = { "Agility", "Attack Power" }, ilvl = 60, note = "Max rank" }),
			R("Stalwart Watcher's Signet", S.EXALTED, { type = "Armor", slot = "Finger", stats = { "Strength", "Stamina" }, ilvl = 60, note = "Max rank" }),
			R("Vigilant Watcher's Signet", S.EXALTED, { type = "Armor", slot = "Finger", stats = { "Stamina", "Defense" }, ilvl = 60, note = "Max rank" }),
		}),
	},
	[2826] = { name = "Brotherhood of the Horse", side = "Alliance", category = "Forever", forever = true, icon = "Interface\\Icons\\ability_mount_ridinghorse",
		desc = "Outcast Stormwind cavalry establishing new trade routes along the eastern coast." },
}

-- Category display order
RepRewards_Data.CATEGORY_ORDER = {
	"Forever",
	"Professions",
	"PvP",
	"World",
	"Steamwheedle Cartel",
	"Cities",
	"Other",
}

RepRewards_Data.FILTER_TYPES = {
	"Any", "Armor", "Weapon", "Recipe", "Consumable", "Tabard", "Mount", "Pet", "Toy", "Trinket", "Enchant", "Misc",
}

RepRewards_Data.FILTER_SLOTS = {
	"Any", "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
	"Finger", "Trinket", "One-Hand", "Two-Hand", "Ranged", "Off Hand", "Tabard",
}

RepRewards_Data.FILTER_STATS = {
	"Any", "Strength", "Agility", "Stamina", "Intellect", "Spirit",
	"Attack Power", "Spell Power", "Critical Strike", "Hit", "Defense", "Dodge", "Parry", "Health",
}

RepRewards_Data.FILTER_PROFESSIONS = {
	"Any", "Alchemy", "Blacksmithing", "Cooking", "Enchanting", "Engineering",
	"First Aid", "Leatherworking", "Tailoring",
}
