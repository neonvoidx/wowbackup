local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.IconShape = addon.IconShape or {}
local IconShape = addon.IconShape

IconShape.DEFAULT = "DEFAULT"
IconShape.SQUARE = "SQUARE"
IconShape.ROUND = "ROUND"
IconShape.ROUND_STAR = "ROUND_STAR"
IconShape.STAR = "STAR"
IconShape.HEXAGON = "HEXAGON"
IconShape.DIAMOND = "DIAMOND"
IconShape.HEXAGON_MASK_TEXTURE = "Interface\\AddOns\\Blizzard_SharedTalentUI\\talents-hexagon-mask.png"
IconShape.ROUND_MASK_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
IconShape.ROUND_STAR_MASK_TEXTURE = "Interface\\AddOns\\EnhanceQoL\\Assets\\round_star_mask.tga"
IconShape.STAR_MASK_TEXTURE = "Interface\\AddOns\\EnhanceQoL\\Assets\\StarShape.tga"
IconShape.DIAMOND_MASK_TEXTURE = "Interface\\AddOns\\EnhanceQoL\\Assets\\diamond_mask.tga"
IconShape.DEFAULT_SWIPE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
IconShape.SQUARE_TEX_COORDS = { 0.07, 0.93, 0.07, 0.93 }
IconShape.ICON_ZOOM_MIN = 0
IconShape.ICON_ZOOM_MAX = 35
IconShape.ICON_ZOOM_DEFAULT = 0

function IconShape.Normalize(value, fallback)
	local normalized = type(value) == "string" and strupper(value) or nil
	if normalized == IconShape.HEXAGON or normalized == "HEX" then return IconShape.HEXAGON end
	if normalized == IconShape.ROUND_STAR or normalized == "ROUNDSTAR" or normalized == "ROUND-STAR" then return IconShape.ROUND_STAR end
	if normalized == IconShape.ROUND or normalized == "CIRCLE" then return IconShape.ROUND end
	if normalized == IconShape.SQUARE then return IconShape.SQUARE end
	if normalized == IconShape.STAR then return IconShape.STAR end
	if normalized == IconShape.DIAMOND then return IconShape.DIAMOND end
	if normalized == IconShape.DEFAULT or normalized == "NONE" then return IconShape.DEFAULT end
	local normalizedFallback = type(fallback) == "string" and strupper(fallback) or nil
	if normalizedFallback == IconShape.HEXAGON or normalizedFallback == "HEX" then return IconShape.HEXAGON end
	if normalizedFallback == IconShape.ROUND_STAR or normalizedFallback == "ROUNDSTAR" or normalizedFallback == "ROUND-STAR" then return IconShape.ROUND_STAR end
	if normalizedFallback == IconShape.ROUND or normalizedFallback == "CIRCLE" then return IconShape.ROUND end
	if normalizedFallback == IconShape.SQUARE then return IconShape.SQUARE end
	if normalizedFallback == IconShape.STAR then return IconShape.STAR end
	if normalizedFallback == IconShape.DIAMOND then return IconShape.DIAMOND end
	return IconShape.DEFAULT
end

