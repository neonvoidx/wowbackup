-- luacheck: globals EnhanceQoL
local addonName, addon = ...
local L = addon.L
local options = addon.MarkBarOptions

local function ensureDB()
	return options.EnsureDB()
end

local function atlasIcon(name, size, offsetX, offsetY) return ("|A:%s:%d:%d:%d:%d|a"):format(name, size, size, offsetX or 0, offsetY or 0) end

local RAID_TARGET_COLORS = {
	[1] = { 1, 0.92, 0 },
	[2] = { 0.98, 0.57, 0 },
	[3] = { 0.83, 0.22, 0.9 },
	[4] = { 0.04, 0.95, 0 },
	[5] = { 0.7, 0.82, 0.875 },
	[6] = { 0, 0.71, 1 },
	[7] = { 1, 0.24, 0.168 },
	[8] = { 0.98, 0.98, 0.98 },
}

local function markerIcon(marker, ringSize, iconSize)
	local ringOffsetX, ringOffsetY = 0, 0
	local iconOffsetX, iconOffsetY = 0, ringSize * 3 / 44
	local raidTargetIndex = 9 - marker
	local ringColor = RAID_TARGET_COLORS[raidTargetIndex]
	return {
		icon = {
			atlas = "Ping_UnitMarker_BG_OnMyWay",
			size = ringSize,
			offsetX = ringOffsetX,
			offsetY = ringOffsetY,
			vertexColor = ringColor,
			desaturate = true,
		},
		iconOverlay = { atlas = "GM-raidMarker" .. tostring(marker), size = iconSize, offsetX = iconOffsetX, offsetY = iconOffsetY },
		iconSize = ringSize,
	}
end

local WORLD_MARKER_ORDER = { 8, 4, 1, 7, 2, 3, 6, 5 }

local function buildParts(ringSize, iconSize)
	local parts = {}
	for index, marker in ipairs(WORLD_MARKER_ORDER) do
		local icon = markerIcon(index, ringSize, iconSize)
		parts[#parts + 1] = {
			icon = icon.icon,
			iconOverlay = icon.iconOverlay,
			iconSize = icon.iconSize,
			secure = {
				forwardRightClick = true,
				attributes = addon.MarkBarActions.World(marker),
			},
		}
	end
	parts[#parts + 1] = {
		text = atlasIcon("GM-raidMarker-reset", math.floor(ringSize * 12 / 44 + 0.5)),
		secure = {
			forwardRightClick = true,
			attributes = addon.MarkBarActions.World(),
		},
	}
	return parts
end

local function update(stream)
	local db = ensureDB()
	if not db.showWorld then
		stream.snapshot.hidden = true
		stream.snapshot.parts = nil
		stream.snapshot.text = nil
		return
	end

	stream.snapshot.hidden = nil
	local ringSize = db.worldIconSize
	local iconSize = ringSize * 24 / 44
	stream.snapshot.partSpacing = db.worldSpacing
	stream.snapshot.fontSize = ringSize
	stream.snapshot.parts = buildParts(ringSize, iconSize)
end

local function openOptions()
	if options and options.Show then options.Show("DataPanel_markbar_showWorld") end
end

local provider = {
	id = "markbar_world",
	version = 1,
	title = L["MarkBarWorld"] or "Mark Bar: World Markers",
	OnClick = {
		RightButton = openOptions,
	},
	update = update,
	events = {
		PLAYER_LOGIN = function(s) addon.DataHub:RequestUpdate(s) end,
	},
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
