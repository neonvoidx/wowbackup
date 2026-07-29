local addonName, addon = ...

local _, _, _, interfaceVersion = GetBuildInfo()
if (tonumber(interfaceVersion) or 0) < 120100 then
	return
end

addon.AuraCompat = addon.AuraCompat or {}
local AuraCompat = addon.AuraCompat

local C_AddOns = _G.C_AddOns
local C_Secrets = _G.C_Secrets
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime
local InCombatLockdown = _G.InCombatLockdown
local UIParent = _G.UIParent
local issecretvalue = _G.issecretvalue

local AURA_CONTAINER_ADDON = "Blizzard_AuraContainer"
local DEFAULT_CONTAINER_TEMPLATE = "CustomAuraContainerTemplate"

local REQUIRED_CONTAINER_METHODS = {
	"AddAuraGroup",
	"AddAuraSlot",
	"AddItemEnchantment",
	"GetAuraGroupFrame",
	"GetAuraGroupFrameCount",
	"HasAuraGroup",
	"SetAuraGroupCandidateFilters",
	"SetAuraGroupFilterString",
	"SetAuraGroupLayout",
	"SetAuraGroupMaxFrameCount",
	"SetAuraGroupSortMethod",
	"SetAuraSlotCandidateFilters",
	"SetAuraSlotFilterString",
	"SetAuraSlotSortMethod",
	"SetItemEnchantmentLayout",
	"SetItemEnchantmentSortMethod",
	"ResetFlowLayoutOptions",
	"SetFlowLayoutAnchorPoint",
	"SetFlowLayoutAxis",
	"SetFlowLayoutGrowthDirection",
	"SetFlowLayoutMaximumLineSize",
	"SetFlowLayoutPadding",
	"SetEnabled",
	"SetUnit",
	"UpdateAllAuras",
}
local groupFiltersByContainer = setmetatable({}, { __mode = "k" })
local slotFramesByContainer = setmetatable({}, { __mode = "k" })
local itemEnchantmentFramesByContainer = setmetatable({}, { __mode = "k" })
local tooltipPolicyByButton = setmetatable({}, { __mode = "k" })
AuraCompat._flowLayoutAxisByContainer = AuraCompat._flowLayoutAxisByContainer or setmetatable({}, { __mode = "k" })

AuraCompat.interfaceVersion = interfaceVersion
AuraCompat.containerAddonName = AURA_CONTAINER_ADDON
AuraCompat.defaultContainerTemplate = DEFAULT_CONTAINER_TEMPLATE

local function CallContainerMethod(container, methodName, ...)
	local method = container and container[methodName]
	if type(method) ~= "function" then return false end
	return true, method(container, ...)
end

local function HasRequiredContainerMethods(container)
	if not container then return false end
	for i = 1, #REQUIRED_CONTAINER_METHODS do
		if type(container[REQUIRED_CONTAINER_METHODS[i]]) ~= "function" then return false end
	end
	return true
end

local function GetInboundAuraSlotOptions(options)
	local anchorFrame = options and options.anchorFrame
	local cancelAuraButtons = options and options.cancelAuraButtons
	if anchorFrame == nil and cancelAuraButtons == nil then return options end

	local inbound = {}
	for key, value in pairs(options) do
		if key ~= "anchorFrame" and key ~= "cancelAuraButtons" then inbound[key] = value end
	end
	local initializeFrame = inbound.initializeFrame
	inbound.initializeFrame = function(button)
		-- Runtime-created AuraButtons can receive access restrictions immediately
		-- after initializeFrame returns. Login/reload creation defers those
		-- restrictions until PLAYER_ENTERING_WORLD, but configuring every
		-- AuraButton-owned relationship here remains safe in both paths.
		if anchorFrame then
			button:ClearAllPoints()
			button:SetAllPoints(anchorFrame)
		end
		if cancelAuraButtons ~= nil and button.SetCancelAuraButtons then button:SetCancelAuraButtons(cancelAuraButtons) end
		if initializeFrame then initializeFrame(button) end
	end
	return inbound
end

function AuraCompat:IsSecretValue(value)
	return issecretvalue and issecretvalue(value) or false
end

function AuraCompat:ShouldAurasBeSecret()
	return C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() == true or false
end

function AuraCompat:CanReadAuraData()
	return not self:ShouldAurasBeSecret()
end

local function IsTooltipHideOverrideActive()
	local db = addon.db
	if not (db and db.TooltipHideOverrideEnabled) then return false end
	local modifier = db.TooltipHideOverrideModifier or "CTRL"
	if modifier == "SHIFT" then return _G.IsShiftKeyDown and _G.IsShiftKeyDown() == true end
	if modifier == "ALT" then return _G.IsAltKeyDown and _G.IsAltKeyDown() == true end
	if modifier == "CTRL" then return _G.IsControlKeyDown and _G.IsControlKeyDown() == true end
	return false
end

function AuraCompat:GetGlobalAuraButtonTooltipHidePolicy()
	if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EnhanceQoLTooltip")) then return false, false end
	local db = addon.db
	if not db or tonumber(db.TooltipBuffHideType) ~= 2 or IsTooltipHideOverrideActive() then return false, false end
	if db.TooltipBuffHideInDungeon == true then
		local inInstance = _G.IsInInstance and select(1, _G.IsInInstance()) == true
		if not inInstance then return false, false end
	end
	if db.TooltipBuffHideInCombat == true then return false, true end
	return true, false
end

function AuraCompat:ShouldHideAuraButtonTooltipInCombat(explicitHideInCombat)
	local hideAlways, hideInCombat = self:GetGlobalAuraButtonTooltipHidePolicy()
	return explicitHideInCombat == true or hideAlways or hideInCombat
end

