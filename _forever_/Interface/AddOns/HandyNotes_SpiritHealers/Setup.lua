local ADDON_NAME, ns = ...

local HandyNotes = _G.HandyNotes
if not HandyNotes then return end

-- The first-time setup. This file is the same in every plugin of the family; Core.lua says in ns.SETUP what this
-- plugin asks about (its own pages, settings, words and where its previews look first).
local SETUP = ns.SETUP
if not SETUP then return end

local PLUGIN, TITLE = ns.PLUGIN, ns.TITLE
local format, ipairs, pairs, type, floor, ceil, min, max = string.format, ipairs, pairs, type, math.floor, math.ceil, math.min, math.max

local NOUN = SETUP.noun
local S = {
	TITLE = TITLE .. " Setup",
	SUBTITLE = "First-time setup",
	STEP = "Step %d of %d",
	BACK = "Back",
	NEXT = "Next",
	FINISH = "Finish",
	SKIP = "Skip setup",

	ICONS_TITLE = "How should the " .. NOUN.one .. " icons look?",
	ICONS_TEXT = "Pick a size and an opacity for the icons. The preview shows them on your map.",
	SIZE = "Icon size",
	OPACITY = "Icon opacity",

	MINIMAP_TITLE = "Show " .. NOUN.many .. " on the minimap?",
	MINIMAP_TEXT = NOUN.Many .. " close to you show up on your minimap while you travel.",
	MINIMAP_YES = "Yes, show them on the minimap",
	MINIMAP_NO = "No, only on the world map",

	CONTINENT_TITLE = "Show " .. NOUN.many .. " on the continent maps?",
	CONTINENT_TEXT = NOUN.Many .. " can also show on the Kalimdor and Eastern Kingdoms maps, so you see a whole continent at once.",
	CONTINENT_YES = "Yes, show them on the continent maps",
	CONTINENT_NO = "No, only on zone and city maps",

	ALL = "All",
	NONE = "None",
	PICK_ONE = "Pick at least one.",

	FACTION_TITLE = "Show the other faction's " .. NOUN.many .. "?",
	FACTION_TEXT = "An icon's color shows the faction: blue for the Alliance, red for the Horde, gold for both.",
	FACTION_YES = "Yes, also show %s " .. NOUN.many,
	FACTION_NO = "No, only %s " .. NOUN.many .. " and the ones for both factions",
	FACTION_YES_ANY = "Yes, show both factions' " .. NOUN.many,
	FACTION_NO_ANY = "No, only my faction's " .. NOUN.many .. " and the ones for both factions",
	FACTION_COUNT = "%d " .. NOUN.many,
	FACTION_COUNT_ONE = "1 " .. NOUN.one,
	SHOWN = "Shown",
	HIDDEN = "Hidden",

	DONE_TITLE = "You're all set!",
	DONE_TEXT = "Here's what you picked. Change it any time with " .. SETUP.slash .. ", or in HandyNotes under Plugins, " .. TITLE .. ".",
	SUMMARY_ICONS = "Icons: %d%% size, %d%% opacity",
	SUMMARY_MINIMAP = "Minimap: %s",
	SUMMARY_CONTINENT = "Continent maps: %s",
	SUMMARY_FACTION = "Other faction's " .. NOUN.many .. ": %s",
	YES = "Yes",
	NO = "No",

	DONE_CHAT = "You're all set. Type " .. SETUP.slash .. " to change your settings.",
	SKIPPED_CHAT = "Setup skipped. Type " .. SETUP.slash .. " setup to run it any time.",
	CLOSED_CHAT = "Setup closed, nothing was changed.",
}
for key, text in pairs(SETUP.text or {}) do S[key] = text end
ns.SETUP_TEXT = S

local WIDTH, HEIGHT = 560, 500
local PAD = 18
local PAGE_WIDTH = WIDTH - 10 - 2 * PAD
local PAGE_HEIGHT = HEIGHT - 86 - 2 * PAD
-- The settings every plugin of the family has; SETUP.settings and SETUP.tables add the plugin's own.
local COMMON = { "icon_scale", "icon_alpha", "minimap", "continent", "otherFaction", "neutral" }
-- The windowed world map shows a map at about this size, so pins look as big next to the map as they do in game.
local CITY_ZOOM, MINIMAP_ZOOM = 0.75, 1.6
local GRID_TOP, GRID_ROW = -66, 40
local CHOICE_TOP, CHOICE_ROW = -70, 30
local SIDE_COLOR = { A = { 0.25, 0.55, 1 }, H = { 1, 0.25, 0.25 }, N = { 1, 0.82, 0 } }

local frame, pages, current, answers
local home -- { mapID, x, y }: the pin the previews centre on, picked when the setup opens
local view -- the settings that show every pin, for picking a home and samples

local function Round(value)
	return floor(value * 20 + 0.5) / 20
end

local function Click()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Page text can depend on the answers so far.
local function Text(value)
	if type(value) == "function" then return value(answers) end
	return value
end

local function Colored(text, r, g, b)
	return format("|cff%02x%02x%02x%s|r", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5), text)
end

-- "Alliance" in blue, "Horde" in red and "Alliance & Horde" in gold, like the icons.
local function SideName(side)
	local name = (side == "A" and (FACTION_ALLIANCE or "Alliance")) or (side == "H" and (FACTION_HORDE or "Horde"))
		or ns.L.BOTH_FACTIONS or "Alliance & Horde"
	local c = SIDE_COLOR[side] or SIDE_COLOR.N
	return Colored(name, c[1], c[2], c[3])
