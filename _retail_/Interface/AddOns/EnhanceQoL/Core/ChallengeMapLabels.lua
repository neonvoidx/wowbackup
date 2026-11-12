local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.functions = addon.functions or {}
addon.variables = addon.variables or {}

-- Locale-specific overrides for short dungeon labels shown in M+ tooltips and frames.
local challengeMapLabelOverrides = {
	deDE = {
		[161] = "Himmelsnadel",
		[239] = "Der Sitz des Triumvirats",
		[402] = "Akademie von Algeth'ar",
		[556] = "Die Grube von Saron",
		[557] = "Windläuferturm",
		[558] = "Terrasse der Magister",
		[559] = "Nexuspunkt Xenas",
		[560] = "Maisarakavernen",
	},
	esES = {
		[402] = "Academia Algeth'ar - AA",
	},
	esMX = {
		[402] = "Academia Algeth'ar - AA",
	},
	frFR = {
		[402] = "AA",
	},
	itIT = {
		[402] = "ADA",
	},
	koKR = {
		[161] = "하늘탑",
		[239] = "삼두정",
		[402] = "대학",
		[556] = "사론",
		[557] = "첨탑",
		[558] = "정원",
		[559] = "제나스",
		[560] = "마이사라",
	},
	ptBR = {
		[402] = "Academia Algeth'ar",
	},
	ruRU = {
		[161] = "Небесный Путь",
		[239] = "Престол Триумвирата",
		[402] = "Академия Алгет'ар",
		[556] = "Яма Сарона",
		[557] = "Шпили Ветрокрылых",
		[558] = "Терраса Магистров",
		[559] = "Узел Нексуса Зенас",
		[560] = "Пещеры Маисара",
	},
	zhCN = {
		[161] = "通天峰",
		[239] = "执政团",
		[402] = "艾杰斯亚",
		[556] = "萨隆",
		[557] = "风行者",
		[558] = "魔导师",
		[559] = "希纳斯",
		[560] = "迈萨拉",
	},
	zhTW = {
		[161] = "擎天峰",
		[239] = "三傑",
		[402] = "學院",
		[556] = "薩倫",
		[557] = "風行者",
		[558] = "博學者",
		[559] = "奧核點",
		[560] = "梅薩拉",
	},
}

addon.variables.challengeMapLabelOverrides = challengeMapLabelOverrides

function addon.functions.BuildChallengeMapLabelTable(defaults)
	local labels = {}
	if type(defaults) == "table" then
		for mapID, label in pairs(defaults) do
			labels[mapID] = label
		end
	end

	local locale = GetLocale and GetLocale() or "enUS"
	local overrides = challengeMapLabelOverrides[locale]
	if type(overrides) == "table" then
		for mapID, label in pairs(overrides) do
			labels[mapID] = label
		end
	end

	return labels
end

function addon.functions.GetChallengeMapLabel(mapID, defaults)
	if mapID == nil then return nil end

	local locale = GetLocale and GetLocale() or "enUS"
	local overrides = challengeMapLabelOverrides[locale]
	if type(overrides) == "table" then
		local label = overrides[mapID]
		if type(label) == "string" and label ~= "" then return label end
	end

	if type(defaults) == "table" then
		local label = defaults[mapID]
		if type(label) == "string" and label ~= "" then return label end
	end

	return nil
end

local function addSeasonMapAlias(aliasList, aliasHash, value)
	if value == nil then return end
	if type(value) ~= "number" and type(value) ~= "string" then return end
	if aliasHash[value] then return end
	aliasHash[value] = true
	table.insert(aliasList, value)
end

local function getLegacySeasonMapID(data, cId)
	if not data or not data.mapID then return nil end
	if type(data.mapID) == "table" then
		local variant = data.mapID[cId]
		if type(variant) == "table" then return variant.mapID .. "_" .. variant.zoneID end
		return variant
	end
	return data.mapID
end

local function getSeasonZoneID(data, cId)
	if not data then return nil end
	if type(data.mapID) == "table" then
		local variant = data.mapID[cId]
		if type(variant) == "table" then return variant.zoneID end
	end
	return data.zoneID
end

function addon.functions.BuildChallengeSeasonMapInfo(portalCompendium)
	local info = {}
	local hash = {}
	local lookup = {}
	if not (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo) then return info, hash, lookup end

	local cModeIDs = C_ChallengeMode.GetMapTable() or {}
	local cModeIDLookup = {}
	local liveMapIDCounts = {}
	local pendingEntries = {}
	local portalDataByCModeID = {}

	for _, cId in ipairs(cModeIDs) do
		cModeIDLookup[cId] = true
		local mapName, _, _, _, _, liveMapID = C_ChallengeMode.GetMapUIInfo(cId)
		if mapName then
			if type(liveMapID) == "number" then liveMapIDCounts[liveMapID] = (liveMapIDCounts[liveMapID] or 0) + 1 end
			table.insert(pendingEntries, {
				cId = cId,
				liveMapID = liveMapID,
				name = mapName,
			})
		end
	end

	if type(portalCompendium) == "table" then
		for _, section in pairs(portalCompendium) do
			local spells = type(section) == "table" and section.spells or nil
			if type(spells) == "table" then
				for _, data in pairs(spells) do
					if type(data) == "table" and type(data.cId) == "table" then
						for cId in pairs(data.cId) do
							if cModeIDLookup[cId] and not portalDataByCModeID[cId] then portalDataByCModeID[cId] = data end
						end
					end
				end
			end
		end
	end

	local seenMapIDs = {}
	for _, entry in ipairs(pendingEntries) do
		local data = portalDataByCModeID[entry.cId]
		local legacyMapID = getLegacySeasonMapID(data, entry.cId)
		local zoneID = getSeasonZoneID(data, entry.cId)
		local liveMapID = entry.liveMapID
		local mapID = legacyMapID or liveMapID or entry.cId

		if type(liveMapID) == "number" then
			mapID = liveMapID
			if liveMapIDCounts[liveMapID] and liveMapIDCounts[liveMapID] > 1 then
				if zoneID then
					mapID = liveMapID .. "_" .. zoneID
				elseif legacyMapID ~= nil then
					mapID = legacyMapID
				end
			end
		end

		if mapID and not seenMapIDs[mapID] then
			seenMapIDs[mapID] = true
			local aliases = {}
			local aliasHash = {}
			addSeasonMapAlias(aliases, aliasHash, mapID)
			addSeasonMapAlias(aliases, aliasHash, legacyMapID)
			if type(liveMapID) == "number" and (mapID == liveMapID or liveMapIDCounts[liveMapID] == 1) then addSeasonMapAlias(aliases, aliasHash, liveMapID) end
			addSeasonMapAlias(aliases, aliasHash, entry.cId)

			local mapEntry = {
				aliases = aliases,
				cId = entry.cId,
				id = mapID,
				name = entry.name,
			}

			table.insert(info, mapEntry)
			for _, alias in ipairs(aliases) do
				hash[alias] = true
				lookup[alias] = mapEntry
			end
		end
	end

	table.sort(info, function(a, b) return a.name < b.name end)
	return info, hash, lookup
end