function AuraCompat:ApplyAuraButtonTooltipPolicy(button, policy)
	if not (button and type(policy) == "table") then return false end
	local hideAlways, hideInCombat = self:GetGlobalAuraButtonTooltipHidePolicy()
	local hideInCombatMethod = button.SetHideTooltipInCombat
	if type(hideInCombatMethod) == "function" then
		-- PTR7 exposes AuraButton APIs through secure delegates, so this remains
		-- callable even when normal ScriptObject mutation is restricted.
		hideInCombatMethod(button, policy.explicitHideInCombat == true or hideAlways or hideInCombat)
	end

	local canAccess = not button.CanBeAccessedInContext or button:CanBeAccessedInContext()
	if issecretvalue and issecretvalue(canAccess) then canAccess = false end
	if canAccess == true and type(button.SetMouseMotionEnabled) == "function" then
		button:SetMouseMotionEnabled(policy.tooltipEnabled == true and not hideAlways)
		return true
	end
	self._auraTooltipMotionRefreshPending = true
	return false
end

function AuraCompat:EnsureAuraButtonTooltipPolicyEvents()
	if self._auraTooltipPolicyEventFrame then return end
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:SetScript("OnEvent", function() AuraCompat:RefreshAuraButtonTooltipPolicy() end)
	self._auraTooltipPolicyEventFrame = frame
end

function AuraCompat:RegisterAuraButtonTooltipPolicy(button, explicitHideInCombat, tooltipEnabled)
	if not (button and type(button.SetHideTooltipInCombat) == "function") then return false end
	local policy = {
		explicitHideInCombat = explicitHideInCombat == true,
		tooltipEnabled = tooltipEnabled ~= false,
	}
	tooltipPolicyByButton[button] = policy
	self:EnsureAuraButtonTooltipPolicyEvents()
	return self:ApplyAuraButtonTooltipPolicy(button, policy)
end

function AuraCompat:RefreshAuraButtonTooltipPolicy()
	self._auraTooltipMotionRefreshPending = nil
	for button, policy in pairs(tooltipPolicyByButton) do self:ApplyAuraButtonTooltipPolicy(button, policy) end
end

addon.functions.RefreshNativeAuraTooltipPolicy = function() AuraCompat:RefreshAuraButtonTooltipPolicy() end

function AuraCompat:ShouldUseAuraContainer()
	-- AuraContainers are the only supported 12.1 renderer and PTR7 permits
	-- addons to create them both before and during combat.
	return self:HasAuraContainerSupport()
end

function AuraCompat:EnsureAuraContainerLoaded()
	if self._auraContainerLoadChecked then return self._auraContainerLoadOK == true end

	if not C_AddOns then
		self._auraContainerLoadChecked = true
		self._auraContainerLoadOK = true
		return true
	end

	if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) then
		self._auraContainerLoadChecked = true
		self._auraContainerLoadOK = true
		return true
	end

	-- PTR7 permits creating AuraContainers in combat, but does not document
	-- C_AddOns.LoadAddOn itself as combat-safe. The main addon preloads the
	-- Blizzard implementation during ADDON_LOADED; only defer this LoD step.
	if InCombatLockdown and InCombatLockdown() then
		self._auraContainerLoadDeferred = true
		return false
	end

	if C_AddOns.LoadAddOn then
		local loaded = C_AddOns.LoadAddOn(AURA_CONTAINER_ADDON)
		local isLoaded = loaded == true or (C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(AURA_CONTAINER_ADDON) == true)
		if isLoaded then
			self._auraContainerLoadChecked = true
			self._auraContainerLoadOK = true
			return true
		end
	end

	self._auraContainerLoadOK = false
	return false
end

function AuraCompat:HasAuraContainerSupport()
	if self._hasAuraContainerSupport ~= nil then return self._hasAuraContainerSupport == true end
	if type(CreateFrame) ~= "function" or not self:EnsureAuraContainerLoaded() then
		return false
	end

	local probe = CreateFrame("AuraContainer", nil, UIParent, DEFAULT_CONTAINER_TEMPLATE)
	if not HasRequiredContainerMethods(probe) then return false end
	self._hasAuraContainerSupport = true
	if probe then
		CallContainerMethod(probe, "SetEnabled", false)
		CallContainerMethod(probe, "Hide")
		self._supportProbe = probe
	end
	return self._hasAuraContainerSupport == true
end

function AuraCompat:CreateAuraContainer(parent, name, template)
	if type(CreateFrame) ~= "function" or not self:HasAuraContainerSupport() then return nil end
	parent = parent or UIParent
	template = template or DEFAULT_CONTAINER_TEMPLATE

	local container = CreateFrame("AuraContainer", name, parent, template)
	if HasRequiredContainerMethods(container) then return container end
	return nil
end

local RESTRICTED_GLOW_MASK_TEXTURE = [[Interface\Buttons\WHITE8X8]]
local RESTRICTED_GLOW_HORIZONTAL_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\glow_dash_h.tga]]
local RESTRICTED_GLOW_VERTICAL_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\glow_dash_v.tga]]
local RESTRICTED_GLOW_BLIZZARD_TEXTURE = [[Interface\SpellActivationOverlay\IconAlert]]
local RESTRICTED_GLOW_BLIZZARD_ANTS_TEXTURE = [[Interface\SpellActivationOverlay\IconAlertAnts]]
local RESTRICTED_GLOW_MARCHING_ANTS_ATLAS = "VisualAlert_Ants_Flipbook"
local RESTRICTED_GLOW_FLASH_ATLAS = "UI-CooldownManager-VisualAlert-Glow"
local RESTRICTED_GLOW_HEXAGON_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\hexagon_1px.tga]]
local RESTRICTED_GLOW_DIAMOND_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\diamond_glow.tga]]
local RESTRICTED_GLOW_ROUND_STAR_TEXTURE = [[Interface\AddOns\EnhanceQoL\Assets\round_star_border.tga]]
local RESTRICTED_GLOW_ROUND_ATLAS = "ChallengeMode-KeystoneSlotFrameGlow"
local RESTRICTED_GLOW_BLIZZARD_BORDER_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"

