-- luacheck: globals EnhanceQoL MenuUtil MenuResponse MASTER_VOLUME MUSIC_VOLUME FX_VOLUME AMBIENCE_VOLUME DIALOG_VOLUME AUDIO_OUTPUT_DEVICE GAMEMENU_OPTIONS GameTooltip NORMAL_FONT_COLOR
local addonName, addon = ...
local L = addon.L

local db
local stream
local hoveredButton

local floor = math.floor
local format = string.format

local STREAM_ORDER = { "master", "sfx", "ambience", "dialog", "music" }
local STREAMS = {
	master = {
		id = "master",
		cvar = "Sound_MasterVolume",
		muteCvar = "Sound_EnableAllSound",
		label = MASTER_VOLUME or "Master Volume",
	},
	sfx = {
		id = "sfx",
		cvar = "Sound_SFXVolume",
		muteCvar = "Sound_EnableSFX",
		label = FX_VOLUME or "Sound Effects",
	},
	ambience = {
		id = "ambience",
		cvar = "Sound_AmbienceVolume",
		muteCvar = "Sound_EnableAmbience",
		label = AMBIENCE_VOLUME or "Ambience Volume",
	},
	dialog = {
		id = "dialog",
		cvar = "Sound_DialogVolume",
		muteCvar = "Sound_EnableDialog",
		label = DIALOG_VOLUME or "Dialog Volume",
	},
	music = {
		id = "music",
		cvar = "Sound_MusicVolume",
		muteCvar = "Sound_EnableMusic",
		label = MUSIC_VOLUME or "Music Volume",
	},
}

local CVAR_WATCH = {
	Sound_MasterVolume = true,
	Sound_SFXVolume = true,
	Sound_AmbienceVolume = true,
	Sound_DialogVolume = true,
	Sound_MusicVolume = true,
	Sound_EnableAllSound = true,
	Sound_EnableSFX = true,
	Sound_EnableAmbience = true,
	Sound_EnableDialog = true,
	Sound_EnableMusic = true,
	Sound_OutputDriverIndex = true,
}

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.volume = addon.db.datapanel.volume or {}
	db = addon.db.datapanel.volume
	db.fontSize = db.fontSize or 14
	db.step = db.step or 0.05
	db.activeStream = db.activeStream or "master"
	if db.iconOnly == nil then db.iconOnly = false end
	if db.useTextColor == nil then db.useTextColor = false end
	if not db.textColor then
		local r, g, b = 1, 0.82, 0
		if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then
			r, g, b = NORMAL_FONT_COLOR:GetRGB()
		end
		db.textColor = { r = r, g = g, b = b }
	end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_volume_fontSize")
	end
end

local function clampVolume(value)
	value = tonumber(value) or 0
	if value < 0 then return 0 end
	if value > 1 then return 1 end
	return value
end

local function formatPercent(value) return format("%d%%", floor(value * 100 + 0.5)) end