function IconShape.GetOptions(localeTable, opts)
	opts = opts or {}
	local excluded = opts.exclude or {}
	local options = {
		{ value = IconShape.DEFAULT, label = (localeTable and localeTable["settingsIconShapeDefault"]) or _G.DEFAULT or "Default" },
		{ value = IconShape.SQUARE, label = (localeTable and localeTable["settingsIconShapeSquare"]) or "Square" },
		{ value = IconShape.ROUND, label = (localeTable and localeTable["settingsIconShapeRound"]) or "Round" },
		{ value = IconShape.ROUND_STAR, label = (localeTable and localeTable["settingsIconShapeRoundStar"]) or "Round star" },
		{ value = IconShape.STAR, label = (localeTable and localeTable["settingsIconShapeStar"]) or "Star" },
		{ value = IconShape.HEXAGON, label = (localeTable and localeTable["settingsIconShapeHexagon"]) or "Hexagon" },
		{ value = IconShape.DIAMOND, label = (localeTable and localeTable["settingsIconShapeDiamond"]) or "Diamond" },
	}
	if not next(excluded) then return options end

	local filtered = {}
	for _, option in ipairs(options) do
		if not excluded[option.value] then filtered[#filtered + 1] = option end
	end
	return filtered
end

IconShape.BORDER = IconShape.BORDER or {
	NONE = "NONE",
	ROUND_1PX = "SHAPE_TEXTURE_ROUND_1PX",
	ROUND_METAL_LIGHT = "SHAPE_ATLAS_CHARACTERCREATE_RING_METALLIGHT",
	ROUND_COMMUNITIES_BLUE = "SHAPE_ATLAS_COMMUNITIES_RING_BLUE",
	ROUND_STAR_1PX = "SHAPE_TEXTURE_ROUND_STAR_1PX",
	HEXAGON_1PX = "SHAPE_TEXTURE_HEXAGON_1PX",
	DIAMOND_1PX = "SHAPE_TEXTURE_DIAMOND_1PX",
}

IconShape.BORDER_DEFINITIONS = IconShape.BORDER_DEFINITIONS or {
	[IconShape.BORDER.ROUND_1PX] = {
		texture = "Interface\\AddOns\\EnhanceQoL\\Assets\\round_1px.tga",
		labelKey = "CooldownPanelIconBorderRound1px",
		label = "Round 1 px",
		shapes = { ROUND = true },
		thicknessMode = "layers",
		tint = true,
	},
	[IconShape.BORDER.ROUND_METAL_LIGHT] = {
		atlas = "charactercreate-ring-metallight",
		labelKey = "CooldownPanelIconBorderCharacterCreateMetalLight",
		label = "Metal light ring",
		shapes = { ROUND = true },
	},
	[IconShape.BORDER.ROUND_COMMUNITIES_BLUE] = {
		atlas = "communities-ring-blue",
		labelKey = "CooldownPanelIconBorderCommunitiesRingBlue",
		label = "Communities blue ring",
		shapes = { ROUND = true },
	},
	[IconShape.BORDER.ROUND_STAR_1PX] = {
		texture = "Interface\\AddOns\\EnhanceQoL\\Assets\\round_star_border.tga",
		labelKey = "CooldownPanelIconBorderRoundStar1px",
		label = "Round star 1 px",
		shapes = { ROUND_STAR = true },
		thicknessMode = "layers",
		tint = true,
	},
	[IconShape.BORDER.HEXAGON_1PX] = {
		texture = "Interface\\AddOns\\EnhanceQoL\\Assets\\hexagon_1px.tga",
		labelKey = "CooldownPanelIconBorderHexagon1px",
		label = "Hexagon 1 px",
		shapes = { HEXAGON = true },
		thicknessMode = "layers",
		tint = true,
	},
	[IconShape.BORDER.DIAMOND_1PX] = {
		texture = "Interface\\AddOns\\EnhanceQoL\\Assets\\diamond_border.tga",
		labelKey = "CooldownPanelIconBorderDiamond1px",
		label = "Diamond 1 px",
		shapes = { DIAMOND = true },
		thicknessMode = "layers",
		tint = true,
	},
}

IconShape.BORDER_ORDER = IconShape.BORDER_ORDER or {
	IconShape.BORDER.ROUND_METAL_LIGHT,
	IconShape.BORDER.ROUND_COMMUNITIES_BLUE,
	IconShape.BORDER.ROUND_1PX,
	IconShape.BORDER.ROUND_STAR_1PX,
	IconShape.BORDER.HEXAGON_1PX,
	IconShape.BORDER.DIAMOND_1PX,
}

function IconShape.IsBackdropBorderCompatible(shape)
	shape = IconShape.Normalize(shape)
	return shape == IconShape.DEFAULT or shape == IconShape.SQUARE
end

function IconShape.GetBorderInfo(value)
	if type(value) ~= "string" then return nil end
	return IconShape.BORDER_DEFINITIONS[value]
end

function IconShape.IsShapeBorder(value)
	return IconShape.GetBorderInfo(value) ~= nil
end

function IconShape.IsNoBorder(value)
	return type(value) == "string" and strupper(value) == IconShape.BORDER.NONE
end

function IconShape.IsBorderCompatible(value, shape)
	local info = IconShape.GetBorderInfo(value)
	if not info then return false end
	shape = IconShape.Normalize(shape)
	return type(info.shapes) ~= "table" or info.shapes[shape] == true
end

function IconShape.SupportsBorderSize(value, shape)
	if IconShape.IsNoBorder(value) then return false end
	if IconShape.IsBackdropBorderCompatible(shape) then return true end
	local info = IconShape.GetBorderInfo(value)
	return info and info.thicknessMode == "layers" or false
end

function IconShape.SupportsBorderOffset(value, shape)
	if IconShape.IsNoBorder(value) then return false end
	if IconShape.IsBackdropBorderCompatible(shape) then return true end
	value = IconShape.NormalizeBorder(value, nil, shape)
	return IconShape.IsBorderCompatible(value, shape) == true
end

function IconShape.HideBorderTextures(owner, opts)
	opts = opts or {}
	local textures = owner and owner[opts.texturesKey or "_eqolIconShapeBorderTextures"]
	if not textures then return end
	for i = 1, #textures do
		if textures[i] then textures[i]:Hide() end
	end
end

function IconShape.EnsureBorderTexture(owner, index, opts)
	if not owner then return nil end
	opts = opts or {}
	local key = opts.texturesKey or "_eqolIconShapeBorderTextures"
	owner[key] = owner[key] or {}
	local texture = owner[key][index]
	if not texture and index == 1 and opts.primaryTexture then
		texture = opts.primaryTexture
		owner[key][index] = texture
	end
	if not texture then
		local parent = opts.parent or owner
		if not (parent and parent.CreateTexture) then return nil end
		texture = parent:CreateTexture(nil, opts.drawLayer or "OVERLAY")
		owner[key][index] = texture
	end
	if texture.SetDrawLayer and opts.drawLayer then texture:SetDrawLayer(opts.drawLayer, opts.subLevel or 1) end
	return texture
end

function IconShape.GetBorderLayerOffset(index)
	if index <= 1 then return 0, 0 end
	local remaining = index - 2
	local radius = 1
	while remaining >= radius * 8 do
		remaining = remaining - (radius * 8)
		radius = radius + 1
	end
	local side = math.floor(remaining / (radius * 2))
	local step = remaining % (radius * 2)
	if side == 0 then return -radius + step, -radius end
	if side == 1 then return radius, -radius + step end
	if side == 2 then return radius - step, radius end
	return -radius, radius - step
end

function IconShape.ApplyBorder(owner, borderKey, shape, opts)
	opts = opts or {}
	shape = IconShape.Normalize(shape)
	borderKey = IconShape.NormalizeBorder(borderKey, opts.fallbackBorderKey, shape, opts)
	local info = IconShape.GetBorderInfo(borderKey)
	if not (owner and info and IconShape.IsBorderCompatible(borderKey, shape)) then return false end

	local borderSize = tonumber(opts.borderSize) or 1
	if borderSize < 1 then borderSize = 1 end
	local borderOffset = tonumber(opts.borderOffset) or 0
	if borderOffset < -64 then borderOffset = -64 end
	if borderOffset > 64 then borderOffset = 64 end
	local pointFrame = opts.pointFrame or owner
	local color = opts.color or { 1, 1, 1, 1 }
	local layerCount = info.thicknessMode == "layers" and math.min(math.floor(borderSize + 0.5), 24) or 1
	local resolvedBorderOffset = borderOffset
	if opts.pixelPerfect == true and addon.PixelUtil and addon.PixelUtil.Snap then resolvedBorderOffset = addon.PixelUtil.Snap(borderOffset, pointFrame) end

	for i = 1, layerCount do
		local texture = IconShape.EnsureBorderTexture(owner, i, opts)
		if texture then
			if info.atlas and texture.SetAtlas then
				texture:SetAtlas(info.atlas, false)
			elseif info.texture then
				texture:SetTexture(info.texture)
				if texture.SetTexCoord then texture:SetTexCoord(0, 1, 0, 1) end
			else
				texture:Hide()
			end
			local layerX, layerY = IconShape.GetBorderLayerOffset(i)
			if opts.pixelPerfect == true and addon.PixelUtil and addon.PixelUtil.SizeFromPixels then
				layerX = addon.PixelUtil.SizeFromPixels(pointFrame, layerX)
				layerY = addon.PixelUtil.SizeFromPixels(pointFrame, layerY)
			end
			texture:ClearAllPoints()
			texture:SetPoint("TOPLEFT", pointFrame, "TOPLEFT", -resolvedBorderOffset + layerX, resolvedBorderOffset - layerY)
			texture:SetPoint("BOTTOMRIGHT", pointFrame, "BOTTOMRIGHT", resolvedBorderOffset + layerX, -resolvedBorderOffset - layerY)
			if info.tint == true then
				texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
			else
				texture:SetVertexColor(1, 1, 1, color[4] or 1)
			end
			texture:Show()
		end
	end

	local textures = owner[opts.texturesKey or "_eqolIconShapeBorderTextures"]
	for i = layerCount + 1, #(textures or {}) do
		if textures[i] then textures[i]:Hide() end
	end
	return true, borderKey, info
end

function IconShape.GetFirstBorderForShape(shape)
	shape = IconShape.Normalize(shape)
	for _, value in ipairs(IconShape.BORDER_ORDER) do
		if IconShape.IsBorderCompatible(value, shape) then return value end
	end
	return nil
end

function IconShape.NormalizeBorder(value, fallback, shape, opts)
	opts = opts or {}
	shape = IconShape.Normalize(shape)
	if opts.allowNone and IconShape.IsNoBorder(value) then return IconShape.BORDER.NONE end
	if opts.allowNone and IconShape.IsNoBorder(fallback) then fallback = nil end
	if not IconShape.IsBackdropBorderCompatible(shape) then
		if IconShape.IsBorderCompatible(value, shape) then return value end
		if IconShape.IsBorderCompatible(fallback, shape) then return fallback end
		return IconShape.GetFirstBorderForShape(shape) or (opts.emptyValue or "DEFAULT")
	end
	if IconShape.IsShapeBorder(value) then value = nil end
	if IconShape.IsShapeBorder(fallback) then fallback = nil end
	if type(value) == "string" and value ~= "" then return value end
	if type(fallback) == "string" and fallback ~= "" then return fallback end
	return opts.emptyValue or "DEFAULT"
end

function IconShape.GetBorderOptions(localeTable, shape, opts)
	opts = opts or {}
	shape = IconShape.Normalize(shape, IconShape.DEFAULT)
	local list = {}
	local seen = {}
	local function add(value, label)
		local key = tostring(value or ""):lower()
		if key == "" or seen[key] then return end
		seen[key] = true
		list[#list + 1] = { value = value, label = label or value }
	end

	if not IconShape.IsBackdropBorderCompatible(shape) then
		if opts.includeNone then add(IconShape.BORDER.NONE, opts.noneLabel or _G.NONE or "None") end
		for _, value in ipairs(IconShape.BORDER_ORDER) do
			local info = IconShape.GetBorderInfo(value)
			if info and IconShape.IsBorderCompatible(value, shape) then add(value, (localeTable and localeTable[info.labelKey]) or info.label) end
		end
		return list
	end

	local defaultOptions = opts.defaultOptions
	if opts.includeNone then add(IconShape.BORDER.NONE, opts.noneLabel or _G.NONE or "None") end
	if type(defaultOptions) == "table" then
		for _, option in ipairs(defaultOptions) do
			add(option.value, option.label)
		end
	elseif opts.includeDefault ~= false then
		add(opts.defaultValue or "DEFAULT", opts.defaultLabel or _G.DEFAULT or "Default")
	end

	if opts.includeLSM ~= false then
		local names = opts.lsmNames
		local hash = opts.lsmHash
		if (not names or not hash) and addon.functions then
			names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(opts.lsmType or "border")
			hash = addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash(opts.lsmType or "border")
		end
		names = type(names) == "table" and names or {}
		hash = type(hash) == "table" and hash or {}
		for i = 1, #names do
			local name = names[i]
			local path = hash[name]
			if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
		end
	end

	if opts.sort == true then table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end) end
	return list
end

function IconShape.GetMaskTexture(shape)
	shape = IconShape.Normalize(shape)
	if shape == IconShape.ROUND then return IconShape.ROUND_MASK_TEXTURE end
	if shape == IconShape.ROUND_STAR then return IconShape.ROUND_STAR_MASK_TEXTURE end
	if shape == IconShape.STAR then return IconShape.STAR_MASK_TEXTURE end
	if shape == IconShape.HEXAGON then return IconShape.HEXAGON_MASK_TEXTURE end
	if shape == IconShape.DIAMOND then return IconShape.DIAMOND_MASK_TEXTURE end
	return nil
end

function IconShape.ApplyTextureMask(texture, mask, key)
	if not (texture and mask and texture.AddMaskTexture) then return false end
	key = key or "_eqolIconShapeMask"
	if texture[key] == mask then return true end
	if texture[key] and texture.RemoveMaskTexture then pcall(texture.RemoveMaskTexture, texture, texture[key]) end
	local ok = pcall(texture.AddMaskTexture, texture, mask)
	texture[key] = ok and mask or nil
	return ok == true
end

function IconShape.ClearTextureMask(texture, key)
	if not texture then return end
	key = key or "_eqolIconShapeMask"
	if texture[key] and texture.RemoveMaskTexture then pcall(texture.RemoveMaskTexture, texture, texture[key]) end
	texture[key] = nil
end

function IconShape.EnsureMask(frame, shape, key)
	if not (frame and frame.CreateMaskTexture) then return nil end
	shape = IconShape.Normalize(shape)
	local maskTexture = IconShape.GetMaskTexture(shape)
	if not maskTexture then return nil end
	key = key or "_eqolIconShapeMask"
	local mask = frame[key]
	if not mask then
		mask = frame:CreateMaskTexture(nil, "BACKGROUND")
		frame[key] = mask
	end
	mask:SetTexture(maskTexture)
	mask:ClearAllPoints()
	mask:SetAllPoints(frame)
	return mask
end

function IconShape.ApplyCooldownRegionMask(cooldown, mask, key)
	if not (cooldown and cooldown.GetRegions and cooldown.GetNumRegions) then return end
	for index = 1, cooldown:GetNumRegions() do
		local region = select(index, cooldown:GetRegions())
		if region then
			if mask then
				IconShape.ApplyTextureMask(region, mask, key)
			else
				IconShape.ClearTextureMask(region, key)
			end
		end
	end
end

function IconShape.GetCooldownSwipeTexture(shape, blizzardSwipeTexture)
	shape = IconShape.Normalize(shape)
	if shape == IconShape.HEXAGON then return IconShape.HEXAGON_MASK_TEXTURE end
	if shape == IconShape.ROUND then return IconShape.ROUND_MASK_TEXTURE end
	if shape == IconShape.ROUND_STAR then return IconShape.ROUND_STAR_MASK_TEXTURE end
	if shape == IconShape.STAR then return IconShape.STAR_MASK_TEXTURE end
	if shape == IconShape.DIAMOND then return IconShape.DIAMOND_MASK_TEXTURE end
	if shape == IconShape.SQUARE then return IconShape.DEFAULT_SWIPE_TEXTURE end
	if type(blizzardSwipeTexture) == "string" and blizzardSwipeTexture ~= "" then return blizzardSwipeTexture end
	return IconShape.DEFAULT_SWIPE_TEXTURE
end

function IconShape.ApplyCooldownSwipeVisual(cooldown, owner, colorFunc, data, opts)
	if not cooldown then return end
	opts = opts or {}
	local r, g, b, a = 1, 1, 1, 1
	if colorFunc then r, g, b, a = colorFunc(data) end
	local needsCustomSwipeColor = opts.customColor == true
	local swipeTexture = IconShape.GetCooldownSwipeTexture(owner and owner._eqolIconShape, opts.blizzardSwipeTexture)
	local shapeSwipe = owner and owner._eqolIconShape and owner._eqolIconShape ~= IconShape.DEFAULT
	local customSwipeTexture = swipeTexture ~= IconShape.DEFAULT_SWIPE_TEXTURE
	local textureR, textureG, textureB, textureA = r, g, b, a
	if shapeSwipe and not needsCustomSwipeColor then
		textureR, textureG, textureB, textureA = 0, 0, 0, 0.8
	end
	if cooldown.SetSwipeTexture and (shapeSwipe or customSwipeTexture or needsCustomSwipeColor or (owner and owner._eqolSwipeTexturePath ~= nil)) then
		if
			not owner
			or owner._eqolSwipeTexturePath ~= swipeTexture
			or owner._eqolSwipeTextureR ~= textureR
			or owner._eqolSwipeTextureG ~= textureG
			or owner._eqolSwipeTextureB ~= textureB
			or owner._eqolSwipeTextureA ~= textureA
		then
			local ok = pcall(cooldown.SetSwipeTexture, cooldown, swipeTexture, textureR, textureG, textureB, textureA)
			if ok and owner then
				owner._eqolSwipeTexturePath = swipeTexture
				owner._eqolSwipeTextureR, owner._eqolSwipeTextureG, owner._eqolSwipeTextureB, owner._eqolSwipeTextureA = textureR, textureG, textureB, textureA
			end
		end
	end
	if needsCustomSwipeColor and cooldown.SetSwipeColor then
		if not owner or owner._eqolSwipeColorR ~= r or owner._eqolSwipeColorG ~= g or owner._eqolSwipeColorB ~= b or owner._eqolSwipeColorA ~= a then
			cooldown:SetSwipeColor(r, g, b, a)
			if owner then owner._eqolSwipeColorR, owner._eqolSwipeColorG, owner._eqolSwipeColorB, owner._eqolSwipeColorA = r, g, b, a end
		end
	elseif not needsCustomSwipeColor then
		if cooldown.SetSwipeColor and owner and owner._eqolSwipeColorR ~= nil then cooldown:SetSwipeColor(0, 0, 0, 0.8) end
		if owner then owner._eqolSwipeColorR, owner._eqolSwipeColorG, owner._eqolSwipeColorB, owner._eqolSwipeColorA = nil, nil, nil, nil end
	end
end

function IconShape.ResetCooldownSwipeVisual(cooldown, owner)
	if not cooldown then return end
	if cooldown.SetSwipeTexture then pcall(cooldown.SetSwipeTexture, cooldown, IconShape.DEFAULT_SWIPE_TEXTURE, 0, 0, 0, 0.8) end
	if cooldown.SetSwipeColor then cooldown:SetSwipeColor(0, 0, 0, 0.8) end
	if owner then
		owner._eqolSwipeTexturePath = nil
		owner._eqolSwipeTextureR, owner._eqolSwipeTextureG, owner._eqolSwipeTextureB, owner._eqolSwipeTextureA = nil, nil, nil, nil
		owner._eqolSwipeColorR, owner._eqolSwipeColorG, owner._eqolSwipeColorB, owner._eqolSwipeColorA = nil, nil, nil, nil
	end
end

function IconShape.StoreTextureTexCoord(texture, key)
	if not (texture and texture.GetTexCoord) then return end
	key = key or "_eqolIconShapeTexCoord"
	if texture[key] then return end
	texture[key] = { texture:GetTexCoord() }
end

function IconShape.RestoreTextureTexCoord(texture, key)
	if not (texture and texture.SetTexCoord) then return end
	key = key or "_eqolIconShapeTexCoord"
	local coords = texture[key]
	if type(coords) == "table" and #coords >= 4 then
		texture:SetTexCoord(unpack(coords))
	end
	texture[key] = nil
end

function IconShape.ApplyTextureTexCoord(texture, coords, key)
	if not (texture and texture.SetTexCoord and type(coords) == "table") then return end
	IconShape.StoreTextureTexCoord(texture, key)
	texture:SetTexCoord(coords[1] or 0, coords[2] or 1, coords[3] or 0, coords[4] or 1)
end

function IconShape.NormalizeIconZoom(value, fallback)
	local zoom = tonumber(value)
	if zoom == nil then zoom = tonumber(fallback) or IconShape.ICON_ZOOM_DEFAULT end
	if zoom < IconShape.ICON_ZOOM_MIN then zoom = IconShape.ICON_ZOOM_MIN end
	if zoom > IconShape.ICON_ZOOM_MAX then zoom = IconShape.ICON_ZOOM_MAX end
	return zoom
end

function IconShape.GetZoomTexCoords(zoom, baseInset)
	zoom = IconShape.NormalizeIconZoom(zoom)
	local inset = (tonumber(baseInset) or 0) + (zoom / 100)
	if inset < 0 then inset = 0 end
	if inset > 0.45 then inset = 0.45 end
	return { inset, 1 - inset, inset, 1 - inset }
end

function IconShape.ApplyTextureZoom(texture, zoom, key, baseInset)
	zoom = IconShape.NormalizeIconZoom(zoom)
	baseInset = tonumber(baseInset) or 0
	if zoom <= 0 and baseInset <= 0 then
		IconShape.RestoreTextureTexCoord(texture, key)
		return
	end
	IconShape.ApplyTextureTexCoord(texture, IconShape.GetZoomTexCoords(zoom, baseInset), key)
end

function IconShape.ApplyFrameShape(frame, shape, opts)
	if not frame then return end
	opts = opts or {}
	shape = IconShape.Normalize(shape)
	local iconZoom = IconShape.NormalizeIconZoom(opts.iconZoom)
	if shape == IconShape.DEFAULT then
		frame._eqolIconShape = IconShape.DEFAULT
		for _, texture in ipairs(opts.textures or {}) do
			IconShape.ClearTextureMask(texture, opts.textureMaskKey)
			IconShape.ApplyTextureZoom(texture, iconZoom, opts.textureTexCoordKey, 0)
		end
		IconShape.ApplyCooldownRegionMask(opts.cooldown, nil, opts.textureMaskKey)
		frame._eqolGlowShape = nil
		IconShape.ResetCooldownSwipeVisual(opts.cooldown, frame)
		if opts.refreshSwipe then opts.refreshSwipe(frame) end
		return
	end

	if shape == IconShape.SQUARE then
		frame._eqolIconShape = IconShape.SQUARE
		for _, texture in ipairs(opts.textures or {}) do
			IconShape.ClearTextureMask(texture, opts.textureMaskKey)
			if iconZoom > 0 then
				IconShape.ApplyTextureZoom(texture, iconZoom, opts.textureTexCoordKey, 0.07)
			else
				IconShape.ApplyTextureTexCoord(texture, opts.squareTexCoords or IconShape.SQUARE_TEX_COORDS, opts.textureTexCoordKey)
			end
		end
		IconShape.ApplyCooldownRegionMask(opts.cooldown, nil, opts.textureMaskKey)
		frame._eqolGlowShape = nil
		IconShape.ResetCooldownSwipeVisual(opts.cooldown, frame)
		if opts.refreshSwipe then opts.refreshSwipe(frame) end
		return
	end

	local mask = IconShape.EnsureMask(frame, shape, opts.maskKey)
	frame._eqolIconShape = shape
	frame._eqolGlowShape = shape
	for _, texture in ipairs(opts.textures or {}) do
		IconShape.ApplyTextureZoom(texture, iconZoom, opts.textureTexCoordKey, 0)
		IconShape.ApplyTextureMask(texture, mask, opts.textureMaskKey)
	end
	IconShape.ApplyCooldownRegionMask(opts.cooldown, mask, opts.textureMaskKey)
	if opts.refreshSwipe then opts.refreshSwipe(frame) end
end