local function GetRestrictedAuraGlowConfig(anchorFrame, options)
	options = type(options) == "table" and options or {}
	local color = type(options.color) == "table" and options.color or {}
	local style = type(options.style) == "string" and string.upper(options.style) or "PIXEL"
	if
		style ~= "BLIZZARD"
		and style ~= "FLASH"
		and style ~= "MARCHING_ANTS"
		and style ~= "PIXEL"
		and style ~= "PULSING"
		and style ~= "SOLID"
		and style ~= "TINT_BORDER"
	then
		style = "PIXEL"
	end
	local inset = tonumber(options.inset) or 0
	local baseWidth = tonumber(options.width)
	if not baseWidth or baseWidth <= 0 then
		baseWidth = anchorFrame.GetWidth and anchorFrame:GetWidth() or nil
		if type(baseWidth) ~= "number" or baseWidth <= 0 then baseWidth = 36 end
	end
	local baseHeight = tonumber(options.height)
	if not baseHeight or baseHeight <= 0 then
		baseHeight = anchorFrame.GetHeight and anchorFrame:GetHeight() or nil
		if type(baseHeight) ~= "number" or baseHeight <= 0 then baseHeight = baseWidth end
	end
	local frequency = tonumber(options.frequency) or 0.25
	local period = frequency ~= 0 and math.abs(1 / frequency) or 4
	if period < 0.05 then period = 0.05 end
	local borderOffset = tonumber(options.borderOffset) or 0
	local borderIsBlizzard = options.borderIsBlizzard == true
	return {
		style = style,
		inset = inset,
		rootInset = style == "TINT_BORDER" and (borderIsBlizzard and 0 or borderOffset) or inset,
		xOffset = tonumber(options.xOffset) or 0,
		yOffset = tonumber(options.yOffset) or 0,
		levelOffset = tonumber(options.frameLevelOffset) or 15,
		strata = type(options.strata) == "string" and options.strata ~= "" and options.strata or nil,
		r = tonumber(color.r or color[1]) or 1,
		g = tonumber(color.g or color[2]) or 0.82,
		b = tonumber(color.b or color[3]) or 0.2,
		a = tonumber(color.a or color[4]) or 1,
		count = math.max(1, math.floor((tonumber(options.count) or 8) + 0.5)),
		thickness = math.max(1, tonumber(options.thickness) or 2),
		frequency = frequency,
		period = period,
		direction = frequency < 0 and -1 or 1,
		baseWidth = baseWidth,
		baseHeight = baseHeight,
		width = math.max(1, baseWidth + (2 * inset)),
		height = math.max(1, baseHeight + (2 * inset)),
		shape = type(options.shape) == "string" and string.upper(options.shape) or "DEFAULT",
		border = options.border == true,
		borderEnabled = options.borderEnabled == true,
		borderTexture = options.borderTexture,
		borderSize = math.max(1, tonumber(options.borderSize) or 1),
		borderOffset = borderOffset,
		borderIsBlizzard = borderIsBlizzard,
	}
end

local function ConfigureRestrictedGlowRoot(glow, anchorFrame, config)
	glow:ClearAllPoints()
	glow:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", -config.rootInset + config.xOffset, config.rootInset + config.yOffset)
	glow:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMRIGHT", config.rootInset + config.xOffset, -config.rootInset + config.yOffset)
	if config.strata then
		glow:SetFrameStrata(config.strata)
	elseif anchorFrame.GetFrameStrata then
		glow:SetFrameStrata(anchorFrame:GetFrameStrata())
	end
	if anchorFrame.GetFrameLevel then glow:SetFrameLevel(math.max(0, (anchorFrame:GetFrameLevel() or 0) + config.levelOffset)) end
	glow:SetAlpha(1)
end

local function ConfigureRestrictedLineBorder(glow, config, additive, trimCorners)
	glow.Lines = glow.Lines or {}
	for lineIndex = 1, 4 do
		local line = glow.Lines[lineIndex]
		if not line then
			line = glow:CreateTexture(nil, "OVERLAY", nil, 7)
			line:SetTexture(RESTRICTED_GLOW_MASK_TEXTURE)
			glow.Lines[lineIndex] = line
		end
		if line.SetBlendMode then line:SetBlendMode(additive and "ADD" or "BLEND") end
		line:SetVertexColor(config.r, config.g, config.b, config.lineAlpha or 1)
		line:ClearAllPoints()
		line:Show()
	end
	local top, right, bottom, left = glow.Lines[1], glow.Lines[2], glow.Lines[3], glow.Lines[4]
	top:SetPoint("TOPLEFT", glow, "TOPLEFT")
	top:SetPoint("TOPRIGHT", glow, "TOPRIGHT")
	top:SetHeight(config.thickness)
	right:SetPoint("TOPRIGHT", glow, "TOPRIGHT", 0, trimCorners and -config.thickness or 0)
	right:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", 0, trimCorners and config.thickness or 0)
	right:SetWidth(config.thickness)
	bottom:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT")
	bottom:SetHeight(config.thickness)
	left:SetPoint("TOPLEFT", glow, "TOPLEFT", 0, trimCorners and -config.thickness or 0)
	left:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, trimCorners and config.thickness or 0)
	left:SetWidth(config.thickness)
end

