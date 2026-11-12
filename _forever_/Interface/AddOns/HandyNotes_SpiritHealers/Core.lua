local ADDON_NAME, ns = ...

local HandyNotes = _G.HandyNotes
if not HandyNotes then return end

local PLUGIN = "SpiritHealers"
local TITLE = "Spirit Healers"
ns.PLUGIN, ns.TITLE = PLUGIN, TITLE

local C_Map, C_Texture = C_Map, C_Texture
local GameTooltip, UIParent, Minimap = GameTooltip, UIParent, Minimap
local format, ipairs, pairs, type, next = string.format, ipairs, pairs, type, next

local L = {
	ABOUT = "Shows every spirit healer in WoW Forever on your world map and minimap: the graveyard's name and which faction is sent there.",
	DISPLAY = "Display",
	ICON_SCALE = "Icon scale",
	ICON_SCALE_DESC = "Size of the spirit healer icons.",
	ICON_ALPHA = "Icon opacity",
	ICON_ALPHA_DESC = "Opacity of the spirit healer icons.",
	WORLD_MAP = "Show on the world map",
	MINIMAP = "Show on the minimap",
	CONTINENT = "Show on continent maps",
	CONTINENT_DESC = "Also show the spirit healers on the Kalimdor and Eastern Kingdoms maps.",
	FILTERS = "Filters",
	OTHER_FACTION = "Show the other faction's graveyards",
	NEUTRAL = "Show neutral graveyards",
	NEUTRAL_DESC = "Graveyards that take in both the Alliance and the Horde.",
	HIDDEN = "Hidden spirit healers",
	HIDDEN_DESC = "Right-click a spirit healer on the world map to hide it.",
	HIDDEN_COUNT = "Hidden spirit healers: %d",
	RESTORE = "Show hidden spirit healers again",
	RUN_SETUP = "Run setup again",
	RUN_SETUP_DESC = "Walk through the first-time setup again.",
	RESET = "Reset to defaults",
	ALLIANCE_SIDE = "Alliance graveyard",
	HORDE_SIDE = "Horde graveyard",
	NEUTRAL_SIDE = "Neutral graveyard: Alliance & Horde",
	UNKNOWN_SIDE = "Faction not known yet",
	INSIDE = "Inside %s",
	HINT = "Right-click for a waypoint, or to hide this spirit healer.",
	MENU_TOMTOM = "Add TomTom waypoint",
	MENU_PIN = "Set map pin",
	MENU_HIDE = "Hide this spirit healer",
	WAYPOINT_SET = "Waypoint set to %s.",
	WAYPOINT_FAILED = "A waypoint can't be placed on this map.",
	HIDDEN_ONE = "%s is hidden. Type /spirithealers to show hidden spirit healers again.",
}
ns.L = L

-- The art in the middle of every pin: Resurrection (file ID in the Forever client).
local ART = 135955

local defaults = {
	profile = {
		icon_scale = 1.5,
		icon_alpha = 1.0,
		worldmap = true,
		minimap = true,
		continent = false,
		otherFaction = false,
		neutral = true,
		hidden = {},
	},
	global = {
		setupDone = false,
	},
}

local db
local playerSide

LibStub("AceAddon-3.0"):NewAddon(ns, ADDON_NAME, "AceEvent-3.0")

local function UpdatePlayer()
	local faction = UnitFactionGroup("player")
	playerSide = (faction == "Alliance" and "A") or (faction == "Horde" and "H") or nil
end

function ns.PlayerSide() return playerSide end

local function HiddenKey(uiMapID, coord)
	return uiMapID .. ":" .. coord
end

-- Graveyards whose faction isn't known yet count as neutral.
function ns.IsVisible(node, settings)
	local s = settings or db
	local side = node.side or "N"
	if side == "N" then
		if not s.neutral then return false end
	elseif playerSide and side ~= playerSide and not s.otherFaction then
		return false
	end
	return true
end

-- Pins hidden with right-click.
function ns.IsHidden(uiMapID, coord)
	return db.hidden[HiddenKey(uiMapID, coord)] and true or false
end
local IsVisible = ns.IsVisible

