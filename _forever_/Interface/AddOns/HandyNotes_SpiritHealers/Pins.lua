local ADDON_NAME, ns = ...

local HandyNotes = _G.HandyNotes
if not HandyNotes then return end

local PLUGIN = ns.PLUGIN

-- Part of the ring the sharp art fills: the ring's own dark middle.
local ART_SIZE = ns.ART_SIZE or 0.6
local GLOW_SIZE = 1.7
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local GLOW = "Artifacts-PerkRing-WhiteGlow"

-- HandyNotes shares its pins between all plugins, so every plugin keeps its textures under its own keys.
local ART_KEY, GLOW_KEY, AURA_KEY = PLUGIN .. "Art", PLUGIN .. "Glow", PLUGIN .. "Aura"

local function ArtTexture(frame)
	local art = frame[ART_KEY]
	if not art then
		art = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		art:SetSnapToPixelGrid(false)
		art:SetTexelSnappingBias(0)
		local mask = frame:CreateMaskTexture()
		mask:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetAllPoints(art)
		art:AddMaskTexture(mask)
		frame[ART_KEY] = art
	end
	return art
end

local function GlowTexture(frame, key, layer)
	local glow = frame[key]
	if not glow then
		glow = frame:CreateTexture(nil, layer)
		glow:SetAtlas(GLOW)
		glow:SetBlendMode("ADD")
		frame[key] = glow
	end
	return glow
end

-- A soft glow that stays on, for pins that should stand out (ns.Aura returns its colour).
local function ShowAura(frame, node, size)
	local r, g, b = ns.Aura(node)
	if not r then
		if frame[AURA_KEY] then frame[AURA_KEY]:Hide() end
		return
	end
	local aura = GlowTexture(frame, AURA_KEY, "BACKGROUND")
	aura:ClearAllPoints()
	aura:SetPoint("CENTER", frame, "CENTER")
	aura:SetSize(size * GLOW_SIZE, size * GLOW_SIZE)
	aura:SetVertexColor(r, g, b)
	aura:SetAlpha(0.9)
	aura:Show()
end

-- Puts the sharp art in the middle of a pin that shows a ring icon. `settings` are the ones the pin is shown with
-- (the setup's previews pass their answers; the map uses the saved settings).
function ns.Decorate(frame, node, size, settings)
	if not (frame and frame.CreateTexture and frame.CreateMaskTexture) then return false end
	size = size or frame:GetWidth()
	if not size or size <= 0 then return false end
	local art = ArtTexture(frame)
	art:ClearAllPoints()
	art:SetPoint("CENTER", frame, "CENTER")
	art:SetSize(size * ART_SIZE, size * ART_SIZE)
	ns.SetArt(art, node, settings)
	art:Show()
	ShowAura(frame, node, size)
	return true
end

function ns.Undecorate(frame)
	if frame[ART_KEY] then frame[ART_KEY]:Hide() end
	if frame[GLOW_KEY] then frame[GLOW_KEY]:Hide() end
	if frame[AURA_KEY] then frame[AURA_KEY]:Hide() end
end

-- A soft glow in the pin's colour while the mouse is over it.
function ns.Highlight(frame, node, on)
	if not (frame and frame.CreateTexture) then return end
	if not on or not node then
		if frame[GLOW_KEY] then frame[GLOW_KEY]:Hide() end
		return
	end
	local glow = GlowTexture(frame, GLOW_KEY, "BACKGROUND")
	local size = (frame:GetWidth() or 0) * GLOW_SIZE
	glow:ClearAllPoints()
	glow:SetPoint("CENTER", frame, "CENTER")
	glow:SetSize(size, size)
	glow:SetVertexColor(ns.RingColor(node))
	glow:SetAlpha(0.8)
	glow:Show()
end

---------------------------------------------------------
-- Styling HandyNotes' pins
--
-- HandyNotes draws one texture per pin and shares its pins between all plugins, so after every redraw our
-- pins get the sharp art and pins that went to another plugin lose it again. If HandyNotes ever changes
-- how it does this, our pins simply keep showing the plain ring icon.

local worldPins, minimapPins = {}, {}

local function NodeOf(pin)
	return pin.pluginName == PLUGIN and pin.uiMapID and pin.coord and ns.FindNode(pin.uiMapID, pin.coord)
end

local function Style(pin, styled)
	local node = NodeOf(pin)
	if node and ns.Decorate(pin, node) then
		styled[pin] = true
	elseif styled[pin] then
		ns.Undecorate(pin)
		styled[pin] = nil
	end
end

local function ReleaseOthers(styled)
	for pin in pairs(styled) do
		if pin.pluginName ~= PLUGIN then
			ns.Undecorate(pin)
			styled[pin] = nil
		end
	end
end

local function OnWorldMapPlugin(provider, pluginName)
	ReleaseOthers(worldPins)
	if pluginName ~= PLUGIN then return end
	local map = provider.GetMap and provider:GetMap()
	if not (map and map.EnumeratePinsByTemplate) then return end
	for pin in map:EnumeratePinsByTemplate("HandyNotesWorldMapPinTemplate") do
		Style(pin, worldPins)
	end
end

local function OnMinimapPlugin(_, pluginName)
	ReleaseOthers(minimapPins)
	if pluginName ~= PLUGIN then return end
	local i = 1
	local pin = _G.HandyNotesPin1
	while pin do
		if pin.pluginName == PLUGIN then
			Style(pin, minimapPins)
		end
		i = i + 1
		pin = _G["HandyNotesPin" .. i]
	end
end

local provider = HandyNotes.WorldMapDataProvider
if type(provider) == "table" and type(provider.RefreshPlugin) == "function" then
	hooksecurefunc(provider, "RefreshPlugin", OnWorldMapPlugin)
end
if type(HandyNotes.UpdateMinimapPlugin) == "function" then
	hooksecurefunc(HandyNotes, "UpdateMinimapPlugin", OnMinimapPlugin)
end