local function ConfigureRestrictedPixelGlow(glow, config)
	local perimeter = 2 * (config.width + config.height)
	local cycle = perimeter / config.count
	local animationDuration = math.max(0.01, config.period / config.count)
	local edges = {
		{ texture = RESTRICTED_GLOW_HORIZONTAL_TEXTURE, length = config.width, dx = cycle * config.direction, dy = 0, base = 0 },
		{ texture = RESTRICTED_GLOW_VERTICAL_TEXTURE, length = config.height, dx = 0, dy = -cycle * config.direction, base = config.width / cycle },
		{ texture = RESTRICTED_GLOW_HORIZONTAL_TEXTURE, length = config.width, dx = -cycle * config.direction, dy = 0, base = (config.width + config.height) / cycle },
		{ texture = RESTRICTED_GLOW_VERTICAL_TEXTURE, length = config.height, dx = 0, dy = cycle * config.direction, base = ((config.width * 2) + config.height) / cycle },
	}

	glow.Edges = glow.Edges or {}
	for edgeIndex = 1, 4 do
		local edgeOptions = edges[edgeIndex]
		local edge = glow.Edges[edgeIndex]
		if not edge then
			edge = {}
			edge.mask = glow:CreateMaskTexture()
			edge.mask:SetTexture(RESTRICTED_GLOW_MASK_TEXTURE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			edge.strip = glow:CreateTexture(nil, "OVERLAY", nil, 7)
			edge.strip:AddMaskTexture(edge.mask)
			if edge.strip.SetBlendMode then edge.strip:SetBlendMode("ADD") end
			edge.animation = edge.strip:CreateAnimationGroup()
			edge.animation:SetLooping("REPEAT")
			edge.translation = edge.animation:CreateAnimation("Translation")
			edge.translation:SetSmoothing("NONE")
			glow.Edges[edgeIndex] = edge
		end
		edge.animation:Stop()
		edge.mask:ClearAllPoints()
		edge.strip:ClearAllPoints()
		edge.strip:SetTexture(edgeOptions.texture, "REPEAT", "REPEAT")
		edge.strip:SetVertexColor(config.r, config.g, config.b, config.a)
		local textureCycles = (edgeOptions.length + cycle) / cycle
		if edgeIndex == 1 then
			edge.mask:SetSize(edgeOptions.length, config.thickness)
			edge.mask:SetPoint("TOPLEFT", glow, "TOPLEFT", 0, 0)
			edge.strip:SetSize(edgeOptions.length + cycle, config.thickness)
			edge.strip:SetPoint("TOPLEFT", glow, "TOPLEFT", edgeOptions.dx > 0 and -cycle or 0, 0)
			edge.strip:SetTexCoord(edgeOptions.base, edgeOptions.base + textureCycles, 0, 1)
		elseif edgeIndex == 2 then
			edge.mask:SetSize(config.thickness, edgeOptions.length)
			edge.mask:SetPoint("TOPRIGHT", glow, "TOPRIGHT", 0, 0)
			edge.strip:SetSize(config.thickness, edgeOptions.length + cycle)
			if edgeOptions.dy < 0 then
				edge.strip:SetPoint("TOPRIGHT", glow, "TOPRIGHT", 0, cycle)
			else
				edge.strip:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", 0, -cycle)
			end
			edge.strip:SetTexCoord(0, 1, edgeOptions.base, edgeOptions.base + textureCycles)
		elseif edgeIndex == 3 then
			edge.mask:SetSize(edgeOptions.length, config.thickness)
			edge.mask:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, 0)
			edge.strip:SetSize(edgeOptions.length + cycle, config.thickness)
			edge.strip:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", edgeOptions.dx > 0 and -cycle or 0, 0)
			edge.strip:SetTexCoord(edgeOptions.base, edgeOptions.base + textureCycles, 0, 1)
		else
			edge.mask:SetSize(config.thickness, edgeOptions.length)
			edge.mask:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, 0)
			edge.strip:SetSize(config.thickness, edgeOptions.length + cycle)
			if edgeOptions.dy < 0 then
				edge.strip:SetPoint("TOPLEFT", glow, "TOPLEFT", 0, cycle)
			else
				edge.strip:SetPoint("BOTTOMLEFT", glow, "BOTTOMLEFT", 0, -cycle)
			end
			edge.strip:SetTexCoord(0, 1, edgeOptions.base, edgeOptions.base + textureCycles)
		end
		edge.translation:SetOffset(edgeOptions.dx, edgeOptions.dy)
		edge.translation:SetDuration(animationDuration)
		edge.strip:Show()
		edge.animation:Play()
	end
	if config.border then
		local borderConfig = {
			r = config.r,
			g = config.g,
			b = config.b,
			lineAlpha = config.a * 0.25,
			thickness = config.thickness,
		}
		ConfigureRestrictedLineBorder(glow, borderConfig, true)
	end
end

local function ConfigureRestrictedFlipBook(glow, key, assetType, asset, width, height, config, rows, columns, frames, duration, frameWidth, frameHeight)
	local data = glow[key]
	if not data then
		local texture = glow:CreateTexture(nil, "OVERLAY", nil, 7)
		texture:SetPoint("CENTER", glow, "CENTER")
		if texture.SetBlendMode then texture:SetBlendMode("ADD") end
		local animation = texture:CreateAnimationGroup()
		animation:SetLooping("REPEAT")
		local flipBook = animation:CreateAnimation("FlipBook")
		data = { texture = texture, animation = animation, flipBook = flipBook }
		glow[key] = data
	end
	data.animation:Stop()
	data.texture:SetSize(width, height)
	if assetType == "atlas" and data.texture.SetAtlas then
		data.texture:SetAtlas(asset, false)
	else
		data.texture:SetTexture(asset)
	end
	if data.texture.SetDesaturated then data.texture:SetDesaturated(true) end
	data.texture:SetVertexColor(config.r, config.g, config.b, config.a)
	data.texture:Show()
	data.flipBook:SetFlipBookRows(rows)
	data.flipBook:SetFlipBookColumns(columns)
	data.flipBook:SetFlipBookFrames(frames)
	data.flipBook:SetFlipBookFrameWidth(frameWidth or 0)
	data.flipBook:SetFlipBookFrameHeight(frameHeight or 0)
	data.flipBook:SetDuration(duration)
	data.animation:Play()
