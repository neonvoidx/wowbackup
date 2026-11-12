local _, addon = ...
local M = { defaultColor = { r = 0.65, g = 0.45, b = 1, a = 0.8 } }
addon.WorldMapReveal = M

-- Keep addon state off native map pins, including pins reused by the canvas.
local pinStates = setmetatable({}, { __mode = "k" })
local function getPinState(pin)
	local state = pinStates[pin]
	if not state then
		state = { textures = {} }
		pinStates[pin] = state
	end
	return state
end

function M.IsSecret(value)
	return (_G.issecretvalue and _G.issecretvalue(value)) or (type(value) == "table" and _G.issecrettable and _G.issecrettable(value)) or false
end

function M.Clear(pin)
	local state = pinStates[pin]
	if not state then return end
	for _, texture in ipairs(state.textures) do
		texture:Hide()
	end
end

function M.GetColor()
	local color = addon.db and addon.db.worldMapRevealColor or M.defaultColor
	return color.r, color.g, color.b, color.a or 1
end

function M.RefreshPin(pin)
	M.Clear(pin)
	if not (addon.db and addon.db.worldMapReveal) then return end
	local map = pin:GetMap()
	local mapID = map:GetMapID()
	if not mapID then return end
	local artID = C_Map.GetMapArtID(mapID)
	local art = addon.WorldMapRevealData.art[artID]
	if not art then return end
	local container = map:GetCanvasContainer()
	-- Settings can refresh the pin before the map initializes its zoom levels.
	if not (container and container.zoomLevels and container.zoomLevels[1]) then return end
	local layerIndex = container:GetCurrentLayerIndex()
	local data = art[layerIndex]
	if not data then return end
	local layers = C_Map.GetMapArtLayers(mapID)
	local layer = layers and layers[layerIndex]
	if not layer or layer.tileWidth ~= data.tileWidth or layer.tileHeight ~= data.tileHeight then return end

	local explored = {}
	local overlays = _G.C_MapExplorationInfo.GetExploredMapTextures(mapID)
	if M.IsSecret(overlays) then return end
	for _, overlay in ipairs(overlays or {}) do
		if M.IsSecret(overlay) then return end
		local ids = overlay.fileDataIDs
		if M.IsSecret(ids) or M.IsSecret(overlay.isShownByMouseOver) then return end
		-- Hover-only artwork does not indicate that the area has been explored.
		if not overlay.isShownByMouseOver then
			for _, id in ipairs(ids or {}) do
				if M.IsSecret(id) then return end
				explored[id] = true
			end
		end
	end

	local r, g, b = 1, 1, 1
	if addon.db.worldMapRevealTint ~= false then
		local alpha
		r, g, b, alpha = M.GetColor()
		-- Alpha controls tint strength; the revealed artwork itself stays opaque.
		local original = 1 - alpha
		r, g, b = original + r * alpha, original + g * alpha, original + b * alpha
	end
	local drawLayer, subLevel = pin.dataProvider:GetDrawLayer()
	local textures = getPinState(pin).textures
	local used = 0
	for _, overlay in ipairs(data.overlays) do
		local columns = math.ceil(overlay.width / data.tileWidth)
		for index, fileID in ipairs(overlay.files) do
			if fileID > 0 and not explored[fileID] then
				local col = (index - 1) % columns
				local row = math.floor((index - 1) / columns)
				local width = math.min(data.tileWidth, overlay.width - col * data.tileWidth)
				local height = math.min(data.tileHeight, overlay.height - row * data.tileHeight)
				local fileWidth, fileHeight = 16, 16
				while fileWidth < width do fileWidth = fileWidth * 2 end
				while fileHeight < height do fileHeight = fileHeight * 2 end
				used = used + 1
				local texture = textures[used]
				if not texture then
					texture = pin:CreateTexture(nil, drawLayer)
					textures[used] = texture
					map:AddMaskableTexture(texture)
				end
				-- Native explored artwork stays above the additional tiles.
				texture:SetDrawLayer(drawLayer, subLevel + (overlay.topLayer and 0 or -1))
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", pin, "TOPLEFT", overlay.x + col * data.tileWidth, -(overlay.y + row * data.tileHeight))
				texture:SetSize(width, height)
				texture:SetTexCoord(0, width / fileWidth, 0, height / fileHeight)
				texture:SetTexture(fileID, nil, nil, "TRILINEAR")
				texture:SetVertexColor(r, g, b, 1)
				texture:Show()
				if pin.isWaitingForLoad then pin.textureLoadGroup:AddTexture(texture) end
			end
		end
	end
end

function M.Refresh()
	local map = _G.WorldMapFrame
	if not (map and map.EnumeratePinsByTemplate) then return end
	for pin in map:EnumeratePinsByTemplate("MapExplorationPinTemplate") do
		local state = getPinState(pin)
		if not state.hooked then
			state.hooked = true
			hooksecurefunc(pin, "RemoveAllData", M.Clear)
			hooksecurefunc(pin, "RefreshOverlays", M.RefreshPin)
		end
		M.RefreshPin(pin)
	end
end

M.events = CreateFrame("Frame")
M.events:RegisterEvent("ADDON_LOADED")
M.events:RegisterEvent("PLAYER_LOGIN")
M.events:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" or name == "Blizzard_WorldMap" then
		local map = _G.WorldMapFrame
		if map and not M.mapHooked then
			M.mapHooked = true
			map:HookScript("OnShow", M.Refresh)
		end
		M.Refresh()
	end
end)

function M.Init()
	addon.functions.InitDBValue("worldMapReveal", false)
	addon.functions.InitDBValue("worldMapRevealTint", true)
	addon.functions.InitDBValue("worldMapRevealColor", { r = 0.65, g = 0.45, b = 1, a = 0.8 })
	M.Refresh()
end

function M.RegisterSettings(category, parentSection, L)
	addon.functions.SettingsCreateCheckbox(category, {
		var = "worldMapReveal",
		text = L["worldMapReveal"],
		desc = L["worldMapRevealDesc"],
		default = false,
		newTagID = "worldMapReveal",
		parentSection = parentSection,
		groupID = "world-map",
		groupTitle = L["World Map"],
		func = function(value)
			addon.db.worldMapReveal = value
			addon.WorldMapReveal.Refresh()
		end,
	})
	addon.functions.SettingsCreateCheckbox(category, {
		var = "worldMapRevealTint",
		text = L["worldMapRevealTint"],
		desc = L["worldMapRevealTintDesc"],
		default = true,
		newTagID = "worldMapRevealTint",
		parentSection = parentSection,
		groupID = "world-map",
		groupTitle = L["World Map"],
		indent = 16,
		parentCheck = function() return addon.db.worldMapReveal == true end,
		func = function(value)
			addon.db.worldMapRevealTint = value
			addon.WorldMapReveal.Refresh()
		end,
	})
	addon.functions.SettingsCreateColorPicker(category, {
		var = "worldMapRevealColor",
		text = L["worldMapRevealColor"],
		desc = L["worldMapRevealColorDesc"],
		default = addon.WorldMapReveal.defaultColor,
		newTagID = "worldMapRevealColor",
		parentSection = parentSection,
		groupID = "world-map",
		groupTitle = L["World Map"],
		indent = 16,
		hasOpacity = true,
		parentCheck = function() return addon.db.worldMapReveal == true and addon.db.worldMapRevealTint ~= false end,
		getColor = addon.WorldMapReveal.GetColor,
		setColor = function(_, r, g, b, a)
			addon.db.worldMapRevealColor = { r = r, g = g, b = b, a = a or 1 }
			addon.WorldMapReveal.Refresh()
		end,
	})
end
