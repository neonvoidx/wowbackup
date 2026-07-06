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

-- Manual fixed-duration spell activations.
-- Keys are tracked spellIDs. duration is the shown activation duration in seconds.
-- triggerMode = "cooldown" starts from SPELL_UPDATE_COOLDOWN instead of UNIT_SPELLCAST_SUCCEEDED.
-- cooldownEventSpellID optionally requires the direct SPELL_UPDATE_COOLDOWN spellID to match,
-- ignoring baseSpellID matches for multi-stage spells that fire follow-up cooldown events.
-- cooldownClearEventSpellID optionally clears the manual duration when a follow-up cooldown
-- event means the real cooldown should become visible immediately.
CooldownPanels.autoCooldownDurationBySpellID = {
	[20594] = { duration = 8, name = "Stoneform" },
	[20572] = { duration = 15, name = "Blood Fury" },
	[26297] = { duration = 12, name = "Berserking" },
	[28880] = { duration = 5, name = "Gift of the Naaru" },
	[59542] = { duration = 5, name = "Gift of the Naaru" },
	[59543] = { duration = 5, name = "Gift of the Naaru" },
	[59544] = { duration = 5, name = "Gift of the Naaru" },
	[59545] = { duration = 5, name = "Gift of the Naaru" },
	[59547] = { duration = 5, name = "Gift of the Naaru" },
	[59548] = { duration = 5, name = "Gift of the Naaru" },
	[68992] = { duration = 10, name = "Darkflight" },
	[121093] = { duration = 5, name = "Gift of the Naaru" },
	[255647] = { duration = 3, name = "Light's Judgment" },
	[265221] = { duration = 8, name = "Fireblood" },
	[274738] = { duration = 15, name = "Ancestral Call" },
	[33697] = { duration = 15, name = "Blood Fury" },
	[33702] = { duration = 15, name = "Blood Fury" },
	[370626] = { duration = 5, name = "Gift of the Naaru" },
	[416250] = { duration = 5, name = "Gift of the Naaru" },
	[256948] = { duration = 6, name = "Spatial Rift", triggerMode = "cooldown", cooldownEventSpellID = 256948, cooldownClearEventSpellID = 257040 },
}