end

local function ConfigureRestrictedMarchingAntsGlow(glow, config)
	local scale = math.max(0.1, 1 + ((config.thickness - 2) * 0.1))
	local paddedWidth = config.baseWidth + 17 + (2 * config.inset)
	local paddedHeight = config.baseHeight + 17 + (2 * config.inset)
	ConfigureRestrictedFlipBook(
		glow,
		"MarchingAnts",
		"atlas",
		RESTRICTED_GLOW_MARCHING_ANTS_ATLAS,
		paddedWidth * scale,
		paddedHeight * scale,
		config,
		6,
		5,
		30,
		1
	)
end

local function ConfigureRestrictedFlashGlow(glow, config)
	local texture = glow.FlashTexture
	if not texture then
		texture = glow:CreateTexture(nil, "OVERLAY", nil, 7)
		texture:SetPoint("CENTER", glow, "CENTER")
		if texture.SetBlendMode then texture:SetBlendMode("ADD") end
		if texture.SetAtlas then texture:SetAtlas(RESTRICTED_GLOW_FLASH_ATLAS, false) end
		local animation = texture:CreateAnimationGroup()
		animation:SetLooping("BOUNCE")
		animation:SetToFinalAlpha(true)
		local alpha = animation:CreateAnimation("Alpha")
		alpha:SetOrder(1)
		alpha:SetSmoothing("IN_OUT")
		glow.FlashTexture = texture
		glow.FlashAnimation = animation
		glow.FlashAlpha = alpha
	end
	local scale = math.max(0.1, 1 + ((config.thickness - 2) * 0.1))
	texture:SetSize(math.max(1, (config.baseWidth * (66 / 45) * scale) + (2 * config.inset)), math.max(1, (config.baseHeight * (66 / 45) * scale) + (2 * config.inset)))
	if texture.SetDesaturated then texture:SetDesaturated(true) end
	texture:SetVertexColor(config.r, config.g, config.b, 1)
	texture:Show()
	glow.FlashAnimation:Stop()
	glow.FlashAlpha:SetFromAlpha(config.a * 0.25)
	glow.FlashAlpha:SetToAlpha(config.a)
	glow.FlashAlpha:SetDuration(math.max(0.05, math.abs(config.frequency ~= 0 and config.frequency or 0.25) * 2))
	glow.FlashAnimation:Play()
end

local function ConfigureRestrictedPulsingGlow(glow, config)
	local shape = config.shape
	local shaped = shape == "HEXAGON" or shape == "DIAMOND" or shape == "ROUND_STAR" or shape == "ROUND" or shape == "CIRCLE"
	if shaped then
		glow.ShapeLayers = glow.ShapeLayers or {}
		local layerCount = (shape == "ROUND" or shape == "CIRCLE") and 1 or 3
		for layerIndex = 1, layerCount do
			local texture = glow.ShapeLayers[layerIndex]
			if not texture then
				texture = glow:CreateTexture(nil, "OVERLAY", nil, 7)
				texture:SetPoint("CENTER", glow, "CENTER")
				if texture.SetBlendMode then texture:SetBlendMode("ADD") end
				glow.ShapeLayers[layerIndex] = texture
			end
			local grow = layerCount == 1 and (config.thickness * 2) or ((3 - layerIndex) * config.thickness)
			texture:SetSize(config.width + (grow * 2), config.height + (grow * 2))
			if shape == "ROUND" or shape == "CIRCLE" then
				if texture.SetAtlas then texture:SetAtlas(RESTRICTED_GLOW_ROUND_ATLAS, false) end
			elseif shape == "HEXAGON" then
				texture:SetTexture(RESTRICTED_GLOW_HEXAGON_TEXTURE)
			elseif shape == "DIAMOND" then
				texture:SetTexture(RESTRICTED_GLOW_DIAMOND_TEXTURE)
			else
				texture:SetTexture(RESTRICTED_GLOW_ROUND_STAR_TEXTURE)
			end
			local layerAlpha = layerCount == 1 and 1 or ({ 0.18, 0.35, 1 })[layerIndex]
			texture:SetVertexColor(config.r, config.g, config.b, layerAlpha)
			texture:Show()
		end
	else
		ConfigureRestrictedLineBorder(glow, config, true)
	end
	if not glow.PulseAnimation then
		local animation = glow:CreateAnimationGroup()
		animation:SetLooping("BOUNCE")
		animation:SetToFinalAlpha(true)
		local alpha = animation:CreateAnimation("Alpha")
		alpha:SetOrder(1)
		alpha:SetSmoothing("IN_OUT")
		glow.PulseAnimation = animation
		glow.PulseAlpha = alpha
	end
	glow.PulseAnimation:Stop()
	glow.PulseAlpha:SetFromAlpha(config.a * (shaped and 0.35 or 0.45))
	glow.PulseAlpha:SetToAlpha(config.a)
	glow.PulseAlpha:SetDuration(math.max(0.05, math.abs(config.frequency ~= 0 and config.frequency or 0.25) * 2))
	glow.PulseAnimation:Play()
end