---------------------------------------------------------
-- Icons
--
-- Every pin is a round talent-node ring in the colour of the faction(s) the graveyard takes in (blue for the Alliance,
-- red for the Horde, gold for both, dark when it isn't known). Pins.lua then masks Resurrection into its centre.
-- HandyNotes itself only ever gets the ring.

local RINGS = {
	A = { atlas = "talents-node-circle-gray", r = 0.35, g = 0.62, b = 1 },
	H = { atlas = "talents-node-circle-red" },
	N = { atlas = "talents-node-circle-yellow" },
	U = { atlas = "talents-node-circle-locked" },
}
local RING_COLOR = { A = { 0.35, 0.62, 1 }, H = { 1, 0.25, 0.25 }, N = { 1, 0.82, 0 }, U = { 0.6, 0.6, 0.6 } }
local RING_FALLBACK = ART
ns.ART_SIZE = 0.74

local function RingKey(node)
	return node.side or "U"
end

local ringCache = {}

function ns.RingIcon(node)
	local key = RingKey(node)
	local icon = ringCache[key]
	if not icon then
		local ring = RINGS[key]
		local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(ring.atlas)
		local file = info and (info.file or info.filename)
		if file then
			icon = {
				icon = file,
				tCoordLeft = info.leftTexCoord, tCoordRight = info.rightTexCoord,
				tCoordTop = info.topTexCoord, tCoordBottom = info.bottomTexCoord,
				r = ring.r or 1, g = ring.g or 1, b = ring.b or 1, a = 1,
			}
		else
			icon = RING_FALLBACK
		end
		ringCache[key] = icon
	end
	return icon
end

function ns.RingColor(node)
	local c = RING_COLOR[RingKey(node)]
	return c[1], c[2], c[3]
end

function ns.Aura()
	return nil
end

-- The sharp art that goes inside the ring. Icon art has a frame painted into its edge, so that is cut off.
function ns.SetArt(texture)
	texture:SetTexture(ART)
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

---------------------------------------------------------
-- Node lists

local byMap, byContinent = {}, {}

local function BuildLists()
	for mapID, nodes in pairs(ns.points) do
		local list = {}
		for coord, node in pairs(nodes) do
			list[#list + 1] = { coord = coord, mapID = mapID, node = node }
		end
		table.sort(list, function(a, b) return a.coord < b.coord end)
		byMap[mapID] = list
	end
end

local function ContinentOf(mapID)
	local info = C_Map.GetMapInfo(mapID)
	for _ = 1, 8 do
		if not info then return nil end
		if info.mapType == Enum.UIMapType.Continent then return info.mapID end
		if not info.parentMapID or info.parentMapID == 0 then return nil end
		info = C_Map.GetMapInfo(info.parentMapID)
	end
end

local function ContinentList(uiMapID)
	local list = byContinent[uiMapID]
	if list == nil then
		list = false
		local info = C_Map.GetMapInfo(uiMapID)
		if info and info.mapType == Enum.UIMapType.Continent then
			list = {}
			for mapID, entries in pairs(byMap) do
				if ContinentOf(mapID) == uiMapID then
					for _, entry in ipairs(entries) do
						list[#list + 1] = entry
					end
				end
			end
			table.sort(list, function(a, b)
				if a.mapID ~= b.mapID then return a.mapID < b.mapID end
				return a.coord < b.coord
			end)
		end
		byContinent[uiMapID] = list
	end
	return list or nil
end

---------------------------------------------------------
-- HandyNotes plugin handler

local function noop() end

function ns:GetNodes2(uiMapID, minimap)
	if not db then return noop end
	local list = byMap[uiMapID]
	if minimap then
		if not db.minimap then return noop end
	else
		if not db.worldmap then return noop end
		if not list and db.continent then
			list = ContinentList(uiMapID)
		end
	end
	if not list then return noop end

	local i, scale, alpha = 0, db.icon_scale, db.icon_alpha
	return function()
		while true do
			i = i + 1
			local entry = list[i]
			if not entry then return nil end
			local node = entry.node
			if IsVisible(node, db) and not db.hidden[HiddenKey(entry.mapID, entry.coord)] then
				return entry.coord, entry.mapID, ns.RingIcon(node), scale, alpha
			end
		end
	end
end

local function SideText(side)
	if side == "A" then return L.ALLIANCE_SIDE, 0.25, 0.55, 1 end
	if side == "H" then return L.HORDE_SIDE, 1, 0.25, 0.25 end
	if side == "N" then return L.NEUTRAL_SIDE, 1, 0.82, 0 end
	return L.UNKNOWN_SIDE, 0.6, 0.6, 0.6
end

local function FindNode(uiMapID, coord)
	local nodes = ns.points[uiMapID]
	return nodes and nodes[coord]
end
ns.FindNode = FindNode

local function MapName(uiMapID)
	local info = uiMapID and C_Map.GetMapInfo(uiMapID)
	return info and info.name or ""
end

function ns:OnEnter(uiMapID, coord)
	local node = FindNode(uiMapID, coord)
	if not node then return end
	if ns.Highlight then ns.Highlight(self, node, true) end

	local cx = self:GetCenter()
	if cx and cx > (UIParent:GetCenter()) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end

	GameTooltip:AddLine(node.name, 1, 1, 1)
	if node.graveyard then
		GameTooltip:AddLine(node.graveyard, 1, 0.82, 0)
	end
	GameTooltip:AddLine(SideText(node.side))
	if node.inside then
		GameTooltip:AddLine(L.INSIDE:format(node.inside), 0.9, 0.9, 0.9)
	end

	local x, y = HandyNotes:getXY(coord)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(MapName(uiMapID), format("%.1f, %.1f", x * 100, y * 100), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
	if self:GetParent() ~= Minimap then
		GameTooltip:AddLine(L.HINT, 0.5, 0.8, 1)
	end
	GameTooltip:Show()
end

function ns:OnLeave()
	if ns.Highlight then ns.Highlight(self, nil, false) end
	GameTooltip:Hide()
end

local function Print(message)
	print(format("|cff33ff99%s|r: %s", TITLE, message))
end
ns.Print = Print

---------------------------------------------------------
-- Right-click menu: a waypoint, or hide the pin

function ns:Refresh()
	self:SendMessage("HandyNotes_NotifyUpdate", PLUGIN)
end

local function NotifyOptions()
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then registry:NotifyChange("HandyNotes") end
end
ns.NotifyOptions = NotifyOptions

local function TomTomReady()
	local tomtom = _G.TomTom
	return tomtom and tomtom.AddWaypoint and tomtom
end

local function CanPin(uiMapID)
	return UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(uiMapID)
end

local function SetWaypoint(uiMapID, x, y, name)
	local tomtom = TomTomReady()
	if tomtom then
		tomtom:AddWaypoint(uiMapID, x, y, { title = name, from = TITLE, persistent = nil, minimap = true, world = true })
		return
	end
	if CanPin(uiMapID) then
		C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(uiMapID, x, y))
		if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
			C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		end
		Print(L.WAYPOINT_SET:format(name))
	else
		Print(L.WAYPOINT_FAILED)
	end
end

local function HideNode(uiMapID, coord, name)
	db.hidden[HiddenKey(uiMapID, coord)] = true
	ns:Refresh()
	NotifyOptions()
	Print(L.HIDDEN_ONE:format(name))
end

function ns:OnClick(button, down, uiMapID, coord)
	if button ~= "RightButton" or down then return end
	local node = FindNode(uiMapID, coord)
	if not node then return end
	local x, y = HandyNotes:getXY(coord)
	local name = node.name
	if not (MenuUtil and MenuUtil.CreateContextMenu) then
		-- No menu on this client: Shift-right-click hides, right-click sets a waypoint.
		if IsShiftKeyDown() then
			HideNode(uiMapID, coord, name)
		else
			SetWaypoint(uiMapID, x, y, name)
		end
		return
	end
	MenuUtil.CreateContextMenu(self, function(_, root)
		root:CreateTitle(name)
		if TomTomReady() then
			root:CreateButton(L.MENU_TOMTOM, function() SetWaypoint(uiMapID, x, y, name) end)
		elseif CanPin(uiMapID) then
			root:CreateButton(L.MENU_PIN, function() SetWaypoint(uiMapID, x, y, name) end)
		end
		root:CreateButton(L.MENU_HIDE, function() HideNode(uiMapID, coord, name) end)
	end)
end

---------------------------------------------------------
-- Options

local function HiddenCount()
	local count = 0
	for _ in pairs(db.hidden) do count = count + 1 end
	return count
end

local function BuildOptions()
	return {
		type = "group",
		name = TITLE,
		desc = L.ABOUT,
		get = function(info) return db[info[#info]] end,
		set = function(info, value)
			db[info[#info]] = value
			ns:Refresh()
		end,
		args = {
			about = { type = "description", order = 0, name = L.ABOUT .. "\n" },
			displayHeader = { type = "header", order = 10, name = L.DISPLAY },
			icon_scale = { type = "range", order = 11, name = L.ICON_SCALE, desc = L.ICON_SCALE_DESC, min = 0.5, max = 3, step = 0.05, bigStep = 0.1 },
			icon_alpha = { type = "range", order = 12, name = L.ICON_ALPHA, desc = L.ICON_ALPHA_DESC, min = 0.1, max = 1, step = 0.05, isPercent = true },
			worldmap = { type = "toggle", order = 13, width = "full", name = L.WORLD_MAP },
			minimap = { type = "toggle", order = 14, width = "full", name = L.MINIMAP },
			continent = { type = "toggle", order = 15, width = "full", name = L.CONTINENT, desc = L.CONTINENT_DESC },
			filterHeader = { type = "header", order = 20, name = L.FILTERS },
			otherFaction = { type = "toggle", order = 21, width = "full", name = L.OTHER_FACTION },
			neutral = { type = "toggle", order = 22, width = "full", name = L.NEUTRAL, desc = L.NEUTRAL_DESC },
			hiddenHeader = { type = "header", order = 40, name = L.HIDDEN },
			hiddenCount = {
				type = "description", order = 41,
				name = function() return L.HIDDEN_COUNT:format(HiddenCount()) .. "\n" .. L.HIDDEN_DESC .. "\n" end,
			},
			restore = {
				type = "execute", order = 42, name = L.RESTORE,
				disabled = function() return next(db.hidden) == nil end,
				func = function()
					wipe(db.hidden)
					ns:Refresh()
				end,
			},
			setup = {
				type = "execute", order = 49, name = L.RUN_SETUP, desc = L.RUN_SETUP_DESC,
				func = function()
					if ns.OpenSetup then ns.OpenSetup() end
				end,
			},
			reset = {
				type = "execute", order = 50, name = L.RESET,
				func = function()
					ns.db:ResetProfile()
					NotifyOptions()
				end,
			},
		},
	}
end

function ns.OpenOptions()
	local dialog = LibStub("AceConfigDialog-3.0", true)
	if dialog then
		dialog:Open("HandyNotes")
		dialog:SelectGroup("HandyNotes", "plugins", PLUGIN)
	end
end

---------------------------------------------------------
-- First-time setup (Setup.lua): what this plugin asks

ns.SETUP = {
	portrait = ART,
	slash = "/spirithealers",
	noun = { one = "spirit healer", many = "spirit healers", Many = "Spirit healers" },
	-- Previews start at the spirit healer nearest to the character, or else in Elwynn Forest, Durotar or the Barrens.
	hubs = { A = 1429, H = 1411, N = 1413 },
	view = function() return { neutral = true } end,
	text = {
		FACTION_TITLE = "Show the other faction's graveyards?",
		FACTION_TEXT = "When you die, you're sent to the nearest graveyard that takes in your faction. An icon's color shows who a graveyard takes in.",
		FACTION_YES = "Yes, also show %s graveyards",
		FACTION_NO = "No, only %s graveyards and the ones both factions use",
		FACTION_YES_ANY = "Yes, show both factions' graveyards",
		FACTION_NO_ANY = "No, only my faction's graveyards and the ones both factions use",
		FACTION_COUNT = "%d graveyards",
		FACTION_COUNT_ONE = "1 graveyard",
		SUMMARY_FACTION = "Other faction's graveyards: %s",
	},
	pages = {
		{
			type = "question", key = "neutral", afterFaction = true,
			-- The preview starts at the graveyard both factions use nearest to the character, so the answer shows on it.
			focus = function(node) return node.side == "N" end,
			title = "Show graveyards both factions use?",
			text = "Many graveyards, in contested zones and neutral towns, take in both the Alliance and the Horde.",
			yes = "Yes, show graveyards both factions use",
			no = "No, only my faction's graveyards",
			summary = function(a) return "Graveyards both factions use: " .. (a.neutral and "Yes" or "No") end,
		},
	},
}

---------------------------------------------------------
-- Initialisation

function ns:OnProfileChanged()
	db = self.db.profile
	self:Refresh()
end

function ns:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_SpiritHealersDB", defaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	db = self.db.profile
	BuildLists()
end

function ns:OnPlayerChanged()
	UpdatePlayer()
	self:Refresh()
end

function ns:OnEnable()
	UpdatePlayer()
	HandyNotes:RegisterPluginDB(PLUGIN, self, BuildOptions())
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerChanged")
	self:RegisterEvent("NEUTRAL_FACTION_SELECT_RESULT", "OnPlayerChanged")
	self:Refresh()
end

SLASH_HANDYNOTESSPIRITHEALERS1 = "/spirithealers"
SLASH_HANDYNOTESSPIRITHEALERS2 = "/hnspirit"
SlashCmdList.HANDYNOTESSPIRITHEALERS = function(message)
	if (message or ""):lower():match("^%s*setup%s*$") and ns.OpenSetup then
		ns.OpenSetup()
	else
		ns.OpenOptions()
	end
end
