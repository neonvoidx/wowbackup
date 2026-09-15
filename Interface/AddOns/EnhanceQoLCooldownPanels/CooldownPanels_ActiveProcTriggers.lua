local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CooldownPanels = addon.Aura.CooldownPanels

CooldownPanels.activeProcTriggerByItemID = {
	[249341] = {
		effectSpellID = 1258535,
		stackTriggerSpellID = 1258535,
		duration = 12,
		stackDuration = 12,
		mode = "stacked",
		name = "Volatile Void Suffuser",
		itemName = "Volatile Void Suffuser",
	},
	[249342] = {
		effectSpellID = 1251822,
		triggerSpellID = 1262753,
		duration = 12,
		mode = "simple",
		name = "Heart of Ancient Hunger",
		itemName = "Heart of Ancient Hunger",
	},
	[268292] = {
        effectSpellID = 1284696,
        triggerSpellID = 1284698,
        duration = 12,
        mode = "simple",
        name = "Sporelord's Mycelium",
        itemName = "Sporelord's Mycelial Insignia",
    },
	[249343] = {
		effectSpellID = 1256896,
		stackTriggerSpellID = 1266687,
		duration = 12,
		stackDuration = 12,
		mode = "stacked",
		name = "Alnscorned Essence",
		itemName = "Gaze of the Alnseer",
	},
	[249809] = {
		effectSpellID = 1259314,
		startTriggerSpellID = 1259317,
		stackTriggerSpellID = 1268058,
		duration = 10,
		stackDuration = 10,
		mode = "stackedAfterStart",
		name = "Deepening Temptation",
		itemName = "Locus-Walker's Ribbon",
	},
	[250228] = {
		effectSpellID = 1250564,
		startTriggerSpellID = 1254180,
		stackTriggerSpellID = 1254331,
		duration = 30,
		stackDuration = 30,
		mode = "stackedAfterStart",
		name = "Echoing Roar",
		itemName = "Resonant Bellowstone",
	},
	[250229] = {
		effectSpellID = 1250567,
		triggerSpellID = 1258223,
		duration = 15,
		mode = "simple",
		name = "Nalorakk's Rage",
		itemName = "Idol of the War Loa",
	},
	[250242] = {
		effectSpellID = 1250584,
		triggerSpellID = 1254520,
		duration = 10,
		mode = "simple",
		name = "Gelatinous Protection",
		itemName = "Jelly Replicator",
	},
	[250256] = {
		effectSpellID = 1250599,
		triggerSpellID = 1263318,
		duration = 10,
		mode = "simple",
		name = "The Wind Awoken",
		itemName = "Heart of Wind",
	},
	[250259] = {
		effectSpellID = 1250604,
		triggerSpellID = 1263077,
		duration = 15,
		mode = "simple",
		name = "Uprooted Lasher",
		itemName = "Sapling of the Dawnroot",
	},
	[251782] = {
		effectSpellID = 1253110,
		triggerSpellID = 1255226,
		duration = 10,
		mode = "simple",
		name = "Withered Saptor's Paw",
		itemName = "Withered Saptor's Paw",
	},
	[251789] = {
		effectSpellID = 1253117,
		triggerSpellID = 1259994,
		duration = 20,
		mode = "simple",
		name = "Hope",
		itemName = "Consecrated Chalice",
	},
	[251790] = {
		effectSpellID = 1253118,
		triggerSpellID = 1265323,
		duration = 10,
		mode = "simple",
		name = "Despair",
		itemName = "Desecrated Chalice",
	},
}

CooldownPanels.activeProcTriggerBySpellID = {}
for itemID, info in pairs(CooldownPanels.activeProcTriggerByItemID) do
	if CooldownPanels.ForEachActiveProcTriggerSpellID then
		CooldownPanels:ForEachActiveProcTriggerSpellID(info, function(triggerSpellID)
			CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
			CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
		end)
	else
		for _, key in ipairs({ "triggerSpellID", "startTriggerSpellID", "stackTriggerSpellID" }) do
			local triggerSpellID = tonumber(info and info[key])
			if triggerSpellID and triggerSpellID > 0 then
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
			end
		end
		for _, triggerSpellID in ipairs(info.triggerSpellIDs or {}) do
			triggerSpellID = tonumber(triggerSpellID)
			if triggerSpellID and triggerSpellID > 0 then
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] = CooldownPanels.activeProcTriggerBySpellID[triggerSpellID] or {}
				CooldownPanels.activeProcTriggerBySpellID[triggerSpellID][itemID] = info
			end
		end
	end
end