local function ConfigureRestrictedBlizzardGlow(glow, config)
	local softGlow = glow.BlizzardSoftGlow
	if not softGlow then
		softGlow = glow:CreateTexture(nil, "ARTWORK", nil, 6)
		softGlow:SetPoint("CENTER", glow, "CENTER")
		softGlow:SetTexture(RESTRICTED_GLOW_BLIZZARD_TEXTURE)
		softGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
		if softGlow.SetBlendMode then softGlow:SetBlendMode("ADD") end
		glow.BlizzardSoftGlow = softGlow
	end
	local rootWidth = config.baseWidth + (2 * math.max(0, (config.baseWidth * 0.2) + config.inset))
	local rootHeight = config.baseHeight + (2 * math.max(0, (config.baseHeight * 0.2) + config.inset))
	softGlow:SetSize(rootWidth, rootHeight)
	if softGlow.SetDesaturated then softGlow:SetDesaturated(true) end
	softGlow:SetVertexColor(config.r, config.g, config.b, config.a)
	softGlow:Show()
	-- Match the legacy IconAlertAnts cycle used by normal spell-frame glows.
	local duration = 0.45 * (0.25 / math.max(0.01, config.frequency))
	ConfigureRestrictedFlipBook(
		glow,
		"BlizzardAnts",
		"texture",
		RESTRICTED_GLOW_BLIZZARD_ANTS_TEXTURE,
		rootWidth * 0.85,
		rootHeight * 0.85,
		config,
		5,
		5,
		22,
		math.max(0.001, duration),
		48,
		48
	)
end

local function ConfigureRestrictedTintBorderGlow(glow, config)
	if not config.borderEnabled then
		glow:SetAlpha(0)
		return
	end
	if config.borderIsBlizzard then
		local texture = glow.TintBlizzardBorder
		if not texture then
			texture = glow:CreateTexture(nil, "OVERLAY", nil, 7)
			if texture.SetAtlas then texture:SetAtlas(RESTRICTED_GLOW_BLIZZARD_BORDER_ATLAS, false) end
			glow.TintBlizzardBorder = texture
		end
		local offsetX = math.max(1, math.floor((config.baseWidth * 0.175) + 0.5))
		local offsetY = math.max(1, math.floor((config.baseHeight * 0.175) + 0.5))
		texture:ClearAllPoints()
		texture:SetPoint("TOPLEFT", glow, "TOPLEFT", -offsetX, offsetY)
		texture:SetPoint("BOTTOMRIGHT", glow, "BOTTOMRIGHT", offsetX, -offsetY)
		if texture.SetDesaturated then texture:SetDesaturated(true) end
		texture:SetVertexColor(config.r, config.g, config.b, config.a)
		texture:Show()
		return
	end
	if addon.functions and addon.functions.SetSafeBorder then
		addon.functions.SetSafeBorder(glow, true, config.borderTexture, config.borderSize, config.r, config.g, config.b, config.a, {
			stateKey = "_eqolRestrictedAuraTintBorder",
			defaultTexture = RESTRICTED_GLOW_MASK_TEXTURE,
			mediaType = "border",
			drawLayer = "OVERLAY",
		})
	else
		local borderConfig = {
			r = config.r,
			g = config.g,
			b = config.b,
			lineAlpha = config.a,
			thickness = config.borderSize,
		}
		ConfigureRestrictedLineBorder(glow, borderConfig, false, true)
	end
end

local function ConfigureRestrictedAuraGlow(glow, anchorFrame, options)
	if not (glow and anchorFrame) then return false end
	if glow.CanBeAccessedInContext and glow:CanBeAccessedInContext() ~= true then return false end
	local config = GetRestrictedAuraGlowConfig(anchorFrame, options)
	ConfigureRestrictedGlowRoot(glow, anchorFrame, config)
	if config.style == "BLIZZARD" then
		ConfigureRestrictedBlizzardGlow(glow, config)
	elseif config.style == "FLASH" then
		ConfigureRestrictedFlashGlow(glow, config)
	elseif config.style == "MARCHING_ANTS" then
		ConfigureRestrictedMarchingAntsGlow(glow, config)
	elseif config.style == "PULSING" then
		ConfigureRestrictedPulsingGlow(glow, config)
	elseif config.style == "SOLID" then
		ConfigureRestrictedLineBorder(glow, config, false, true)
		glow:SetAlpha(config.a)
	elseif config.style == "TINT_BORDER" then
		ConfigureRestrictedTintBorderGlow(glow, config)
	else
		ConfigureRestrictedPixelGlow(glow, config)
	end
	glow:Show()
	return true
end

function AuraCompat:CreateRestrictedAuraGlow(button, anchorFrame, options)
	if not (button and anchorFrame and type(CreateFrame) == "function") then return nil end
	local glow = CreateFrame("Frame", nil, button)
	glow:EnableMouse(false)
	if not ConfigureRestrictedAuraGlow(glow, anchorFrame, options) then return nil end
	return glow
end

function AuraCompat:UpdateRestrictedAuraGlow(glow, anchorFrame, options)
	return ConfigureRestrictedAuraGlow(glow, anchorFrame, options)
end

function AuraCompat:NormalizeFlowGroupLayout(container, options)
	if type(options) ~= "table" then return options end
	if options.elementSpacingX == nil
		and options.elementSpacingY == nil
		and options.gapX == nil
		and options.gapY == nil
		and options.forceNewRow == nil then
		return options
	end

	local normalized = {}
	for key, value in pairs(options) do
		if key ~= "elementSpacingX"
			and key ~= "elementSpacingY"
			and key ~= "gapX"
			and key ~= "gapY"
			and key ~= "forceNewRow" then
			normalized[key] = value
		end
	end

	local axis = self._flowLayoutAxisByContainer[container]
	local verticalAxis = _G.AnchorUtil
		and _G.AnchorUtil.FlowLayoutAxis
		and _G.AnchorUtil.FlowLayoutAxis.Vertical
		or 1
	local isVertical = axis == verticalAxis
	if normalized.elementSpacing == nil then
		normalized.elementSpacing = isVertical and (options.elementSpacingY or options.elementSpacingX)
			or (options.elementSpacingX or options.elementSpacingY)
	end
	if normalized.lineSpacing == nil then
		normalized.lineSpacing = isVertical and (options.elementSpacingX or options.elementSpacingY)
			or (options.elementSpacingY or options.elementSpacingX)
	end
	if normalized.groupSpacing == nil then
		normalized.groupSpacing = isVertical and (options.gapY or options.gapX) or (options.gapX or options.gapY)
	end
	if normalized.groupLineSpacing == nil then
		normalized.groupLineSpacing = isVertical and (options.gapX or options.gapY) or (options.gapY or options.gapX)
	end
	if normalized.forceNewLine == nil then normalized.forceNewLine = options.forceNewRow end
	return normalized
