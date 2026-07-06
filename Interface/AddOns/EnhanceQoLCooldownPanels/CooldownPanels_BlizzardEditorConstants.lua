local DraggedItemMixin = {}
_G.EQOLCooldownPanelsBlizzardEditorDraggedItemMixin = DraggedItemMixin

function DraggedItemMixin:SetToCursor(texture)
	self.Icon:SetTexture(texture)
	self:Show()
end

function DraggedItemMixin:OnUpdate()
	local getTopLevel = _G.GetAppropriateTopLevelParent
	local topLevel = getTopLevel and getTopLevel() or UIParent
	local x, y
	local getScaledCursorPosition = _G.GetScaledCursorPositionForFrame
	if getScaledCursorPosition then
		x, y = getScaledCursorPosition(topLevel)
	else
		x, y = GetCursorPosition()
		local scale = topLevel:GetEffectiveScale()
		x, y = x / scale, y / scale
	end
	self:SetPoint("TOPLEFT", topLevel, "BOTTOMLEFT", x, y)
end

local ReorderMarkerMixin = {}
_G.EQOLCooldownPanelsBlizzardEditorReorderMarkerMixin = ReorderMarkerMixin

function ReorderMarkerMixin:SetHorizontal()
	self.Texture:SetAtlas("cdm-horizontal", true)
end

function ReorderMarkerMixin:SetVertical()
	self.Texture:SetAtlas("CDM-vertical", true)
end
