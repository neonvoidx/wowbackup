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

local VALUE_PREFIX = "CDM:"
local groups = {
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_ANIMALS",
		sounds = {
			{ soundKitID = 316401, soundFileID = 7466002, labelKey = "CDMSND_ANIMALS_CAT" },
			{ soundKitID = 316406, soundFileID = 7466004, labelKey = "CDMSND_ANIMALS_CHICKEN" },
			{ soundKitID = 316407, soundFileID = 7466006, labelKey = "CDMSND_ANIMALS_COW" },
			{ soundKitID = 316409, soundFileID = 7466010, labelKey = "CDMSND_ANIMALS_GNOLL" },
			{ soundKitID = 316715, soundFileID = 7466951, labelKey = "CDMSND_ANIMALS_GOAT" },
			{ soundKitID = 316411, soundFileID = 7466012, labelKey = "CDMSND_ANIMALS_LION" },
			{ soundKitID = 316412, soundFileID = 7466014, labelKey = "CDMSND_ANIMALS_PANTHER" },
			{ soundKitID = 316413, soundFileID = 7466016, labelKey = "CDMSND_ANIMALS_RATTLESNAKE" },
			{ soundKitID = 316414, soundFileID = 7466018, labelKey = "CDMSND_ANIMALS_SHEEP" },
			{ soundKitID = 316415, soundFileID = 7466020, labelKey = "CDMSND_ANIMALS_WOLF" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_DEVICES",
		sounds = {
			{ soundKitID = 316442, soundFileID = 7466062, labelKey = "CDMSND_DEVICES_BOAT_HORN" },
			{ soundKitID = 316436, soundFileID = 7466054, labelKey = "CDMSND_DEVICES_AIR_HORN" },
			{ soundKitID = 316713, soundFileID = 7466947, labelKey = "CDMSND_DEVICES_BIKE_HORN" },
			{ soundKitID = 316446, soundFileID = 7466070, labelKey = "CDMSND_DEVICES_CASH_REGISTER" },
			{ soundKitID = 316717, soundFileID = 7466955, labelKey = "CDMSND_DEVICES_JACKPOT_BELL" },
			{ soundKitID = 316718, soundFileID = 7466957, labelKey = "CDMSND_DEVICES_JACKPOT_COINS" },
			{ soundKitID = 316719, soundFileID = 7466959, labelKey = "CDMSND_DEVICES_JACKPOT_FAIL" },
			{ soundKitID = 316433, soundFileID = 7466048, labelKey = "CDMSND_DEVICES_ROTARY_PHONE_DIAL" },
			{ soundKitID = 316492, soundFileID = 7466124, labelKey = "CDMSND_DEVICES_ROTARY_PHONE_RING" },
			{ soundKitID = 316425, soundFileID = 7466036, labelKey = "CDMSND_DEVICES_STOVE_PIPE" },
			{ soundKitID = 316430, soundFileID = 7466046, labelKey = "CDMSND_DEVICES_TRASHCAN_LID" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_IMPACTS",
		sounds = {
			{ soundKitID = 316528, soundFileID = 7466899, labelKey = "CDMSND_IMPACTS_ANVIL_STRIKE" },
			{ soundKitID = 316419, soundFileID = 7466026, labelKey = "CDMSND_IMPACTS_BUBBLE_SMASH" },
			{ soundKitID = 316531, soundFileID = 7466901, labelKey = "CDMSND_IMPACTS_LOW_THUD" },
			{ soundKitID = 316532, soundFileID = 7466903, labelKey = "CDMSND_IMPACTS_METAL_CLANKS" },
			{ soundKitID = 316486, soundFileID = 7466116, labelKey = "CDMSND_IMPACTS_METAL_RATTLE" },
			{ soundKitID = 316484, soundFileID = 7466112, labelKey = "CDMSND_IMPACTS_METAL_SCRAPE" },
			{ soundKitID = 316536, soundFileID = 7466913, labelKey = "CDMSND_IMPACTS_METAL_WARBLE" },
			{ soundKitID = 316434, soundFileID = 7466050, labelKey = "CDMSND_IMPACTS_POP_CLICK" },
			{ soundKitID = 316453, soundFileID = 7466082, labelKey = "CDMSND_IMPACTS_STRANGE_CLANG" },
			{ soundKitID = 316535, soundFileID = 7466911, labelKey = "CDMSND_IMPACTS_SWORD_SCRAPE" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_INSTRUMENTS",
		sounds = {
			{ soundKitID = 316493, soundFileID = 7466126, labelKey = "CDMSND_INSTRUMENTS_BELL_RING" },
			{ soundKitID = 316712, soundFileID = 7466945, labelKey = "CDMSND_INSTRUMENTS_BELL_TRILL" },
			{ soundKitID = 316722, soundFileID = 7466965, labelKey = "CDMSND_INSTRUMENTS_BRASS" },
			{ soundKitID = 316447, soundFileID = 7466072, labelKey = "CDMSND_INSTRUMENTS_CHIME_ASCENDING" },
			{ soundKitID = 316477, soundFileID = 7466098, labelKey = "CDMSND_INSTRUMENTS_GUITAR_CHUG" },
			{ soundKitID = 316482, soundFileID = 7466108, labelKey = "CDMSND_INSTRUMENTS_GUITAR_PINCH" },
			{ soundKitID = 316509, soundFileID = 7466148, labelKey = "CDMSND_INSTRUMENTS_PITCH_PIPE_DISTRESSED" },
			{ soundKitID = 316501, soundFileID = 7466138, labelKey = "CDMSND_INSTRUMENTS_PITCH_PIPE_NOTE" },
			{ soundKitID = 316540, soundFileID = 7466915, labelKey = "CDMSND_INSTRUMENTS_SYNTH_BIG" },
			{ soundKitID = 316476, soundFileID = 7466096, labelKey = "CDMSND_INSTRUMENTS_SYNTH_BUZZ" },
			{ soundKitID = 316460, soundFileID = 7466092, labelKey = "CDMSND_INSTRUMENTS_SYNTH_HIGH" },
			{ soundKitID = 316723, soundFileID = 7466967, labelKey = "CDMSND_INSTRUMENTS_WARHORN" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_SHORT",
		sounds = {
			{ soundKitID = 353392, soundFileID = 7962218, labelKey = "CDMSND_SHORT_BELL_STRIKE" },
			{ soundKitID = 353387, soundFileID = 7962208, labelKey = "CDMSND_SHORT_BELL_TREE" },
			{ soundKitID = 353388, soundFileID = 7962210, labelKey = "CDMSND_SHORT_BIG_POT" },
			{ soundKitID = 353389, soundFileID = 7962212, labelKey = "CDMSND_SHORT_BLADES" },
			{ soundKitID = 353424, soundFileID = 7962220, labelKey = "CDMSND_SHORT_COFFEE_MUG" },
			{ soundKitID = 353393, soundFileID = 7962222, labelKey = "CDMSND_SHORT_COW_BELL" },
			{ soundKitID = 353395, soundFileID = 7962224, labelKey = "CDMSND_SHORT_FINGER_SNAP" },
			{ soundKitID = 353404, soundFileID = 7962236, labelKey = "CDMSND_SHORT_GUITAR" },
			{ soundKitID = 353405, soundFileID = 7962238, labelKey = "CDMSND_SHORT_KALIMBA" },
			{ soundKitID = 353406, soundFileID = 7962240, labelKey = "CDMSND_SHORT_METAL_BLADE_DROP" },
			{ soundKitID = 353407, soundFileID = 7962242, labelKey = "CDMSND_SHORT_METAL_BLADE_ON_ROD" },
			{ soundKitID = 353408, soundFileID = 7962244, labelKey = "CDMSND_SHORT_METAL_IMPACT" },
			{ soundKitID = 353410, soundFileID = 7962246, labelKey = "CDMSND_SHORT_MINI_WOOD_XYLOPHONE" },
			{ soundKitID = 353425, soundFileID = 7962248, labelKey = "CDMSND_SHORT_PAPER_CUP" },
			{ soundKitID = 353417, soundFileID = 7962256, labelKey = "CDMSND_SHORT_SHEET_METAL" },
			{ soundKitID = 353419, soundFileID = 7962258, labelKey = "CDMSND_SHORT_STOVE_PIPE" },
			{ soundKitID = 353420, soundFileID = 7962260, labelKey = "CDMSND_SHORT_STOVE_PIPE_BLADE" },
			{ soundKitID = 353421, soundFileID = 7962262, labelKey = "CDMSND_SHORT_SWORD_SHING" },
			{ soundKitID = 353402, soundFileID = 7962234, labelKey = "CDMSND_SHORT_SYNTH_BLEEP" },
			{ soundKitID = 353400, soundFileID = 7962232, labelKey = "CDMSND_SHORT_SYNTH_BLURP" },
			{ soundKitID = 353397, soundFileID = 7962228, labelKey = "CDMSND_SHORT_SYNTH_ERROR" },
			{ soundKitID = 353399, soundFileID = 7962230, labelKey = "CDMSND_SHORT_SYNTH_HIGH" },
			{ soundKitID = 353423, soundFileID = 7962266, labelKey = "CDMSND_SHORT_TRIANGLE" },
			{ soundKitID = 353426, soundFileID = 7962268, labelKey = "CDMSND_SHORT_WATER_DROP" },
			{ soundKitID = 353427, soundFileID = 7962270, labelKey = "CDMSND_SHORT_WINE_BOTTLE" },
			{ soundKitID = 353428, soundFileID = 7962272, labelKey = "CDMSND_SHORT_WOOD_XYLOPHONE" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR2",
		sounds = {
			{ soundKitID = 316731, soundFileID = 7467017, labelKey = "CDMSND_WAR2_ABSTRACT_WHOOSH" },
			{ soundKitID = 316733, soundFileID = 7467021, labelKey = "CDMSND_WAR2_CHOIR" },
			{ soundKitID = 316735, soundFileID = 7467023, labelKey = "CDMSND_WAR2_CONSTRUCTION" },
			{ soundKitID = 316736, soundFileID = 7467025, labelKey = "CDMSND_WAR2_MAGIC_CHIMES" },
			{ soundKitID = 316745, soundFileID = 7464792, labelKey = "CDMSND_WAR2_PIG_SQUEAL" },
			{ soundKitID = 316738, soundFileID = 7467029, labelKey = "CDMSND_WAR2_SAWS" },
			{ soundKitID = 316746, soundFileID = 7464794, labelKey = "CDMSND_WAR2_SEAL" },
			{ soundKitID = 316748, soundFileID = 7464798, labelKey = "CDMSND_WAR2_SLOW" },
			{ soundKitID = 316749, soundFileID = 7464800, labelKey = "CDMSND_WAR2_SMITH" },
			{ soundKitID = 316739, soundFileID = 7467031, labelKey = "CDMSND_WAR2_SYNTH_STINGER" },
			{ soundKitID = 316740, soundFileID = 7467033, labelKey = "CDMSND_WAR2_TRUMPET_RALLY" },
			{ soundKitID = 316737, soundFileID = 7467027, labelKey = "CDMSND_WAR2_ZIPPY_MAGIC" },
		},
	},
	{
		labelKey = "COOLDOWN_VIEWER_SETTINGS_SOUND_ALERT_CATEGORY_WAR3",
		sounds = {
			{ soundKitID = 316773, soundFileID = 7467088, labelKey = "CDMSND_WAR3_BELL" },
			{ soundKitID = 316774, soundFileID = 7467090, labelKey = "CDMSND_WAR3_CRUNCHY_BELL" },
			{ soundKitID = 316768, soundFileID = 7467080, labelKey = "CDMSND_WAR3_DRUM_SPLASH" },
			{ soundKitID = 316775, soundFileID = 7467092, labelKey = "CDMSND_WAR3_ERROR" },
			{ soundKitID = 316769, soundFileID = 7467082, labelKey = "CDMSND_WAR3_FANFARE" },
			{ soundKitID = 316776, soundFileID = 7467094, labelKey = "CDMSND_WAR3_GATE_OPEN" },
			{ soundKitID = 316770, soundFileID = 7467072, labelKey = "CDMSND_WAR3_GOLD" },
			{ soundKitID = 316778, soundFileID = 7467098, labelKey = "CDMSND_WAR3_MAGIC_SHIMMER" },
			{ soundKitID = 316771, soundFileID = 7467084, labelKey = "CDMSND_WAR3_RINGOUT" },
			{ soundKitID = 316765, soundFileID = 7467074, labelKey = "CDMSND_WAR3_ROOSTER" },
			{ soundKitID = 316779, soundFileID = 7467100, labelKey = "CDMSND_WAR3_SHIMMER_BELL" },
			{ soundKitID = 316766, soundFileID = 7467076, labelKey = "CDMSND_WAR3_WOLF_HOWL" },
		},
	},
}

local soundsByValue = {}
for _, group in ipairs(groups) do
	for _, sound in ipairs(group.sounds) do
		sound.value = VALUE_PREFIX .. sound.soundKitID
		soundsByValue[sound.value] = sound
	end
end

local SoundCatalog = {
	groups = groups,
	soundsByValue = soundsByValue,
}
CooldownPanels.SoundCatalog = SoundCatalog

function SoundCatalog:GetEntry(value)
	if type(value) ~= "string" then return nil end
	return self.soundsByValue[value]
end

function SoundCatalog:GetLabel(value)
	local sound = self:GetEntry(value)
	if not sound then return nil end
	return _G[sound.labelKey] or tostring(sound.soundKitID)
end

function SoundCatalog:GetGroupLabel(group)
	return group and (_G[group.labelKey] or group.labelKey) or nil
end

function SoundCatalog:GetRootLabel()
	return _G.COOLDOWN_VIEWER_SETTINGS_TITLE or _G.COOLDOWN_VIEWER_SETTINGS_MENU
end

function SoundCatalog:GetSoundFileID(value)
	local sound = self:GetEntry(value)
	return sound and sound.soundFileID or nil
end

function SoundCatalog:Play(value)
	local sound = self:GetEntry(value)
	if not sound then return false end
	if PlaySound then
		PlaySound(sound.soundKitID, "Gameplay SFX")
		return true
	end
	return false
end