end

function AuraCompat:ConfigureAuraContainerLayout(container, options)
	if not HasRequiredContainerMethods(container) then return false end
	options = options or {}
	if type(options) ~= "table" then return false end

	local axis = options.axis
	if axis == nil then axis = options.layoutAxis end
	if axis ~= nil then
		if not CallContainerMethod(container, "SetFlowLayoutAxis", axis) then return false end
		self._flowLayoutAxisByContainer[container] = axis
	end
	if options.anchorPoint ~= nil and not CallContainerMethod(container, "SetFlowLayoutAnchorPoint", options.anchorPoint) then return false end
	if (options.horizontalGrowthDirection ~= nil or options.verticalGrowthDirection ~= nil)
		and (options.horizontalGrowthDirection == nil or options.verticalGrowthDirection == nil
			or not CallContainerMethod(container, "SetFlowLayoutGrowthDirection", options.horizontalGrowthDirection, options.verticalGrowthDirection)) then
		return false
	end
	if options.padding ~= nil then
		local padding = options.padding
		if type(padding) ~= "table"
			or not CallContainerMethod(container, "SetFlowLayoutPadding", padding.left or 0, padding.right or 0, padding.top or 0, padding.bottom or 0) then
			return false
		end
	end
	local maximumLineSize = options.maximumLineSize
	if maximumLineSize == nil then maximumLineSize = options.rowWidth end
	if maximumLineSize ~= nil and not CallContainerMethod(container, "SetFlowLayoutMaximumLineSize", maximumLineSize) then return false end
	return true
end

function AuraCompat:ResetAuraContainerLayout(container)
	if not HasRequiredContainerMethods(container) then return false end
	local called = CallContainerMethod(container, "ResetFlowLayoutOptions")
	if called then self._flowLayoutAxisByContainer[container] = nil end
	return called
end

function AuraCompat:UpdateAuraGroup(container, groupKey, options)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" or type(options) ~= "table" then return false end
	local hasGroupOK, hasGroup = CallContainerMethod(container, "HasAuraGroup", groupKey)
	if not hasGroupOK or hasGroup ~= true then return false end

	if options.filterString ~= nil then
		if type(options.filterString) ~= "string" or options.filterString == ""
			or not CallContainerMethod(container, "SetAuraGroupFilterString", groupKey, options.filterString) then
			return false
		end
		local registeredFilters = groupFiltersByContainer[container]
		if not registeredFilters then
			registeredFilters = {}
			groupFiltersByContainer[container] = registeredFilters
		end
		registeredFilters[groupKey] = options.filterString
	end
	if options.maxFrameCount ~= nil and not CallContainerMethod(container, "SetAuraGroupMaxFrameCount", groupKey, options.maxFrameCount) then return false end
	if options.candidateFilters ~= nil and not CallContainerMethod(container, "SetAuraGroupCandidateFilters", groupKey, options.candidateFilters) then return false end
	if options.sortMethod ~= nil or options.sortDirection ~= nil then
		if options.sortMethod == nil or options.sortDirection == nil
			or not CallContainerMethod(container, "SetAuraGroupSortMethod", groupKey, options.sortMethod, options.sortDirection) then
			return false
		end
	end
	if options.layout ~= nil
		and not CallContainerMethod(container, "SetAuraGroupLayout", groupKey, self:NormalizeFlowGroupLayout(container, options.layout)) then
		return false
	end
	return true
end

function AuraCompat:RegisterAuraGroup(container, groupKey, filterString, options)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" or type(filterString) ~= "string" then return false end
	options = options or {}
	if type(options) ~= "table" then return false end

	local hasGroupOK, hasGroup = CallContainerMethod(container, "HasAuraGroup", groupKey)
	if not hasGroupOK then return false end
	local registeredFilters = groupFiltersByContainer[container]
	if not registeredFilters then
		registeredFilters = {}
		groupFiltersByContainer[container] = registeredFilters
	end

	if hasGroup == true then
		if registeredFilters[groupKey] ~= filterString then
			if not CallContainerMethod(container, "SetAuraGroupFilterString", groupKey, filterString) then return false end
			registeredFilters[groupKey] = filterString
		end
		return self:UpdateAuraGroup(container, groupKey, options)
	end

	local inboundOptions = options
	if options.layout ~= nil then
		local normalizedLayout = self:NormalizeFlowGroupLayout(container, options.layout)
		if normalizedLayout ~= options.layout then
			inboundOptions = {}
			for key, value in pairs(options) do inboundOptions[key] = value end
			inboundOptions.layout = normalizedLayout
		end
	end
	if not CallContainerMethod(container, "AddAuraGroup", groupKey, filterString, inboundOptions) then return false end
	registeredFilters[groupKey] = filterString
	return true
end

function AuraCompat:GetAuraGroupFrame(container, groupKey, frameIndex)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" or type(frameIndex) ~= "number" then return nil end
	local called, frame = CallContainerMethod(container, "GetAuraGroupFrame", groupKey, frameIndex)
	if not called then return nil end
	return frame
end