end
ns.SideName = SideName

local function YesNo(value)
	return value and S.YES or S.NO
end

---------------------------------------------------------
-- Pins for the previews

local function Sorted(t)
	local keys = {}
	for key in pairs(t) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

local function Hidden(mapID, coord)
	return ns.IsHidden and ns.IsHidden(mapID, coord)
end

-- { { x = 0-1, y = 0-1, node = node }, ... } for the pins on `mapID` that `settings` show.
local function Spots(mapID, settings)
	local spots = {}
	local nodes = ns.points[mapID]
	if nodes then
		for _, coord in ipairs(Sorted(nodes)) do
			local node = nodes[coord]
			if ns.IsVisible(node, settings) and not Hidden(mapID, coord) then
				local x, y = HandyNotes:getXY(coord)
				spots[#spots + 1] = { x = x, y = y, node = node }
			end
		end
	end
	return spots
end

-- A pin to show as an example: one of the character's own faction that it sees, otherwise one both factions use,
-- otherwise any. `match` picks which pins count, `side` the faction it must have.
local function SampleNode(match, side)
	local mine = ns.PlayerSide()
	local best, bestRank
	for _, mapID in ipairs(Sorted(ns.points)) do
		local nodes = ns.points[mapID]
		for _, coord in ipairs(Sorted(nodes)) do
			local node = nodes[coord]
			if (not match or match(node)) and (not side or node.side == side) then
				local rank = (node.side == mine and 1) or (node.side == "N" and 2) or 3
				if not ns.IsVisible(node, view) then rank = rank + 3 end
				if not bestRank or rank < bestRank then best, bestRank = node, rank end
			end
		end
	end
	return best
end
ns.SampleNode = SampleNode

-- The pin nearest to the character (on its continent), otherwise the first one in its faction's hub. With `match`,
-- only the pins it picks count, and there may be none (nil).
local function FindHome(match)
	local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	local continent, here
	if pos and CreateVector2D and C_Map.GetWorldPosFromMapPos then
		continent, here = C_Map.GetWorldPosFromMapPos(mapID, pos)
	end
	if continent and here then
		local px, py = here:GetXY()
		local best, bestDistance
		for _, pinMap in ipairs(Sorted(ns.points)) do
			for _, spot in ipairs(Spots(pinMap, view)) do
				if not match or match(spot.node) then
					local c, world = C_Map.GetWorldPosFromMapPos(pinMap, CreateVector2D(spot.x, spot.y))
					if c == continent and world then
						local wx, wy = world:GetXY()
						local distance = (wx - px) ^ 2 + (wy - py) ^ 2
						if not bestDistance or distance < bestDistance then
							best, bestDistance = { mapID = pinMap, x = spot.x, y = spot.y }, distance
						end
					end
				end
			end
		end
		if best then return best end
	end
	local hubs = SETUP.hubs
	local order = {}
	for _, side in ipairs({ ns.PlayerSide() or "N", "N", "A", "H" }) do
		if hubs[side] then order[#order + 1] = hubs[side] end
	end
	if match then
		for _, pinMap in ipairs(Sorted(ns.points)) do order[#order + 1] = pinMap end
	end
	for _, hub in ipairs(order) do
		for _, spot in ipairs(Spots(hub, view)) do
			if not match or match(spot.node) then return { mapID = hub, x = spot.x, y = spot.y } end
		end
	end
	if not match then return { mapID = hubs.A, x = 0.5, y = 0.5 } end
end

local function CreatePin(parent)
	local pin = CreateFrame("Frame", nil, parent)
	pin.texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture:SetAllPoints()
	return pin
end

-- Puts an icon from ns.RingIcon on a texture, the way HandyNotes does.
local function SetIcon(texture, icon)
	if type(icon) == "table" then
		texture:SetTexture(icon.icon)
		texture:SetTexCoord(icon.tCoordLeft or 0, icon.tCoordRight or 1, icon.tCoordTop or 0, icon.tCoordBottom or 1)
		texture:SetVertexColor(icon.r or 1, icon.g or 1, icon.b or 1, icon.a or 1)
	else
		texture:SetTexture(icon)
		texture:SetTexCoord(0, 1, 0, 1)
		texture:SetVertexColor(1, 1, 1, 1)
	end
end

local function ShowPin(pin, node, size, alpha, settings)
	size = size * (ns.NodeScale and ns.NodeScale(node) or 1)
	pin:SetSize(size, size)
	pin:SetAlpha(alpha or 1)
	SetIcon(pin.texture, ns.RingIcon(node))
	ns.Decorate(pin, node, size, settings)
	pin:Show()
end

local function HandyNotesSetting(key)
	local profile = HandyNotes.db and HandyNotes.db.profile
	return profile and profile[key] or 1
end

---------------------------------------------------------
-- Map previews: real map art with the pins on it, laid out the way the world map lays out its tiles

local function CreatePreview(parent, width, height, round)
	local holder = CreateFrame("Frame", nil, parent, not round and "InsetFrameTemplate" or nil)
	holder:SetSize(width, height)
	-- Round previews copy Forever's minimap: a 198 wide map inside the 253 wide minimap ring.
	local pad = round and floor(width * (1 - 198 / 253) / 2 + 0.5) or 3
	holder.viewW, holder.viewH, holder.round = width - 2 * pad, height - 2 * pad, round

	local mapView = CreateFrame("Frame", nil, holder)
	mapView:SetPoint("TOPLEFT", pad, -pad)
	mapView:SetPoint("BOTTOMRIGHT", -pad, pad)
	mapView:SetClipsChildren(true)
	holder.view = mapView

	holder.background = mapView:CreateTexture(nil, "BACKGROUND")
	holder.background:SetAllPoints()
	holder.background:SetColorTexture(0.12, 0.1, 0.07, 1)

	holder.canvas = CreateFrame("Frame", nil, mapView)
	holder.pinLayer = CreateFrame("Frame", nil, holder.canvas)
	holder.pinLayer:SetAllPoints()
	holder.tiles, holder.pins = {}, {}

	local overlay = CreateFrame("Frame", nil, holder)
	overlay:SetAllPoints(holder)
	overlay:SetFrameLevel(mapView:GetFrameLevel() + 10)
	holder.overlay = overlay

	if round then
		local mask = mapView:CreateMaskTexture()
		mask:SetAtlas("ui-hud-minimap-frame-generic-mask")
		mask:SetAllPoints(mapView)
		holder.mask = mask
		holder.background:AddMaskTexture(mask)
		local border = overlay:CreateTexture(nil, "OVERLAY")
		border:SetAtlas("UI-HUD-Minimap-Frame")
		border:SetAllPoints(holder)
		holder.border = border
	else
		holder.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		holder.label:SetPoint("BOTTOMLEFT", mapView, "BOTTOMLEFT", 8, 6)
		holder.label:SetShadowOffset(1, -1)
	end
	return holder
end

local function MapLayer(uiMapID)
	local layers = C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(uiMapID)
	return layers and layers[1]
end

-- Shows `uiMapID` at `zoom`, centred on x, y (0-1). Returns the size of the map at that zoom.
local function ShowMapArt(holder, uiMapID, x, y, zoom)
	local layer = MapLayer(uiMapID)
	local files = layer and C_Map.GetMapArtLayerTextures(uiMapID, 1)
	local canvas = holder.canvas
	if not (layer and files and #files > 0) then
		for _, tile in ipairs(holder.tiles) do tile:Hide() end
		canvas:SetSize(holder.viewW, holder.viewH)
		canvas:ClearAllPoints()
		canvas:SetPoint("TOPLEFT")
		return holder.viewW, holder.viewH, 0, 0
	end

	local width, height = layer.layerWidth * zoom, layer.layerHeight * zoom
	local left = min(0, max(holder.viewW - width, holder.viewW / 2 - x * width))
	local top = min(0, max(holder.viewH - height, holder.viewH / 2 - y * height))
	canvas:SetSize(width, height)
	canvas:ClearAllPoints()
	canvas:SetPoint("TOPLEFT", holder.view, "TOPLEFT", left, -top)

	local cols = ceil(layer.layerWidth / layer.tileWidth)
	local rows = ceil(layer.layerHeight / layer.tileHeight)
	local tileW, tileH = layer.tileWidth * zoom, layer.tileHeight * zoom
	local count = 0
	for row = 1, rows do
		for col = 1, cols do
			count = count + 1
			local tile = holder.tiles[count]
			if not tile then
				tile = canvas:CreateTexture(nil, "BACKGROUND", nil, 1)
				if holder.mask then tile:AddMaskTexture(holder.mask) end
				holder.tiles[count] = tile
			end
			tile:SetTexture(files[(row - 1) * cols + col], nil, nil, "TRILINEAR")
			tile:SetSize(tileW, tileH)
			tile:ClearAllPoints()
			tile:SetPoint("TOPLEFT", canvas, "TOPLEFT", (col - 1) * tileW, -(row - 1) * tileH)
			tile:Show()
		end
	end
	for i = count + 1, #holder.tiles do holder.tiles[i]:Hide() end
	return width, height, left, top
end

-- spots: { { x = 0-1, y = 0-1, node = node }, ... } on the map shown.
local function ShowPins(holder, spots, size, alpha, mapW, mapH, left, top, settings)
	local n = 0
	local radius = holder.round and holder.viewW / 2 - size or nil
	for _, spot in ipairs(spots) do
		local px, py = spot.x * mapW, spot.y * mapH
		local vx, vy = px + left, py + top
		local inside
		if radius then
			local dx, dy = vx - holder.viewW / 2, vy - holder.viewH / 2
			inside = dx * dx + dy * dy <= radius * radius
		else
			inside = vx > -size and vy > -size and vx < holder.viewW + size and vy < holder.viewH + size
		end
		if inside then
			n = n + 1
			local pin = holder.pins[n]
			if not pin then
				pin = CreatePin(holder.pinLayer)
				holder.pins[n] = pin
			end
			pin:ClearAllPoints()
			pin:SetPoint("CENTER", holder.canvas, "TOPLEFT", px, -py)
			ShowPin(pin, spot.node, size, alpha, settings)
		end
	end
	for i = n + 1, #holder.pins do holder.pins[i]:Hide() end
	return n
end

local function MapName(mapID)
	local info = C_Map.GetMapInfo(mapID)
	return info and info.name or ""
end

-- The middle of the place's map's pins when they all fit in the preview, otherwise the place.
local function HomeCenter(place, mapW, mapH, viewW, viewH)
	local spots = Spots(place.mapID, view)
	if #spots > 1 then
		local x0, y0, x1, y1 = 1, 1, 0, 0
		for _, spot in ipairs(spots) do
			x0, y0, x1, y1 = min(x0, spot.x), min(y0, spot.y), max(x1, spot.x), max(y1, spot.y)
		end
		if (x1 - x0) * mapW <= viewW * 0.8 and (y1 - y0) * mapH <= viewH * 0.8 then
			return (x0 + x1) / 2, (y0 + y1) / 2
		end
	end
	return place.x, place.y
end

-- The map around `place` (home unless a page has its own) with the pins `settings` show.
local function ShowHome(holder, settings, zoom, minimap, place)
	place = place or home
	local mapID, x, y = place.mapID, place.x, place.y
	local layer = MapLayer(mapID)
	if layer and not minimap then
		x, y = HomeCenter(place, layer.layerWidth * zoom, layer.layerHeight * zoom, holder.viewW, holder.viewH)
	end
	local mapW, mapH, left, top = ShowMapArt(holder, mapID, x, y, zoom)
	local size, alpha
	if minimap then
		size = 12 * HandyNotesSetting("icon_scale_minimap") * settings.icon_scale
		alpha = HandyNotesSetting("icon_alpha_minimap") * settings.icon_alpha
	else
		size = 12 * HandyNotesSetting("icon_scale") * settings.icon_scale
		alpha = HandyNotesSetting("icon_alpha") * settings.icon_alpha
	end
	local spots = (not minimap or settings.minimap) and Spots(mapID, settings) or {}
	local shown = ShowPins(holder, spots, size, min(alpha, 1), mapW, mapH, left, top, settings)
	if holder.label then holder.label:SetText(MapName(mapID)) end
	return shown
end

-- Every pin on a continent, moved from its zone map onto the continent map (worked out once per continent).
local continentCache = {}

local function ContinentPoints(continentMapID)
	local cached = continentCache[continentMapID]
	if cached then return cached end
	cached = {}
	continentCache[continentMapID] = cached
	if not (CreateVector2D and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos) then return cached end
	for _, mapID in ipairs(Sorted(ns.points)) do
		local nodes = ns.points[mapID]
		for _, coord in ipairs(Sorted(nodes)) do
			local x, y = HandyNotes:getXY(coord)
			local continentID, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
			if continentID and world then
				local onMap, pos = C_Map.GetMapPosFromWorldPos(continentID, world, continentMapID)
				if onMap == continentMapID and pos then
					local cx, cy = pos:GetXY()
					if cx > 0 and cx < 1 and cy > 0 and cy < 1 then
						cached[#cached + 1] = { x = cx, y = cy, node = nodes[coord], mapID = mapID, coord = coord }
					end
				end
			end
		end
	end
	return cached
end

local function ContinentOf(mapID)
	local info = C_Map.GetMapInfo(mapID)
	for _ = 1, 8 do
		if not info then return nil end
		if info.mapType == Enum.UIMapType.Continent then return info.mapID end
		info = info.parentMapID and info.parentMapID ~= 0 and C_Map.GetMapInfo(info.parentMapID)
	end
end

local function ShowContinent(holder, settings)
	local mapID, x, y = home.mapID, home.x, home.y
	local continent = ContinentOf(mapID)
	if not continent then
		-- Islands like Zephras Isle aren't on a continent map: show the continent of the character's faction.
		for _, hub in ipairs({ SETUP.hubs[ns.PlayerSide() or "A"], SETUP.hubs.A, SETUP.hubs.H }) do
			if ContinentOf(hub) then
				mapID = hub
				break
			end
		end
		local spot = Spots(mapID, view)[1]
		x, y = spot and spot.x or 0.5, spot and spot.y or 0.5
		continent = ContinentOf(mapID)
	end
	if not continent then
		return ShowHome(holder, settings, CITY_ZOOM)
	end
	local cx, cy = 0.5, 0.5
	if CreateVector2D and C_Map.GetWorldPosFromMapPos then
		local continentID, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
		if continentID and world then
			local onMap, pos = C_Map.GetMapPosFromWorldPos(continentID, world, continent)
			if onMap == continent and pos then cx, cy = pos:GetXY() end
		end
	end
	local mapW, mapH, left, top = ShowMapArt(holder, continent, cx, cy, 1.0)
	local spots = {}
	if settings.continent then
		for _, spot in ipairs(ContinentPoints(continent)) do
			if ns.IsVisible(spot.node, settings) and not Hidden(spot.mapID, spot.coord) then spots[#spots + 1] = spot end
		end
	end
	local size = 12 * HandyNotesSetting("icon_scale") * settings.icon_scale
	local alpha = min(HandyNotesSetting("icon_alpha") * settings.icon_alpha, 1)
	holder.label:SetText(MapName(continent))
	return ShowPins(holder, spots, size, alpha, mapW, mapH, left, top, settings)
end

---------------------------------------------------------
-- Controls

local function NewText(parent, font, text)
	local fs = parent:CreateFontString(nil, "ARTWORK", font)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	if text then fs:SetText(text) end
	return fs
end

local function NewPage(key, title, text)
	local page = CreateFrame("Frame", nil, frame.Inset)
	page:SetPoint("TOPLEFT", PAD, -PAD)
	page:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	page:Hide()
	page.key = key
	page.Title = NewText(page, "GameFontNormalLarge")
	page.Title:SetPoint("TOPLEFT")
	page.Title:SetWidth(PAGE_WIDTH)
	page.Text = NewText(page, "GameFontHighlight")
	page.Text:SetPoint("TOPLEFT", page.Title, "BOTTOMLEFT", 0, -8)
	page.Text:SetWidth(PAGE_WIDTH)
	page.Text:SetSpacing(2)
	page.titleSource, page.textSource = title, text
	pages[#pages + 1] = page
	return page
end

local Update

-- Two radio buttons answering a yes/no question about `key`.
local function NewQuestion(page, key, yesText, noText, y)
	local radios = {}
	for i, value in ipairs({ true, false }) do
		local radio = CreateFrame("CheckButton", nil, page, "UIRadioButtonTemplate")
		radio:SetPoint("TOPLEFT", page, "TOPLEFT", 4, y - (i - 1) * 26)
		radio.text:SetFontObject("GameFontHighlight")
		radio.source = value and yesText or noText
		radio:SetHitRectInsets(0, -300, -4, -4)
		radio.value = value
		radio:SetScript("OnClick", function()
			Click()
			answers[key] = value
			Update()
		end)
		radios[i] = radio
	end
	page.radios, page.questionKey = radios, key
	return radios
end

local function RefreshQuestion(page)
	for _, radio in ipairs(page.radios) do
		if radio.source then radio.text:SetText(Text(radio.source)) end
		radio:SetChecked(answers[page.questionKey] == radio.value)
	end
end

local function NewCheck(parent, onClick)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(28, 28)
	check:SetScript("OnClick", function(self)
		Click()
		onClick(self:GetChecked() and true or false)
		Update()
	end)
	return check
end

local function NewSmallButton(parent, text, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(90, 22)
	button:SetText(text)
	button:SetScript("OnClick", function()
		Click()
		onClick()
		Update()
	end)
	return button
end

local function NewSlider(page, label, y, minValue, maxValue, steps, onChange)
	local text = NewText(page, "GameFontNormal", label)
	text:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
	local slider = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
	slider:SetSize(300, 40)
	slider:SetPoint("LEFT", text, "LEFT", 130, 0)
	slider.minValue, slider.maxValue, slider.steps = minValue, maxValue, steps
	slider.formatters = {
		[MinimalSliderWithSteppersMixin.Label.Right] = function(value) return format("%d%%", value * 100 + 0.5) end,
	}
	slider.onChange = onChange
	slider.label = text
	return slider
end

local function SetSlider(slider, value)
	slider.updating = true
	slider:Init(value, slider.minValue, slider.maxValue, slider.steps, slider.formatters)
	slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, newValue)
		if not slider.updating then slider.onChange(newValue) end
	end, slider)
	slider.updating = nil
end

-- A setting that is either answers[key] or answers[group][key].
local function ItemValue(item)
	if item.group then return answers[item.group][item.key] end
	return answers[item.key]
end

local function SetItemValue(item, value)
	if item.group then
		answers[item.group][item.key] = value
	else
		answers[item.key] = value
	end
end

---------------------------------------------------------
-- Pages every plugin has

local function BuildIconsPage()
	local page = NewPage("icons", S.ICONS_TITLE, S.ICONS_TEXT)
	page.preview = CreatePreview(page, PAGE_WIDTH, 214)
	page.preview:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -64)
	page.size = NewSlider(page, S.SIZE, -300, 0.5, 3, 25, function(value)
		answers.icon_scale = Round(value)
		Update()
	end)
	page.opacity = NewSlider(page, S.OPACITY, -340, 0.1, 1, 18, function(value)
		answers.icon_alpha = Round(value)
		Update()
	end)
	function page:OnShow()
		SetSlider(self.size, answers.icon_scale)
		SetSlider(self.opacity, answers.icon_alpha)
	end
	function page:Refresh()
		ShowHome(self.preview, answers, CITY_ZOOM)
	end
	function page:Summary()
		return format(S.SUMMARY_ICONS, answers.icon_scale * 100 + 0.5, answers.icon_alpha * 100 + 0.5)
	end
end

local function BuildMinimapPage()
	local page = NewPage("minimap", S.MINIMAP_TITLE, S.MINIMAP_TEXT)
	NewQuestion(page, "minimap", S.MINIMAP_YES, S.MINIMAP_NO, -82)
	page.preview = CreatePreview(page, 224, 224, true)
	page.preview:SetPoint("TOP", page, "TOP", 0, -138)
	function page:Refresh()
		RefreshQuestion(self)
		ShowHome(self.preview, answers, MINIMAP_ZOOM, true)
	end
	function page:Summary()
		return format(S.SUMMARY_MINIMAP, YesNo(answers.minimap))
	end
end

local function BuildContinentPage()
	local page = NewPage("continent", S.CONTINENT_TITLE, S.CONTINENT_TEXT)
	NewQuestion(page, "continent", S.CONTINENT_YES, S.CONTINENT_NO, -82)
	page.preview = CreatePreview(page, PAGE_WIDTH, 210)
	page.preview:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -144)
	function page:Refresh()
		RefreshQuestion(self)
		ShowContinent(self.preview, answers)
	end
	function page:Summary()
		return format(S.SUMMARY_CONTINENT, YesNo(answers.continent))
	end
end

-- Sides that have pins, in legend order, with how many pins each has.
local function Sides()
	local counts = {}
	for _, nodes in pairs(ns.points) do
		for _, node in pairs(nodes) do
			if node.side then counts[node.side] = (counts[node.side] or 0) + 1 end
		end
	end
	local sides = {}
	for _, side in ipairs({ "A", "H", "N" }) do
		if counts[side] then sides[#sides + 1] = { side = side, count = counts[side] } end
	end
	return sides
end

local function BuildFactionPage()
	local page = NewPage("faction", S.FACTION_TITLE, S.FACTION_TEXT)
	NewQuestion(page, "otherFaction", nil, nil, -82)
	page.cards = {}
	local sides = Sides()
	local cardW = floor((PAGE_WIDTH - 24) / 3)
	local offset = floor((3 - #sides) * (cardW + 12) / 2)
	for i, entry in ipairs(sides) do
		local card = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
		card:SetSize(cardW, 192)
		card:SetPoint("TOPLEFT", page, "TOPLEFT", offset + (i - 1) * (cardW + 12), -144)
		card.pin = CreatePin(card)
		card.pin:SetPoint("TOP", card, "TOP", 0, -18)
		card.name = NewText(card, "GameFontHighlight")
		card.name:SetPoint("TOP", card.pin, "BOTTOM", 0, -10)
		card.count = NewText(card, "GameFontHighlightSmall",
			entry.count == 1 and S.FACTION_COUNT_ONE or format(S.FACTION_COUNT, entry.count))
		card.count:SetPoint("TOP", card.name, "BOTTOM", 0, -8)
		card.count:SetWidth(cardW - 16)
		card.count:SetJustifyH("CENTER")
		card.state = NewText(card, "GameFontNormalSmall")
		card.state:SetPoint("BOTTOM", card, "BOTTOM", 0, 14)
		card.side = entry.side
		card.node = SampleNode(nil, entry.side)
		page.cards[i] = card
	end
	function page:Refresh()
		local mine = ns.PlayerSide()
		local other = (mine == "A" and "H") or (mine == "H" and "A") or nil
		if other then
			self.radios[1].text:SetFormattedText(S.FACTION_YES, SideName(other))
			self.radios[2].text:SetFormattedText(S.FACTION_NO, SideName(mine))
		else
			self.radios[1].text:SetText(S.FACTION_YES_ANY)
			self.radios[2].text:SetText(S.FACTION_NO_ANY)
		end
		RefreshQuestion(self)
		-- Only the faction answers count here, not the filters picked before.
		local cardView = {}
		for key, value in pairs(view) do cardView[key] = value end
		cardView.otherFaction, cardView.neutral = answers.otherFaction, answers.neutral
		for _, card in ipairs(self.cards) do
			local node = card.node
			local shown = node and ns.IsVisible(node, cardView)
			if node then ShowPin(card.pin, node, 44, shown and 1 or 0.3, view) else card.pin:Hide() end
			card.name:SetText(SideName(card.side))
			card.name:SetAlpha(shown and 1 or 0.5)
			card.count:SetAlpha(shown and 1 or 0.5)
			card.state:SetFontObject(shown and "GameFontNormalSmall" or "GameFontDisableSmall")
			card.state:SetText(shown and S.SHOWN or S.HIDDEN)
		end
	end
	function page:Summary()
		return format(S.SUMMARY_FACTION, YesNo(answers.otherFaction))
	end
end

local function BuildDonePage()
	local page = NewPage("done", S.DONE_TITLE, S.DONE_TEXT)
	page.lines = {}
	for i = 1, 8 do
		local line = NewText(page, "GameFontHighlight")
		line:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -66 - (i - 1) * 19)
		line:SetWidth(PAGE_WIDTH - 10)
		line:SetWordWrap(false)
		page.lines[i] = line
	end
	page.preview = CreatePreview(page, PAGE_WIDTH, 120)
	function page:Refresh(sequence)
		local n = 0
		for _, p in ipairs(sequence) do
			local text = p.Summary and p:Summary()
			if text and n < #self.lines then
				n = n + 1
				self.lines[n]:SetText("|cffffd100-|r " .. text)
				self.lines[n]:Show()
			end
		end
		for i = n + 1, #self.lines do self.lines[i]:Hide() end
		local top = 66 + n * 19 + 10
		self.preview:ClearAllPoints()
		self.preview:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -top)
		self.preview:SetSize(PAGE_WIDTH, PAGE_HEIGHT - top)
		self.preview.viewW, self.preview.viewH = PAGE_WIDTH - 6, PAGE_HEIGHT - top - 6
		ShowHome(self.preview, answers, CITY_ZOOM)
	end
end

---------------------------------------------------------
-- The plugin's own pages (SETUP.pages)

local function AddPreview(page, top)
	page.preview = CreatePreview(page, PAGE_WIDTH, PAGE_HEIGHT - top)
	page.preview:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
end

-- spec.focus(node) picks the pins a page is about: its preview then starts at the one nearest to the character, so
-- the answer shows on the map.
local function Common(page, spec)
	page.spec = spec
	if spec.skip then
		function page:Skip() return spec.skip(answers) end
	end
	if spec.summary then
		function page:Summary() return spec.summary(answers) end
	end
end

-- A yes/no setting.
local function BuildQuestionPage(spec)
	local page = NewPage(spec.key, spec.title, spec.text)
	Common(page, spec)
	NewQuestion(page, spec.key, spec.yes, spec.no, -82)
	AddPreview(page, 144)
	function page:Refresh()
		RefreshQuestion(self)
		ShowHome(self.preview, answers, CITY_ZOOM, nil, self.place)
	end
end

-- Several on/off settings, at least one of them on.
local function BuildChecksPage(spec)
	local page = NewPage(spec.key, spec.title, spec.text)
	Common(page, spec)
	local columns = spec.columns or 3
	local colW = floor(PAGE_WIDTH / columns)
	page.checks = {}
	for i, item in ipairs(spec.items) do
		local col, row = (i - 1) % columns, floor((i - 1) / columns)
		local check = NewCheck(page, function(checked) SetItemValue(item, checked) end)
		check:SetPoint("TOPLEFT", page, "TOPLEFT", col * colW, GRID_TOP - row * GRID_ROW)
		check.pin = CreatePin(page)
		check.pin:SetPoint("LEFT", check, "RIGHT", 2, 0)
		check.Text:ClearAllPoints()
		check.Text:SetPoint("LEFT", check.pin, "RIGHT", 6, 0)
		check.Text:SetFontObject("GameFontHighlight")
		check:SetHitRectInsets(0, -(colW - 40), 0, 0)
		check.item = item
		page.checks[i] = check
	end
	local y = GRID_TOP - ceil(#spec.items / columns) * GRID_ROW - 4
	page.all = NewSmallButton(page, S.ALL, function()
		for _, item in ipairs(spec.items) do SetItemValue(item, true) end
	end)
	page.all:SetPoint("TOPLEFT", page, "TOPLEFT", 4, y)
	page.none = NewSmallButton(page, S.NONE, function()
		for _, item in ipairs(spec.items) do SetItemValue(item, false) end
	end)
	page.none:SetPoint("LEFT", page.all, "RIGHT", 8, 0)
	page.warning = NewText(page, "GameFontRed", spec.empty or S.PICK_ONE)
	page.warning:SetPoint("LEFT", page.none, "RIGHT", 14, 0)
	AddPreview(page, -y + 34)
	function page:Valid()
		for _, item in ipairs(spec.items) do
			if ItemValue(item) then return true end
		end
		return false
	end
	function page:Refresh()
		for _, check in ipairs(self.checks) do
			check:SetChecked(ItemValue(check.item) and true or false)
			check.Text:SetText(Text(check.item.label))
			ShowPin(check.pin, Text(check.item.node), 30, 1, answers)
		end
		self.warning:SetShown(not self:Valid())
		ShowHome(self.preview, answers, CITY_ZOOM, nil, self.place)
	end
end

-- One setting with several possible values.
local function BuildChoicePage(spec)
	local page = NewPage(spec.key, spec.title, spec.text)
	Common(page, spec)
	local columns = spec.columns or 3
	local colW = floor(PAGE_WIDTH / columns)
	page.radios = {}
	for i, item in ipairs(spec.items) do
		local col, row = (i - 1) % columns, floor((i - 1) / columns)
		local radio = CreateFrame("CheckButton", nil, page, "UIRadioButtonTemplate")
		radio:SetPoint("TOPLEFT", page, "TOPLEFT", col * colW + 4, CHOICE_TOP - row * CHOICE_ROW)
		radio.pin = CreatePin(page)
		radio.pin:SetPoint("LEFT", radio, "RIGHT", 4, 0)
		radio.text:ClearAllPoints()
		radio.text:SetPoint("LEFT", radio.pin, "RIGHT", 4, 0)
		radio.text:SetFontObject("GameFontHighlight")
		radio:SetHitRectInsets(0, -(colW - 24), -4, -4)
		radio.item = item
		radio:SetScript("OnClick", function()
			Click()
			answers[spec.key] = item.value
			Update()
		end)
		page.radios[i] = radio
	end
	AddPreview(page, -(CHOICE_TOP - ceil(#spec.items / columns) * CHOICE_ROW) + 6)
	function page:Refresh()
		for _, radio in ipairs(self.radios) do
			radio:SetChecked(answers[spec.key] == radio.item.value)
			radio.text:SetText(Text(radio.item.label))
			ShowPin(radio.pin, Text(radio.item.node), 22, 1, answers)
		end
		ShowHome(self.preview, answers, CITY_ZOOM, nil, self.place)
	end
end

local BUILDERS = { question = BuildQuestionPage, checks = BuildChecksPage, choice = BuildChoicePage }

---------------------------------------------------------
-- Wizard

local function Sequence()
	local sequence = {}
	for _, page in ipairs(pages) do
		if not (page.Skip and page:Skip()) then sequence[#sequence + 1] = page end
	end
	return sequence
end

local function Position(sequence, page)
	for i, p in ipairs(sequence) do
		if p == page then return i end
	end
	return 1
end

function Update()
	if not (frame and current) then return end
	local sequence = Sequence()
	current.Title:SetText(Text(current.titleSource))
	current.Text:SetText(Text(current.textSource))
	current:Refresh(sequence)
	local i = Position(sequence, current)
	frame.Step:SetFormattedText(S.STEP, i, #sequence)
	frame.Back:SetEnabled(i > 1)
	frame.Next:SetText(i == #sequence and S.FINISH or S.NEXT)
	frame.Next:SetEnabled(not current.Valid or current:Valid())
end

local function ShowPage(page)
	current = page
	for _, p in ipairs(pages) do p:SetShown(p == page) end
	if page.OnShow then page:OnShow() end
	Update()
end

local function Settings()
	local keys = {}
	for _, key in ipairs(COMMON) do keys[#keys + 1] = key end
	for _, key in ipairs(SETUP.settings or {}) do keys[#keys + 1] = key end
	return keys
end

local function CopySettings(profile)
	local copy = {}
	for _, key in ipairs(Settings()) do copy[key] = profile[key] end
	for name, keys in pairs(SETUP.tables or {}) do
		local t = {}
		for _, key in ipairs(keys) do t[key] = profile[name][key] and true or false end
		copy[name] = t
	end
	return copy
end

local function Apply()
	local profile = ns.db.profile
	for _, key in ipairs(Settings()) do profile[key] = answers[key] end
	for name, keys in pairs(SETUP.tables or {}) do
		for _, key in ipairs(keys) do profile[name][key] = answers[name][key] end
	end
	ns.db.global.setupDone = true
	frame.finished = true
	frame:Hide()
	ns:Refresh()
	ns.NotifyOptions()
	ns.Print(S.DONE_CHAT)
end

local function Step(delta)
	local sequence = Sequence()
	local i = Position(sequence, current)
	if delta > 0 and i == #sequence then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		Apply()
		return
	end
	local page = sequence[i + delta]
	if page then
		Click()
		ShowPage(page)
	end
end

local function OnHide(self)
	if self.restarting then return end
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	if self.finished then return end
	if ns.db then ns.db.global.setupDone = true end
	ns.Print(self.firstRun and S.SKIPPED_CHAT or S.CLOSED_CHAT)
end

local function NewButton(text, onClick)
	local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	button:SetSize(116, 22)
	button:SetText(text)
	button:SetScript("OnClick", onClick)
	return button
end

local function CreateSetupFrame()
	frame = CreateFrame("Frame", "HandyNotes" .. PLUGIN .. "Setup", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
	-- The same layer as the HandyNotes options window, where "Run setup again" is, so the setup can open on top of it.
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnHide", OnHide)
	frame:SetTitle(S.TITLE)
	frame:SetPortraitToAsset(SETUP.portrait)
	frame:SetPortraitTexCoord(0.08, 0.92, 0.08, 0.92)
	tinsert(UISpecialFrames, frame:GetName())

	frame.Subtitle = NewText(frame, "GameFontHighlightSmall", S.SUBTITLE)
	frame.Subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -38)
	frame.Step = NewText(frame, "GameFontNormalSmall")
	frame.Step:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -38)
	frame.Step:SetJustifyH("RIGHT")

	frame.Next = NewButton(S.NEXT, function() Step(1) end)
	frame.Next:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)
	frame.Back = NewButton(S.BACK, function() Step(-1) end)
	frame.Back:SetPoint("RIGHT", frame.Next, "LEFT", -4, 0)
	frame.Skip = NewButton(S.SKIP, function() frame:Hide() end)
	frame.Skip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 4)

	pages = {}
	BuildIconsPage()
	BuildMinimapPage()
	BuildContinentPage()
	for _, spec in ipairs(SETUP.pages or {}) do
		if spec.afterFaction == nil then BUILDERS[spec.type](spec) end
	end
	BuildFactionPage()
	for _, spec in ipairs(SETUP.pages or {}) do
		if spec.afterFaction then BUILDERS[spec.type](spec) end
	end
	BuildDonePage()
end

function ns.OpenSetup(firstRun)
	if not ns.db then return end
	view = SETUP.view()
	view.icon_scale, view.icon_alpha, view.minimap, view.continent = 1, 1, true, true
	if view.neutral == nil then view.neutral = true end
	answers = CopySettings(ns.db.profile)
	home = FindHome()
	if not frame then CreateSetupFrame() end
	for _, page in ipairs(pages) do
		page.place = page.spec and page.spec.focus and FindHome(page.spec.focus) or nil
	end
	if frame:IsShown() then
		frame.restarting = true
		frame:Hide()
		frame.restarting = nil
	end
	frame.finished = false
	frame.firstRun = firstRun and true or false
	frame.Skip:SetText(firstRun and S.SKIP or CANCEL or "Cancel")
	frame:Show()
	frame:Raise()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	ShowPage(Sequence()[1])
end

function ns.GetSetupFrame()
	return frame
end

---------------------------------------------------------
-- First login
--
-- The family's setup windows open one after another, never on top of each other: oldest plugin first. Class
-- Trainers and Traveler don't know about the newer plugins, so these also wait until both are done with theirs.

local FAMILY = { "ClassTrainers", "Traveler", "WeaponMasters", "ProfessionTrainers", "RecipeVendors", "Innkeepers",
	"SpiritHealers", "MountVendors", "ReagentVendors" }
local OLDER = { "ClassTrainers", "Traveler" }
local ORDER = #FAMILY
for i, name in ipairs(FAMILY) do
	if name == PLUGIN then ORDER = i end
end

local watcher = CreateFrame("Frame")
local hooked, polls = {}, 0

local function OtherWindow()
	for _, name in ipairs(FAMILY) do
		local other = name ~= PLUGIN and _G["HandyNotes" .. name .. "Setup"]
		if type(other) == "table" and other.IsShown and other:IsShown() then return other end
	end
end

-- An older plugin that is loaded but hasn't asked its questions yet; it opens its window a few seconds after login.
local function OlderPending()
	local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded
	if not isLoaded then return false end
	for _, name in ipairs(OLDER) do
		local saved = _G["HandyNotes_" .. name .. "DB"]
		if isLoaded("HandyNotes_" .. name) and type(saved) == "table" then
			local global = rawget(saved, "global")
			if not (type(global) == "table" and rawget(global, "setupDone")) then return true end
		end
	end
	return false
end

local OpenWhenReady

local function Retry(delay)
	C_Timer.After(delay + ORDER / 10, OpenWhenReady)
end

function OpenWhenReady()
	if not ns.db or ns.db.global.setupDone or (frame and frame:IsShown()) then return end
	if InCombatLockdown() then
		watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	local other = OtherWindow()
	if other then
		if not hooked[other] then
			hooked[other] = true
			other:HookScript("OnHide", function() Retry(1) end)
		end
		return
	end
	-- Waits at most a minute for them, in case one of them can't open its window.
	if OlderPending() and polls < 30 then
		polls = polls + 1
		Retry(2)
		return
	end
	ns.OpenSetup(true)
end

watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	-- Class Trainers opens its setup 3 seconds after loading and Traveler after 4, so the newer plugins start after them.
	Retry(event == "PLAYER_ENTERING_WORLD" and 5 or 1)
end)