local function colorizeText(text, color)
	if not text or text == "" then return text end
	if color and color.r and color.g and color.b then return ("|cff%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, text) end
	return text
end

local function getStreamInfo(id) return STREAMS[id] or STREAMS.master end

local function getActiveStreamId()
	ensureDB()
	if not STREAMS[db.activeStream] then db.activeStream = "master" end
	return db.activeStream
end

local function setActiveStreamId(id)
	ensureDB()
	if not STREAMS[id] then id = "master" end
	if db.activeStream == id then return end
	db.activeStream = id
	addon.DataHub:RequestUpdate(stream)
end

local function getStreamVolume(id)
	local info = getStreamInfo(id)
	if not info or not info.cvar then return 0 end
	return clampVolume(GetCVar and GetCVar(info.cvar))
end

local function setStreamVolume(id, value)
	local info = getStreamInfo(id)
	if not info or not info.cvar then return end
	SetCVar(info.cvar, clampVolume(value))
end

local function isStreamEnabled(id)
	local info = getStreamInfo(id)
	if not info or not info.muteCvar then return true end
	return tonumber(GetCVar and GetCVar(info.muteCvar)) == 1
end

local function setStreamEnabled(id, enabled)
	local info = getStreamInfo(id)
	if not info or not info.muteCvar then return end
	SetCVar(info.muteCvar, enabled and "1" or "0")
end

local function getOutputDeviceName()
	if not Sound_GameSystem_GetNumOutputDrivers or not Sound_GameSystem_GetOutputDriverNameByIndex then return nil end
	local count = Sound_GameSystem_GetNumOutputDrivers()
	if not count or count <= 0 then return nil end
	local index = tonumber(GetCVar and GetCVar("Sound_OutputDriverIndex")) or 0
	if index < 0 or index >= count then index = 0 end
	return Sound_GameSystem_GetOutputDriverNameByIndex(index)
end

local function buildTooltip()
	local lines = {}
	local output = getOutputDeviceName()
	if output and output ~= "" then
		lines[#lines + 1] = AUDIO_OUTPUT_DEVICE or "Output Device"
		lines[#lines + 1] = output
		lines[#lines + 1] = " "
	end

	lines[#lines + 1] = L["volumeStreams"] or "Volume Streams"
	local activeId = getActiveStreamId()
	for _, id in ipairs(STREAM_ORDER) do
		local info = STREAMS[id]
		if info then
			local label = info.label or id
			if not isStreamEnabled(id) then
				label = "|cff9b9b9b" .. label .. "|r"
			elseif id == activeId then
				label = "|cff00ff00" .. label .. "|r"
			end
			lines[#lines + 1] = format("%s: %s", label, formatPercent(getStreamVolume(id)))
		end
	end

	lines[#lines + 1] = " "
	lines[#lines + 1] = L["volumeLeftClickHint"] or "Left-click: Select volume stream"
	lines[#lines + 1] = L["volumeRightClickHint"] or "Right-click: Toggle volume stream"
	lines[#lines + 1] = L["volumeMiddleClickHint"] or "Middle-click: Toggle mute active stream"
	lines[#lines + 1] = L["volumeMouseWheelHint"] or "Mouse wheel: Adjust active volume"
	return table.concat(lines, "\n")
end

local function updateTooltipForButton(btn, text)
	if not btn or not GameTooltip or not GameTooltip.IsOwned then return end
	if not GameTooltip:IsOwned(btn) then return end
	GameTooltip:SetText(text or buildTooltip())
	GameTooltip:Show()
end

local function updateVolume(streamObj)
	ensureDB()
	local activeId = getActiveStreamId()
	local info = getStreamInfo(activeId)
	local volume = getStreamVolume(activeId)
	local size = db.fontSize or 14
	local label = info.label or info.id or "Volume"
	local useTextColor = db.useTextColor and db.textColor
	if not useTextColor and not isStreamEnabled(activeId) then label = "|cffff0000" .. label .. "|r" end
	local tooltip = buildTooltip()
	streamObj.snapshot.fontSize = size
	local baseText = ("%s: %s"):format(label, formatPercent(volume))
	if useTextColor then baseText = colorizeText(baseText, db.textColor) end
	local icon = ("|TInterface\\Common\\VoiceChat-Speaker:%d:%d:0:0|t"):format(size, size)
	if db.iconOnly then
		streamObj.snapshot.text = icon
	else
		streamObj.snapshot.text = icon .. " " .. baseText
	end
	streamObj.snapshot.tooltip = tooltip
	streamObj.snapshot.ignoreMenuModifier = true
	updateTooltipForButton(hoveredButton, tooltip)
end

local function showSelectStreamMenu(owner)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end
	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_VOLUME_SELECT")
		rootDescription:CreateTitle(L["volumeSelectMenuTitle"] or "Select Volume Stream")
		for _, id in ipairs(STREAM_ORDER) do
			local info = STREAMS[id]
			if info then
				local label = info.label or id
				rootDescription:CreateRadio(label, function() return getActiveStreamId() == id end, function()
					setActiveStreamId(id)
					return MenuResponse and MenuResponse.Close
				end, id)
			end
		end
	end)
end

local function showMuteMenu(owner)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end
	MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag("MENU_EQOL_VOLUME_MUTE")
		rootDescription:CreateTitle(L["volumeMuteMenuTitle"] or "Toggle Volume Stream")
		for _, id in ipairs(STREAM_ORDER) do
			local info = STREAMS[id]
			if info and info.muteCvar then
				local label = info.label or id
				rootDescription:CreateCheckbox(label, function() return isStreamEnabled(id) end, function()
					setStreamEnabled(id, not isStreamEnabled(id))
					addon.DataHub:RequestUpdate(stream)
				end)
			end
		end
		rootDescription:CreateDivider()
		rootDescription:CreateButton(GAMEMENU_OPTIONS, function()
			openSettings()
			return MenuResponse and MenuResponse.Close
		end)
	end)
end

local function toggleActiveStreamMute()
	local activeId = getActiveStreamId()
	if not STREAMS[activeId] or not STREAMS[activeId].muteCvar then return end
	setStreamEnabled(activeId, not isStreamEnabled(activeId))
	addon.DataHub:RequestUpdate(stream)
end

local function attachMouseWheel(btn)
	if not btn or btn._eqolVolumeWheel then return end
	btn._eqolVolumeWheel = true
	btn:EnableMouseWheel(true)
	btn:SetScript("OnMouseWheel", function(_, delta)
		ensureDB()
		local step = db.step or 0.05
		local activeId = getActiveStreamId()
		local volume = getStreamVolume(activeId)
		if delta > 0 then
			volume = volume + step
		else
			volume = volume - step
		end
		setStreamVolume(activeId, volume)
		updateTooltipForButton(btn)
		addon.DataHub:RequestUpdate(stream)
	end)
end

local provider = {
	id = "volume",
	version = 1,
	title = MASTER_VOLUME or "Master Volume",
	update = updateVolume,
	events = {
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
		CVAR_UPDATE = function(s, _, name)
			if name and CVAR_WATCH[name] then addon.DataHub:RequestUpdate(s) end
		end,
	},
	OnClick = function(btn, mouseButton)
		if mouseButton == "LeftButton" then
			showSelectStreamMenu(btn)
		elseif mouseButton == "RightButton" then
			showMuteMenu(btn)
		elseif mouseButton == "MiddleButton" then
			toggleActiveStreamMute()
		end
	end,
	OnMouseEnter = function(btn)
		hoveredButton = btn
		attachMouseWheel(btn)
		updateTooltipForButton(btn)
	end,
	OnMouseLeave = function(btn)
		if hoveredButton == btn then hoveredButton = nil end
	end,
}

stream = EnhanceQoL.DataHub.RegisterStream(provider)

return provider