function AuraCompat:GetAuraGroupFrameCount(container, groupKey)
	if not HasRequiredContainerMethods(container) or type(groupKey) ~= "string" or groupKey == "" then return 0 end
	local called, count = CallContainerMethod(container, "GetAuraGroupFrameCount", groupKey)
	if not called or type(count) ~= "number" then return 0 end
	return count
end

function AuraCompat:RegisterAuraSlot(container, slotKey, filterString, options)
	if not HasRequiredContainerMethods(container) or type(slotKey) ~= "string" or slotKey == "" or type(filterString) ~= "string" then return nil end
	options = options or {}
	if type(options) ~= "table" then return nil end

	local slots = slotFramesByContainer[container]
	if not slots then
		slots = {}
		slotFramesByContainer[container] = slots
	end
	-- PTR4 exposes AddAuraSlot on the public container, but HasAuraSlot only on
	-- its private mixin. AuraCompat owns the slot keys, so the local cache is
	-- the public-side idempotence guard.
	if slots[slotKey] then return slots[slotKey] end

	local added, slotFrame = CallContainerMethod(container, "AddAuraSlot", slotKey, filterString, GetInboundAuraSlotOptions(options))
	if not added or not slotFrame then return nil end
	slots[slotKey] = slotFrame
	return slotFrame
end

function AuraCompat:UpdateAuraSlot(container, slotKey, options)
	if not HasRequiredContainerMethods(container) or type(slotKey) ~= "string" or slotKey == "" or type(options) ~= "table" then return false end
	local slots = slotFramesByContainer[container]
	if not (slots and slots[slotKey]) then return false end
	if options.filterString ~= nil and not CallContainerMethod(container, "SetAuraSlotFilterString", slotKey, options.filterString) then return false end
	if options.candidateFilters ~= nil and not CallContainerMethod(container, "SetAuraSlotCandidateFilters", slotKey, options.candidateFilters) then return false end
	if options.sortMethod ~= nil or options.sortDirection ~= nil then
		if options.sortMethod == nil or options.sortDirection == nil
			or not CallContainerMethod(container, "SetAuraSlotSortMethod", slotKey, options.sortMethod, options.sortDirection) then
			return false
		end
	end
	return true
end

function AuraCompat:RegisterItemEnchantment(container, itemEnchantmentSlot, options)
	if not HasRequiredContainerMethods(container) or type(itemEnchantmentSlot) ~= "number" then return nil end
	options = options or {}
	if type(options) ~= "table" then return nil end
	local frames = itemEnchantmentFramesByContainer[container]
	if not frames then
		frames = {}
		itemEnchantmentFramesByContainer[container] = frames
	end
	if frames[itemEnchantmentSlot] then return frames[itemEnchantmentSlot] end
	local added, frame = CallContainerMethod(container, "AddItemEnchantment", itemEnchantmentSlot, GetInboundAuraSlotOptions(options))
	if not added or not frame then return nil end
	frames[itemEnchantmentSlot] = frame
	return frame
end

function AuraCompat:ConfigureItemEnchantmentLayout(container, options)
	if not HasRequiredContainerMethods(container) or type(options) ~= "table" then return false end
	return CallContainerMethod(container, "SetItemEnchantmentLayout", self:NormalizeFlowGroupLayout(container, options))
end

function AuraCompat:SetItemEnchantmentSortMethod(container, sortMethod, sortDirection)
	if not HasRequiredContainerMethods(container) then return false end
	return CallContainerMethod(container, "SetItemEnchantmentSortMethod", sortMethod, sortDirection)
end

function AuraCompat:UpdateAuraContainer(container)
	if not HasRequiredContainerMethods(container) then return false end
	return CallContainerMethod(container, "UpdateAllAuras")
end

function AuraCompat:RefreshAuraContainer(container, unit, configureFunc)
	if not HasRequiredContainerMethods(container) then return false end
	if unit ~= nil and not CallContainerMethod(container, "SetUnit", unit) then return false end
	if configureFunc then
		if type(configureFunc) ~= "function" then return false end
		if configureFunc(container, unit) == false then return false end
	end
	if not CallContainerMethod(container, "SetEnabled", true) then return false end
	CallContainerMethod(container, "Show")
	return self:UpdateAuraContainer(container)
end

function AuraCompat:DisableAuraContainer(container)
	if not HasRequiredContainerMethods(container) then return false end
	if not CallContainerMethod(container, "SetEnabled", false) then return false end
	CallContainerMethod(container, "Hide")
	return true
end

-- Kept as a semantic compatibility alias. PTR4 deliberately does not expose
-- ClearAuraGroups, so this disables the container without discarding groups.
function AuraCompat:ClearAuraContainer(container)
	return self:DisableAuraContainer(container)
end

function AuraCompat:MarkAurasBlocked(unit)
	self._restrictionSeen = true
	self._lastBlockedUnit = unit
	self._lastBlockedAuraInstanceID = nil
	self._lastBlockedAt = GetTime and GetTime() or nil
end

function AuraCompat:GetLastBlockedInfo()
	return self._restrictionSeen == true, self._lastBlockedUnit, self._lastBlockedAuraInstanceID, self._lastBlockedAt
end

function AuraCompat:RegisterRestrictionEvents(ownerFrame)
	if ownerFrame and ownerFrame.RegisterEvent then
		self._eventFrame = ownerFrame
	else
		if not self._eventFrame and type(CreateFrame) == "function" then self._eventFrame = CreateFrame("Frame") end
	end

	local frame = self._eventFrame
	if not frame then return false end
	if self._restrictionEventsRegistered then return true end

	if frame.RegisterEvent then frame:RegisterEvent("UNIT_AURA_BLOCKED") end
	if frame.SetScript then
		frame:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_AURA_BLOCKED" then AuraCompat:MarkAurasBlocked(unit) end
		end)
	end

	self._restrictionEventsRegistered = true
	return true
end

AuraCompat:RegisterRestrictionEvents()
