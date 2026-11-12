local parentAddonName = "EnhanceQoL"
local _, addon = ...
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local HeroSpecs = {}
addon.Aura.CooldownPanels.HeroSpecs = HeroSpecs

-- Retail 12.1.0.69933: playable class TraitSubTree records and their atlas names.
-- Keep IDs stable for saved filters; companion and test trees are excluded.
HeroSpecs.data = {
	{ id = 18, classID = 5, atlas = "talents-heroclass-priest-voidweaver" },
	{ id = 19, classID = 5, atlas = "talents-heroclass-priest-archon" },
	{ id = 20, classID = 5, atlas = "talents-heroclass-priest-oracle" },
	{ id = 21, classID = 11, atlas = "talents-heroclass-druid-druidoftheclaw" },
	{ id = 22, classID = 11, atlas = "talents-heroclass-druid-wildstalker" },
	{ id = 23, classID = 11, atlas = "talents-heroclass-druid-keeperofthegrove" },
	{ id = 24, classID = 11, atlas = "talents-heroclass-druid-eluneschosen" },
	{ id = 31, classID = 6, atlas = "talents-heroclass-deathknight-sanlayn" },
	{ id = 32, classID = 6, atlas = "talents-heroclass-deathknight-rideroftheapocalypse" },
	{ id = 33, classID = 6, atlas = "talents-heroclass-deathknight-deathbringer" },
	{ id = 34, classID = 12, atlas = "talents-heroclass-demonhunter-felscarred" },
	{ id = 35, classID = 12, atlas = "talents-heroclass-demonhunter-aldrachireaver" },
	{ id = 36, classID = 13, atlas = "talents-heroclass-evoker-scalecommander" },
	{ id = 37, classID = 13, atlas = "talents-heroclass-evoker-flameshaper" },
	{ id = 38, classID = 13, atlas = "talents-heroclass-evoker-chronowarden" },
	{ id = 39, classID = 8, atlas = "talents-heroclass-mage-sunfury" },
	{ id = 40, classID = 8, atlas = "talents-heroclass-mage-spellslinger" },
	{ id = 41, classID = 8, atlas = "talents-heroclass-mage-frostfire" },
	{ id = 42, classID = 3, atlas = "talents-heroclass-hunter-sentinel" },
	{ id = 43, classID = 3, atlas = "talents-heroclass-hunter-packleader" },
	{ id = 44, classID = 3, atlas = "talents-heroclass-hunter-darkranger" },
	{ id = 48, classID = 2, atlas = "talents-heroclass-paladin-templar" },
	{ id = 49, classID = 2, atlas = "talents-heroclass-paladin-lightsmith" },
	{ id = 50, classID = 2, atlas = "talents-heroclass-paladin-heraldofthesun" },
	{ id = 51, classID = 4, atlas = "talents-heroclass-rogue-trickster" },
	{ id = 52, classID = 4, atlas = "talents-heroclass-rogue-fatebound" },
	{ id = 53, classID = 4, atlas = "talents-heroclass-rogue-deathstalker" },
	{ id = 54, classID = 7, atlas = "talents-heroclass-shaman-totemic" },
	{ id = 55, classID = 7, atlas = "talents-heroclass-shaman-stormbringer" },
	{ id = 56, classID = 7, atlas = "talents-heroclass-shaman-farseer" },
	{ id = 57, classID = 9, atlas = "talents-heroclass-warlock-soulharvester" },
	{ id = 58, classID = 9, atlas = "talents-heroclass-warlock-hellcaller" },
	{ id = 59, classID = 9, atlas = "talents-heroclass-warlock-diabolist" },
	{ id = 60, classID = 1, atlas = "talents-heroclass-warrior-slayer" },
	{ id = 61, classID = 1, atlas = "talents-heroclass-warrior-mountainthane" },
	{ id = 62, classID = 1, atlas = "talents-heroclass-warrior-colossus" },
	{ id = 64, classID = 10, atlas = "talents-heroclass-monk-conduitofthecelestials" },
	{ id = 65, classID = 10, atlas = "talents-heroclass-monk-shadopan" },
	{ id = 66, classID = 10, atlas = "talents-heroclass-monk-masterofharmony" },
	{ id = 124, classID = 12, atlas = "talents-heroclass-demonhunter-annihilator" },
	{ id = 126, classID = 12, atlas = "talents-heroclass-demonhunter-felscarred2" },
}

local function withIcon(atlas, name)
	if atlas and CreateAtlasMarkup and C_Texture and C_Texture.GetAtlasInfo(atlas) then return CreateAtlasMarkup(atlas, 16, 16) .. " " .. name end
	return name
end

function HeroSpecs:GetOptions(entry, classes)
	local options, seen = {}, {}
	local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	local _, _, playerClassID = UnitClass("player")
	for _, classData in ipairs(classes) do
		local classLabel = withIcon("classicon-" .. classData.classTag:lower(), classData.name)
		local classOptions = {}
		local function add(id, info, data)
			if seen[id] then return end
			local name = info and info.name or (data and L["CooldownPanelHeroSpecName" .. id]) or tostring(id)
			local atlas = info and info.iconElementID or (data and data.atlas)
			classOptions[#classOptions + 1] = { value = id, name = name, label = withIcon(atlas, name), classID = classData.id, classLabel = classLabel, group = classLabel }
			seen[id] = true
		end
		for _, data in ipairs(self.data) do
			if data.classID == classData.id then add(data.id, nil, data) end
		end
		-- Include newly available trees for the current class before a catalog update.
		if classData.id == playerClassID and configID and C_ClassTalents.GetHeroTalentSpecsForClassSpec then
			for _, spec in ipairs(classData.specs or {}) do
				for _, id in ipairs(C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, spec.id) or {}) do
					if not seen[id] then add(id, C_Traits.GetSubTreeInfo(configID, id)) end
				end
			end
		end
		table.sort(classOptions, function(a, b)
			if strcmputf8i then return strcmputf8i(a.name, b.name) < 0 end
			return a.name:lower() < b.name:lower()
		end)
		for _, option in ipairs(classOptions) do options[#options + 1] = option end
	end
	-- Preserve imported or retired IDs even if the current client cannot name them.
	if entry then
		addon.Aura.CooldownPanels.helper.NormalizeHeroSpecFilter(entry)
		local unknown = {}
		for id in pairs(entry.heroSpecFilter or {}) do
			if not seen[id] then unknown[#unknown + 1] = id end
		end
		table.sort(unknown)
		for _, id in ipairs(unknown) do
			local info = configID and C_Traits and C_Traits.GetSubTreeInfo(configID, id)
			local name = info and info.name or tostring(id)
			options[#options + 1] = { value = id, label = withIcon(info and info.iconElementID, name) }
		end
	end
	return options
end
