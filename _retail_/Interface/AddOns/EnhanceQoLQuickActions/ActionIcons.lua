local addon = _G.EnhanceQoL
local QC = addon.QuickCast
local atlasInfo = {}
local portraits = setmetatable({}, { __mode = "k" })
local portraitEvents

local function ensurePlayerPortrait(texture, parent)
	local portrait = texture._eqolQuickActionsPortrait
	if not portrait then
		local layer, sublevel = texture:GetDrawLayer()
		portrait = parent:CreateTexture(nil, layer, nil, math.min((sublevel or 0) + 1, 7))
		texture._eqolQuickActionsPortrait = portrait
		local mask = parent:CreateMaskTexture()
		mask:SetAtlas("UI-HUD-MicroMenu-Portrait-Mask", false)
		mask:SetPoint("CENTER", parent, "CENTER")
		portrait:AddMaskTexture(mask)
		portrait._eqolPortraitMask = mask
	end
	if not portraitEvents then
		portraitEvents = _G.CreateFrame("Frame")
		portraitEvents:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
		portraitEvents:RegisterEvent("PORTRAITS_UPDATED")
		portraitEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
		portraitEvents:SetScript("OnEvent", function(_, event, unit)
			if event == "UNIT_PORTRAIT_UPDATE" and unit ~= "player" then return end
			for owner in pairs(portraits) do
				if owner._eqolQuickActionsPortraitActive and owner:IsVisible() then _G.SetPortraitTexture(owner._eqolQuickActionsPortrait, "player") end
			end
		end)
	end
	portraits[texture] = true
	texture._eqolQuickActionsPortraitActive = true
	_G.SetPortraitTexture(portrait, "player")
	portrait:Show()
end

function QC:SetActionIconDesaturated(texture, desaturated)
	texture:SetDesaturated(desaturated)
	if texture._eqolQuickActionsPortraitActive then texture._eqolQuickActionsPortrait:SetDesaturated(desaturated) end
end

function QC:SetActionIconVertexColor(texture, ...)
	texture:SetVertexColor(...)
	if texture._eqolQuickActionsPortraitActive then texture._eqolQuickActionsPortrait:SetVertexColor(...) end
end

function QC:GetActionIconAtlas(action, fallback)
	if action.customIcon then return nil end
	if action.customIconAtlas then return action.customIconAtlas end
	-- Compiled actions can outlive a date change; resolve calendar art when showing them.
	if action.kind == "microMenu" and action.id == "calendar" then return select(5, self.MicroMenu:GetInfo("calendar")) end
	return fallback
end

function QC:ApplyActionIconAtlas(texture, parent, zoom, shape)
	local info = texture._eqolQuickActionsAtlasInfo
	if not info then return end
	local width, height = parent:GetSize()
	if texture._eqolQuickActionsPortraitActive then
		-- Keep the frame and portrait on the native 32 x 40 micro button canvas.
		local scale = math.min(width / math.max(info.width, 32), height / math.max(info.height, 40))
		texture:ClearAllPoints()
		texture:SetPoint("CENTER", parent, "CENTER")
		texture:SetSize(info.width * scale, info.height * scale)
		texture:SetTexCoord(0, 1, 0, 1)
		texture._eqolQuickActionsTexCoords = nil
		local portrait = texture._eqolQuickActionsPortrait
		portrait:ClearAllPoints()
		portrait:SetPoint("CENTER", parent, "CENTER")
		portrait:SetSize(18 * scale, 26 * scale)
		portrait._eqolPortraitMask:SetSize(35 * scale, 65 * scale)
		local coords = addon.IconShape.GetZoomTexCoords(zoom, 0)
		portrait:SetTexCoord(0.2 + 0.6 * coords[1], 0.2 + 0.6 * coords[2], 0.0666 + 0.8334 * coords[3], 0.0666 + 0.8334 * coords[4])
		local shapeMask = texture._eqolQuickActionsTextureMask
		if shapeMask then
			addon.IconShape.ApplyTextureMask(portrait, shapeMask, "_eqolQuickActionsTextureMask")
		else
			addon.IconShape.ClearTextureMask(portrait, "_eqolQuickActionsTextureMask")
		end
		return
	end
	local aspect = info.width / info.height
	if width > height * aspect then width = height * aspect else height = width / aspect end
	texture:ClearAllPoints()
	texture:SetPoint("CENTER", parent, "CENTER")
	texture:SetSize(width, height)

	-- SetAtlas already selects the entry; SetTexCoord is relative to that entry.
	local iconShape = addon.IconShape
	local coords = iconShape.GetZoomTexCoords(zoom, iconShape.Normalize(shape) == iconShape.SQUARE and 0.07 or 0)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	texture._eqolQuickActionsTexCoords = nil
end

function QC:SetActionIcon(texture, parent, icon, atlas, action)
	texture._eqolQuickActionsAtlasInfo = nil
	texture._eqolQuickActionsTexCoords = nil
	texture._eqolQuickActionsPortraitActive = nil
	if texture._eqolQuickActionsPortrait then texture._eqolQuickActionsPortrait:Hide() end
	texture:ClearAllPoints()
	texture:SetAllPoints(parent)
	if atlas and texture.SetAtlas then
		local info = atlasInfo[atlas]
		if not info and _G.C_Texture and _G.C_Texture.GetAtlasInfo then
			info = _G.C_Texture.GetAtlasInfo(atlas)
			if info and info.width > 0 and info.height > 0 then atlasInfo[atlas] = info else info = nil end
		end
		if info then
			texture:SetAtlas(atlas, false)
			texture._eqolQuickActionsAtlasInfo = info
			if action and action.kind == "microMenu" and action.id == "character" and not action.customIcon and not action.customIconAtlas then
				ensurePlayerPortrait(texture, parent)
			end
			self:ApplyActionIconAtlas(texture, parent, 0)
			return
		end
	end
	texture:SetTexture(icon or 134400)
	texture:SetTexCoord(0, 1, 0, 1)
end

-- Editor previews always identify item ranks, independently of the menu's runtime appearance.
function QC:GetEditorCraftingQualityAtlas(action)
	local tradeSkill = _G.C_TradeSkillUI
	if not (action and action.kind == "item" and tradeSkill) then return end
	local itemID = action.id
	if (_G.issecretvalue and _G.issecretvalue(itemID)) or type(itemID) ~= "number" or itemID <= 0 then return end
	if _G.C_Item and _G.C_Item.IsItemDataCachedByID and not _G.C_Item.IsItemDataCachedByID(itemID) then return end
	for _, method in ipairs({ "GetItemReagentQualityInfo", "GetItemCraftedQualityInfo" }) do
		if tradeSkill[method] then
			local ok, info = pcall(tradeSkill[method], itemID)
			if ok and not (_G.issecretvalue and _G.issecretvalue(info)) and type(info) == "table" and not (_G.issecrettable and _G.issecrettable(info)) then
				local atlas = info.iconInventory
				if not (_G.issecretvalue and _G.issecretvalue(atlas)) and type(atlas) == "string" and atlas ~= "" then return atlas end
			end
		end
	end
end

function QC:SetEditorCraftingQuality(texture, atlas)
	local badge = texture._eqolQuickActionsCraftingQuality
	if not atlas then
		if badge then badge:Hide() end
		return
	end
	if not badge then
		badge = texture:GetParent():CreateTexture(nil, "OVERLAY", nil, 7)
		badge:SetPoint("TOPLEFT", texture, "TOPLEFT", -3, 2)
		texture._eqolQuickActionsCraftingQuality = badge
	end
	badge:SetAtlas(atlas, true)
	badge:Show()
end
